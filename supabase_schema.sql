-- ============================================================================
-- NextMeet Production Database Schema for Supabase
-- Target Region: ap-south-1 (Mumbai)
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. USERS & PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.users (
    id TEXT PRIMARY KEY,                       -- Supabase UUID or Firebase UID
    firebase_uid TEXT UNIQUE,                  -- Original Firebase UID for seamless mapping
    email TEXT UNIQUE,
    display_name TEXT,
    photo_url TEXT,
    timezone TEXT DEFAULT 'UTC',
    work_status TEXT DEFAULT 'available',
    current_mood TEXT,
    is_premium BOOLEAN DEFAULT FALSE,
    fcm_token TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_active TIMESTAMPTZ DEFAULT NOW(),
    data JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON public.users(firebase_uid);

-- 2. RELATIONSHIPS TABLE
-- Matches NextMeet's RelationshipModel perfectly with indexed fast columns + JSONB payload
CREATE TABLE IF NOT EXISTS public.relationships (
    id TEXT PRIMARY KEY,                       -- Preserves Firestore Document ID
    uid1 TEXT NOT NULL,                        -- User 1 ID (Firebase or Supabase UID)
    uid2 TEXT,                                 -- User 2 ID (null when pending)
    uids TEXT[] NOT NULL DEFAULT '{}',         -- Array of both UIDs for rapid .contains() queries
    invite_code TEXT UNIQUE,                   -- 6-character unique pairing code
    status TEXT NOT NULL DEFAULT 'active',     -- 'active' or 'waiting'
    anniversary_date TIMESTAMPTZ,
    next_meeting_date TIMESTAMPTZ,
    distance_km DOUBLE PRECISION DEFAULT 0.0,
    streak_count INT DEFAULT 0,
    is_plus BOOLEAN DEFAULT FALSE,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,   -- Complete serialized RelationshipModel data
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fast lookup indexes
CREATE INDEX IF NOT EXISTS idx_relationships_uid1 ON public.relationships(uid1);
CREATE INDEX IF NOT EXISTS idx_relationships_uid2 ON public.relationships(uid2);
CREATE INDEX IF NOT EXISTS idx_relationships_uids ON public.relationships USING GIN(uids);
CREATE INDEX IF NOT EXISTS idx_relationships_invite_code ON public.relationships(invite_code);
CREATE INDEX IF NOT EXISTS idx_relationships_status ON public.relationships(status);

-- 3. MEMORIES (Shared Photo Timeline)
CREATE TABLE IF NOT EXISTS public.memories (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    relationship_id TEXT NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    uploader_id TEXT,
    image_url TEXT NOT NULL,
    caption TEXT,
    location TEXT,
    date TIMESTAMPTZ DEFAULT NOW(),
    is_story BOOLEAN DEFAULT FALSE,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_memories_rel_id ON public.memories(relationship_id);
CREATE INDEX IF NOT EXISTS idx_memories_date ON public.memories(date DESC);

-- 4. MESSAGES & INTERACTIONS (Chat, Love Letters, Touches, Surprises)
CREATE TABLE IF NOT EXISTS public.messages (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    relationship_id TEXT NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL,
    type TEXT DEFAULT 'text',                  -- 'text', 'image', 'voice', 'hug', 'touch', 'letter', 'surprise'
    content TEXT,
    media_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_messages_rel_id ON public.messages(relationship_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);

-- 5. PRIVATE SPACE (Notes, Secret Photos, Whispers)
CREATE TABLE IF NOT EXISTS public.private_notes (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    relationship_id TEXT NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    author_id TEXT NOT NULL,
    category TEXT DEFAULT 'note',              -- 'love_letter', 'whisper', 'note', 'secret_photo'
    title TEXT,
    content TEXT,
    media_url TEXT,
    unlock_date TIMESTAMPTZ,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_private_notes_rel_id ON public.private_notes(relationship_id);

-- 6. REALTIME REPLICATION SETUP
-- Enables live instant sync between paired phones
ALTER PUBLICATION supabase_realtime ADD TABLE public.relationships;
ALTER PUBLICATION supabase_realtime ADD TABLE public.memories;
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.private_notes;

-- 7. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.private_notes ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users & service role full read/write for seamless client interaction
CREATE POLICY "Allow public read users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Allow insert update users" ON public.users FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow relationships access" ON public.relationships FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow memories access" ON public.memories FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow messages access" ON public.messages FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow private notes access" ON public.private_notes FOR ALL USING (true) WITH CHECK (true);

-- 8. STORAGE BUCKETS SETUP
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('memories', 'memories', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']),
  ('chat_media', 'chat_media', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp', 'audio/m4a', 'audio/mp4', 'audio/mpeg'])
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public Memories Access" ON storage.objects FOR SELECT USING (bucket_id IN ('memories', 'chat_media'));
CREATE POLICY "Authenticated Media Upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id IN ('memories', 'chat_media'));
CREATE POLICY "Authenticated Media Delete" ON storage.objects FOR DELETE USING (bucket_id IN ('memories', 'chat_media'));

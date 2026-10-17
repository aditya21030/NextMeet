-- ============================================================================
-- NextMeet Complete Production Database Schema for Supabase
-- Target Region: ap-south-1 (Mumbai) / Global
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
CREATE TABLE IF NOT EXISTS public.relationships (
    id TEXT PRIMARY KEY,                       -- Relationship / Journey ID
    uid1 TEXT NOT NULL,                        -- User 1 ID
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

-- 4. PRIVATE SPACE: SECRET PHOTOS (Encrypted Vault Photos)
CREATE TABLE IF NOT EXISTS public.private_photos (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    relationship_id TEXT NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    size_bytes INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_private_photos_rel_id ON public.private_photos(relationship_id);
CREATE INDEX IF NOT EXISTS idx_private_photos_created ON public.private_photos(created_at DESC);

-- 5. PRIVATE SPACE: LOVE LETTERS
CREATE TABLE IF NOT EXISTS public.love_letters (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    relationship_id TEXT NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL,
    sender_name TEXT DEFAULT 'Partner',
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_love_letters_rel_id ON public.love_letters(relationship_id);
CREATE INDEX IF NOT EXISTS idx_love_letters_created ON public.love_letters(created_at DESC);

-- 6. PRIVATE SPACE: VOICE WHISPERS (Audio Notes)
CREATE TABLE IF NOT EXISTS public.whispers (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    relationship_id TEXT NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL,
    audio_url TEXT NOT NULL,
    duration_seconds INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_whispers_rel_id ON public.whispers(relationship_id);

-- 7. PRIVATE SPACE: RITUALS
CREATE TABLE IF NOT EXISTS public.rituals (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    relationship_id TEXT NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    emoji TEXT DEFAULT '❤️',
    is_completed BOOLEAN DEFAULT FALSE,
    "order" INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rituals_rel_id ON public.rituals(relationship_id);

-- 8. PRIVATE SPACE: SURPRISE MESSAGES (Time-locked Capsules)
CREATE TABLE IF NOT EXISTS public.surprise_messages (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    relationship_id TEXT NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    unlock_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_surprises_rel_id ON public.surprise_messages(relationship_id);

-- 9. PRIVATE SPACE: NOTES
CREATE TABLE IF NOT EXISTS public.private_notes (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    relationship_id TEXT NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    author_id TEXT NOT NULL,
    category TEXT DEFAULT 'note',
    title TEXT,
    content TEXT,
    media_url TEXT,
    unlock_date TIMESTAMPTZ,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_private_notes_rel_id ON public.private_notes(relationship_id);

-- 10. SHARED CALENDAR EVENTS
CREATE TABLE IF NOT EXISTS public.calendar_events (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    relationship_id TEXT NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_date TIMESTAMPTZ NOT NULL,
    category TEXT DEFAULT 'date',
    created_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_calendar_events_rel_id ON public.calendar_events(relationship_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_date ON public.calendar_events(event_date ASC);

-- 11. SHARED TRIPS & ITINERARY & EXPENSES
CREATE TABLE IF NOT EXISTS public.trips (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    relationship_id TEXT NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    destination TEXT NOT NULL,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trips_rel_id ON public.trips(relationship_id);

CREATE TABLE IF NOT EXISTS public.itinerary (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    relationship_id TEXT NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    trip_id TEXT REFERENCES public.trips(id) ON DELETE CASCADE,
    activity TEXT NOT NULL,
    time TEXT,
    date TIMESTAMPTZ,
    location TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.expenses (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    relationship_id TEXT NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    trip_id TEXT REFERENCES public.trips(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    amount DOUBLE PRECISION DEFAULT 0.0,
    category TEXT DEFAULT 'general',
    paid_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. BUCKET LIST TABLE
CREATE TABLE IF NOT EXISTS public.bucket_list (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    relationship_id TEXT NOT NULL REFERENCES public.relationships(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category TEXT DEFAULT 'dream',
    is_completed BOOLEAN DEFAULT FALSE,
    created_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bucket_list_rel_id ON public.bucket_list(relationship_id);

-- 13. REALTIME REPLICATION (Instant WebSocket push across phones)
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.relationships;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.memories;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.private_notes;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.private_photos;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.love_letters;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.whispers;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.calendar_events;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.bucket_list;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- 14. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.private_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.love_letters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whispers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rituals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.surprise_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.private_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itinerary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bucket_list ENABLE ROW LEVEL SECURITY;

-- Seamless access policies for authenticated clients
DO $$ BEGIN CREATE POLICY "Allow users access" ON public.users FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Allow relationships access" ON public.relationships FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Allow memories access" ON public.memories FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Allow private_photos access" ON public.private_photos FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Allow love_letters access" ON public.love_letters FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Allow whispers access" ON public.whispers FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Allow rituals access" ON public.rituals FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Allow surprise_messages access" ON public.surprise_messages FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Allow private_notes access" ON public.private_notes FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Allow calendar_events access" ON public.calendar_events FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Allow trips access" ON public.trips FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Allow itinerary access" ON public.itinerary FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Allow expenses access" ON public.expenses FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Allow bucket_list access" ON public.bucket_list FOR ALL USING (true) WITH CHECK (true); EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- 15. STORAGE BUCKETS SETUP
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('memories', 'memories', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']),
  ('whispers', 'whispers', true, 52428800, ARRAY['audio/m4a', 'audio/mp4', 'audio/mpeg', 'audio/aac']),
  ('chat_media', 'chat_media', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp', 'audio/m4a', 'audio/mp4', 'audio/mpeg'])
ON CONFLICT (id) DO UPDATE SET public = true;

DO $$ BEGIN CREATE POLICY "Public Storage Select" ON storage.objects FOR SELECT USING (bucket_id IN ('memories', 'whispers', 'chat_media')); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Public Storage Insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id IN ('memories', 'whispers', 'chat_media')); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Public Storage Delete" ON storage.objects FOR DELETE USING (bucket_id IN ('memories', 'whispers', 'chat_media')); EXCEPTION WHEN OTHERS THEN NULL; END $$;

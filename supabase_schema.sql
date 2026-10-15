-- NextMeet 2.0 Supabase Schema

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS TABLE
-- Extends the default Supabase auth.users table
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    display_name TEXT,
    photo_url TEXT,
    timezone TEXT DEFAULT 'UTC',
    work_status TEXT DEFAULT 'available', -- e.g., working, sleeping, available
    current_mood TEXT,
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_active TIMESTAMPTZ DEFAULT NOW()
);

-- 2. RELATIONSHIPS TABLE
-- Links two users together
CREATE TABLE public.relationships (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user1_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    user2_id UUID REFERENCES public.users(id) ON DELETE SET NULL, -- Can be null when invite is pending
    invite_code TEXT UNIQUE,
    status TEXT DEFAULT 'pending', -- pending, active
    created_at TIMESTAMPTZ DEFAULT NOW(),
    accepted_at TIMESTAMPTZ
);

-- 3. MEETUPS TABLE (The Planner Workspace)
-- Tracks the next physical meetup details
CREATE TABLE public.meetups (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    relationship_id UUID REFERENCES public.relationships(id) ON DELETE CASCADE,
    title TEXT DEFAULT 'Next Meetup',
    target_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    location TEXT,
    budget NUMERIC DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. MEETUP TASKS
-- Collaborative checklist for the meetup (visas, packing)
CREATE TABLE public.meetup_tasks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    meetup_id UUID REFERENCES public.meetups(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    assigned_to UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. UNIFIED MESSAGES (Inbox)
-- Handles chat, voice notes, love letters, and surprises
CREATE TABLE public.messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    relationship_id UUID REFERENCES public.relationships(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    message_type TEXT DEFAULT 'text', -- text, voice, love_letter, surprise
    content TEXT,
    media_url TEXT, -- For voice notes or image attachments
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ
);

-- 6. MEMORIES
-- Shared photo timeline
CREATE TABLE public.memories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    relationship_id UUID REFERENCES public.relationships(id) ON DELETE CASCADE,
    uploader_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    caption TEXT,
    partner_caption TEXT, -- Collaborative captions
    memory_date TIMESTAMPTZ DEFAULT NOW(), -- The date the photo was taken
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. FUTURE BOARD
-- Shared goals and dreams
CREATE TABLE public.future_goals (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    relationship_id UUID REFERENCES public.relationships(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    target_date TIMESTAMPTZ,
    is_achieved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ROW LEVEL SECURITY (RLS) POLICIES --
-- These ensure users can ONLY access data belonging to their relationship

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meetups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meetup_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.future_goals ENABLE ROW LEVEL SECURITY;

-- Example RLS Policy: Users can only read relationships they are a part of
CREATE POLICY "Users can view their own relationship" 
ON public.relationships FOR SELECT 
USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Example RLS Policy: Users can only read messages in their relationship
CREATE POLICY "Users can read relationship messages" 
ON public.messages FOR SELECT 
USING (
    relationship_id IN (
        SELECT id FROM public.relationships 
        WHERE user1_id = auth.uid() OR user2_id = auth.uid()
    )
);

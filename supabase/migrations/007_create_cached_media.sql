-- Migration: 007_create_cached_media.sql
-- Create table for indexing and querying cached generated media

CREATE TABLE IF NOT EXISTS public.cached_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('meal', 'workout')),
    display_name TEXT NOT NULL,
    image_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cached_media_key ON public.cached_media (key);

-- Allow public read access
ALTER TABLE public.cached_media ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read access to cached_media"
    ON public.cached_media FOR SELECT USING (true);
CREATE POLICY "Allow service role full access to cached_media"
    ON public.cached_media FOR ALL USING (auth.role() = 'service_role');

-- Migration: 004_add_comprehensive_onboarding_fields.sql
-- Adds detailed health, injury, equipment, and fitness routine customization fields.

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS target_focus_areas text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS body_fat_range text,
ADD COLUMN IF NOT EXISTS target_weight_kg numeric,
ADD COLUMN IF NOT EXISTS target_pace text,
ADD COLUMN IF NOT EXISTS weight_loss_history text,
ADD COLUMN IF NOT EXISTS lifestyle_issues text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS injuries text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS equipment text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS workout_days text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS workout_reminder boolean DEFAULT false;

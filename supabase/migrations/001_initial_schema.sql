-- FitForge Initial Schema
-- Run this in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User roles enum
CREATE TYPE user_role AS ENUM ('fitness_user', 'trainer');
CREATE TYPE subscription_tier AS ENUM ('free', 'pro', 'trainer');
CREATE TYPE fitness_goal AS ENUM ('lose_weight', 'build_muscle', 'endurance');
CREATE TYPE fitness_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE dietary_preference AS ENUM ('veg', 'non_veg', 'vegan');

-- Profiles (extends auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  role user_role DEFAULT 'fitness_user',
  subscription_tier subscription_tier DEFAULT 'free',
  ai_plans_used_this_month INT DEFAULT 0,
  ai_plans_reset_at TIMESTAMPTZ DEFAULT NOW(),
  razorpay_customer_id TEXT,
  razorpay_subscription_id TEXT,
  follower_count INT DEFAULT 0,
  bio TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workout plans
CREATE TABLE workout_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT 'My Workout Plan',
  goal fitness_goal NOT NULL,
  level fitness_level NOT NULL,
  days_per_week INT NOT NULL CHECK (days_per_week BETWEEN 1 AND 7),
  equipment TEXT[] DEFAULT '{}',
  plan_data JSONB NOT NULL DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Meal plans
CREATE TABLE meal_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT 'My Meal Plan',
  calorie_target INT NOT NULL,
  dietary_preference dietary_preference NOT NULL,
  allergies TEXT[] DEFAULT '{}',
  plan_data JSONB NOT NULL DEFAULT '{}',
  grocery_list JSONB DEFAULT '[]',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily progress logs
CREATE TABLE progress_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  weight_kg DECIMAL(5,2),
  workout_completed BOOLEAN DEFAULT false,
  water_ml INT DEFAULT 0,
  sleep_hours DECIMAL(3,1),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, log_date)
);

-- Progress photos
CREATE TABLE progress_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  photo_type TEXT NOT NULL CHECK (photo_type IN ('before', 'after')),
  storage_path TEXT NOT NULL,
  taken_at TIMESTAMPTZ DEFAULT NOW()
);

-- Marketplace programs
CREATE TABLE programs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trainer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  duration_weeks INT NOT NULL,
  price_inr INT NOT NULL,
  cover_image_url TEXT,
  workout_plan_data JSONB DEFAULT '{}',
  meal_plan_data JSONB DEFAULT '{}',
  pdf_resources JSONB DEFAULT '[]',
  preview_week_data JSONB DEFAULT '{}',
  is_published BOOLEAN DEFAULT false,
  purchase_count INT DEFAULT 0,
  avg_rating DECIMAL(3,2) DEFAULT 0,
  review_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Program purchases
CREATE TABLE program_purchases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  program_id UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
  buyer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount_inr INT NOT NULL,
  commission_inr INT NOT NULL,
  razorpay_payment_id TEXT,
  razorpay_order_id TEXT,
  purchased_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(program_id, buyer_id)
);

-- Program reviews
CREATE TABLE program_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  program_id UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(program_id, user_id)
);

-- Trainer followers
CREATE TABLE trainer_followers (
  trainer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  follower_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (trainer_id, follower_id)
);

-- AI coach chat messages
CREATE TABLE ai_chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Weekly AI insights
CREATE TABLE weekly_insights (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  week_start DATE NOT NULL,
  insight_text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, week_start)
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER workout_plans_updated_at BEFORE UPDATE ON workout_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER meal_plans_updated_at BEFORE UPDATE ON meal_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER programs_updated_at BEFORE UPDATE ON programs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE program_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE program_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_followers ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_insights ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Public profiles are viewable" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Workout plans
CREATE POLICY "Users manage own workout plans" ON workout_plans FOR ALL USING (auth.uid() = user_id);

-- Meal plans
CREATE POLICY "Users manage own meal plans" ON meal_plans FOR ALL USING (auth.uid() = user_id);

-- Progress logs
CREATE POLICY "Users manage own progress" ON progress_logs FOR ALL USING (auth.uid() = user_id);

-- Progress photos
CREATE POLICY "Users manage own photos" ON progress_photos FOR ALL USING (auth.uid() = user_id);

-- Programs
CREATE POLICY "Published programs are viewable" ON programs FOR SELECT
  USING (is_published = true OR auth.uid() = trainer_id);
CREATE POLICY "Trainers manage own programs" ON programs FOR ALL USING (auth.uid() = trainer_id);

-- Purchases
CREATE POLICY "Users see own purchases" ON program_purchases FOR SELECT
  USING (auth.uid() = buyer_id OR auth.uid() IN (SELECT trainer_id FROM programs WHERE id = program_id));
CREATE POLICY "Users create purchases" ON program_purchases FOR INSERT WITH CHECK (auth.uid() = buyer_id);

-- Reviews
CREATE POLICY "Reviews are viewable" ON program_reviews FOR SELECT USING (true);
CREATE POLICY "Buyers can review" ON program_reviews FOR INSERT
  WITH CHECK (auth.uid() = user_id AND EXISTS (
    SELECT 1 FROM program_purchases WHERE program_id = program_reviews.program_id AND buyer_id = auth.uid()
  ));

-- Followers
CREATE POLICY "Followers viewable" ON trainer_followers FOR SELECT USING (true);
CREATE POLICY "Users manage follows" ON trainer_followers FOR ALL USING (auth.uid() = follower_id);

-- AI chat
CREATE POLICY "Users manage own chat" ON ai_chat_messages FOR ALL USING (auth.uid() = user_id);

-- Weekly insights
CREATE POLICY "Users see own insights" ON weekly_insights FOR ALL USING (auth.uid() = user_id);

-- Storage buckets (run in Supabase dashboard)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('progress-photos', 'progress-photos', false);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('program-covers', 'program-covers', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('program-pdfs', 'program-pdfs', false);

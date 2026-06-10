-- Migration: Add Physique Data to Profiles
-- Adds height, weight, goal, and fitness level to the profiles table for personalized AI workouts.

ALTER TABLE profiles
ADD COLUMN height_cm INT,
ADD COLUMN weight_kg DECIMAL(5,2),
ADD COLUMN primary_goal fitness_goal DEFAULT 'build_muscle',
ADD COLUMN fitness_level fitness_level DEFAULT 'intermediate';

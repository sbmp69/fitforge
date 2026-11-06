-- Migration: 005_add_desired_body_fat.sql
-- Adds desired_body_fat column to profiles table for full goal tracking.

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS desired_body_fat text;

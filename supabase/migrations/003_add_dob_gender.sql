-- Add date_of_birth and gender columns to profiles table
ALTER TABLE profiles 
ADD COLUMN date_of_birth DATE,
ADD COLUMN gender TEXT;

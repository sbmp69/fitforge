-- Migration: 006_alter_dietary_preference_to_text.sql
-- Converts dietary_preference from rigid enum to TEXT so it flexibly supports all cuisines (e.g. Traditional Indian, High Protein, Keto, Mediterranean).

ALTER TABLE meal_plans ALTER COLUMN dietary_preference TYPE TEXT;

-- Migration: Add order columns to sub_skills and goals tables
-- Run this in your Supabase SQL Editor

-- Add order column to sub_skills table
ALTER TABLE sub_skills 
ADD COLUMN IF NOT EXISTS "order" INTEGER NOT NULL DEFAULT 0;

-- Add order column to goals table
ALTER TABLE goals 
ADD COLUMN IF NOT EXISTS "order" INTEGER NOT NULL DEFAULT 0;

-- Update existing records to have sequential order values
-- This ensures existing data has proper ordering
DO $$
DECLARE
  skill_rec RECORD;
  sub_skill_rec RECORD;
  goal_rec RECORD;
  order_idx INTEGER;
BEGIN
  -- Update sub_skills order
  FOR skill_rec IN SELECT DISTINCT skill_id FROM sub_skills LOOP
    order_idx := 0;
    FOR sub_skill_rec IN 
      SELECT id FROM sub_skills 
      WHERE skill_id = skill_rec.skill_id 
      ORDER BY created_at
    LOOP
      UPDATE sub_skills SET "order" = order_idx WHERE id = sub_skill_rec.id;
      order_idx := order_idx + 1;
    END LOOP;
  END LOOP;

  -- Update goals order
  FOR sub_skill_rec IN SELECT DISTINCT sub_skill_id FROM goals LOOP
    order_idx := 0;
    FOR goal_rec IN 
      SELECT id FROM goals 
      WHERE sub_skill_id = sub_skill_rec.sub_skill_id 
      ORDER BY created_at
    LOOP
      UPDATE goals SET "order" = order_idx WHERE id = goal_rec.id;
      order_idx := order_idx + 1;
    END LOOP;
  END LOOP;
END $$;


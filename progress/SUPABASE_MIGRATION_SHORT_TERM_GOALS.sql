-- Migration: Create short_term_goals table
-- Run this in your Supabase SQL Editor

-- Create short_term_goals table
CREATE TABLE IF NOT EXISTS short_term_goals (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  status INTEGER NOT NULL DEFAULT 0,
  difficulty INTEGER,
  due_date TIMESTAMPTZ,
  "order" INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Enable Row Level Security
ALTER TABLE short_term_goals ENABLE ROW LEVEL SECURITY;

-- Create policies for short_term_goals
-- Allow all operations for now (you can restrict later)
DROP POLICY IF EXISTS "Allow all operations on short_term_goals" ON short_term_goals;
CREATE POLICY "Allow all operations on short_term_goals"
  ON short_term_goals
  FOR ALL
  USING (true)
  WITH CHECK (true);


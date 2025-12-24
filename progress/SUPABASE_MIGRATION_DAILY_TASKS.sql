-- Migration: Create daily_tasks and daily_task_completions tables
-- Run this in your Supabase SQL Editor

-- Create daily_tasks table
CREATE TABLE IF NOT EXISTS daily_tasks (
  id TEXT PRIMARY KEY,
  short_term_goal_id TEXT NOT NULL,
  task_name TEXT NOT NULL,
  day_of_week INTEGER, -- 0 = Monday, 1 = Tuesday, ..., 6 = Sunday, null = specific date
  specific_date TIMESTAMPTZ, -- If day_of_week is null, use this specific date
  is_recurring BOOLEAN NOT NULL DEFAULT false,
  "order" INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create daily_task_completions table
CREATE TABLE IF NOT EXISTS daily_task_completions (
  id TEXT PRIMARY KEY,
  daily_task_id TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE daily_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_task_completions ENABLE ROW LEVEL SECURITY;

-- Create policies for daily_tasks
DROP POLICY IF EXISTS "Allow all operations on daily_tasks" ON daily_tasks;
CREATE POLICY "Allow all operations on daily_tasks"
  ON daily_tasks
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Create policies for daily_task_completions
DROP POLICY IF EXISTS "Allow all operations on daily_task_completions" ON daily_task_completions;
CREATE POLICY "Allow all operations on daily_task_completions"
  ON daily_task_completions
  FOR ALL
  USING (true)
  WITH CHECK (true);


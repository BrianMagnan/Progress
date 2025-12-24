-- Migration: Add is_daily column to daily_tasks table
-- Run this in your Supabase SQL Editor

-- Add is_daily column to daily_tasks table
ALTER TABLE daily_tasks 
ADD COLUMN IF NOT EXISTS is_daily BOOLEAN NOT NULL DEFAULT false;


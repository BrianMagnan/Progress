# Supabase Setup Instructions

## Step 1: Create Supabase Account

1. Go to https://supabase.com
2. Sign up for a free account
3. Create a new project
4. Choose a name (e.g., "progress-app")
5. Set a database password (save this!)
6. Choose a region closest to you
7. Wait for project to be created (~2 minutes)

## Step 2: Get Your API Keys

1. In your Supabase project dashboard, go to **Settings** → **API**
2. Copy the following:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon/public key** (long string starting with `eyJ...`)

## Step 3: Update Configuration

1. Open `lib/config/supabase_config.dart`
2. Replace `YOUR_SUPABASE_URL` with your Project URL
3. Replace `YOUR_SUPABASE_ANON_KEY` with your anon key

## Step 4: Create Database Tables

In your Supabase dashboard, go to **SQL Editor** and run this SQL:

```sql
-- Categories table
CREATE TABLE IF NOT EXISTS categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  "order" INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Skills table
CREATE TABLE IF NOT EXISTS skills (
  id TEXT PRIMARY KEY,
  category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  skill_level INTEGER,
  "order" INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sub-skills table
CREATE TABLE IF NOT EXISTS sub_skills (
  id TEXT PRIMARY KEY,
  skill_id TEXT NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  skill_level INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Goals table
CREATE TABLE IF NOT EXISTS goals (
  id TEXT PRIMARY KEY,
  sub_skill_id TEXT NOT NULL REFERENCES sub_skills(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status INTEGER NOT NULL DEFAULT 0, -- 0=not_started, 1=in_progress, 2=completed
  difficulty INTEGER, -- 0=easy, 1=medium, 2=hard
  estimated_hours INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Progress logs table
CREATE TABLE IF NOT EXISTS progress_logs (
  id TEXT PRIMARY KEY,
  goal_id TEXT NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  date TIMESTAMPTZ NOT NULL,
  notes TEXT,
  learned TEXT,
  struggled_with TEXT,
  next_steps TEXT,
  duration_minutes INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE sub_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_logs ENABLE ROW LEVEL SECURITY;

-- Create policies to allow all operations (for now - you can restrict later)
CREATE POLICY "Allow all operations on categories" ON categories
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all operations on skills" ON skills
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all operations on sub_skills" ON sub_skills
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all operations on goals" ON goals
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all operations on progress_logs" ON progress_logs
  FOR ALL USING (true) WITH CHECK (true);
```

## Step 5: Install Dependencies

Run:

```bash
cd /Users/brianmagnan/Coding/Projects/Progress/progress
flutter pub get
```

## Step 6: Test

The app will now use Supabase instead of local storage. Your data will be stored in the cloud and accessible from any device!

## Optional: Add Authentication

If you want user accounts later, Supabase has built-in authentication. We can add that in a future update.

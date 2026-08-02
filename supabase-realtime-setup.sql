-- ══════════════════════════════════════════════════════════════
-- My Kitchen — Realtime setup
-- Paste into Supabase → SQL Editor → Run
--
-- The app subscribes to changes with supabase-js, but that only works if
-- Postgres is actually publishing those changes.
--
-- A table must belong to the `supabase_realtime` publication. Without it,
-- no INSERT/UPDATE/DELETE event is ever sent — the client subscribes
-- successfully and then just waits forever, with no error anywhere.
--
-- As of the check on 2026-08-02, `grocery_items` was already published but
-- `recipes`, `recipe_ingredients` and `recipe_steps` were not, so recipe
-- changes have never synced between devices.
--
-- NOTE: an earlier version of this file also set REPLICA IDENTITY FULL,
-- claiming it was needed for deletes under RLS. That was wrong. Supabase's
-- docs are explicit that RLS is not applied to DELETE statements at all, and
-- that with RLS enabled the `old` record contains only primary keys either
-- way. The app only reads `old.id`, so nothing extra is required.
-- ══════════════════════════════════════════════════════════════


-- ── 1. CHECK WHAT'S ALREADY ENABLED ───────────────────────────
-- Run this first. Any table missing from the results is not syncing.

SELECT tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;


-- ── 2. ENABLE REALTIME ────────────────────────────────────────
-- Safe to re-run: adding a table that's already there raises an error,
-- so each statement is guarded.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'grocery_items'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE grocery_items;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'recipes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE recipes;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'recipe_ingredients'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE recipe_ingredients;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'recipe_steps'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE recipe_steps;
  END IF;
END $$;


-- ── 3. VERIFY ─────────────────────────────────────────────────
-- All four tables should now be listed.

SELECT tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND tablename IN ('grocery_items','recipes','recipe_ingredients','recipe_steps')
ORDER BY tablename;

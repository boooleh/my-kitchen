-- ══════════════════════════════════════════════════════════════
-- My Kitchen — Food box log ("cooked_log")
--
-- What this adds:
--   Every time you tick a recipe off "Planerat" on Home, the app now
--   logs a row here with the recipe and today's date. Home shows these
--   as a list of food boxes so you know when each one was cooked and
--   when it's getting old (6+ days). You clear a box yourself by
--   tapping its remove button — nothing here deletes automatically.
--
-- Run the whole file in Supabase → SQL Editor → Run.
-- Safe to run more than once: nothing here deletes or overwrites data.
-- ══════════════════════════════════════════════════════════════


-- ══════════════════════════════════════════════════════════════
-- PART 1 — TABLE
-- ══════════════════════════════════════════════════════════════

-- recipe_name/emoji/image_url are a snapshot taken at cook time, not a live
-- link — so a food box still shows correctly even if the recipe is later
-- renamed or deleted. recipe_id is kept too (ON DELETE SET NULL) so the
-- history survives a deleted recipe rather than disappearing with it.

CREATE TABLE IF NOT EXISTS cooked_log (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  recipe_id    uuid REFERENCES recipes(id) ON DELETE SET NULL,
  recipe_name  text NOT NULL,
  emoji        text,
  image_url    text,
  cooked_at    timestamptz NOT NULL DEFAULT now(),
  created_by   uuid REFERENCES auth.users(id)
);

CREATE INDEX IF NOT EXISTS cooked_log_household_idx ON cooked_log (household_id);


-- ══════════════════════════════════════════════════════════════
-- PART 2 — SECURITY
-- ══════════════════════════════════════════════════════════════
-- Same pattern as recipes/grocery_items: any member of the household can
-- view, add, and remove entries.

ALTER TABLE cooked_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view their cooked log" ON cooked_log;
CREATE POLICY "Members can view their cooked log"
ON cooked_log FOR SELECT
USING (
  household_id IN (
    SELECT household_id FROM household_members
    WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Members can add to their cooked log" ON cooked_log;
CREATE POLICY "Members can add to their cooked log"
ON cooked_log FOR INSERT
WITH CHECK (
  household_id IN (
    SELECT household_id FROM household_members
    WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Members can remove from their cooked log" ON cooked_log;
CREATE POLICY "Members can remove from their cooked log"
ON cooked_log FOR DELETE
USING (
  household_id IN (
    SELECT household_id FROM household_members
    WHERE user_id = auth.uid()
  )
);


-- ══════════════════════════════════════════════════════════════
-- PART 3 — REALTIME
-- ══════════════════════════════════════════════════════════════
-- Without this, the table works fine but changes never show up live on
-- the other phone — same gap that recipes had before supabase-add-missing.sql.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'cooked_log'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE cooked_log;
  END IF;
END $$;


-- ══════════════════════════════════════════════════════════════
-- PART 4 — VERIFY
-- ══════════════════════════════════════════════════════════════
-- Expect: cooked_log_table = 1, cooked_log_policies = 3, realtime_on = 1

SELECT
  (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'cooked_log')  AS cooked_log_table,
  (SELECT COUNT(*) FROM pg_policies
     WHERE tablename = 'cooked_log')                                AS cooked_log_policies,
  (SELECT COUNT(*) FROM pg_publication_tables
     WHERE pubname = 'supabase_realtime' AND tablename = 'cooked_log') AS realtime_on;

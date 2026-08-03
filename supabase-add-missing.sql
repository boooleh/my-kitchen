-- ══════════════════════════════════════════════════════════════
-- My Kitchen — add everything the app currently expects but the
-- database doesn't have yet.
--
-- Run the whole file in Supabase → SQL Editor → Run.
-- Safe to run more than once: nothing here deletes or overwrites data.
--
-- Two things are missing, both confirmed:
--
--   1. The recipe_ratings table doesn't exist. This is why your recipes
--      disappeared — the app asks for recipes and their ratings in one
--      query, and a join to a missing table fails the entire query, so
--      zero recipes come back. Your recipes are untouched in the database.
--
--   2. Only grocery_items is set up for realtime. recipes,
--      recipe_ingredients and recipe_steps are not, which is why recipe
--      changes have never appeared on the other phone automatically.
-- ══════════════════════════════════════════════════════════════


-- ══════════════════════════════════════════════════════════════
-- PART 1 — RECIPE RATINGS
-- ══════════════════════════════════════════════════════════════

-- One row per person per recipe, so everyone has their own opinion and the
-- app can show an average. Scale is 1–3:
--   1 = 😕 inte igen     2 = 🙂 helt ok     3 = 😍 favorit

CREATE TABLE IF NOT EXISTS recipe_ratings (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id   uuid NOT NULL REFERENCES recipes(id)    ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating      smallint NOT NULL CHECK (rating BETWEEN 1 AND 3),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),

  -- One rating per person per recipe. This is what makes changing your mind
  -- overwrite your old score instead of adding a second row and skewing the
  -- average. ON DELETE CASCADE above means deleting a recipe also removes
  -- its ratings, so the app's existing delete flow needs no extra step.
  UNIQUE (recipe_id, user_id)
);

CREATE INDEX IF NOT EXISTS recipe_ratings_recipe_idx ON recipe_ratings (recipe_id);


-- ── Security ──────────────────────────────────────────────────
-- You may read every rating on a recipe your household can see (that's how
-- the average works), but you may only write your own.

ALTER TABLE recipe_ratings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view ratings in their household" ON recipe_ratings;
CREATE POLICY "Members can view ratings in their household"
ON recipe_ratings FOR SELECT
USING (
  recipe_id IN (
    SELECT id FROM recipes
    WHERE household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid()
    )
    OR is_public = true
  )
);

DROP POLICY IF EXISTS "Users can add their own rating" ON recipe_ratings;
CREATE POLICY "Users can add their own rating"
ON recipe_ratings FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  AND recipe_id IN (
    SELECT id FROM recipes
    WHERE household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid()
    )
  )
);

DROP POLICY IF EXISTS "Users can change their own rating" ON recipe_ratings;
CREATE POLICY "Users can change their own rating"
ON recipe_ratings FOR UPDATE
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can remove their own rating" ON recipe_ratings;
CREATE POLICY "Users can remove their own rating"
ON recipe_ratings FOR DELETE
USING (user_id = auth.uid());


-- ── Keep updated_at honest ────────────────────────────────────

CREATE OR REPLACE FUNCTION set_recipe_rating_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS recipe_ratings_updated_at ON recipe_ratings;
CREATE TRIGGER recipe_ratings_updated_at
  BEFORE UPDATE ON recipe_ratings
  FOR EACH ROW EXECUTE FUNCTION set_recipe_rating_updated_at();


-- ══════════════════════════════════════════════════════════════
-- PART 2 — REALTIME
-- ══════════════════════════════════════════════════════════════

-- A table only sends live updates if it belongs to the supabase_realtime
-- publication. Without it the app connects successfully and then simply
-- never receives an event — no error anywhere, which is why this was easy
-- to miss. Guarded so re-running the file doesn't error.

DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['recipes','recipe_ingredients','recipe_steps','recipe_ratings']
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND tablename = t
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE %I', t);
    END IF;
  END LOOP;
END $$;


-- ══════════════════════════════════════════════════════════════
-- PART 3 — VERIFY
-- ══════════════════════════════════════════════════════════════

-- Expect: ratings_table = 1, rating_policies = 4, realtime_tables = 5
-- (grocery_items plus the four added above)

SELECT
  (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'recipe_ratings')  AS ratings_table,
  (SELECT COUNT(*) FROM pg_policies
     WHERE tablename = 'recipe_ratings')                               AS rating_policies,
  (SELECT COUNT(*) FROM pg_publication_tables
     WHERE pubname = 'supabase_realtime'
       AND tablename IN ('grocery_items','recipes','recipe_ingredients',
                         'recipe_steps','recipe_ratings'))             AS realtime_tables;


-- Your recipes should be back as soon as this finishes — reload the app.
-- Nothing above touches existing rows.

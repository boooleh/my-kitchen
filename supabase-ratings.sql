-- ══════════════════════════════════════════════════════════════
-- My Kitchen — recipe ratings
-- Paste into Supabase → SQL Editor → Run
--
-- One row per person per recipe, so everyone in the household has their own
-- opinion and the app can show an average. Scale is 1–3:
--   1 = 😕 inte igen    2 = 🙂 helt ok    3 = 😍 favorit
-- ══════════════════════════════════════════════════════════════


-- ── 1. TABLE ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS recipe_ratings (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id   uuid NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating      smallint NOT NULL CHECK (rating BETWEEN 1 AND 3),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),

  -- One rating per person per recipe. This is what makes the app's upsert
  -- work: rating again overwrites your previous score instead of adding
  -- a second row and skewing the average.
  UNIQUE (recipe_id, user_id)
);

-- ON DELETE CASCADE above means deleting a recipe removes its ratings too,
-- so the app's existing delete flow needs no extra step.

CREATE INDEX IF NOT EXISTS recipe_ratings_recipe_idx ON recipe_ratings (recipe_id);


-- ── 2. ROW LEVEL SECURITY ─────────────────────────────────────
-- You may read every rating on any recipe your household can see (that's how
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


-- ── 3. KEEP updated_at HONEST ─────────────────────────────────

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


-- ── 4. REALTIME ───────────────────────────────────────────────
-- So a rating your partner gives shows up on your phone without a reload.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'recipe_ratings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE recipe_ratings;
  END IF;
END $$;


-- ── 5. VERIFY ─────────────────────────────────────────────────

SELECT
  (SELECT COUNT(*) FROM pg_policies
    WHERE tablename = 'recipe_ratings')                     AS policies,
  (SELECT COUNT(*) FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND tablename = 'recipe_ratings')                     AS realtime_enabled;
-- Expect: policies = 4, realtime_enabled = 1

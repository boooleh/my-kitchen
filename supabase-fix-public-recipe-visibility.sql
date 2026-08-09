-- ══════════════════════════════════════════════════════════════
-- My Kitchen — Fix: public recipes were missing their ingredients & steps
--
-- THE BUG
--   A recipe is spread across three tables: recipes, recipe_ingredients
--   and recipe_steps. Each has its own rule about who may read it, and
--   the three rules disagreed:
--
--     recipes            → your household  OR  is_public = true
--     recipe_ingredients → your household                       ← no OR
--     recipe_steps       → your household                       ← no OR
--
--   So another family opening your public recipe in "Utforska" got the
--   name and emoji, but zero ingredients and zero steps. No error — the
--   database just returned an empty list, which looks like a broken
--   recipe rather than a permissions mismatch.
--
-- THE FIX
--   Add a second SELECT policy to each of the two child tables covering
--   public recipes. Postgres combines policies with OR, so the existing
--   household rule is untouched — this only widens reading to include
--   recipes that are already public anyway.
--
--   Deliberately SELECT only. Being able to READ a public recipe should
--   not let anyone WRITE to it; editing stays with the owning household
--   (and admins, via supabase-admin.sql).
--
-- Run the whole file in Supabase → SQL Editor → Run.
-- Safe to run more than once.
-- ══════════════════════════════════════════════════════════════


DROP POLICY IF EXISTS "Anyone can view public recipe ingredients" ON recipe_ingredients;
CREATE POLICY "Anyone can view public recipe ingredients"
ON recipe_ingredients FOR SELECT
USING (
  recipe_id IN (SELECT id FROM recipes WHERE is_public = true)
);

DROP POLICY IF EXISTS "Anyone can view public recipe steps" ON recipe_steps;
CREATE POLICY "Anyone can view public recipe steps"
ON recipe_steps FOR SELECT
USING (
  recipe_id IN (SELECT id FROM recipes WHERE is_public = true)
);


-- ══════════════════════════════════════════════════════════════
-- VERIFY
-- ══════════════════════════════════════════════════════════════
-- Expect 3 and 3 — the original household policy, the admin policy from
-- supabase-admin.sql, and the new public one added above.

SELECT
  (SELECT COUNT(*) FROM pg_policies
     WHERE tablename = 'recipe_ingredients' AND cmd = 'SELECT') AS ingredient_select_policies,
  (SELECT COUNT(*) FROM pg_policies
     WHERE tablename = 'recipe_steps'       AND cmd = 'SELECT') AS step_select_policies;

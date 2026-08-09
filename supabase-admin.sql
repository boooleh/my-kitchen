-- ══════════════════════════════════════════════════════════════
-- My Kitchen — Admin (moderation + usage stats)
--
-- What this adds:
--   1. An `app_admins` table. Being listed here makes you an admin.
--   2. Admins can edit, unpublish, or delete PUBLIC recipes only.
--      Private household data stays private — an admin still cannot read
--      another family's private recipes, grocery list, or food boxes.
--   3. An `admin_stats()` function returning usage COUNTS only — never
--      names, emails, or content.
--
-- IMPORTANT — why this is SQL and not JavaScript:
--   The anon key ships inside index.html, so anything checked in the
--   browser ("if (isAdmin) show button") can be bypassed by editing the
--   page. The rules below run inside Postgres, where the browser can't
--   reach them. The app's admin UI is only a convenience; THIS is the
--   actual security.
--
-- Run the whole file in Supabase → SQL Editor → Run.
-- Safe to run more than once.
-- ══════════════════════════════════════════════════════════════


-- ══════════════════════════════════════════════════════════════
-- PART 1 — WHO IS AN ADMIN
-- ══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS app_admins (
  user_id    uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  note       text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE app_admins ENABLE ROW LEVEL SECURITY;

-- Deliberately: there is NO insert, update, or delete policy on this table.
-- That means no logged-in user can make themselves (or anyone else) an
-- admin through the app, no matter what they send. The only way in is the
-- SQL editor, which is you. This is the single most important line in the
-- file — an admin table the app can write to is not a security boundary.

DROP POLICY IF EXISTS "You can see your own admin row" ON app_admins;
CREATE POLICY "You can see your own admin row"
ON app_admins FOR SELECT
USING (user_id = auth.uid());


-- Helper used by every policy below.
-- SECURITY DEFINER means it runs with the table owner's rights, which lets
-- it read app_admins without triggering that table's own RLS. Without this
-- you get infinite recursion: the policy checks the table, which checks
-- the policy, forever.
CREATE OR REPLACE FUNCTION is_app_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (SELECT 1 FROM app_admins WHERE user_id = auth.uid());
$$;


-- ══════════════════════════════════════════════════════════════
-- PART 2 — MODERATION POWERS (PUBLIC RECIPES ONLY)
-- ══════════════════════════════════════════════════════════════

-- These are ADDITIONAL policies. Postgres combines policies with OR, so
-- normal members keep exactly the access they already had — this only
-- widens what an admin can reach, and only for is_public = true rows.

-- Note the separate WITH CHECK: USING tests the row as it exists now,
-- WITH CHECK tests the row after the edit. Unpublishing sets is_public to
-- false, so if WITH CHECK also demanded is_public = true, the unpublish
-- would fail — the row would no longer satisfy its own policy.

DROP POLICY IF EXISTS "Admins can update public recipes" ON recipes;
CREATE POLICY "Admins can update public recipes"
ON recipes FOR UPDATE
USING (is_public = true AND is_app_admin())
WITH CHECK (is_app_admin());

DROP POLICY IF EXISTS "Admins can delete public recipes" ON recipes;
CREATE POLICY "Admins can delete public recipes"
ON recipes FOR DELETE
USING (is_public = true AND is_app_admin());


-- Editing a recipe means editing its ingredients and steps too, so the
-- same reach is needed on those tables — still scoped to public recipes.

DROP POLICY IF EXISTS "Admins can view public recipe ingredients" ON recipe_ingredients;
CREATE POLICY "Admins can view public recipe ingredients"
ON recipe_ingredients FOR SELECT
USING (is_app_admin() AND recipe_id IN (SELECT id FROM recipes WHERE is_public = true));

DROP POLICY IF EXISTS "Admins can add public recipe ingredients" ON recipe_ingredients;
CREATE POLICY "Admins can add public recipe ingredients"
ON recipe_ingredients FOR INSERT
WITH CHECK (is_app_admin() AND recipe_id IN (SELECT id FROM recipes WHERE is_public = true));

DROP POLICY IF EXISTS "Admins can update public recipe ingredients" ON recipe_ingredients;
CREATE POLICY "Admins can update public recipe ingredients"
ON recipe_ingredients FOR UPDATE
USING (is_app_admin() AND recipe_id IN (SELECT id FROM recipes WHERE is_public = true));

DROP POLICY IF EXISTS "Admins can delete public recipe ingredients" ON recipe_ingredients;
CREATE POLICY "Admins can delete public recipe ingredients"
ON recipe_ingredients FOR DELETE
USING (is_app_admin() AND recipe_id IN (SELECT id FROM recipes WHERE is_public = true));


DROP POLICY IF EXISTS "Admins can view public recipe steps" ON recipe_steps;
CREATE POLICY "Admins can view public recipe steps"
ON recipe_steps FOR SELECT
USING (is_app_admin() AND recipe_id IN (SELECT id FROM recipes WHERE is_public = true));

DROP POLICY IF EXISTS "Admins can add public recipe steps" ON recipe_steps;
CREATE POLICY "Admins can add public recipe steps"
ON recipe_steps FOR INSERT
WITH CHECK (is_app_admin() AND recipe_id IN (SELECT id FROM recipes WHERE is_public = true));

DROP POLICY IF EXISTS "Admins can update public recipe steps" ON recipe_steps;
CREATE POLICY "Admins can update public recipe steps"
ON recipe_steps FOR UPDATE
USING (is_app_admin() AND recipe_id IN (SELECT id FROM recipes WHERE is_public = true));

DROP POLICY IF EXISTS "Admins can delete public recipe steps" ON recipe_steps;
CREATE POLICY "Admins can delete public recipe steps"
ON recipe_steps FOR DELETE
USING (is_app_admin() AND recipe_id IN (SELECT id FROM recipes WHERE is_public = true));


-- ══════════════════════════════════════════════════════════════
-- PART 3 — USAGE STATS (COUNTS ONLY)
-- ══════════════════════════════════════════════════════════════

-- You wanted to see how many people use the app. This returns numbers and
-- nothing else — no emails, no names, no recipe content. That's deliberate:
-- if this account is ever compromised, "how many users exist" is a much
-- smaller leak than "here is every user".
--
-- SECURITY DEFINER lets it count auth.users, which normal users can't read.
-- That makes the is_app_admin() check on the first line essential — without
-- it, ANY logged-in user could call this and get the numbers.

CREATE OR REPLACE FUNCTION admin_stats()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_app_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  RETURN json_build_object(
    'users',          (SELECT COUNT(*) FROM auth.users),
    'households',     (SELECT COUNT(*) FROM households),
    'recipes',        (SELECT COUNT(*) FROM recipes),
    'public_recipes', (SELECT COUNT(*) FROM recipes WHERE is_public = true),
    'food_boxes',     (SELECT COUNT(*) FROM cooked_log),
    'grocery_items',  (SELECT COUNT(*) FROM grocery_items),
    'new_users_7d',   (SELECT COUNT(*) FROM auth.users
                         WHERE created_at > now() - interval '7 days')
  );
END;
$$;

-- Anonymous visitors should never be able to call this.
REVOKE ALL ON FUNCTION admin_stats() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION admin_stats() TO authenticated;


-- ══════════════════════════════════════════════════════════════
-- PART 4 — MAKE YOURSELF AN ADMIN
-- ══════════════════════════════════════════════════════════════

-- This grants admin to whichever account matches the email below.
-- Change the email if you sign in with a different one.
-- Re-running is harmless: ON CONFLICT means it won't create duplicates.

INSERT INTO app_admins (user_id, note)
SELECT id, 'Amanda — owner'
FROM auth.users
WHERE email = 'amanda.bohlin@outlook.com'
ON CONFLICT (user_id) DO NOTHING;


-- ══════════════════════════════════════════════════════════════
-- PART 5 — VERIFY
-- ══════════════════════════════════════════════════════════════

-- admin_count should be 1. If it's 0, the email above didn't match any
-- account — check which address you actually signed up with.
-- recipe_admin_policies should be 2, ingredient/step ones 4 each.

SELECT
  (SELECT COUNT(*) FROM app_admins)                          AS admin_count,
  (SELECT COUNT(*) FROM pg_policies
     WHERE tablename = 'recipes'
       AND policyname LIKE 'Admins can%')                    AS recipe_admin_policies,
  (SELECT COUNT(*) FROM pg_policies
     WHERE tablename = 'recipe_ingredients'
       AND policyname LIKE 'Admins can%')                    AS ingredient_admin_policies,
  (SELECT COUNT(*) FROM pg_policies
     WHERE tablename = 'recipe_steps'
       AND policyname LIKE 'Admins can%')                    AS step_admin_policies;

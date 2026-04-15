-- ══════════════════════════════════════════════════════════════
-- My Kitchen — Row Level Security (RLS) Policies
-- Paste this entire file into Supabase → SQL Editor → Run
-- ══════════════════════════════════════════════════════════════


-- ── 1. HOUSEHOLDS ─────────────────────────────────────────────
-- Users can only see and edit the household they belong to.

ALTER TABLE households ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their household"
ON households FOR SELECT
USING (
  id IN (
    SELECT household_id FROM household_members
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Authenticated users can create a household"
ON households FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Members can update their household"
ON households FOR UPDATE
USING (
  id IN (
    SELECT household_id FROM household_members
    WHERE user_id = auth.uid()
  )
);


-- ── 2. HOUSEHOLD_MEMBERS ──────────────────────────────────────
-- Users can see their own membership, join households, and leave.

ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own membership"
ON household_members FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can join a household"
ON household_members FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can leave a household"
ON household_members FOR DELETE
USING (user_id = auth.uid());


-- ── 3. GROCERY_LISTS ──────────────────────────────────────────
-- Only members of the household can see and manage their lists.

ALTER TABLE grocery_lists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their grocery lists"
ON grocery_lists FOR SELECT
USING (
  household_id IN (
    SELECT household_id FROM household_members
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Members can create grocery lists"
ON grocery_lists FOR INSERT
WITH CHECK (
  household_id IN (
    SELECT household_id FROM household_members
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Members can update their grocery lists"
ON grocery_lists FOR UPDATE
USING (
  household_id IN (
    SELECT household_id FROM household_members
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Members can delete their grocery lists"
ON grocery_lists FOR DELETE
USING (
  household_id IN (
    SELECT household_id FROM household_members
    WHERE user_id = auth.uid()
  )
);


-- ── 4. GROCERY_ITEMS ──────────────────────────────────────────
-- Items belong to a list, which belongs to a household.
-- Access is checked by following that chain.

ALTER TABLE grocery_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their grocery items"
ON grocery_items FOR SELECT
USING (
  grocery_list_id IN (
    SELECT id FROM grocery_lists
    WHERE household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid()
    )
  )
);

CREATE POLICY "Members can add grocery items"
ON grocery_items FOR INSERT
WITH CHECK (
  grocery_list_id IN (
    SELECT id FROM grocery_lists
    WHERE household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid()
    )
  )
);

CREATE POLICY "Members can update grocery items"
ON grocery_items FOR UPDATE
USING (
  grocery_list_id IN (
    SELECT id FROM grocery_lists
    WHERE household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid()
    )
  )
);

CREATE POLICY "Members can delete grocery items"
ON grocery_items FOR DELETE
USING (
  grocery_list_id IN (
    SELECT id FROM grocery_lists
    WHERE household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid()
    )
  )
);


-- ── 5. RECIPES ────────────────────────────────────────────────
-- Only members of the household can see and manage their recipes.

ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their recipes"
ON recipes FOR SELECT
USING (
  household_id IN (
    SELECT household_id FROM household_members
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Members can create recipes"
ON recipes FOR INSERT
WITH CHECK (
  household_id IN (
    SELECT household_id FROM household_members
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Members can update their recipes"
ON recipes FOR UPDATE
USING (
  household_id IN (
    SELECT household_id FROM household_members
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Members can delete their recipes"
ON recipes FOR DELETE
USING (
  household_id IN (
    SELECT household_id FROM household_members
    WHERE user_id = auth.uid()
  )
);


-- ── 6. RECIPE_INGREDIENTS ─────────────────────────────────────
-- Ingredients belong to a recipe, which belongs to a household.

ALTER TABLE recipe_ingredients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view recipe ingredients"
ON recipe_ingredients FOR SELECT
USING (
  recipe_id IN (
    SELECT id FROM recipes
    WHERE household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid()
    )
  )
);

CREATE POLICY "Members can add recipe ingredients"
ON recipe_ingredients FOR INSERT
WITH CHECK (
  recipe_id IN (
    SELECT id FROM recipes
    WHERE household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid()
    )
  )
);

CREATE POLICY "Members can update recipe ingredients"
ON recipe_ingredients FOR UPDATE
USING (
  recipe_id IN (
    SELECT id FROM recipes
    WHERE household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid()
    )
  )
);

CREATE POLICY "Members can delete recipe ingredients"
ON recipe_ingredients FOR DELETE
USING (
  recipe_id IN (
    SELECT id FROM recipes
    WHERE household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid()
    )
  )
);


-- ── 7. RECIPE_STEPS ───────────────────────────────────────────
-- Steps belong to a recipe, which belongs to a household.

ALTER TABLE recipe_steps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view recipe steps"
ON recipe_steps FOR SELECT
USING (
  recipe_id IN (
    SELECT id FROM recipes
    WHERE household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid()
    )
  )
);

CREATE POLICY "Members can add recipe steps"
ON recipe_steps FOR INSERT
WITH CHECK (
  recipe_id IN (
    SELECT id FROM recipes
    WHERE household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid()
    )
  )
);

CREATE POLICY "Members can update recipe steps"
ON recipe_steps FOR UPDATE
USING (
  recipe_id IN (
    SELECT id FROM recipes
    WHERE household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid()
    )
  )
);

CREATE POLICY "Members can delete recipe steps"
ON recipe_steps FOR DELETE
USING (
  recipe_id IN (
    SELECT id FROM recipes
    WHERE household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid()
    )
  )
);

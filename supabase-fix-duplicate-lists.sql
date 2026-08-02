-- ══════════════════════════════════════════════════════════════
-- My Kitchen — find and repair duplicate grocery lists
--
-- The app assumed one grocery_list per household, but nothing enforced it.
-- If two ever got created, each phone could end up subscribed to a different
-- list — both look normal, neither sees the other's items.
--
-- Run the sections in order. Section 1 only reads; nothing changes until 2.
-- ══════════════════════════════════════════════════════════════


-- ── 1. DIAGNOSE ───────────────────────────────────────────────
-- How many lists does each household have? Anything above 1 is the bug.

SELECT
  h.name        AS household,
  h.id          AS household_id,
  COUNT(gl.id)  AS list_count,
  MIN(gl.created_at) AS oldest_list
FROM households h
LEFT JOIN grocery_lists gl ON gl.household_id = h.id
GROUP BY h.id, h.name
ORDER BY list_count DESC;


-- Which items sit on which list?
SELECT
  gl.id           AS list_id,
  gl.created_at   AS list_created,
  COUNT(gi.id)    AS items
FROM grocery_lists gl
LEFT JOIN grocery_items gi ON gi.grocery_list_id = gl.id
GROUP BY gl.id, gl.created_at
ORDER BY gl.household_id, gl.created_at;


-- ── 2. REPAIR ─────────────────────────────────────────────────
-- Keeps the OLDEST list per household (the app now picks the oldest too),
-- moves every item onto it, then removes the leftovers.
-- No items are deleted — they're relocated.

WITH keeper AS (
  SELECT DISTINCT ON (household_id)
         household_id,
         id AS keep_id
  FROM grocery_lists
  ORDER BY household_id, created_at ASC
)
UPDATE grocery_items gi
SET grocery_list_id = k.keep_id
FROM grocery_lists gl
JOIN keeper k ON k.household_id = gl.household_id
WHERE gi.grocery_list_id = gl.id
  AND gl.id <> k.keep_id;


-- Delete the now-empty duplicate lists.
WITH keeper AS (
  SELECT DISTINCT ON (household_id)
         household_id,
         id AS keep_id
  FROM grocery_lists
  ORDER BY household_id, created_at ASC
)
DELETE FROM grocery_lists gl
USING keeper k
WHERE gl.household_id = k.household_id
  AND gl.id <> k.keep_id;


-- ── 3. PREVENT IT HAPPENING AGAIN ─────────────────────────────
-- One list per household, enforced by the database. Even if two phones race
-- to create one at the same moment, the second insert now fails instead of
-- quietly producing a second list.

CREATE UNIQUE INDEX IF NOT EXISTS grocery_lists_one_per_household
  ON grocery_lists (household_id);


-- ── 4. VERIFY ─────────────────────────────────────────────────
-- Every household should now show list_count = 1.

SELECT
  h.name       AS household,
  COUNT(gl.id) AS list_count
FROM households h
LEFT JOIN grocery_lists gl ON gl.household_id = h.id
GROUP BY h.id, h.name
ORDER BY list_count DESC;

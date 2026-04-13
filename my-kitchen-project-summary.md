# My Kitchen — Project Summary

## What is this app?
A family food app built as a clean, minimal web app with an orange accent color.
Design style: Option C — white background, lots of breathing room, Syne + Plus Jakarta Sans fonts, orange (#ff6b35) as the accent color.

---

## Current Version: V1 ✅
A fully working downloadable HTML file (`my-kitchen.html`).

### Features in V1:
- 🛒 **Grocery list** — add, check off, and clear items. Saves to browser localStorage.
- 📖 **Recipes** — manually add recipes with name, emoji, time, category, ingredients and steps.
- 👨‍🍳 **Cooking mode** — full screen dark mode, landscape layout with ingredients on the left and one step at a time on the right. Steps have checkboxes in the recipe detail view.
- 💾 Everything saves locally to the browser (localStorage). No backend needed for V1.

### Deliberately removed from V1 (saved for V3):
- ❌ Fridge AI (needs backend + API key)
- ❌ URL recipe import (needs backend + API key)

---

## Roadmap

### V2 — Family Sync (in progress)
Goal: Let multiple people (e.g. you and your partner) share the same grocery list and recipes in real time.

**Tech stack chosen:**
- **Supabase** — database, authentication, real-time sync
- **Netlify or Vercel** — free hosting
- **GitHub** — code storage and version control

**Supabase database — all 7 tables created ✅**

| Table | Purpose |
|---|---|
| `households` | The family group. Has a short invite_code to share with partner |
| `household_members` | Links users to a household. Role = owner or member |
| `recipes` | Recipes owned by a household |
| `recipe_ingredients` | Ingredients for each recipe, with sort_order |
| `recipe_steps` | Steps for each recipe, with sort_order |
| `grocery_lists` | A household can have multiple lists |
| `grocery_items` | Items in a list, with checked status and added_by |

**Foreign key relationships:**
- `household_members.household_id` → `households.id` (cascade delete)
- `household_members.user_id` → `auth.users.id`
- `recipes.household_id` → `households.id` (cascade delete)
- `recipes.created_by` → `auth.users.id`
- `recipe_ingredients.recipe_id` → `recipes.id` (cascade delete)
- `recipe_steps.recipe_id` → `recipes.id` (cascade delete)
- `grocery_lists.household_id` → `households.id` (cascade delete)
- `grocery_items.grocery_list_id` → `grocery_lists.id` (cascade delete)
- `grocery_items.added_by` → `auth.users.id`

**Next steps for V2:**
1. Get Supabase Project URL and Anon public key from Project Settings → API
2. Connect app to Supabase using their JavaScript library
3. Add login screen (email + password)
4. Add create/join household flow with invite code
5. Migrate grocery list to Supabase with real-time sync
6. Migrate recipes to Supabase

### V3 — AI Features (planned)
- 🧊 What's in the fridge? — type ingredients, AI suggests recipes
- 🔗 Import recipe from URL — backend fetches page, AI extracts recipe
- ✨ Paste recipe text — AI extracts structured recipe data

---

## Design Details
- **Font:** Syne (headings, bold) + Plus Jakarta Sans (body)
- **Accent color:** #ff6b35 (orange)
- **Background:** #ffffff
- **Gray scale:** #f7f7f7 / #eeeeee / #bbbbbb / #888888
- **Border radius:** 12px (small) / 18px (medium) / 26px (large)
- **Style:** Clean minimal, lots of white space, rounded corners, no borders

---

## Other App Ideas Saved for Later
- ⏰ "We're late" mode
- 🎨 Activity idea generator
- 💌 Appreciation jar
- 🔧 Home maintenance log
- 🌟 Swedish alphabet learning app for kids (age 4)

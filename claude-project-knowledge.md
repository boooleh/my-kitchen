# My Kitchen — Full Project Summary for Claude

## Who am I?
- Mom of two kids (one is 4 years old)
- Lives with partner
- Product designer wanting to improve design skills and learn coding
- Based in Gothenburg, Sweden
- Learning frontend development alongside building this app

---

## My Kitchen App

### What is it?
A family food web app. Clean, minimal design with a warm orange accent.
Built as a single HTML file, no frameworks, no build tools — just HTML, CSS and JavaScript.

### Design System
- **Style:** Option C — minimal with a pop
- **Fonts:** Syne (headings) + Plus Jakarta Sans (body)
- **Accent color:** #ff6b35 (orange)
- **Light backgrounds:** #ffffff / #f7f7f7 / #eeeeee
- **Text grays:** #bbbbbb / #888888 / #111111
- **Border radius:** 12px small / 18px medium / 26px large
- **Feel:** Lots of white space, rounded corners, friendly but clean

---

## Version Roadmap

### V1 ✅ Complete
Single downloadable HTML file. No backend needed. Works offline.

**Features:**
- 🛒 Grocery list — add, check off, clear items (saves to localStorage)
- 📖 Recipes — manually add with name, emoji, time, category, ingredients, steps
- 👨‍🍳 Cooking mode — full screen dark mode, landscape layout, ingredients left / steps right, step checkboxes in recipe detail view

**Removed from V1 (saved for V3):**
- Fridge AI feature
- URL recipe import
- AI text extraction

---

### V2 — Family Sync (in progress)
Goal: Share grocery list and recipes in real time between household members.

**Tech stack:**
- Supabase (database + auth + real-time)
- GitHub (version control)
- Netlify or Vercel (free hosting)
- Visual Studio Code (code editor)

**Status:**
- ✅ Supabase account created
- ✅ All 7 database tables created
- ⏳ Next: get Supabase API credentials and connect the app

**Database tables:**

| Table | Purpose |
|---|---|
| `households` | Family group with invite_code to share with partner |
| `household_members` | Links users to a household, role = owner or member |
| `recipes` | Recipes owned by a household |
| `recipe_ingredients` | Ingredients per recipe with sort_order |
| `recipe_steps` | Steps per recipe with sort_order |
| `grocery_lists` | Lists owned by a household |
| `grocery_items` | Items with checked status and added_by |

**Foreign keys:**
- `household_members.household_id` → `households.id` (cascade delete)
- `household_members.user_id` → `auth.users.id`
- `recipes.household_id` → `households.id` (cascade delete)
- `recipes.created_by` → `auth.users.id`
- `recipe_ingredients.recipe_id` → `recipes.id` (cascade delete)
- `recipe_steps.recipe_id` → `recipes.id` (cascade delete)
- `grocery_lists.household_id` → `households.id` (cascade delete)
- `grocery_items.grocery_list_id` → `grocery_lists.id` (cascade delete)
- `grocery_items.added_by` → `auth.users.id`

**V2 build order:**
1. Get Supabase Project URL + Anon public key (Project Settings → API)
2. Connect app to Supabase via JS library
3. Build login screen (email + password)
4. Build create/join household flow with invite code
5. Migrate grocery list to Supabase + real-time sync
6. Migrate recipes to Supabase

---

### V3 — AI Features (planned)
- 🧊 What's in the fridge? — type ingredients, AI suggests recipes
- 🔗 Import recipe from URL — backend fetches page, AI extracts recipe
- ✨ Paste recipe text — AI extracts structured recipe data

**Note:** All AI features need a backend to hide the API key securely. URL import also needs a backend due to browser CORS restrictions.

---

## Other App Ideas (saved for later)
- ⏰ "We're late" mode — countdown + checklist before leaving the house
- 🎨 Activity idea generator — "I'm bored" button for kids
- 💌 Appreciation jar — digital notes for partner
- 🔧 Home maintenance log — track when things were last serviced
- 🌟 Swedish alphabet learning app — for 4 year old, all 29 letters including Å Ä Ö, tap to hear, fun and colorful

---

## Instructions for Claude
- Always keep the orange (#ff6b35) accent color
- Always use Syne + Plus Jakarta Sans fonts
- Keep the minimal clean style — lots of white space
- App is called "My Kitchen"
- User is learning to code so explain things clearly when making changes
- Keep V1 as a simple downloadable HTML file
- V2 connects to Supabase for family sync
- Never add AI features until V3

# Yumbook — Production Smoke-Test Runbook

Operational guide for standing up the Django backend against **Supabase production**,
loading data, verifying the API, and running a Flutter end-to-end smoke test.

> Scope: deployment/verification only. No application logic is changed by this document.
> Paths assume repo root `…/yumbook/app/yumbook_app` with `backend/` and `frontend/`.

---

## 1. Backend runbook — Supabase production setup

### 1.1 Prerequisites
- Python 3.12+ and `pip`, Git.
- A Supabase project (Postgres + Auth + Storage).
- Backend deps: `backend/requirements.txt`
  (Django 6.0.4, DRF 3.17.1, django-cors-headers, python-dotenv, supabase, psycopg[binary], dj-database-url, drf-spectacular).

### 1.2 Supabase project setup (one-time)
1. **Database** — Project → Settings → Database → Connection string. Use the **connection pooler** URI (port `6543`) for serverless/concurrent workloads, or the direct connection (`5432`). This is `DATABASE_URL`.
2. **Auth** — Project → Settings → API. Copy:
   - Project URL → `SUPABASE_URL`
   - `anon` public key → `SUPABASE_ANON_KEY` (backend validates user JWTs with this)
   - `service_role` key → `SUPABASE_SERVICE_ROLE_KEY` (server-only; never ship to the client)
3. **Storage** — create a bucket for restaurant/food images (default name `restaurants`). Set `SUPABASE_STORAGE_BUCKET` to match.
4. **Admin role for API writes** — the API treats a Supabase user as admin when their `app_metadata.role == "admin"` (see `reservations/authentication.py`). Set this on the operator's auth user to allow `POST/PUT/PATCH/DELETE /api/restaurants/`.

### 1.3 Install & configure
```bash
cd backend
python -m venv venv
# Windows:  venv\Scripts\activate     |  Linux/macOS:  source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # then fill in real values (see §2)
```

### 1.4 Run the server
- **Smoke test / staging:**
  ```bash
  python manage.py runserver 0.0.0.0:8000
  ```
- **Production:** serve the WSGI app behind a real server, e.g.
  ```bash
  pip install gunicorn
  gunicorn yumbook_server.wsgi:application --bind 0.0.0.0:8000 --workers 3
  python manage.py collectstatic --noinput     # serve admin/static assets
  ```
- Set Django host/CORS for prod in `yumbook_server/settings.py`:
  - `DEBUG = False`
  - add your domain to `ALLOWED_HOSTS`
  - replace `CORS_ALLOW_ALL_ORIGINS = True` with an explicit `CORS_ALLOWED_ORIGINS` list (the app domain). *(These are currently dev-friendly defaults — harden before go-live.)*

### 1.5 Django admin (for the CSV import UI, §4)
The Django admin site uses **Django** auth (separate from Supabase). Create a superuser:
```bash
python manage.py createsuperuser
```
Then the admin import page is at `/admin/restaurants/restaurant/import-csv/`.

---

## 2. Required environment variables

File: `backend/.env` (loaded by `python-dotenv`; see `.env.example`).

| Variable | Required | Purpose | Notes |
|---|---|---|---|
| `DATABASE_URL` | **Yes (prod)** | Django ORM → Supabase Postgres | `postgresql://USER:PASS@HOST:PORT/DBNAME`. If unset, Django falls back to local SQLite (`db.sqlite3`) — dev only. `SUPABASE_DB_URL` is accepted as an alias. |
| `DATABASE_SSL` | Recommended | Force SSL on the DB connection | `true` (Supabase recommended). Set `false` only for local. |
| `SUPABASE_URL` | **Yes** | Supabase REST/Auth/Storage base | `https://<project-ref>.supabase.co` |
| `SUPABASE_ANON_KEY` | **Yes** | Validates incoming user JWTs (`auth.get_user`) | `SUPABASE_KEY` accepted as fallback. |
| `SUPABASE_SERVICE_ROLE_KEY` | For Storage admin | Server-side privileged ops (image uploads) | **Never expose to clients.** |
| `SUPABASE_STORAGE_BUCKET` | Optional | Image bucket name | Defaults to `restaurants`. |

**Frontend (Flutter)** — set the API base URL at build time:
| Variable | Where | Purpose |
|---|---|---|
| `DJANGO_API_BASE_URL` | `--dart-define` at build/run | Points the app at the deployed backend. If unset, the app auto-detects (Codespaces `-8000` host, Android emulator `10.0.2.2`, else `127.0.0.1:8000`) — override for prod. |

Example: `flutter run --dart-define=DJANGO_API_BASE_URL=https://api.yourdomain.com`

---

## 3. Migration commands

Run from `backend/` with the venv active and `.env` pointing at the target DB.

```bash
# Apply all migrations to the (Supabase) database — required before first use
python manage.py migrate

# Verify there are no unapplied / missing migrations (CI-safe check; makes no changes)
python manage.py makemigrations --check --dry-run

# Inspect migration state
python manage.py showmigrations
```

Notes:
- **Do not** run `makemigrations` against production to author schema; generate migrations in dev, commit them, then `migrate` in prod.
- App migrations present: `restaurants`, `reservations`, `food_records`, `accounts` (profile/dining-prefs/notification-settings/saved-restaurants/payment-methods/transactions).
- The test runner builds an isolated test DB; tests never touch prod data. To run tests against SQLite regardless of env, clear DB vars first (see §6).

---

## 4. CSV import commands

The importer ingests **already-hosted image URLs** (no binary upload). Logic lives in `restaurants/importer.py`, shared by the CLI command and the admin upload view.

### 4.1 Expected CSV header (canonical)
```
name,region,category,image_url,address,description,rating
```
Optional columns: `is_primary` (default `true`), `storage_path` (Supabase Storage path).

Mapping: `category→raw_category`, `address→location`, `image_url→Restaurant.image_url` + one primary `RestaurantImage`; `region` is a **slug** → `Region.get_or_create` (name defaults to `SLUG.upper()`). Restaurants are upserted by `(name, region)`.

A ready-to-run example lives at **`backend/sample_data/restaurants_canonical_sample.csv`** (12 restaurants across `insadong`, `hongdae`, `itaewon`, `seongsu`, `gangnam`, using `placehold.co` placeholder images). Its header is the canonical columns plus three forward-compatible columns:
```
name,region,category,image_url,address,description,rating,price_level,latitude,longitude
```
> **Note:** `price_level`, `latitude`, and `longitude` are included for completeness/future use but are **not consumed by the current `import_restaurants` importer** — they are silently ignored (extra CSV columns are harmless). Populate restaurant `price_level`/`lat`/`lng` via Django admin or a future importer change. The seven canonical columns above are the ones actually imported today.

### 4.2 Command
```bash
# Dry run first — validates & reports counts, writes nothing
python manage.py import_restaurants sample_data/restaurants_canonical_sample.csv --dry-run

# Import new restaurants (existing (name,region) rows are skipped)
python manage.py import_restaurants sample_data/restaurants_canonical_sample.csv

# Import and also update fields on existing restaurants
python manage.py import_restaurants sample_data/restaurants_canonical_sample.csv --update
```
(Substitute your own CSV path for production data.) Output reports `restaurants created/updated/skipped`, `regions created`, `images created/updated`, and any per-row warnings.

### 4.3 Admin UI alternative
Logged in as a Django superuser: `/admin/restaurants/restaurant/import-csv/` (same importer, same columns).

### 4.4 About `backend/sample_data/restaurants.csv` (raw Webflow export)
This is a **raw source export** (Webflow-style headers: `nameEnglish`, `Category 1`, `image`, `Price ($)`, …) and is **NOT** in the canonical import format. **It must be transformed before any production import.** Map it to the canonical schema — use `backend/sample_data/restaurants_canonical_sample.csv` as the target template:

| Raw Webflow column | → Canonical column |
|---|---|
| `nameEnglish` | `name` |
| (derive from Location/area) | `region` (slug, e.g. `hongdae`) |
| `Category 1` (or chosen `Category n`) | `category` |
| `image` | `image_url` |
| `Address (English)` | `address` |
| `Restaurant Description` | `description` |
| (rating source, else `0`) | `rating` |
| `Price ($)` | `price_level` *(not imported today — see §4.1 note)* |

#### Transformer script (raw Webflow → canonical)
`backend/scripts/transform_webflow_restaurants.py` automates the mapping above (standalone, no Django needed). It keeps a row when `name` **and** `region` are derivable, leaves missing optional fields blank, drops non-`http(s)` image references (e.g. Wix `wix:image://…`), and normalizes the five home regions (`Insadong/Hongdae/Itaewon/Seongsu/Gangnam` → slug); other regions are slugified with a warning.

```bash
# 1) Transform — dry run (reports rows read/written/skipped + warnings, writes nothing)
python scripts/transform_webflow_restaurants.py sample_data/restaurants.csv sample_data/restaurants_canonical_from_webflow.csv --dry-run

# 2) Transform — write the canonical CSV
python scripts/transform_webflow_restaurants.py sample_data/restaurants.csv sample_data/restaurants_canonical_from_webflow.csv

# 3) Import — dry run against the DB
python manage.py import_restaurants sample_data/restaurants_canonical_from_webflow.csv --dry-run

# 4) Import — apply (use --update to refresh existing rows)
python manage.py import_restaurants sample_data/restaurants_canonical_from_webflow.csv --update
```

Review the transformer's warnings before importing:
- **`non-URL image reference dropped`** — the raw export uses Wix internal refs, so `image_url` comes out blank and no `RestaurantImage` is created. Supply real hosted URLs (Supabase Storage) in the `image` column, or fill `image_url` in the canonical CSV before import.
- **`non-standard region`** — the raw export spans many areas beyond the five home regions (e.g. Jeju, Incheon). Each becomes its own slug/Region. If you only want the five home regions live, filter the canonical CSV (or deactivate extra regions in admin) before/after import.

After transforming, always run `import_restaurants … --dry-run` first and review the created/updated/skipped counts and warnings before the real import.

### 4.5 Dev-only seeding (never in prod)
`python manage.py seed_restaurants [--flush]` inserts hardcoded mock restaurants for local UI work. **Do not run against production.**

---

## 5. Verifying API endpoints

Base: `https://<your-backend-host>`. List endpoints return **bare JSON arrays**.

### 5.1 Public (no auth)
```bash
# OpenAPI docs (sanity that the app booted)
curl -s https://HOST/api/schema/ | head
#   Swagger UI:  https://HOST/api/docs/      ReDoc: https://HOST/api/redoc/

# Regions (home tabs) and restaurants
curl -s https://HOST/api/regions/
curl -s https://HOST/api/restaurants/
curl -s "https://HOST/api/restaurants/?region=hongdae"
curl -s "https://HOST/api/restaurants/?cuisine=Korean&price=2&ordering=-rating"
curl -s "https://HOST/api/restaurants/?bbox=126.9,37.5,127.1,37.6"
curl -s https://HOST/api/restaurants/1/
```
Expect HTTP 200. An invalid `bbox` (e.g. `1,2,3`) must return **400**.

### 5.2 Authenticated — get a token
Use a real Supabase user JWT. Quick way via the GoTrue REST API:
```bash
TOKEN=$(curl -s -X POST "https://<project-ref>.supabase.co/auth/v1/token?grant_type=password" \
  -H "apikey: <SUPABASE_ANON_KEY>" -H "Content-Type: application/json" \
  -d '{"email":"smoke@yourdomain.com","password":"••••••"}' | python -c "import sys,json;print(json.load(sys.stdin)['access_token'])")
```

### 5.3 Authenticated endpoints
```bash
AUTH="Authorization: Bearer $TOKEN"

# Reservations
curl -s -H "$AUTH" https://HOST/api/reservations/
curl -s -H "$AUTH" -H "Content-Type: application/json" -X POST https://HOST/api/reservations/ \
  -d '{"restaurant_id":"1","restaurant_name":"Cafe Um","date":"2030-01-01","time":"19:00:00","party_size":2,"guest_name":"Smoke"}'
# Lifecycle (use the {id} from create):  cancel / request-change / approve-change / reject-change
curl -s -H "$AUTH" -X POST https://HOST/api/reservations/<id>/cancel/ -d '{"reason":"smoke"}'

# Food records (public list; mine requires auth)
curl -s https://HOST/api/food-records/
curl -s -H "$AUTH" "https://HOST/api/food-records/?mine=1"

# Account (get-or-create singletons)
curl -s -H "$AUTH" https://HOST/api/account/profile/
curl -s -H "$AUTH" https://HOST/api/account/dining-preferences/
curl -s -H "$AUTH" https://HOST/api/account/notification-settings/

# Saved restaurants, payment methods, transactions
curl -s -H "$AUTH" https://HOST/api/saved-restaurants/
curl -s -H "$AUTH" https://HOST/api/payment-methods/
curl -s -H "$AUTH" https://HOST/api/transactions/
```
**Auth gate check:** calling any authenticated endpoint with no token must return **401**.
**Security check:** `POST /api/payment-methods/` or `/api/transactions/` containing `card_number`/`cvv` must return **400** (sensitive fields rejected).

---

## 6. Flutter E2E smoke-test checklist

Build against the deployed backend:
```bash
cd frontend
flutter run --dart-define=DJANGO_API_BASE_URL=https://api.yourdomain.com
```
Pre-flight (host machine):
```bash
flutter analyze        # expect 0 errors
flutter test           # expect all service tests green
```

Manual E2E (sign in with a real Supabase account first):

**Discovery**
- [ ] Home: region tabs load; restaurants per region render; recent food records show.
- [ ] Explore: map markers appear; "Search this area" (bbox) returns results; cuisine + price filters change the list; loading spinner then results/empty state.
- [ ] Restaurant detail: data loads; ⭐ save toggles and persists across app restart.

**Saved**
- [ ] Account → Saved Restaurants lists saved items; unsave removes; survives restart.

**Account**
- [ ] My Profile loads from backend; Edit Profile → Save shows spinner, persists, survives restart.
- [ ] Dining Preferences flow → Save persists; cards reflect new values.
- [ ] Notification Settings toggles persist (flip, leave, return).

**Payments**
- [ ] Add card (Save shows spinner) → appears in list; set/primary works; delete works. No card number/CVV leaves the device (display fields only).

**Transactions**
- [ ] Transactions list loads newest-first; filter All/Reservation/Refund works; empty + error/retry states behave.

**Reservations (full lifecycle)**
- [ ] Create reservation (complete flow) → appears under Upcoming.
- [ ] Reservation detail: thumbnail/location come from backend (not mock).
- [ ] Edit → Request change (≥24h out) → "Awaiting confirmation" banner; <24h is blocked.
- [ ] Cancel → reservation leaves the Upcoming list; survives restart.

**Cross-cutting**
- [ ] Every screen shows a loading state on first load and a recoverable error/retry on network failure.
- [ ] Sign out → protected screens no longer show another user's data; sign in as a second user shows isolated data (owner-scoping).

---

## 7. Quick reference

| Action | Command |
|---|---|
| Install deps | `pip install -r requirements.txt` |
| Apply migrations | `python manage.py migrate` |
| Check migrations | `python manage.py makemigrations --check --dry-run` |
| Transform Webflow CSV | `python scripts/transform_webflow_restaurants.py sample_data/restaurants.csv sample_data/restaurants_canonical_from_webflow.csv [--dry-run]` |
| Import data (dry) | `python manage.py import_restaurants FILE.csv --dry-run` |
| Import data | `python manage.py import_restaurants FILE.csv [--update]` |
| Create admin | `python manage.py createsuperuser` |
| Run (staging) | `python manage.py runserver 0.0.0.0:8000` |
| Run (prod) | `gunicorn yumbook_server.wsgi:application --bind 0.0.0.0:8000 --workers 3` |
| Backend tests (SQLite) | `DATABASE_URL= SUPABASE_DB_URL= python manage.py test accounts reservations restaurants food_records` |
| Flutter checks | `flutter analyze && flutter test` |

> Windows PowerShell test invocation: `$env:DATABASE_URL=""; $env:SUPABASE_DB_URL=""; python manage.py test accounts reservations restaurants food_records`

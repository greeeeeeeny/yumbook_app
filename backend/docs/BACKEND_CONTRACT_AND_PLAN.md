# Yumbook Backend — Contract & Implementation Plan (Frontend-Derived)

> Derived from the Flutter app under `frontend/lib`. The backend is designed to serve the
> **existing** UI: every endpoint, field, and type below is justified by something the app
> already reads or writes. "✅ Built" = exists in Django today; "🔴 Gap" = UI needs it, no API yet.

---

## 1. Architecture overview

| Concern | Decision (from the app) |
|---|---|
| API style | Django REST Framework, JSON, `/api/...`, trailing slash (Flutter URIs all end in `/`). |
| Auth | **Supabase JWT** via `Authorization: Bearer <token>`. Django validates with `SupabaseAuthentication`; user identity = Supabase `user.id` (string UUID). Login/signup proxied through `/api/login/`, `/api/signup/` but the app primarily uses Supabase directly. |
| User identity | A **string UUID** (`request.user.id`), not a Django `auth.User`. All user-owned rows store `user = CharField`. No local user table — keep it that way. |
| Images | Binary lives in **Supabase Storage**; Postgres stores **URLs only** (`image_url`). Confirmed by `RestaurantImage`, `FoodRecordImage`, and `SupabaseStorageService`. |
| List responses | **Plain JSON arrays**, not paginated envelopes. Every Flutter parser does `(decoded as List).map(...)`. Pagination would break the client — keep list endpoints returning bare arrays (or add opt-in pagination later behind a flag). |
| IDs | Restaurant / FoodRecord PKs are **integers**. Reservation `restaurant_id` is currently typed as **String** on the client (legacy mock ids like `cafe_um_mock`) — see §7 mismatch. |

---

## 2. Flutter model inventory

Exact fields the client serializes (`fromJson`/`toJson`). Backend field names must match the **snake_case JSON keys**.

### 2.1 `Restaurant` (`models/restaurant.dart`)
| Dart field | JSON key | Type | Notes |
|---|---|---|---|
| id | `id` | String (parsed from any) | PK |
| name | `name` | String | |
| location | `location` | String | |
| description | `description` | String | |
| imagePath | `image_url` | String | single primary image URL |
| tags | `tags` | List\<String\> | JSON array |
| rawCategory | `raw_category` | String? | |
| region | `region` | String? | Region **slug** |
| lat / lng | `lat` / `lng` | double? | |
| rating | `rating` | double | |
| reviewCount | `review_count` | int | |

### 2.2 `Region` (`models/region.dart`)
`id:int`, `slug:String`, `name:String`, `display_order:int`, `is_active:bool`.

### 2.3 `FoodRecord` + `FoodRecordImage` (`models/food_record.dart`)
| JSON key | Type | Direction |
|---|---|---|
| `id` | int | read |
| `user` / `user_id` | String | read |
| `restaurant` | int? | read/write |
| `restaurant_name` | String | read/write |
| `menu_name` | String | read/write |
| `rating` | String/decimal | read/write |
| `review` | String | read/write |
| `price` | String/decimal? | read/write |
| `tags` | List\<String\> | read/write |
| `visited_at` | date `yyyy-MM-dd` | read/write |
| `is_public` | bool | read/write |
| `images` | `[{id, image_url, order}]` | read/write |
| `created_at` / `updated_at` | datetime | read |

### 2.4 `ReservationData` + change request (`models/reservation_data.dart`)
Client read/write keys (`reservationToJson` / `reservationFromJson`):
- **Write:** `restaurant_id`, `restaurant_name`, `date` (`yyyy-MM-dd`), `time` (`HH:mm:ss`), `party_size`, `guest_name`, `seat_type`.
- **Read:** above + `confirmation_code`.
- **UI-only (not yet sent/received):** `paymentMethodId`, `paymentMethodLabel`, `paymentSnapshot`, `pendingChange` (`ReservationChangeRequest{requestedDate, requestedTime, requestedPartySize, requestedAt, status∈{none,pending,approved,rejected}}`).

### 2.5 `ReservationPaymentSnapshot` + `RestaurantPolicy`
- Policy: `depositType∈{none,perGuest,fixed}`, `depositAmount`, `freeCancelDays`, `refundWithinWindowRate`, `refundOutsideWindowRate`, `noShowRefundRate`, `restaurantCancelRefundRate`. **Already modeled** in `RestaurantPolicy` and nested under restaurant as `policy`.
- Snapshot: `serviceFeePerGuest`, `depositAmount`, `currency`, `processingFeeRate`, `policySnapshot`. **Computed client-side**; not persisted yet.

### 2.6 `UserProfile` (`models/user_profile.dart`)
`name`, `dateOfBirth`, `mobileNumber`, `email`, `profileImagePath?`. In-memory only today.

### 2.7 `DiningPreferences` (`models/dining_preferences.dart`)
`favoriteCuisines:[String]`, `diningStyles:[String]`, `dietaryRestrictions:[String]`, `additionalNotes:String`. In-memory only.

### 2.8 `PaymentMethodModel` (`state/payment_method_store.dart`)
`id`, `brand`, `last4`, `holderName`, `expiry`. In-memory only.

### 2.9 `TransactionModel` (`models/transaction_model.dart`)
`id`, `type∈{reservation,refund,failed}`, `title`, `subtitle`, `cardBrand`, `cardLast4`, `trailingText`, `createdAt`. Hardcoded mock only.

---

## 3. Endpoint contract

### 3.1 Built today ✅
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/api/regions/` | public | active regions, ordered |
| GET | `/api/restaurants/` | public | filters: `q`, `location`, `category`, `region` (slug) |
| GET | `/api/restaurants/{id}/` | public | nested `policy`, `images`, `region_detail` |
| POST/PUT/PATCH/DELETE | `/api/restaurants/...` | admin | management |
| GET | `/api/food-records/` | public/optional | filters: `mine`, `restaurant`, `user`, `q`, `ordering` |
| GET | `/api/food-records/{id}/` | public/optional | |
| POST/PUT/DELETE | `/api/food-records/{id}/` | owner | recomputes restaurant `rating`/`review_count` |
| GET | `/api/reservations/` | auth | own reservations, filter `date` |
| POST | `/api/reservations/` | auth | create |
| POST | `/api/signup/`, `/api/login/` | public | Supabase proxy |

### 3.2 Gaps to build 🔴
Request/response shapes match the existing Dart models so the client can adopt them with minimal change.

```
# Reservations — lifecycle (UI exists: edit screen, cancel sheet, change-request flow)
PATCH  /api/reservations/{id}/                 # edit date/time/party_size (24h-window enforced)
POST   /api/reservations/{id}/cancel/          # body: {reason}; returns refund breakdown
POST   /api/reservations/{id}/change-request/  # body: {requested_date, requested_time, requested_party_size}
POST   /api/reservations/{id}/change-request/approve/   # (restaurant/admin)
POST   /api/reservations/{id}/change-request/reject/     # (restaurant/admin)
   -> Reservation read gains: confirmation already present + pending_change{...}, payment_snapshot{...}

# Saved restaurants / bookmarks (saved_restaurants_screen, detail_screen heart toggle)
GET    /api/saved-restaurants/                 # -> [Restaurant]  (expand to full restaurant objects)
POST   /api/saved-restaurants/                 # body: {restaurant}
DELETE /api/saved-restaurants/{restaurant_id}/

# Payment methods (payment_register_screen, payment_methods_widget)
GET    /api/payment-methods/                   # -> [{id, brand, last4, holder_name, expiry, is_primary}]
POST   /api/payment-methods/
PATCH  /api/payment-methods/{id}/              # e.g. set primary
DELETE /api/payment-methods/{id}/

# Transactions (transactions_screen)
GET    /api/transactions/?type=reservation|refund|failed
   -> [{id, type, title, subtitle, card_brand, card_last4, trailing_text, created_at}]

# User profile + preferences + notifications (account/* screens)
GET    /api/me/profile/                        # {name, date_of_birth, mobile_number, email, profile_image_url}
PATCH  /api/me/profile/
GET    /api/me/dining-preferences/             # {favorite_cuisines[], dining_styles[], dietary_restrictions[], additional_notes}
PUT    /api/me/dining-preferences/
GET    /api/me/notification-settings/          # {push_enabled, email_enabled}
PUT    /api/me/notification-settings/
```

---

## 4. Django model design

### 4.1 Existing (keep) ✅
`Region`, `Restaurant`, `RestaurantImage`, `RestaurantPolicy` (restaurants app); `Reservation` (reservations app); `FoodRecord`, `FoodRecordImage` (food_records app). All already align with the client.

### 4.2 New models 🔴

```python
# reservations/models.py — extend Reservation + add change request
class Reservation(models.Model):
    ...                                   # existing fields
    status = models.CharField(            # active | cancelled | completed | no_show
        max_length=20, default="active")
    cancel_reason = models.TextField(blank=True)
    payment_snapshot = models.JSONField(null=True, blank=True)   # ReservationPaymentSnapshot

class ReservationChangeRequest(models.Model):
    reservation = models.ForeignKey(Reservation, on_delete=models.CASCADE,
                                    related_name="change_requests")
    requested_date = models.DateField()
    requested_time = models.TimeField()
    requested_party_size = models.PositiveIntegerField()
    status = models.CharField(max_length=20, default="pending")  # pending|approved|rejected
    requested_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

# accounts app (new) — all keyed by Supabase user id (CharField), one row per user
class UserProfile(models.Model):
    user = models.CharField(max_length=255, unique=True, db_index=True)
    name = models.CharField(max_length=120, blank=True)
    date_of_birth = models.CharField(max_length=40, blank=True)   # UI stores as display string
    mobile_number = models.CharField(max_length=40, blank=True)
    email = models.EmailField(blank=True)
    profile_image_url = models.URLField(max_length=500, blank=True)

class DiningPreference(models.Model):
    user = models.CharField(max_length=255, unique=True, db_index=True)
    favorite_cuisines = models.JSONField(default=list, blank=True)
    dining_styles = models.JSONField(default=list, blank=True)
    dietary_restrictions = models.JSONField(default=list, blank=True)
    additional_notes = models.TextField(blank=True)

class NotificationSetting(models.Model):
    user = models.CharField(max_length=255, unique=True, db_index=True)
    push_enabled = models.BooleanField(default=True)
    email_enabled = models.BooleanField(default=True)

class SavedRestaurant(models.Model):
    user = models.CharField(max_length=255, db_index=True)
    restaurant = models.ForeignKey("restaurants.Restaurant", on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    class Meta:
        unique_together = ("user", "restaurant")

class PaymentMethod(models.Model):
    user = models.CharField(max_length=255, db_index=True)
    brand = models.CharField(max_length=40)
    last4 = models.CharField(max_length=4)
    holder_name = models.CharField(max_length=120, blank=True)
    expiry = models.CharField(max_length=7)        # "MM/YY"
    is_primary = models.BooleanField(default=False)
    # NOTE: store only display metadata. NEVER store full PAN/CVV — tokenize via a PSP.

class Transaction(models.Model):
    user = models.CharField(max_length=255, db_index=True)
    type = models.CharField(max_length=20)         # reservation|refund|failed
    title = models.CharField(max_length=200)
    subtitle = models.CharField(max_length=200, blank=True)
    card_brand = models.CharField(max_length=40, blank=True)
    card_last4 = models.CharField(max_length=4, blank=True)
    trailing_text = models.CharField(max_length=60, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    reservation = models.ForeignKey("reservations.Reservation",
                                    null=True, blank=True, on_delete=models.SET_NULL)
```

---

## 5. Serializers & endpoints (per app)

- **restaurants** — no change. `RestaurantSerializer` already exposes everything the UI needs (`policy`, `images`, `region`, `region_detail`).
- **reservations** — add `pending_change` (latest change request, nested) and `payment_snapshot` to `ReservationSerializer`. Add `@action` methods on `ReservationViewSet`: `cancel`, `change_request`, `change_request/approve|reject`, plus enable `partial_update`. **Fix the `restaurant_id` contract** (see §7).
- **accounts** (new app) — `ProfileSerializer`, `DiningPreferenceSerializer`, `NotificationSettingSerializer` exposed as **singleton** endpoints (`get_object` returns/creates the row for `request.user.id`). `SavedRestaurantSerializer` (write: `restaurant` id; read: nested `RestaurantSerializer`). `PaymentMethodSerializer`, `TransactionSerializer` (read-only list). All viewsets filter `queryset.filter(user=request.user.id)` and `perform_create(user=request.user.id)`, authenticated via `SupabaseAuthentication` + `IsAuthenticated`.

---

## 6. Screen → API map

| Screen | Reads | Writes | Status |
|---|---|---|---|
| `home_screen` | regions, restaurants?region, public food-records | — | ✅ |
| `explore_screen` | restaurants (map/filters) | — | ⚠️ uses mock; needs geo/cuisine/price filters on `/restaurants/` |
| `detail_screen` | restaurant + policy + images | save/unsave | 🔴 saved-restaurants |
| `reserve_screen` | reservations (upcoming/past), notify reqs | — | ✅ list (notify reqs local) |
| `reservation_details_screen` | reservation, pending_change | approve/reject change | 🔴 change-request endpoints |
| `reservation_edit_screen` | reservation (24h rule) | change-request / edit | 🔴 PATCH + change-request |
| `reservation_cancel_sheet` | reservation + policy → refund calc | cancel | 🔴 cancel endpoint |
| `complete_reservation_screen` | reservation draft | create reservation | ✅ POST |
| `food_records/*` | public/mine feeds, detail | create/update/delete + Supabase upload | ✅ |
| `account/my_profile` + `profile_edit` | profile | update profile, avatar | 🔴 `/me/profile/` + avatar upload |
| `account/saved_restaurants` | saved list | remove | 🔴 saved-restaurants |
| `account/transactions` | transactions | — | 🔴 transactions |
| `account/notification_settings` | settings | toggle | 🔴 `/me/notification-settings/` |
| `account/dining_preferences_flow` | preferences | save | 🔴 `/me/dining-preferences/` |
| `payment/payment_register` | payment methods | add/select | 🔴 payment-methods |
| `auth/*` | — | sign in/up/verify/reset | ✅ Supabase direct |

---

## 7. Missing fields & contract mismatches

1. **Reservation `restaurant_id` mismatch (high).** Client sends/reads JSON key **`restaurant_id`** (String), but `ReservationSerializer` exposes `restaurant` (FK int) and `external_restaurant_id`. Result today: `restaurant_id` is dropped on create and always `null` on read. **Fix:** add a `restaurant_id` serializer field mapping to `external_restaurant_id` (string-safe), or migrate the client to int `restaurant`. Recommend supporting `restaurant_id` as the public key backed by `external_restaurant_id` to match the client without a client change.
2. **Reservation read lacks `pending_change` / `payment_snapshot`.** UI models them; serializer must emit them once §4.2 lands.
3. **Restaurant single image vs gallery.** Client `Restaurant.imagePath` reads scalar `image_url`; detail UI can also use the `images[]` gallery. Keep both; ensure `image_url` is populated (e.g., from primary `RestaurantImage`).
4. **Avatar upload path.** `UserProfile.profileImagePath` is asset-based on the client. Backend should store `profile_image_url`; uploads go through Supabase Storage (reuse `SupabaseStorageService` pattern) and the URL is PATCHed to the profile.
5. **Explore filters not wired.** `explore_screen` has TODO filters (cuisine, price, date/time, map bounds). `/restaurants/` supports `q/location/category/region` only — add `cuisine`, `price_level`, and bbox (`min_lat,max_lat,min_lng,max_lng`) params when that screen goes live.
6. **Payment security.** Never persist PAN/CVV. Store display metadata only; tokenize via a PSP if real charging is added.
7. **Notify requests (waitlist)** are local-only (`NotifyRequest`); no endpoint yet — out of scope unless prioritized.

---

## 8. Implementation plan (phased, before coding)

**Phase 0 — Fix existing contract (no new models)**
- Resolve the `restaurant_id` mismatch in `ReservationSerializer` (§7.1). Add a regression test asserting round-trip of `restaurant_id`.

**Phase 1 — Reservation lifecycle** (highest UI coverage)
- Migration: `Reservation.status`, `cancel_reason`, `payment_snapshot`; new `ReservationChangeRequest`.
- Serializer: nested `pending_change`, `payment_snapshot`. Enable `partial_update`.
- ViewSet `@action`s: `cancel` (compute refund from `RestaurantPolicy`), `change_request`, `approve`, `reject`; enforce the 24h window server-side (mirrors `canEditReservation`).
- Tests: cancel refund math, 24h rule, change-request state machine, ownership.

**Phase 2 — Accounts app** (`profile`, `dining-preferences`, `notification-settings`)
- New `accounts` app; three singleton get-or-create endpoints keyed by `user.id`.
- Avatar: document Supabase Storage upload → PATCH `profile_image_url`.
- Tests: get-or-create, isolation between users.

**Phase 3 — Saved restaurants + payment methods**
- `SavedRestaurant` (unique per user+restaurant), list returns nested restaurants for `saved_restaurants_screen`.
- `PaymentMethod` CRUD + set-primary; display-metadata only.
- Tests: dedupe, primary toggle, owner scoping.

**Phase 4 — Transactions**
- `Transaction` read-only list with `type` filter; optionally auto-create rows on reservation create/cancel.

**Phase 5 — Explore enhancements** (only when that screen is wired)
- Add `cuisine`, `price_level`, bbox filters to `RestaurantViewSet.get_queryset`.

**Cross-cutting**
- Every new owner-scoped viewset: `SupabaseAuthentication` + `IsAuthenticated`, filter by `request.user.id`, `perform_create(user=...)`.
- Keep list endpoints returning **bare JSON arrays** (client contract).
- Register new apps in `INSTALLED_APPS` and `yumbook_server/urls.py` (`path("api/", include("accounts.urls"))`).
- Update `drf-spectacular` schema; the app reads `/api/schema/`.

---

## Admin visibility sync (yumbook_admin, 2026-08)

The Yumbook Admin backend (`yumbook_admin`) manages restaurant visibility in
its own table `admin_restaurant_meta` (same shared Postgres DB). This backend
maps it **read-only** as `restaurants.AdminRestaurantMeta` (`managed=False`;
yumbook_admin owns the schema — never write or migrate that table here).

Visibility rules enforced by `RestaurantViewSet` (list/retrieve only; admin
write actions are unaffected):

| admin_restaurant_meta | User-facing API |
|---|---|
| no row, or `status='active'` | visible |
| `status='draft'` / `'inactive'` / `'archived'` | hidden (list, search, region filter, detail → 404) |

Local sqlite dev/test DBs get the physical table from migration
`restaurants/0005_adminrestaurantmeta.py` (sqlite-only bootstrap; no-op on
Postgres, where yumbook_admin's migrations own the table).

---

## Availability enforcement (yumbook_admin seats, 2026-08, Phase 5.1)

yumbook_admin owns `admin_restaurant_seat_type`,
`admin_restaurant_seat_inventory`, `admin_restaurant_exception_day`. This
backend maps them READ-ONLY (`restaurants.AdminRestaurantSeatType` etc.,
`managed=False`; sqlite bootstrap in `restaurants/0006`). Never write or
migrate these tables here.

Reservation creation (`POST /api/reservations/`) now validates, inside
`transaction.atomic()` with the inventory row locked:

1. Exception day: `is_closed` blocks; special-hours days require
   `open_time <= time <= close_time`. Always enforced.
2. Seat type: if the restaurant has active seat types, `seat_type` must
   match an active `code` (case-insensitive). No seat types → fail-open.
3. Inventory: an active row for (restaurant, seat_type, date, exact time —
   else all-day) enforces `capacity`, counting reservations with status
   `pending`/`confirmed` only. No row → fail-open.
4. Reservations without a restaurant FK (legacy external_restaurant_id
   flow) are not validated. Historical free-text seat_type values are
   never blocked retroactively.

Blocked requests return 400 with one of: "Restaurant is closed on this
date." / "Reservation time is outside special opening hours." / "Invalid
seat type for this restaurant." / "Selected time slot is fully booked."

New public endpoint: `GET /api/restaurants/{id}/availability/?date=YYYY-MM-DD`
→ `{closed, special_hours, seat_types, slots: [{seat_type, time, capacity,
booked, remaining}]}` (404 for admin-hidden restaurants; slots only where
inventory is configured).

### Phase 5.2 addendum — consistency across mutation paths

Availability validation (same rules as creation) now also runs on:

- `PATCH/PUT /api/reservations/{id}/` (owner update) — only when an
  availability field (restaurant/date/time/party_size/seat_type) changes
  and the reservation status is pending/confirmed; the reservation itself
  is EXCLUDED from the capacity count, so guest_name-only or same-slot
  edits never fail capacity.
- `POST /api/reservations/{id}/approve-change/` — the requested
  date/time must pass validation (self-excluded) BEFORE anything is
  applied; a 400 leaves both the reservation and the change request
  unchanged. Runs inside transaction.atomic().

The yumbook_admin backend applies identical rules on its reservation
PATCH and change-request approve endpoints (mirrored implementation —
keep `reservations/availability.py` in both projects in sync).

Capacity semantics: RESERVATION-count (capacity=4 → 4 bookings regardless
of party_size); pending+confirmed consume. If operators expect capacity
to mean seats/people, switch both projects to guest-count (sum of
party_size) together with tests and docs.

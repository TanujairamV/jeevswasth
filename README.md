<div align="center">

<img src="frontend/assets/images/jeevswasth_logo.svg" alt="JEEVSWASTH Logo" width="120" height="120" />

# JEEVSWASTH

**Offline-first livestock health surveillance and decision-support platform for earlier reporting, coordinated veterinary response, and safer animal-health operations.**

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/Flutter-Mobile%20Client-02569B?style=for-the-badge&logo=flutter&logoColor=white&labelColor=202124" alt="Flutter" /></a>
  <a href="#"><img src="https://img.shields.io/badge/NestJS-Backend-E0234E?style=for-the-badge&logo=nestjs&logoColor=white&labelColor=202124" alt="NestJS" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Firebase-Authentication-FFCA28?style=for-the-badge&logo=firebase&logoColor=black&labelColor=202124" alt="Firebase" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white&labelColor=202124" alt="Android" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Status-Prototype-F59E0B?style=for-the-badge&logo=gitbook&logoColor=white&labelColor=202124" alt="Prototype status" /></a>
</p>

<p align="center">
  <a href="statment.md">SIH 2026 Problem Statement</a>
  &nbsp;•&nbsp;
  <a href="ToDo.md">Implementation Roadmap</a>
  &nbsp;•&nbsp;
  <a href="LICENSE">License</a>
</p>

</div>

<br />

## <img src="https://api.iconify.design/lucide:sparkles.svg?color=%23C6F100" width="20" height="20" align="center" /> Overview

**JEEVSWASTH** is a health-tech prototype created for the Smart India Hackathon 2026 problem on early detection, prevention, and management of livestock diseases and animal-health issues.

The project brings together a Flutter mobile client, a NestJS API foundation, Firebase-based sign-in, farmer GPS and health-report capture, local-first persistence, and an AI dataset preparation area. Its long-term goal is to connect farmers, veterinarians, laboratories, and government officials through one evidence-grounded surveillance workflow.

> **Current status:** The repository is an active prototype. The farmer health-report flow and prototype reports endpoint are implemented, while durable server persistence, full role workflows, background synchronization, clinical governance, and production deployment remain in progress.

---

## <img src="https://api.iconify.design/lucide:layers.svg?color=%23C6F100" width="20" height="20" align="center" /> Key Features

| Icon | Capability | Current implementation |
|:---:|:---|:---|
| <img src="https://api.iconify.design/lucide:clipboard-list.svg?color=%23C6F100" width="20" height="20" /> | **Field Health Surveys** | Capture species, livestock count, farmer details, village, symptoms, clinical signs, notes, and optional GPS coordinates. |
| <img src="https://api.iconify.design/lucide:map-pin.svg?color=%2300E5FF" width="20" height="20" /> | **GPS & Location Context** | Request location permission, show coordinates, reverse-geocode the current position, and retain a last-known fallback locally. |
| <img src="https://api.iconify.design/lucide:save.svg?color=%23C6F100" width="20" height="20" /> | **Local-First Capture** | Save surveys as JSON through `SharedPreferences` before attempting network submission, reducing data loss during field work. |
| <img src="https://api.iconify.design/lucide:send.svg?color=%2324A1DE" width="20" height="20" /> | **Prototype Report API** | Submit saved surveys to versioned `POST /api/v1/reports` and display explicit saving, submitting, submitted, and failed states. |
| <img src="https://api.iconify.design/lucide:users.svg?color=%23FFB4A2" width="20" height="20" /> | **Role-Oriented UI** | Flutter navigation foundations exist for farmers, veterinarians, and surveillance officials. Several role experiences are still prototypes. |
| <img src="https://api.iconify.design/lucide:shield-check.svg?color=%23C6F100" width="20" height="20" /> | **Authentication Foundation** | Firebase and Google sign-in client paths are present; server-side token verification and authorization are planned next. |
| <img src="https://api.iconify.design/lucide:brain-circuit.svg?color=%23C6F100" width="20" height="20" /> | **AI-Ready Dataset Layer** | Includes schema guidance, safety constraints, train/validation/test JSONL files, and a static validator for structured extraction work. |

---

## <img src="https://api.iconify.design/lucide:cpu.svg?color=%23C6F100" width="20" height="20" align="center" /> Tech Stack & Architecture

- **Mobile client:** Flutter and Dart with Material 3, dynamic color, Google Sign-In, Firebase Auth, geolocation, geocoding, and local preferences.
- **Backend:** NestJS 12, TypeScript, Express, RxJS, Firebase Admin dependency, and versioned API modules.
- **Current data flow:** Flutter survey → local `SharedPreferences` save → best-effort `POST /api/v1/reports` → in-memory prototype response.
- **AI workspace:** JSONL datasets and validation guidance under `ai/`; no trained model or inference service is currently included.
- **Delivery:** GitHub Actions workflow for Flutter analysis, Android builds, and release artifacts.
- **Planned architecture:** Flutter clients → authenticated API → domain services → durable database → analytics, alerts, laboratory, weather, and messaging integrations.

---

## <img src="https://api.iconify.design/lucide:rocket.svg?color=%23C6F100" width="20" height="20" align="center" /> Getting Started

### Prerequisites

- Flutter SDK compatible with Dart `^3.13.4`
- Node.js and npm
- Firebase project configuration for sign-in flows
- Android Studio or an Android device/emulator for mobile testing

### Run the Flutter client

```bash
cd frontend
flutter pub get
flutter run
```

For a physical Android device, configure the API host when needed:

```bash
flutter run --dart-define=JEEVSWASTH_ANDROID_API_HOST=<LAN_HOST>
```

### Run the backend

```bash
cd backend
npm install
npm run start:dev
```

The prototype reports API is exposed under `/api/v1/reports`.

---

## <img src="https://api.iconify.design/lucide:terminal.svg?color=%23C6F100" width="20" height="20" align="center" /> Useful Commands

### Frontend

```bash
cd frontend
flutter analyze
flutter test
flutter build apk --release
```

### Backend

```bash
cd backend
npm run lint
npm run build
npm run test
npm run test:e2e
```

### AI dataset validation

```bash
python ai/validate_dataset.py
```

---

## <img src="https://api.iconify.design/lucide:database.svg?color=%23C6F100" width="20" height="20" align="center" /> Database Administration — SQL Queries

These queries target the PostgreSQL schema created by the migrations in
`backend/src/database/migrations/`. Run them only against an authorized Neon
administration session. Firebase Authentication UIDs are stored in
`users.firebase_uid`; they are not email addresses.

### Database overview

The current schema contains these tables:

| Table | Important columns and constraints |
|:---|:---|
| `roles` | `id uuid` primary key, `name varchar(64)` not null and unique. Seeded values are `farmer`, `veterinarian`, and `surveillance_officer`. |
| `users` | `id uuid` primary key, `firebase_uid varchar(255)` not null and unique, `email varchar(320)` not null, nullable `display_name`, `is_active boolean` default `true`, and `created_at`/`updated_at timestamptz` default `now()`. |
| `user_roles` | `user_id uuid` → `users(id)` and `role_id uuid` → `roles(id)`, both cascading on delete; composite primary key `(user_id, role_id)` prevents duplicate assignments. |
| `role_requests` | `id uuid` primary key, `user_id` → `users(id)` cascading, `role_id` → `roles(id)` restricting deletion, `status varchar(20)` default `pending`, `created_at`, nullable `reviewed_at`; status is restricted to `pending`, `approved`, or `rejected`. Unique `(user_id, role_id, status)` prevents duplicate requests with the same status. |
| `reports` | `report_id varchar(80)` primary key; `owner_firebase_uid` → `users(firebase_uid)` restricting deletion; required `species`, positive `animal_count`, `village`, `symptoms jsonb`, and `report_timestamp`; optional farmer/contact, clinical, notes, location, and accuracy fields. A partial unique index prevents duplicate non-null `(owner_firebase_uid, client_report_id)` pairs. |

`reports.latitude` and `longitude` must be both null or within valid geographic
ranges. `accuracy_meters`, when present, must be non-negative. The Worker
persists reports in this table and exposes the owner's reports through
`GET /api/v1/reports/mine`. The NestJS `ReportsService` currently keeps its
separate prototype data in memory, so reports created only through that Node
prototype are not available to SQL queries.

### Tables and relationships

`users` is identified at the application boundary by `firebase_uid`. A user
receives roles through `user_roles`, which joins to `roles`. A role request
belongs to one user and one role. A persisted report belongs to a user through
`reports.owner_firebase_uid`, which references `users.firebase_uid` rather
than `users.id`.

### Available roles

```sql
SELECT id, name
FROM roles
ORDER BY name;
```

No replacement is required. The result is the authoritative list of role IDs
and role names for subsequent queries.

### Viewing role requests

```sql
-- All registered users
SELECT id, firebase_uid, email, display_name, is_active, created_at, updated_at
FROM users
ORDER BY created_at DESC;

-- All role requests
SELECT rr.id AS request_id, u.firebase_uid, u.email, r.name AS role,
       rr.status, rr.created_at, rr.reviewed_at
FROM role_requests rr
JOIN users u ON u.id = rr.user_id
JOIN roles r ON r.id = rr.role_id
ORDER BY rr.created_at DESC;

-- Pending requests
SELECT rr.id AS request_id, u.firebase_uid, u.email, r.name AS role,
       rr.created_at
FROM role_requests rr
JOIN users u ON u.id = rr.user_id
JOIN roles r ON r.id = rr.role_id
WHERE rr.status = 'pending'
ORDER BY rr.created_at ASC;

-- Requests for one role
SELECT rr.id AS request_id, u.firebase_uid, u.email, r.name AS role,
       rr.status, rr.created_at, rr.reviewed_at
FROM role_requests rr
JOIN users u ON u.id = rr.user_id
JOIN roles r ON r.id = rr.role_id
WHERE r.name = 'ROLE_NAME'
ORDER BY rr.created_at DESC;
```

Replace `ROLE_NAME` with an existing value such as `veterinarian` or
`surveillance_officer`. For a specific request, use its UUID as
`REQUEST_ID` below.

### Approving requests

Run the following transaction after replacing `REQUEST_ID` and `ROLE_NAME`.
The role check is deliberately restricted to the two administrator-approved
non-farmer roles. It locks the request, rejects missing or already-resolved
requests, uses the composite primary key to avoid duplicate assignments, and
updates the request only after assignment succeeds.

```sql
BEGIN;

DO $approve$
DECLARE
  request_user_id uuid;
  requested_role text;
  request_status text;
BEGIN
  SELECT rr.user_id, r.name, rr.status
    INTO request_user_id, requested_role, request_status
  FROM role_requests rr
  JOIN roles r ON r.id = rr.role_id
  WHERE rr.id = 'REQUEST_ID'::uuid
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Role request REQUEST_ID does not exist';
  END IF;
  IF request_status <> 'pending' THEN
    RAISE EXCEPTION 'Role request REQUEST_ID is already %', request_status;
  END IF;
  IF requested_role <> 'ROLE_NAME' THEN
    RAISE EXCEPTION 'Role request REQUEST_ID is for %, not ROLE_NAME', requested_role;
  END IF;
  IF requested_role NOT IN ('veterinarian', 'surveillance_officer') THEN
    RAISE EXCEPTION 'Only veterinarian or surveillance_officer requests may be approved here';
  END IF;

  INSERT INTO user_roles (user_id, role_id)
  SELECT request_user_id, id FROM roles WHERE name = requested_role
  ON CONFLICT (user_id, role_id) DO NOTHING;

  UPDATE role_requests
  SET status = 'approved', reviewed_at = now()
  WHERE id = 'REQUEST_ID'::uuid AND status = 'pending';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Role request REQUEST_ID could not be approved';
  END IF;
END
$approve$;

COMMIT;
```

For separate veterinarian and surveillance approval operations, use
`ROLE_NAME = 'veterinarian'` or `ROLE_NAME = 'surveillance_officer'`.

### Rejecting requests

This transaction verifies that the request exists and is still pending, then
changes only its status. It never inserts into `user_roles`.

```sql
BEGIN;

DO $reject$
DECLARE
  request_status text;
BEGIN
  SELECT status INTO request_status
  FROM role_requests
  WHERE id = 'REQUEST_ID'::uuid
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Role request REQUEST_ID does not exist';
  END IF;
  IF request_status <> 'pending' THEN
    RAISE EXCEPTION 'Role request REQUEST_ID is already %', request_status;
  END IF;

  UPDATE role_requests
  SET status = 'rejected', reviewed_at = now()
  WHERE id = 'REQUEST_ID'::uuid AND status = 'pending';
END
$reject$;

COMMIT;
```

### Manual role assignment

Use a Firebase UID, not an email address. This assigns an existing role and
does nothing if the composite `user_roles` primary key already contains the
assignment.

```sql
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON r.name = 'ROLE_NAME'
WHERE u.firebase_uid = 'FIREBASE_USER_UID'
ON CONFLICT (user_id, role_id) DO NOTHING;
```

Replace `FIREBASE_USER_UID` with the Firebase Authentication UID and
`ROLE_NAME` with a value returned by the roles query. If the UID or role does
not exist, zero rows are inserted.

### Revoking roles

```sql
DELETE FROM user_roles ur
USING users u, roles r
WHERE ur.user_id = u.id
  AND ur.role_id = r.id
  AND u.firebase_uid = 'FIREBASE_USER_UID'
  AND r.name = 'ROLE_NAME';
```

Replace both placeholders. This removes only the selected assignment; it does
not delete the user, role, or historical role request.

### User and report queries

```sql
-- All roles assigned to one Firebase UID
SELECT u.firebase_uid, r.id AS role_id, r.name AS role
FROM users u
JOIN user_roles ur ON ur.user_id = u.id
JOIN roles r ON r.id = ur.role_id
WHERE u.firebase_uid = 'FIREBASE_USER_UID'
ORDER BY r.name;

-- Reports submitted by one Firebase UID (Worker-persisted reports)
SELECT report_id, owner_firebase_uid, client_report_id, species, animal_count,
       village, symptoms, report_timestamp, farmer_name, farmer_phone,
       clinical_signs, notes, latitude, longitude, location_address,
       accuracy_meters, created_at
FROM reports
WHERE owner_firebase_uid = 'FIREBASE_USER_UID'
ORDER BY created_at DESC;
```

Replace `FIREBASE_USER_UID` with the Firebase Authentication UID. There is no
report status column, case table, or report-to-role-request foreign key in the
current migrations, so those relationships cannot be queried as application
records yet.

### Verification queries

```sql
-- Request, requested role, user, and current assignments together
SELECT rr.id AS request_id, u.firebase_uid, u.email,
       requested.name AS requested_role, rr.status, rr.created_at, rr.reviewed_at,
       COALESCE(string_agg(DISTINCT assigned.name, ', ' ORDER BY assigned.name),
                '(none)') AS assigned_roles
FROM role_requests rr
JOIN users u ON u.id = rr.user_id
JOIN roles requested ON requested.id = rr.role_id
LEFT JOIN user_roles ur ON ur.user_id = u.id
LEFT JOIN roles assigned ON assigned.id = ur.role_id
WHERE rr.id = 'REQUEST_ID'::uuid
GROUP BY rr.id, u.firebase_uid, u.email, requested.name,
         rr.status, rr.created_at, rr.reviewed_at;

-- Check whether a request is still actionable
SELECT rr.id AS request_id, rr.status, r.name AS requested_role,
       (rr.status = 'pending') AS can_be_reviewed
FROM role_requests rr
JOIN roles r ON r.id = rr.role_id
WHERE rr.id = 'REQUEST_ID'::uuid;
```

Replace `REQUEST_ID` with the role-request UUID. The first query relates the
user, request, requested role, and assigned roles; reports relate to the same
user independently through `owner_firebase_uid`.

### Security precautions

- Use a least-privilege administrator database role and a private Neon
  connection; never place passwords, connection strings, Firebase secrets, or
  API keys in this README.
- Verify the Firebase UID from a trusted Firebase Authentication profile
  before changing roles. Do not use an email address as a UID substitute.
- Review the target row and run approval/rejection statements in a transaction;
  do not remove the `pending` checks or the request row lock.
- Record who performed manual changes in the approved operational audit system.
  The current schema has no audit-events table, so these SQL statements cannot
  create an audit record themselves.
- Take care with `DELETE` when revoking access. It is intentionally limited to
  one user and one role and does not undo an approved request.

---

## <img src="https://api.iconify.design/lucide:map.svg?color=%2300E5FF" width="20" height="20" align="center" /> Repository Layout

```text
.
├── frontend/              # Flutter mobile client and platform runners
├── backend/               # NestJS API foundation
├── ai/                    # Dataset guidance, JSONL data, and validation
├── .github/workflows/     # Android build workflow
├── statment.md            # SIH 2026 problem statement
├── ToDo.md                # Detailed implementation roadmap and evidence index
└── LICENSE
```

---

## <img src="https://api.iconify.design/lucide:construction.svg?color=%23FFB4A2" width="20" height="20" align="center" /> Roadmap & Limitations

The next major milestones are:

1. Add Firebase ID-token verification, role claims, and protected API routes.
2. Replace in-memory reports with a durable database and migrations.
3. Build reliable offline synchronization with retries, idempotency, and conflict handling.
4. Implement veterinarian review, surveillance dashboards, advisories, and laboratory referrals.
5. Add explainable, human-reviewed triage and risk-signal workflows.

JEEVSWASTH does **not** currently provide autonomous disease diagnosis, confirmed outbreak declarations, production-grade notifications, or a complete government surveillance dashboard. AI outputs must remain evidence-grounded and subject to veterinary review.

See [`ToDo.md`](ToDo.md) for the complete phase-by-phase plan and repository evidence.

---

## <img src="https://api.iconify.design/lucide:shield-alert.svg?color=%23FFB4A2" width="20" height="20" align="center" /> Disclaimer

> [!WARNING]
> **Prototype and research notice**
>
> JEEVSWASTH is a prototype for the SIH 2026 challenge and is not a substitute for professional veterinary diagnosis, laboratory confirmation, government disease-control procedures, or emergency response.
>
> Do not use the current build as a production clinical or surveillance system. It does not yet include complete authentication enforcement, durable server persistence, validated outbreak logic, comprehensive privacy controls, or end-to-end operational monitoring.

---

<div align="center">
  <p><b>JEEVSWASTH</b> is built to support earlier, better-coordinated livestock health action. 🐄 🐐 🐔</p>
</div>
nirunjhana is the best

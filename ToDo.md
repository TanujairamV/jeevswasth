# JEEVSWASTH — Master Project Implementation TODO

> **Static repository audit:** 21 October 2026. This document is based on source/configuration inspection only. No commands, tests, builds, formatters, runtime sessions, database connections, or device checks were run. `[x]` means the repository contains evidence of an implemented code/configuration element; it does **not** prove production correctness or end-to-end operation.

## Dependency audit and optimization — 24 October 2026

- [x] Removed unused Flutter direct dependencies: `cupertino_icons` and `geocoding`; retained their feature replacements (`Icons`/`geolocator`) and regenerated `frontend/pubspec.lock`.
- [x] Removed unused backend runtime dependencies: `@nestjs/config` and `firebase-admin`; regenerated `backend/package-lock.json` with npm.
- [x] Confirmed `dynamic_color`, Firebase, Google Sign-In, Font Awesome, geolocator, shared preferences, and HTTP are directly used by the Flutter source. `material_ui` remains transitive and was not removed from the resolved graph.
- [x] Enabled Android release code/resource shrinking and Gradle build caching/parallelism without changing the universal APK command or application ID.
- [x] Added Java 17 and Pub/Gradle cache setup to the Android GitHub Actions workflow.
- [x] Backend validation completed locally: build, unit tests (1 passing), and oxlint all pass. The container has no Flutter/Dart/Java/Gradle SDKs, so Flutter analysis, APK size comparison, and Android release verification remain CI-required.
- [ ] Measure before/after universal APK size and GitHub Actions duration on a successful CI run; no prior run metrics were available locally.
- [ ] Review the remaining 14 npm audit findings separately before applying any security upgrades; no broad version upgrade was made in this audit.

## Official SIH problem statement

- **Problem Statement ID:** 26128
- **Title:** Efficient systems for early detection, prevention, and management of livestock diseases and animal health issues
- **Organization:** Government of Maharashtra
- **Department:** Maharashtra State Innovation Society, Department of Skills, Employment, Entrepreneurship and Innovation
- **Category / Theme:** Software / MedTech, BioTech, HealthTech

## Project summary

### Objective

Deliver a practical, scalable livestock-health surveillance and decision-support system that captures farmer reports, maintains animal/herd health history, supports veterinary review and referral, detects spatial/temporal risk early, and delivers preventive advisories to farmers and government officials, including in low-connectivity settings.

### Requested capability coverage — review added 22 October 2026

The requested product scope is broadly represented across the phases below, but most items remain planned rather than implemented. The following explicit checklist closes the few scope terms that were previously implicit:

- [ ] **P0** Define animal-health risk assessment outputs: risk level, contributing evidence, time window, geography, affected species/herds, confidence/limitations, owner, and human-review status. Do not present unconfirmed risk as diagnosis or outbreak fact.
- [ ] **P1** Add explainable risk analysis and graph views for animal, herd, symptom, mortality, vaccination, treatment, geography, weather, historical disease, referral, and response relationships. Include drill-down from an aggregate signal to authorized source reports.
- [ ] **P1** Add herd-level vaccination and treatment history dashboards, including coverage, missed preventive care, treatment outcomes, repeat symptoms, and longitudinal timelines.
- [ ] **P0** Implement fast-spreading-disease early warnings with thresholds, time-window comparison, minimum-data safeguards, deduplication, acknowledgement, escalation, and explicit suspected/watchlist/confirmed states.
- [ ] **P1** Model preventive measures and coordinated response plans: quarantine/biosecurity, vaccination campaigns, treatment follow-up, sample collection, referral, task assignment, response owner, SLA, and closure evidence.
- [ ] **P0** Support symptom and mortality reports as first-class inputs, including affected/dead counts, onset, species/herd, location, attachments, source, consent, and offline queue state.
- [ ] **P1** Provide geospatial risk mapping with privacy-safe aggregation, village/block/district boundaries, hotspots, report density, vaccination coverage, response actions, stale-data indicators, and authorized drill-down.
- [ ] **P2** Add weather and historical disease-trend inputs through documented adapters with source, timestamp, freshness, provenance, and failure/absence states.
- [ ] **P1** Provide reviewed multilingual UI, reports, advisories, risk explanations, and accessibility support; define the initial language set and translation ownership before release.
- [ ] **P1** Add sample collection and laboratory workflow: specimen metadata, barcode/kit, chain of custody, cold-chain checks, referral, result import, veterinarian review, and case linkage.
- [ ] **P0** Complete veterinarian and official dashboards for queue/triage, risk signals, vaccination/treatment history, maps, preventive actions, referrals, outbreak watchlists, and coordinated response.
- [ ] **P1** Define helpline and offline-enabled channels, including local save, retry queue, SMS/IVR or approved fallback contact, assisted reporting, emergency escalation, and clear stale/sync status.
- [ ] **P1** Define supported mobile and web experiences separately, including responsive layouts, browser/device capability limits, offline behavior, authentication, and release acceptance criteria.
- [ ] **P0** Measure outcomes without unsupported claims: reporting time, review time, containment time, treatment/referral turnaround, vaccination coverage, mortality, alert precision/recall, preventive-action completion, and evidence-based planning use.

### Technology stack discovered

- **Frontend:** Flutter/Dart package under `frontend/`, Dart SDK constraint `^3.13.4`.
- **Frontend packages:** Material 3, `dynamic_color`, `firebase_core`, `firebase_auth`, `google_sign_in`, `geolocator`, `geocoding`, `shared_preferences`, `material_ui`, Font Awesome.
- **Backend:** NestJS 12 / TypeScript ESM under `backend/`, Express platform, RxJS, Firebase Admin dependency, Nest Observe instrumentation.
- **Database:** No configured PostgreSQL, other SQL database, ORM, entities, migrations, repositories, or persistence module was found in the inspected repository. Current farmer-report persistence is local `SharedPreferences` only.
- **AI:** `ai/` contains annotation guidance, JSONL train/validation/test datasets, and a dataset validator. No model implementation, training script, inference service, API, or deployment code was found.
- **CI/CD:** `.github/workflows/android-build.yml` builds/analyzes/releases an Android APK when manually dispatched or when a commit message contains `--build`.
- **Platforms:** Android and Linux Flutter runner configuration are present; web and macOS artifacts are also present in the Flutter project. Linux intentionally skips Firebase initialization in `frontend/lib/main.dart`.

### Current architecture, based on evidence

The repository currently contains a Flutter UI prototype with role-themed screens, Firebase/Google authentication setup, a farmer GPS/health-report flow backed by local key-value storage, and a NestJS backend. The farmer report now best-effort submits to a versioned reports endpoint after local save. Authentication, durable server persistence, and a general synchronization worker remain absent.

### Verified implemented elements

- Flutter project and Material 3 theme abstraction in `frontend/lib/theme/app_theme.dart`.
- Dynamic color setup and platform-aware Firebase initialization in `frontend/lib/main.dart`.
- Firebase Android configuration files and Google sign-in code path in `frontend/lib/pages/login_page.dart`.
- Farmer health-report form with species, count, farmer, village, symptoms, clinical signs, notes, and optional GPS in `frontend/lib/farmer/reporting/livestock_survey_page.dart`.
- Local report serialization and `SharedPreferences` storage in `frontend/lib/farmer/reporting/models/livestock_survey.dart` and `data/livestock_survey_repository.dart`.
- Android location permissions and Firebase Android configuration.
- Backend NestJS bootstrap, starter controller/service, unit/e2e test scaffolding, and Android build workflow.
- Prototype `POST /api/v1/reports` validation, response IDs, and isolated in-memory report storage in `backend/src/reports/`.
- Flutter reports API client and best-effort submission flow that preserves the locally saved survey on API failure.
- AI dataset schema guidance, sample dataset files, and static validation script.

### Partial, placeholder, or unverified elements

- Google/Firebase sign-in is implemented on the client, but backend token verification is explicitly not connected.
- Role routing is demo-only: the email field is treated as a role string; it routes only to Farmer, Veterinarian, or Surveillance dashboards.
- Farmer screens contain hard-coded presentation data and placeholder actions. Farmer reporting is the owner of the existing livestock survey, local-first save, GPS capture, and best-effort API submission flow. The veterinarian dashboard now has explicitly labeled, isolated fictional fixtures and session-only controls; it is not connected to clinical backend services. `surveillance/home.dart` now has the requested monitoring-oriented shell and sample visualizations, but remains demo telemetry rather than live analytics.
- Offline survey saving and prototype upload exist, but sync status is not advanced, and there is no retry queue, conflict resolution, authentication, or durable server persistence.
- GPS coordinates are captured in the farmer report payload and cached locally where available, but there is no server geospatial pipeline, veterinarian report-location view, or surveillance risk map.
- Notification icons and alert cards are UI-only; no notification transport or advisory backend exists.
- AI datasets exist, but there is no trained/deployed/integrated model and the guidelines explicitly prohibit disease inference, risk scoring, and outbreak declaration.
- CI/CD configuration exists but runtime build/release success was not verified.

### Major missing components

Backend domain APIs; authentication guards and role authorization; profiles; PostgreSQL/schema/migrations; animal/herd/case/vaccination/treatment/mortality entities; server sync; veterinarian workflows; official surveillance dashboards; disease/risk rules; geospatial and temporal aggregation; notifications/advisories; laboratory referral; multilingual content; AI inference; security/audit; integration and acceptance tests; deployment environments and operational documentation.

### Critical blockers and dependencies

- Product and clinical governance decisions: disease taxonomy, triage rules, escalation thresholds, official workflows, and responsibility boundaries.
- Backend/database design and deployment target are undecided in repository configuration.
- Firebase project/OAuth/backend service-account configuration must be provided securely; do not commit secrets.
- Curated, consented, representative livestock-health data and veterinary review are required before model training or risk automation.
- External weather, maps/geocoding, laboratory, messaging/IVR, and government-system contracts are not present.
- Offline sync semantics and conflict ownership need an explicit decision.

### Recommended next three implementation tasks

1. **P0:** Define and implement the backend foundation: environment configuration, Firebase ID-token guard, roles, PostgreSQL schema/migrations, health checks, and versioned API contracts.
2. **P0/P1:** Connect the existing farmer health-report flow to authenticated backend create/read/sync endpoints with durable local queue, retry, idempotency, and visible sync errors.
3. **P1:** Turn the farmer report prototype into a real end-to-end case workflow: symptom/mortality submission → triage status → veterinarian review → advisory/escalation.

## Status and priority legend

- `[x]` — repository evidence shows the element exists; runtime behavior remains unverified unless stated.
- `[ ]` — outstanding implementation work.
- `[ ] **[PARTIAL]**` — incomplete, disconnected, placeholder, or only partly represented.
- `[ ] **[BLOCKED]**` — requires an external dependency, credential, data source, or product decision.
- `[ ] **[VERIFY]**` — static inspection cannot establish the result; runtime/device/integration verification is required.
- **P0** critical; **P1** high/core SIH; **P2** medium/operational completeness; **P3** optional enhancement.

---

## Phase 1 — Repository audit and architecture

**Objective:** Establish a maintainable system boundary and remove ambiguity between prototype UI, backend, AI, and deployment components.

- [x] **P0** Record the current Flutter, NestJS, AI, Android, Linux, and CI/CD areas in this roadmap (`frontend/`, `backend/`, `ai/`, `.github/workflows/`).
- [ ] **P0** Define the target architecture diagram: Flutter clients → API/auth → domain services → PostgreSQL → analytics/AI/integrations.
- [ ] **P0** Decide whether Firebase remains only an identity provider or also stores application data; document the decision.
- [ ] **P0** Add a versioned API contract (OpenAPI or equivalent) covering authentication, reports, animals, cases, sync, advisories, and dashboards.
- [ ] **P1** Separate demo fixtures from production data access; remove hard-coded names, dates, temperatures, case IDs, and alert text from production paths.

**Dependencies/blockers:** Architecture decision, backend hosting choice, database choice, clinical governance.

**Acceptance criteria:** A reviewed architecture diagram and API contract identify ownership, data flow, offline boundaries, and every external dependency.

## Phase 2 — Product requirements and user roles

**Objective:** Convert SIH requirements into testable workflows for farmers, veterinarians, and surveillance officials.

- [ ] **P0** Define role capabilities and least-privilege permissions for farmer, veterinarian, surveillance official, administrator, and laboratory user.
- [ ] **P0** Define report lifecycle states: draft, queued, submitted, triaged, assigned, under review, referred, resolved, rejected, and escalated.
- [ ] **P0** Define the minimum required fields for symptom, mortality, vaccination, treatment, sample, and herd reports.
- [ ] **P1** Define escalation SLAs and notification ownership by village, block, district, and state.
- [ ] **P1** Define measurable SIH outcomes: reporting latency, review latency, vaccination coverage, referral turnaround, mortality, and false-alert rate.
- [ ] **P2** Define language, literacy, accessibility, and channel requirements for mobile, web, IVR, and offline operation.

**Acceptance criteria:** Product requirements map every official expected outcome to an owner, data field, state transition, and verification metric.

## Phase 3 — Frontend foundation, design system and navigation

**Objective:** Preserve the existing visual foundation while making navigation and data states production-ready.

- [x] **P1** Keep centralized Material 3 and dynamic-color theming in `frontend/lib/theme/app_theme.dart` and `frontend/lib/main.dart`.
- [ ] **P1** Introduce real app routing with authenticated route guards instead of direct demo `MaterialPageRoute` role navigation.
- [ ] **P1** Add consistent loading, empty, error, retry, offline, queued, and permission-denied states.
- [x] **P1** Implement veterinarian demo navigation shell with Hub, Animals, Surveys, and Alerts; veterinarian role aliases now open `VeterinarianHome` rather than `FieldWorkerHome`.
- [ ] **P1** Implement the remaining surveillance navigation shell and authenticated role guards.
- [ ] **P1** Replace placeholder pages in `frontend/lib/farmer/home.dart` with feature routes backed by repositories.
- [ ] **P2** Centralize typography, spacing, date/time formatting, status colors, and accessible contrast rules.
- [ ] **P2** Add localization infrastructure; do not hard-code Hindi/Haryanvi claims until translations are reviewed.

**Acceptance criteria:** Every role can reach only permitted screens, and every network/local state has a user-visible deterministic state.

## Phase 4 — Authentication, authorization and profiles

**Objective:** Establish secure identity and role-aware access.

- [x] **P1** Retain Firebase client initialization and Google sign-in code path in `frontend/lib/pages/login_page.dart`.
- [ ] **P0** Implement NestJS Firebase ID-token verification using `firebase-admin` and a request guard.
- [ ] **P0** Replace `_verifyWithBackend` placeholder with an authenticated API call and session/error handling.
- [ ] **P0** Implement server-side role claims/profile lookup; never derive role from the email text field.
- [ ] **P1** Add user profile, organization, geography assignment, phone/contact, language, and consent records.
- [ ] **P1** Implement sign-out, token refresh, account deletion, disabled-account handling, and session expiry.
- [ ] **P2** Add admin workflows for inviting, approving, suspending, and reassigning users.

**Acceptance criteria:** API requests without valid tokens fail; role/geography permissions are enforced server-side and covered by authorization tests.

## Phase 5 — Farmer workflows and livestock records

**Objective:** Deliver the core farmer-facing report and animal/herd record flow.

- [ ] **P1** Replace the farmer dashboard mock data in `frontend/lib/farmer/home.dart` with authenticated API data.
- [ ] **P1** Implement animal and herd registration with stable IDs, species, breed, sex, age, tag, owner, location, and active status.
- [ ] **P1** Implement symptom and mortality reporting with validation, attachments, onset, affected/dead counts, and consent.
- [ ] **P1** Connect the “Start Health Report” action and voice/photo affordances to real workflows or clearly hide unsupported channels.
- [ ] **P1** Implement case tracking, assigned veterinarian details, status history, and farmer-visible advisories.
- [ ] **P2** Implement farmer vaccination/treatment history and upcoming preventive-care reminders.
- [ ] **P2** Add farmer edit/correction rules that preserve an audit trail.
- [ ] **P1** Add a farmer-owned submitted-reports view with local/server status, report IDs, retry state, and veterinarian-visible case updates.

**Acceptance criteria:** A farmer can submit a valid report, receive a case ID, see status changes, and view records only for owned/authorized herds.

## Phase 6 — Farmer reporting, GPS and offline capture

**Objective:** Turn the existing survey/GPS prototype into a reliable farmer health-reporting workflow. A separate field-worker product role is out of scope.

- [x] **P1** Capture optional farmer-report coordinates when location permission is granted; durable location history and server map exposure remain unverified.
- [x] **P1** Capture a structured farmer health report with species, count, farmer/contact, village, symptoms, signs, notes, and optional coordinates in `frontend/lib/farmer/reporting/livestock_survey_page.dart`.
- [x] **P1** Persist reports locally as JSON in `SharedPreferences` through `LivestockSurveyRepository`, including fallback reads from the legacy storage key so existing local records are not discarded.
- [ ] **P0** Replace local-only storage with an encrypted/durable offline database and a durable sync queue.
- [ ] **[PARTIAL]** Implement authenticated upload, idempotency keys, retry/backoff, conflict handling, and durable server acknowledgement; this prototype saves locally first, submits with explicit Saving/Submitting/Submitted/Submission Failed states, supports retry with the same local ID, and displays the in-memory report ID.
- [x] **P1** Connect the farmer report submission to `POST /api/v1/reports` with explicit API host configuration: Linux uses `localhost`, Android emulator uses `10.0.2.2`, and physical Android devices require `--dart-define=JEEVSWASTH_ANDROID_API_HOST=<LAN_HOST>` or `JEEVSWASTH_API_BASE_URL=<URL>`.
- [ ] **P1** Add mortality counts, vaccination/treatment observations, animal tags, photos, samples, and structured clinical metadata.
- [ ] **P2** Add geocoding privacy controls, location accuracy display, consent, and coordinate redaction where required.
- [ ] **P2** Replace “Sync Now” and “coming soon” actions with real stateful operations.

**Acceptance criteria:** A farmer can create a report offline, close/reopen the app without loss, and see the current local/submission state per report. Background synchronization remains out of scope until the backend queue exists.

## Phase 7 — Veterinarian workflows and case review

**Objective:** Provide clinical review, triage, referral, treatment, and closure.

- [x] **P1 — UI only (22 October 2026)** Implement reference-inspired veterinarian dashboard: pale-green scrollable layout, perimeter banner, profile, triage cards, priority cases, routine visit, rapid-action grid, illustrative sector map, follow-ups, and explicit unavailable sync status. Theme remains centralized; no packages added.
- [x] **P1 — Demo only** Separate fictional profile, case, triage, visit, and follow-up data in `frontend/lib/veterinarian/demo_data.dart`. Review opens read-only demo details. Availability and follow-up completion are reversible in memory, retained across tabs, and reset on leaving the dashboard; they do not write patient records or change real duty status.
- [x] **P1 — Navigation only** Route `vet`, `veterinarian`, `veterinary officer`, and `veterinary_officer` through the existing demo login to this dashboard. Animals shows demo records; Alerts explicitly states no live feed is connected. Log Symptoms opens the Surveys tab, which explains and opens the existing real livestock-survey form without fictional prefill. Saving that form still uses existing local storage and reports submission.
- [ ] **P0** Connect veterinarian dashboard and assigned/unassigned queues to authenticated case/profile APIs with authoritative geography and role authorization. Demo role text is not authorization.
- [ ] **P1** Persist veterinarian availability and follow-up state with audit history, offline handling, and server acknowledgement; replace session-only demo state.
- [ ] **P1** Connect Navigate & Call, Kit Sample, Dispatch Paravet, E-Prescription, Diagnostic Kit, Daily Route, routine visits, and sector navigation to real services. Current actions explain missing functionality; no fake endpoints are introduced.
- [ ] **P1** Supply authoritative perimeter/alert feeds, map coordinates, measured GPS accuracy, and actual synchronization state. The current map is only a schematic, sample hotspots are fictional, and sync/GPS are explicitly unavailable.
- [ ] **[VERIFY]** Run Flutter analysis/build and widget/device checks for veterinarian role routing, case dialogs, tab state, narrow phones, large text, light/dark themes, and survey return navigation. This change received source inspection only; no commands, tests, builds, formatters, or runtime checks were executed.
- [ ] **P1** Show evidence-grounded report details, history, location, attachments, and source attribution.
- [ ] **P0** Read and review farmer-submitted reports from an authenticated backend queue; the current `POST /api/v1/reports` endpoint accepts reports but exposes no list, detail, or status API.
- [ ] **P1** Add triage outcome, differential/ suspected condition, urgency, recommended action, and follow-up date fields.
- [ ] **P1** Add veterinarian assignment, reassignment, comments, case notes, and state transitions.
- [ ] **P1** Record treatment, dosage/instructions, vaccination, quarantine/biosecurity advice, and outcome.
- [ ] **P1** Add laboratory sample/referral initiation and result review.
- [ ] **P2** Add teleconsultation/contact workflow and escalation to officials.

**Acceptance criteria:** A veterinarian can claim a case, review source data, record an action, refer it, and close it with an immutable history.

## Phase 8 — Government-official dashboards and surveillance

**Objective:** Support block/district-level situational awareness and coordinated response.

- [ ] **P0** Connect the existing `surveillance` role screen (`frontend/lib/surveillance/home.dart`) to authoritative report feeds; its current cards, map, trends, alerts, and response controls are sample telemetry and explicit unavailable actions.
- [ ] **P1** Provide village/block/district filters, report volumes, active cases, mortality, vaccination coverage, and referral status.
- [x] **P1 — Surveillance Officer only** Added an OpenFreeMap/MapLibre interactive map to the surveillance Overview and Map screens. Markers currently come from `GET /reports/locations/clusters` and are plotted only when the backend returns valid aggregated coordinates.
- [x] **P1 — Privacy-safe location display** Reused the backend minimum-report cluster response, displayed aggregated coordinates only, and kept individual report coordinates out of the Flutter map. The map includes panning, pinch zoom, recentering, attribution, marker summaries, empty/error states, and a full-map action.
- [x] **Surveillance demo fallback** When the location-cluster API is unavailable, the map shows clearly labelled demonstration clusters for Bilaspur, Indri, and Assandh instead of appearing blank. These markers are not presented as live incidents.
- [ ] **P1 — Pending** Add backend-provided risk levels and authenticated geography filters. Until then, markers use the green “risk level not supplied by API” state; no incident severity, outbreak status, or cluster statistics are invented by the client.
- [ ] **P1** Add outbreak watchlists, alert acknowledgement, action assignment, and response timeline.
- [ ] **P1** Add exportable, access-controlled reports for planning and government review.
- [ ] **P2** Add trend comparison by species, disease/condition, geography, season, and reporting source.

**Acceptance criteria:** An official can identify emerging clusters, drill into authorized evidence, assign response work, and measure actions over time.

## Phase 9 — Backend API and business logic

**Objective:** Replace the NestJS starter endpoint with a modular domain API.

- [x] **P1** Retain NestJS bootstrap in `backend/src/main.ts` and starter root controller/service as the current baseline.
- [ ] **[PARTIAL]** Create modules/controllers/services/DTOs for identity, profiles, animals, herds, reports, cases, visits, vaccinations, treatments, samples, advisories, alerts, and analytics; only the prototype reports controller/service exists.
- [ ] **P0** Add DTO validation, consistent error envelopes, pagination, filtering, sorting, correlation IDs, and API versioning.
- [ ] **P0** Add auth and role/geography guards to every protected route.
- [ ] **P1** Implement transactional report/case state transitions and idempotent sync endpoints.
- [ ] **P1** Add health/readiness endpoints that do not expose secrets or sensitive data.
- [ ] **P1** Replace placeholder Observe credentials (`YOUR_APP_KEY`, `YOUR_APP_SECRET`) with environment configuration or disable instrumentation safely.
- [ ] **P2** Add rate limiting, request size limits, attachment handling, and background job boundaries.

**Acceptance criteria:** API routes are documented, validated, authenticated, authorized, transaction-safe, and covered by unit/integration tests.

## Phase 10 — Database schema, migrations and data integrity

**Objective:** Establish authoritative persistence; no database configuration currently exists.

- [ ] **P0** Choose PostgreSQL (or document another decision) and add environment-based connection configuration.
- [ ] **P0** Select and configure an ORM/query layer; add initial migrations rather than relying on generated runtime schema.
- [ ] **P0** Model users/roles/organizations/geographies, animals, herds, reports, symptoms, mortality, cases, assignments, visits, vaccinations, treatments, samples, lab results, advisories, alerts, and audit events.
- [ ] **P0** Add foreign keys, uniqueness, check constraints, timestamps, soft deletion/retention rules, and indexes for geography/time/status queries.
- [ ] **P1** Add idempotency and client-event identifiers for offline sync.
- [ ] **P1** Define provenance/versioning for imported, edited, AI-extracted, and veterinarian-confirmed fields.
- [ ] **P1** Add seed data only in a clearly isolated development fixture path.

**Acceptance criteria:** A clean environment can migrate, insert a complete report lifecycle, enforce constraints, and recover from failed transactions.

## Phase 11 — AI-assisted report understanding and structured extraction

**Objective:** Use AI safely for extraction and missing-information support without presenting unsupported diagnosis as fact.

- [x] **P1** Preserve dataset schema and safety rules in `ai/DATASET_GUIDELINES.md` and `ai/validate_dataset.py`.
- [x] **P1** Retain JSONL train/validation/test datasets under `ai/dataset/` as data assets; their quality and provenance are not runtime-verified.
- [ ] **P0** Define the model/service boundary, schema version, prompt/model version, confidence fields, and human-review requirement.
- [ ] **P1** Build an inference service or library for structured extraction of species, counts, deaths, symptoms, onset, vaccination, treatment, and summary.
- [ ] **P1** Add missing-information detection that asks targeted follow-up questions without inventing values.
- [ ] **P1** Store raw report, extracted output, evidence spans, model version, and reviewer corrections.
- [ ] **P1** Add evaluation for field-level precision/recall, abstention, multilingual inputs, and out-of-distribution reports.
- [ ] **P2** Add voice/image/document preprocessing only after consent, retention, and model quality decisions.
- [ ] **P0** Keep disease diagnosis, risk scores, and outbreak declarations out of extraction unless separately governed, validated, and human-reviewed.

**Acceptance criteria:** AI output is schema-valid, evidence-grounded, versioned, reviewable, and never silently converted into a clinical diagnosis or official alert.

## Phase 12 — Disease-risk assessment and outbreak early warning

**Objective:** Provide explainable rule-based/AI-assisted triage and early warning.

- [ ] **P0** Define a disease/condition taxonomy, symptom dictionary, severity rules, and clinical review ownership.
- [ ] **P1** Implement deterministic baseline triage with explicit inputs, thresholds, explanations, and abstention.
- [ ] **P1** Aggregate reports by geography/time/species and detect unusual increases with minimum-data safeguards.
- [ ] **P1** Separate suspected case, risk signal, cluster/watchlist, and confirmed outbreak states.
- [ ] **P1** Require official/veterinary confirmation before publishing outbreak declarations.
- [ ] **P2** Add model-assisted ranking only with calibrated confidence, drift monitoring, and human override.
- [ ] **P2** Measure alert precision, recall, timeliness, false positives, and missed clusters.

**Acceptance criteria:** Every alert shows evidence, threshold/model version, geography/time window, confidence/limitations, owner, and acknowledgement state.

## Phase 13 — Geospatial and temporal analysis

**Objective:** Turn location/time data into privacy-safe surveillance intelligence.

- [ ] **P1** Normalize village/block/district boundaries and coordinate reference handling.
- [ ] **P1** Store report/event timestamps in UTC with user-facing timezone conversion and reliable onset dates.
- [ ] **P1** Implement map layers for reports, risk signals, vaccination coverage, and response actions.
- [ ] **P1** Add spatial clustering and temporal trend queries with minimum aggregation thresholds.
- [ ] **P2** Integrate weather and historical disease trends through documented adapters and cached provenance.
- [ ] **P2** Add offline-safe map/coordinate behavior and explicit accuracy/staleness indicators.

**Acceptance criteria:** Authorized users can view reproducible, time-bounded clusters and trace each aggregate to source records without exposing unnecessary household coordinates.

## Phase 14 — Vaccination, treatment history and preventive care

**Objective:** Close the prevention and longitudinal-record gap in the SIH scope.

- [ ] **P1** Implement animal/herd vaccination records with vaccine, batch, dose, date, provider, next due date, and evidence.
- [ ] **P1** Implement treatment records with condition, medicine, dosage, duration, provider, outcome, and withdrawal/safety notes.
- [ ] **P1** Add preventive-care schedules, missed-dose queues, and coverage calculations.
- [ ] **P1** Link vaccination/treatment events to reports, cases, visits, and advisories.
- [ ] **P2** Add bulk campaign planning, attendance, coverage maps, and post-campaign reconciliation.

**Acceptance criteria:** A user can view an auditable animal/herd timeline and officials can calculate coverage from authoritative records.

## Phase 15 — Notifications, multilingual advisories and escalation

**Objective:** Deliver timely, understandable preventive action.

- [ ] **P1** Implement in-app notification data model, read/acknowledge state, priority, expiry, and targeting.
- [ ] **P1** Add push notification delivery with token lifecycle, retry, and opt-in/consent controls.
- [ ] **P1** Build advisory templates for quarantine, vaccination, treatment follow-up, sample collection, and emergency escalation.
- [ ] **P1** Provide reviewed multilingual content and plain-language explanations; do not rely on untranslated UI strings.
- [ ] **P1** Implement escalation timers and fallback channels for unacknowledged critical alerts.
- [ ] **P2** Add SMS/IVR/WhatsApp or other channels only through approved providers and contracts.

**Acceptance criteria:** A targeted user receives the correct localized advisory, can acknowledge it, and the system records delivery/acknowledgement/escalation history.

## Phase 16 — Laboratory referrals and external integrations

**Objective:** Support sample collection, referral, results, and interoperable surveillance.

- [ ] **P1** Model sample ID, specimen type, collection metadata, chain of custody, cold-chain checks, destination lab, and status.
- [ ] **P1** Implement referral creation, tracking, result entry/import, veterinarian review, and case linkage.
- [ ] **P2** Add barcode/QR scanning; the current “Sample Kit” and “Attach Tag” actions are placeholders.
- [ ] **P2** Define adapters/contracts for weather, maps, government registries, vaccination programmes, and lab systems.
- [ ] **P2** Add integration retries, provenance, consent, timeout handling, and reconciliation reports.
- [ ] **P3** Consider IVR and external registry integration only after core mobile/API workflows are stable.

**Acceptance criteria:** A sample can be collected offline, synchronized, tracked through referral/result, and linked to the final case outcome.

## Phase 17 — Offline-first operation and synchronization

**Objective:** Make low-connectivity operation reliable rather than cosmetic.

- [x] **P1** Provide local survey storage and cached location fallback using `SharedPreferences`.
- [ ] **P0** Replace `SharedPreferences` for records with a durable, migration-capable local database.
- [ ] **P0** Implement an outbox with immutable client event IDs, ordering, retries, backoff, and dead-letter/error review.
- [ ] **P0** Implement server-side idempotency and conflict policy for edits made on multiple devices.
- [ ] **P1** Sync attachments separately with resumable upload and local retention limits.
- [ ] **[PARTIAL]** Show true pending/synced/failed states; the survey submission prototype now transitions local status for this foreground request, but has no background queue.
- [ ] **P1** Add connectivity detection, manual retry, background sync, and safe logout/device change behavior.
- [ ] **P2** Define data retention/encryption behavior for lost or shared devices.

**Acceptance criteria:** Network interruption tests demonstrate no data loss, duplicate submissions, silent failures, or misleading “synced” status.

## Phase 18 — Security, privacy, permissions and auditability

**Objective:** Protect sensitive farmer, location, health, and identity data.

- [ ] **P0** Remove secret-like placeholders from runtime configuration and document secret injection; never commit service-account keys.
- [ ] **P0** Enforce server-side authentication, authorization, tenant/geography isolation, and object-level access checks.
- [ ] **P0** Define consent, purpose limitation, retention, deletion, export, and correction processes.
- [ ] **P0** Add append-only audit events for access, edits, role changes, exports, AI review, alerts, and case state transitions.
- [ ] **P1** Encrypt transport and sensitive local/server data; protect tokens and cached records on devices.
- [ ] **P1** Validate uploads, sanitize text, limit payloads, and protect against injection/abuse.
- [ ] **P1** Minimize precise location exposure and implement aggregation/redaction for dashboards.
- [ ] **P2** Add dependency/security scanning, incident response, backups, restore testing, and key rotation.

**Acceptance criteria:** A security review can demonstrate least privilege, auditable access, safe secret handling, privacy controls, and tested recovery procedures.

## Phase 19 — Testing, evaluation and reliability

**Objective:** Prove important user behavior and clinical/data safeguards without relying on visual presence.

- [x] **P1** Retain NestJS unit/e2e test scaffolding in `backend/src/app.controller.spec.ts` and `backend/test/app.e2e-spec.ts`.
- [x] **P1** Retain CI static analysis/build steps in `.github/workflows/android-build.yml` as configured checks; execution was not verified in this audit.
- [ ] **P0** Add backend unit/integration tests for guards, DTOs, state transitions, sync idempotency, permissions, and transactions.
- [ ] **P1** Add Flutter tests for forms, validation, routing, offline persistence, GPS permission states, and sync UI.
- [ ] **P1** Add contract tests between Flutter repositories and NestJS APIs.
- [ ] **P1** Add AI dataset/schema/evaluation tests, including abstention and unsupported-claim checks.
- [ ] **P1** Add geospatial/time aggregation tests and alert threshold regression fixtures.
- [ ] **P1** Add device/manual acceptance matrix for Android low-connectivity, denied GPS, stale GPS, interrupted upload, and Firebase sign-in.
- [ ] **P2** Add load, resilience, backup/restore, accessibility, localization, and security testing.

**Acceptance criteria:** The critical end-to-end flows have repeatable automated checks plus a documented device/field acceptance record.

## Phase 20 — Deployment, CI/CD and release management

**Objective:** Make releases reproducible for Android and backend environments.

- [x] **P1** Keep Android workflow for Flutter analyze/build/release in `.github/workflows/android-build.yml`.
- [ ] **P0** Add backend CI for install, lint, typecheck/build, unit tests, integration tests, and image/package publication.
- [ ] **P0** Define dev/staging/production environment configuration, migrations, secrets, Firebase projects, and rollback procedures.
- [ ] **P1** Prevent release workflows from exposing secrets and restrict release permissions to least privilege.
- [ ] **P1** Add artifact signing/provenance, versioning, changelog, and release approval gates.
- [ ] **P1** Add deployment health checks, logs, metrics, alerts, and database backup verification.
- [ ] **P2** Decide whether Linux/web/macOS are supported products or development previews; document unsupported Firebase behavior.

**Acceptance criteria:** A clean checkout can produce signed, traceable artifacts and deploy/rollback each environment using documented automation.

## Phase 21 — Documentation, demonstration and SIH readiness

**Objective:** Present a credible, evidence-backed SIH solution and preserve continuity for future coding sessions.

- [x] **P1** Preserve the supplied problem statement in `statment.md` and this roadmap as the implementation source of truth.
- [ ] **P0** Add setup documentation for frontend, backend, database, Firebase, AI service, environment variables, and secrets.
- [ ] **P0** Write a demo script that shows farmer report → veterinarian review → risk signal → official response → advisory. Assisted field verification is out of scope as a separate role.
- [ ] **P1** Add an architecture/data-flow diagram and role-permission matrix.
- [ ] **P1** Document limitations: no diagnosis without review, uncertain signals, offline staleness, missing integrations, and supported platforms.
- [ ] **P1** Prepare anonymized seed/demo data and a reproducible presentation environment.
- [ ] **P1** Document SIH outcome metrics and baseline/target values without claiming unmeasured impact.
- [ ] **P2** Add operator runbooks for alerts, lab failures, sync backlog, model rollback, incident response, and data correction.
- [ ] **P2** Maintain this file after each implementation milestone; only mark `[x]` with repository/runtime evidence.

**Acceptance criteria:** A new contributor can set up the project, a judge can follow the end-to-end demo, and every claimed capability has evidence and a stated limitation.

---

## Evidence index

- `statment.md` — supplied SIH problem description and expected outcomes.
- `frontend/pubspec.yaml` — Flutter SDK and installed frontend dependencies.
- `frontend/lib/main.dart` — app entrypoint, dynamic color, Firebase initialization, Linux skip, root login page.
- `frontend/lib/theme/app_theme.dart` — Material 3 centralized theme.
- `frontend/lib/pages/login_page.dart` — Firebase/Google sign-in client path, demo-only role routing, unconnected backend verification.
- `frontend/lib/farmer/home.dart` — farmer dashboard and entry point for health reports.
- `frontend/lib/farmer/reporting/livestock_survey_page.dart` — structured report form, optional GPS capture, local-save, and best-effort submission flow.
- `frontend/lib/farmer/reporting/models/livestock_survey.dart` — report schema, JSON serialization, sync-status enum.
- `frontend/lib/farmer/reporting/data/livestock_survey_repository.dart` — `SharedPreferences` persistence with legacy-key compatibility.
- `frontend/lib/farmer/home.dart` — farmer UI with hard-coded demo content and placeholder actions.
- `frontend/lib/veterinarian/home.dart` — reference-inspired veterinarian demo dashboard and session-only interactions (22 October 2026; runtime unverified).
- `frontend/lib/veterinarian/demo_data.dart` — isolated fictional dashboard fixtures, never submitted to the reports API.
- `frontend/lib/widgets/veterinarian_navbar.dart` — veterinarian Material 3 navigation destinations.
- `frontend/lib/surveillance/home.dart` — surveillance overview shell with sample metrics, risk-map/trend visuals, alert cards, response CTA, and explicit unavailable-data messaging; no analytics backend is connected.
- `backend/src/app.module.ts`, `app.controller.ts`, `app.service.ts`, `main.ts` — NestJS starter app and Observe placeholders.
- `backend/package.json` — NestJS/Firebase Admin dependencies and test/lint/build scripts.
- `ai/DATASET_GUIDELINES.md`, `ai/validate_dataset.py`, `ai/dataset/` — extraction schema, safety constraints, validator, and datasets; no model/inference code.
- `frontend/android/app/src/main/AndroidManifest.xml` — Android location permissions and launcher configuration.
- `.github/workflows/android-build.yml` — Flutter analyze/build/release workflow.

## Audit limitations

This roadmap intentionally does not claim that the app builds, the Android device flow works, Firebase credentials are valid, the backend starts, tests pass, the datasets are valid, or external services respond. Those claims require execution and are marked as outstanding or `[VERIFY]` work above.

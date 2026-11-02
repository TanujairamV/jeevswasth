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
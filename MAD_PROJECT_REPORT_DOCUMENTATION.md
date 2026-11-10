# AutoSphere — MAD Project Report Documentation

> **Source-analysis status:** This document describes the workspace as inspected on 5 November 2026. Technical statements below are based on the Flutter source, platform configuration, README, lockfile, and tests. The linked FastAPI server implementation is not present in this workspace. The report therefore distinguishes implemented behavior from claims that require external verification.

## Project at a glance

| Item | Source-supported description |
|---|---|
| **Project name** | AutoSphere |
| **Project type** | Flutter/Dart mobile application for organizing vehicle ownership, activity, maintenance, expenses, documents, and reminders |
| **Main technologies** | Flutter, Dart, Material 3, Provider, SQLite through `sqflite`, HTTP/JSON, local notifications, `fl_chart`, image/file picker plugins |
| **Main features** | Garage of up to three vehicles; vehicle profile and photo; odometer and service interval tracking; fuel/service/expense activity; garage-wide timeline; spending and fuel/service analytics; local document vault; due-date reminders and notifications; optional service-history upload and maintenance prediction via a remote API |
| **Architecture overview** | Flutter presentation widgets call a Provider-managed `AppState`; the state object coordinates local SQLite persistence and UI notifications. A separate API client supports optional backend operations, and a notification service schedules local reminders. |

## 1. Project Title

**AutoSphere: An Offline-First Vehicle Ownership and Maintenance Management Application**

This expanded academic title describes the implemented application domain and its local-first data approach. The source project itself is named `autosphere` and the UI branding is `AutoSphere`.

## 2. Abstract

AutoSphere is a cross-platform Flutter application focused on consolidating personal vehicle information and ownership activities. It allows a user to maintain profiles for up to three vehicles, record fuel fills, service visits and expenses, review a date-ordered activity timeline, inspect spending and usage charts, store vehicle documents locally, and schedule renewal or maintenance reminders. A vehicle profile can include make, model, model year, fuel type, registration number, odometer value, a nickname, and an optional image.

The application uses a local SQLite database as its primary store. Vehicle, activity, document, reminder, and application-setting records are persisted locally; vehicle photographs and imported document contents are stored as BLOB data. This supports the stated offline-first workflow. An optional HTTP client can register a generated backend user, upload vehicle profiles and service records, and request a maintenance prediction for the selected vehicle. The backend source is not included, and a live prediction or deployed synchronization service cannot be verified from this workspace.

The user interface is written in Dart using Flutter Material 3 and Provider-based state management. Other dependencies support charts, file and image selection, HTTP requests, SQLite, time-zone-aware local notifications, and platform integrations. The included automated tests validate representative widget behavior and a mocked API request contract. They do not establish production deployment, native notification delivery, or compatibility with every generated Flutter platform target.

## 3. Introduction

Vehicle ownership commonly involves several recurring records: vehicle identity and mileage, fuel consumption, maintenance, repairs, insurance or registration documents, and renewal dates. AutoSphere implements a single-device application for recording and reviewing these items. Its four main destinations are **Garage**, **Timeline**, **Analytics**, and **Documents**.

The application is a Flutter project rather than a collection of separate native Android and iOS user interfaces. `lib/main.dart` configures the app and launches `DashboardScreen`; `lib/screens.dart` implements the Garage dashboard and top-level navigation; `lib/feature_screens.dart` implements feature tabs and associated forms; and `lib/state.dart` coordinates SQLite storage and state updates. Android, iOS, macOS, web, Linux, and Windows project scaffolds exist, but the presence of a scaffold is not evidence that every feature works on each platform.

## 4. Problem Statement

The application addresses the practical problem of keeping a vehicle owner's recurring records and due dates together in one accessible interface. Without a consolidated log, information such as the date and odometer of a service, cumulative spending, or an upcoming document renewal can be difficult to review together.

The code establishes the application's intended problem domain, but it does not provide a user study, requirements survey, measured comparison with other products, or evidence that users experienced a particular pain point. Any academic claims about prevalence, user demand, or improvements over named commercial systems require independent research and citations.

## 5. Objectives

The implemented objectives inferred from the source are:

1. Maintain a small local garage with a maximum of three vehicle profiles.
2. Record and display vehicle activity including fuel, service, expenses, document additions, and reminders.
3. Keep activity and vehicle data available through a local SQLite database.
4. Track odometer changes and calculate a distance-based service interval estimate.
5. Summarize costs, fuel efficiency, and distances between service visits when sufficient data is available.
6. Store imported vehicle documents on-device and allow export of a saved copy.
7. Schedule local notifications for future saved due dates where plugin initialization succeeds.
8. Provide an optional integration that uploads vehicle and service information and requests a backend prediction.

## 6. Scope of the Project

### 6.1 Included scope

- One local app installation and its SQLite database.
- Up to three vehicle profiles.
- Per-vehicle activity entry and a timeline aggregating activities from all vehicles.
- Locally stored vehicle photos and documents.
- Charts and summaries derived from local records.
- Device-local reminder scheduling.
- Optional remote user/vehicle/service creation and maintenance-prediction retrieval.

### 6.2 Out of scope or not established

- Multi-user accounts, interactive sign-in, password management, or roles.
- Bidirectional synchronization, conflict resolution, remote update/delete, or synchronization of documents, fuel, expenses, and reminders.
- An included backend implementation or a verifiable deployed API.
- Vehicle telemetry, GPS, fuel-station integrations, payment processing, or manufacturer/OBD integrations.
- Remote backup or encryption of the local database and stored files.
- Reliable notification execution on every platform or across every device state.
- User research, performance benchmarks, production distribution, or measured usability outcomes.

## 7. Existing System

No existing-system implementation, comparative evaluation, or external product analysis is included in the repository. For an academic report, the “existing system” can be framed as a **generic manual or fragmented record-keeping approach**—for example, maintaining service receipts, fuel notes, and renewal dates in separate places—but this should be presented as background context, not as a measured finding about a particular user group.

Do not claim that AutoSphere replaces a named product or that it outperforms existing systems unless a separate, properly cited comparative study is conducted.

## 8. Proposed System

The proposed system, as implemented, is a local-first vehicle-management app. Its primary workflow is:

1. Start the app and initialize the SQLite database.
2. Load or create vehicle profiles and their associated records.
3. Select a vehicle and enter activities, documents, or reminders.
4. Persist changes locally and notify the Provider-backed UI.
5. Derive dashboard summaries, timeline entries, and analytics from saved rows.
6. Optionally connect to a configured API to send vehicle profiles and service-history rows and request a selected vehicle's maintenance prediction.

This description should not be read as a claim of full cloud synchronization: only vehicle registration and service records are uploaded in the current client logic.

## 9. Feasibility Study

| Feasibility area | Source-based assessment | Evidence and qualification |
|---|---|---|
| **Technical** | Feasible for a Flutter application with local storage and platform plugins. | Flutter/Dart, `sqflite`, `provider`, HTTP, notification, image/file picker, and chart dependencies are present. Real-device verification is still required. |
| **Operational** | The UI offers direct forms and four labeled destinations for ordinary vehicle-record workflows. | Widget tests exercise dashboard, navigation, validation, and vehicle-cap behavior. No field study or usability evaluation is included. |
| **Economic** | **Not identifiable from the source code.** | No cost, hosting plan, licensing budget, or hardware procurement estimate is specified. |
| **Schedule** | **Not identifiable from the source code.** | No project plan, milestones, effort log, or completion schedule is present. |
| **Deployment** | Android/iOS project configuration exists; the README describes local Flutter run/build commands. | Signing, store deployment, backend hosting, and live service availability are not verified. |
| **Data/privacy** | Core records are locally stored; optional sync transmits a subset to an external server. | No database encryption, privacy policy, retention policy, or backend security design is included. |

## 10. Software and Hardware Requirements

### 10.1 Software requirements evidenced by project configuration

| Requirement | Evidence / value |
|---|---|
| Flutter and Dart | `pubspec.yaml` requires Dart `^3.12.2`; the lockfile records a Flutter SDK lower bound of `>=3.44.0`. These are project constraints, not proof of the exact SDK installed on a target device. |
| Android build toolchain | Gradle wrapper uses Gradle `9.1.0`; Android plugin is `9.0.1`; Kotlin Android plugin is `2.3.20`; Java/Kotlin bytecode target is JVM 17. Android SDK and NDK versions are delegated to Flutter's configured versions. |
| iOS | Xcode project scaffold; project settings include iOS deployment target `15.0` and recommended-target settings. Exact build/signing environment is not specified. |
| macOS | macOS runner scaffold has deployment target `12.0`. |
| Local development | Flutter SDK and package resolution via `flutter pub get`; README suggests `flutter run`. |
| Optional API | A reachable HTTP service implementing the client routes, or a replacement URL passed with `--dart-define=AUTOSPHERE_API_BASE_URL=...`. The server code is not present. |

### 10.2 Hardware requirements

**Not identifiable from the source code.** No minimum CPU, RAM, storage, screen resolution, or named device model is specified. A device or emulator must meet the chosen Flutter and operating-system requirements and have enough local storage for SQLite records, images, and documents. The client rejects imported documents larger than 20 MiB.

## 11. Technologies Used

| Technology / package | Use in this project |
|---|---|
| Flutter / Dart | Cross-platform UI and application logic. |
| Material 3 (`flutter/material.dart`) | Dark-themed application UI, widgets, forms, navigation, dialogs, and date pickers. |
| Provider `^6.1.5+1` | Exposes `AppState` through `ChangeNotifierProvider`; widgets read/watch it. |
| SQLite via `sqflite ^2.4.4+1` | Local relational storage and transactions. |
| `path ^1.9.1` | Constructs the database file path. |
| `http ^1.6.0` | JSON REST client with a 15-second request timeout. |
| `fl_chart ^1.2.0` | Fuel-efficiency, service-cycle, and monthly-spending charts. |
| `image_picker ^1.2.4` | Selects vehicle images from the gallery; the selected bytes are stored in SQLite. |
| `file_picker ^13.1.0` | Imports and exports document bytes. |
| `flutter_local_notifications ^23.0.0-dev.3` | Schedules and cancels local reminder notifications. |
| `timezone ^0.11.1` and `flutter_timezone ^5.1.1` | Time-zone database and device-local timezone configuration for scheduling. |
| `flutter_test` / `flutter_lints ^6.0.0` | Widget/API testing and static lint configuration. |
| Native platform wrappers | Android Gradle/Kotlin, iOS Swift/Xcode, macOS Swift/Xcode, and generated web/desktop runner scaffolds. |

The versions above are the declared constraints in `pubspec.yaml`; the lockfile is the resolution source for exact transitive versions. No custom font or Flutter asset directory is declared under `flutter:` in `pubspec.yaml`. The UI requests the `Avenir Next` font family; whether that font is available depends on the platform and is not bundled as a project font asset.

## 12. System Architecture

AutoSphere follows a client application architecture with local persistence as its primary data source and an optional remote service for a limited subset of operations.

```text
User
  │
  ▼
Flutter UI (DashboardScreen, tabs, dialogs/forms)
  │  reads/writes through Provider
  ▼
AppState (ChangeNotifier; validation, data loading, aggregation coordination)
  ├──► SQLite database (vehicles, activities, documents, reminders, app_settings)
  ├──► ReminderNotifications ──► OS local notification service
  └──► Api (JSON over HTTP) ──► optional external backend

Platform plugins
  ├── image picker ──► selected vehicle image bytes
  └── file picker ──► selected document bytes / exported copy
```

`main()` initializes Flutter bindings, configures status-bar appearance, creates an `AppState`, starts the app, initializes the database and notifications, then schedules the reminders loaded from local storage. The UI shows a loading indicator until database initialization completes. Database state updates call `notifyListeners`, causing listening widgets to rebuild.

## 13. Application Architecture

The Dart code is organized by responsibility rather than by a multi-package/module boundary:

| Layer | Main file(s) | Responsibility |
|---|---|---|
| App bootstrap/theme | `lib/main.dart` | Flutter initialization, root `MaterialApp`, theme, initial state and service initialization. |
| Presentation/dashboard | `lib/screens.dart` | Garage dashboard, navigation destinations, summary cards, service estimate display, maintenance entry form. |
| Feature presentation | `lib/feature_screens.dart` | Timeline, analytics, document vault, vehicle/activity/reminder/document dialogs and shared UI helpers. |
| State and persistence | `lib/state.dart` | `AppState`, SQLite schema/migrations/seed data, CRUD, computed state, optional API sync. |
| API client | `lib/api.dart` | Base URL resolution, HTTP methods, JSON parsing, timeouts, API exceptions. |
| Notification integration | `lib/reminder_notifications.dart` | Time-zone initialization and notification scheduling/cancellation. |
| Platform integration | `android/`, `ios/`, `macos/`, `web/`, `linux/`, `windows/` | Native app entry points, permissions/configuration, icons, and Flutter runner scaffolding. |

This is not a strict Clean Architecture implementation: persistence and remote-sync orchestration are both in `AppState`; there are no separate repository, domain-entity, or use-case packages.

## 14. Module Description

| Module | Key components | Data handled |
|---|---|---|
| Garage / vehicle profile | Vehicle card, selector, add/edit dialog, service interval editor | Vehicle profile, odometer, fuel type, registration, photo, service interval. |
| Activity logging | Quick actions, activity picker and form, maintenance record dialog | Fuel, service, expense, document-added and reminder activity rows. |
| Timeline | `TimelineTab`, filters, entries | All vehicles' activities ordered newest first. |
| Analytics | `AnalyticsTab`, chart helpers | Fuel efficiency and service distances for selected vehicle; cost summaries across all activities. |
| Document vault | Import dialog, document tile, export/delete actions | Document metadata and BLOB contents, optional expiry date. |
| Reminders | Reminder form, dashboard panel, `ReminderNotifications` | Due date, type, notes, platform notification IDs. |
| Local persistence/state | `AppState` | SQLite schema version 4, local CRUD, vehicle selection, derived values. |
| Optional cloud integration | `Api`, `AppState.syncWithCloud()` | Generated remote user, vehicle creation, unuploaded service records, selected vehicle prediction. |

## 15. Detailed Functionalities of Each Module

### 15.1 Garage and vehicle profiles

- The garage is limited to three vehicles. The limit is checked in the UI and rechecked inside a SQLite transaction in `AppState.addVehicle`.
- A profile captures nickname, make, model, year, fuel type (Petrol, Diesel, CNG, Electric, Hybrid), registration number, odometer, and optional photo.
- The selected vehicle's odometer is displayed with a service interval. The interval defaults to 5,000 km and can be changed to any positive integer.
- Vehicle selection reloads selected-vehicle records and documents; the timeline and some analytics intentionally use all-vehicle data.
- The UI prevents deletion of the last remaining vehicle. Removing a vehicle cascades deletion of its related activity, document, and reminder rows because foreign keys are enabled and schema relations specify `ON DELETE CASCADE`.

### 15.2 Activity and maintenance recording

- Activity types stored are `fuel`, `service`, `expense`, `document`, and `reminder`.
- Fuel entry collects station/description, cost, litres, odometer, date, and optional notes. The form requires cost, quantity, and odometer.
- Service entry collects a description, optionally cost, odometer, service center, category, date, and notes. Odometer is required by the form.
- Expense entry requires a description and cost, with optional odometer, date, category, and notes.
- A separate dashboard **Add record** dialog adds a service-type maintenance row with title, date, and optional cost; it does not collect odometer or service-center data.
- A newly recorded activity with an odometer greater than the current vehicle odometer updates that vehicle's odometer.
- Activity rows may be removed from the dashboard or timeline. There is no activity-edit workflow.

### 15.3 Timeline

The Timeline tab queries all activity rows, sorted by `date DESC, id DESC`, and associates rows with vehicle nicknames. Filters are available for All, Fuel, Service, Expenses, Documents, and Reminders. Entries can be dismissed to delete the activity. Fuel rows can show quantity/odometer; service rows can show odometer/service center; exact multiples of 10,000 km receive a milestone badge.

### 15.4 Analytics

- **Fuel efficiency:** selected-vehicle fuel records with odometer readings are sorted by odometer. For each adjacent pair with increasing odometer and positive quantity in the current fill, the chart plots `(current odometer - previous odometer) / current fill quantity` in km/L. The empty state states that at least three fills are needed for a trend; the code only renders the line chart when it has at least two calculated intervals.
- **Maintenance cycles:** adjacent service records with increasing odometer are plotted as the difference in odometer. At least two service rows with odometer are needed.
- **Monthly spending:** sums activity costs for the last six calendar months, across all vehicles. Invalid dates are ignored.
- **Spending by type:** groups positive activity costs by `category`, descending by aggregate amount.
- Total cost and monthly data are computed from the all-vehicle `timelineRecords`; current odometer and fuel/service interval charts are tied to the selected vehicle. “By type” is a category summary, not an activity-type summary.

### 15.5 Documents

- The user selects any file through `FilePicker`; the client streams and buffers bytes and rejects empty/unreadable content and files over 20 MiB.
- The metadata dialog accepts a title, one of Registration Certificate / Insurance / PUC / Warranty / Service bill / Other, and an optional future expiry date.
- The document is stored as a BLOB in SQLite with filename, inferred MIME type, size, expiry and creation timestamp.
- MIME inference is based on a short extension allowlist; unrecognized extensions are stored as `application/octet-stream`.
- The vault lists metadata and offers a details dialog, export, and delete. It does **not** implement in-app PDF/image preview.
- An expiry date creates a reminder row and a document activity row. Deleting the document does not, in the current implementation, remove its associated reminder or activity.

### 15.6 Reminders and notifications

- Reminders include a title, type (Insurance, PUC, Service, Registration, Other), due date, and optional notes. The form defaults to 30 days in the future and allows dates up to ten years ahead.
- A reminder also creates an activity row.
- Startup loads reminders and then attempts to schedule them. Add-reminder and document-expiry workflows call `scheduleAll` after persistence.
- The notification service initializes timezone data and tries to use the device timezone. Time-zone lookup and plugin initialization errors are caught; a failed plugin initialization leaves notifications unavailable.
- A valid future reminder is scheduled for 09:00 local time on its due date with an inexact-while-idle Android schedule mode. Past or unparseable dates are skipped.
- Android notification permission is requested in code and `POST_NOTIFICATIONS` is declared in the manifest. Explicit iOS/macOS permission request behavior is not established by this code.
- The dashboard displays up to three reminders. The database load query is not filtered by vehicle, so reminders from all vehicles can appear together.

### 15.7 Optional cloud API

`Api` uses `AUTOSPHERE_API_BASE_URL` when supplied. Otherwise it defaults to `http://10.0.2.2:8000` on Android and `http://127.0.0.1:8000` on other Dart platforms. Each request times out after 15 seconds. JSON errors and non-2xx statuses become `ApiException`s.

| Client operation | HTTP route | Client purpose |
|---|---|---|
| `healthCheck()` | `GET /` | API root check helper; no call site is present in the app flow. |
| `createUser()` | `POST /users/` | Creates a backend user. A random email and password are generated by the client; the returned user ID is stored in `app_settings`. |
| `getUser(id)` | `GET /users/{id}` | Confirms the saved backend user still exists. |
| `createVehicle()` | `POST /users/{id}/vehicles/` | Uploads make, model, year, and current mileage. Nickname, registration number, fuel type, photo, and service interval are not sent. |
| `createMaintenance()` | `POST /vehicles/{id}/maintenance/` | Uploads service date, title as service type, cost, mileage, and notes/service center. |
| `getMaintenance()` | `GET /vehicles/{id}/maintenance/` | Fetches and validates a list response; returned history is not merged into local SQLite. |
| `getPrediction()` | `GET /vehicles/{id}/predict-maintenance/` | Retrieves a prediction map for the currently selected backend vehicle. |

Sync creates a backend user if needed, registers unlinked local vehicles, and uploads local `service` activity rows whose `backend_id` is null. Successful remote IDs are stored locally to avoid uploading those same rows again. It then fetches maintenance and obtains a prediction for the selected vehicle. It does not synchronize other activity types, documents, images, reminders, edits, or deletions. The backend API schema/algorithm, availability, authentication policy, and actual prediction quality are **not identifiable from this workspace**.

## 16. System Design

### 16.1 Design decisions evidenced by the implementation

- **Local-first persistence:** SQLite is opened as `autosphere.db`; normal data-entry workflows write directly to it.
- **Relational ownership:** child tables reference `vehicles.id`, with cascading deletion.
- **Stateful UI:** `AppState extends ChangeNotifier` exposes loaded collections and flags to Provider consumers.
- **Service separation:** HTTP encoding and notifications are separated into `Api` and `ReminderNotifications`; the state object calls both as needed.
- **Schema evolution:** the database uses schema version 4 with upgrade steps for earlier database layouts.
- **Seed data:** a newly created database is initialized with a demo 2025 Toyota Innova Hycross ZX, a 10,000 km service dated 2026-05-14 at ₹4,500, and a zero-cost camera upgrade dated 2026-08-10. This is sample data, not verified user-generated data.

### 16.2 Persistence and error behavior

The database enables SQLite foreign keys. Most state mutations reload affected collections and call `notifyListeners`. Database initialization sets `isLoading` to false in a `finally` block even if opening/loading fails; there is no explicit initialization-error property or user-facing failure screen. Some form flows catch and show errors, while some writes rely on uncaught async errors. Notification initialization failures are swallowed and disable scheduling. These are implementation limitations to consider in a formal quality discussion.

## 17. Data Flow Diagram Descriptions

These are **diagram specifications** derived from the source; no DFD image is included in the workspace.

### 17.1 Level 0 (context diagram)

**Processes/entities to draw:**

- External entity **Vehicle owner**.
- Central process **AutoSphere mobile application**.
- Data store **Local SQLite database/device storage**.
- External entity **Optional AutoSphere API backend**.
- External system **Mobile OS services** (notifications, image picker, file picker).

**Flows:**

- Owner → app: vehicle details, activity forms, reminder/document metadata, navigation and delete actions.
- App → owner: dashboard, timeline, analytics, document metadata/status and validation feedback.
- App ↔ local database: vehicle/activity/document/reminder/settings records and image/document bytes.
- App → backend: generated user registration, vehicle profile fields and unuploaded service records.
- Backend → app: remote IDs, maintenance list response, prediction response/errors.
- App ↔ OS services: image/document selection and document export; app → OS: scheduled/cancelled notifications.

### 17.2 Level 1 (major internal processes)

Break the application into:

1. **Manage garage:** read/create/update/delete vehicle and select current vehicle.
2. **Capture activity:** validate and write fuel, service, expense, document, and reminder activities.
3. **Manage document vault:** import bytes, store/read/export/delete document metadata and BLOBs.
4. **Manage reminders:** store due dates, update activity history, schedule/cancel notifications.
5. **Present timeline and analytics:** query local activities and derive lists, totals, km/L, service distances, and category totals.
6. **Optional synchronize and predict:** create/validate backend user, upload vehicle/service rows, fetch selected prediction.

**Data stores:** `vehicles`, `activities`, `documents`, `reminders`, `app_settings`; plus external backend and platform notification/file-selection services.

### 17.3 Level 2 (example: add a document)

1. User invokes **Add document** from the Document Vault.
2. App checks that a current vehicle exists.
3. File picker returns a file stream/name/extension.
4. App enforces the 20 MiB limit, reads bytes and rejects empty content.
5. User enters title/type and optional expiry.
6. App infers MIME type and inserts document metadata and data BLOB into `documents`.
7. If expiry exists, app inserts a related due-date row in `reminders`.
8. App inserts a `document` activity into `activities`.
9. App reloads documents/reminders, schedules due reminders, and displays a confirmation.
10. On export, the app reads the BLOB from SQLite and passes it to the platform file picker save operation.

Other useful Level 2 diagrams are **add fuel fill** (form → validate → activity insert → odometer update if greater → reload records) and **cloud sync** (find/create user → ensure remote vehicle IDs → upload only service rows with no backend ID → request selected vehicle prediction → display message/result).

## 18. UML Diagram Descriptions

### 18.1 Use-case diagram

**Primary actor:** Vehicle owner. **Supporting actors/systems:** mobile OS file/image services, local notification service, optional remote backend.

Use cases: manage vehicle profiles; select vehicle; set service interval; add fuel/service/expense; review/delete activity; filter timeline; view analytics; import/export/delete document; add/delete reminder; receive local reminder notification; optionally synchronize vehicle/service information and view a remote prediction. Show backend sync as optional and do not represent it as full cloud backup.

### 18.2 Activity diagram

Recommended primary activity: **Record and review a vehicle activity**.

1. Start app → wait for local database initialization.
2. Select current vehicle or add one (reject if three already exist).
3. Select activity type.
4. Enter type-specific fields and validate.
5. Persist row in SQLite; if a new odometer exceeds profile mileage, update vehicle mileage.
6. Reload state and display result.
7. Owner optionally views timeline/analytics or invokes optional sync.

For reminders, add a branch to create reminder/activity rows and schedule a future notification. For document expiry, add both document and reminder insertion.

### 18.3 Class diagram

Recommended classes and relationships:

- `AutoSphereApp` (root `StatelessWidget`) → `DashboardScreen`.
- `DashboardScreen` → `AppState` through Provider and feature tabs.
- `AppState extends ChangeNotifier` owns loaded vehicle/activity/document/reminder state and coordinates SQLite, `Api`, and notification actions.
- `Api` offers static HTTP operations and produces `ApiException`.
- `ReminderNotifications` wraps `FlutterLocalNotificationsPlugin`.
- Persistent entities are represented by `Map<String, dynamic>` values, not dedicated Dart model classes: `Vehicle`, `Activity`, `Document`, `Reminder`, and `AppSetting`.
- `Vehicle 1 — 0..* Activity`, `Vehicle 1 — 0..* Document`, `Vehicle 1 — 0..* Reminder` through foreign keys.
- `Document` expiry can cause creation of a reminder; document-added/reminder-created actions also create activity rows.

The `Vehicle`, `Activity`, etc. names in this diagram are conceptual database records, not source-defined Dart classes.

### 18.4 Sequence diagram

Recommended sequence: **optional service synchronization**.

`Owner → DashboardScreen: tap Sync` → `DashboardScreen → AppState.syncWithCloud()` → `AppState → SQLite: read saved backend user ID` → `Api → Backend: GET existing user or POST generated user` → `AppState → Api: create missing remote vehicles` → `AppState → SQLite: save remote vehicle IDs` → `AppState → SQLite: query unlinked service rows` → `AppState → Api: POST each service` → `SQLite: save remote service IDs` → `Api → Backend: GET maintenance list and prediction` → `AppState: set message/prediction and notifyListeners` → `DashboardScreen: render result`. On API errors, the prediction is cleared and a sync-unavailable message is shown.

## 19. Database Design and Schema

Database file: `autosphere.db` in the path returned by `getDatabasesPath()`. Schema version: **4**. Foreign keys are enabled at connection configuration.

| Table | Field | SQLite type | Constraints / purpose |
|---|---|---|---|
| `vehicles` | `id` | INTEGER | Primary key, autoincrement. |
|  | `nickname` | TEXT | NOT NULL. |
|  | `make`, `model` | TEXT | NOT NULL. |
|  | `year` | INTEGER | Nullable. |
|  | `fuel_type`, `registration` | TEXT | Nullable. |
|  | `odometer` | INTEGER | NOT NULL, default 0. |
|  | `service_interval` | INTEGER | NOT NULL, default 5000. |
|  | `photo` | BLOB | Nullable vehicle image bytes. |
|  | `backend_id` | TEXT | Nullable remote vehicle identifier. |
| `activities` | `id` | INTEGER | Primary key, autoincrement. |
|  | `vehicle_id` | INTEGER | NOT NULL; foreign key to `vehicles.id`, `ON DELETE CASCADE`. |
|  | `date`, `type`, `title` | TEXT | All NOT NULL. Date strings are ISO-like values supplied by the UI/seed. |
|  | `cost` | REAL | NOT NULL, default 0. |
|  | `category` | TEXT | Nullable spending grouping. |
|  | `odometer` | INTEGER | Nullable. |
|  | `quantity` | REAL | Nullable; used for fuel quantity. |
|  | `service_center`, `details` | TEXT | Nullable. |
|  | `backend_id` | TEXT | Nullable remote service identifier. |
| `documents` | `id` | INTEGER | Primary key, autoincrement. |
|  | `vehicle_id` | INTEGER | NOT NULL; foreign key to `vehicles.id`, `ON DELETE CASCADE`. |
|  | `title`, `document_type`, `file_name` | TEXT | NOT NULL. |
|  | `mime_type` | TEXT | Nullable. |
|  | `data` | BLOB | NOT NULL document contents. |
|  | `expires_on` | TEXT | Nullable due date. |
|  | `created_at` | TEXT | NOT NULL creation timestamp. |
| `reminders` | `id` | INTEGER | Primary key, autoincrement. |
|  | `vehicle_id` | INTEGER | NOT NULL; foreign key to `vehicles.id`, `ON DELETE CASCADE`. |
|  | `title`, `reminder_type`, `due_date` | TEXT | NOT NULL. |
|  | `notes` | TEXT | Nullable. |
| `app_settings` | `setting_key` | TEXT | Primary key. |
|  | `setting_value` | TEXT | NOT NULL; currently stores `backend_user_id`. |

### 19.1 Relationships and constraints

- One vehicle can own zero or more activities, documents, and reminders.
- Each activity, document, and reminder references one vehicle.
- Deleting a vehicle cascades through those child records.
- A document expiry is represented as a separate reminder row; there is no explicit document-to-reminder foreign key.
- No secondary indexes or unique constraints beyond primary keys are created in the shown schema.
- The database uses explicit migrations up to version 4. The actual contents of pre-v2 databases are handled partly by migration logic that refers to an earlier `maintenance` table.

### 19.2 Data retention and local security

The source stores document and photo bytes in SQLite BLOB columns. No encryption layer, biometric gate, database passphrase, or remote backup mechanism is implemented in the visible code. Data-at-rest protection therefore depends on the operating system and deployment configuration, which are not specified here.

## 20. Implementation Details

1. **Startup:** `WidgetsFlutterBinding.ensureInitialized()` is called; the status bar is made transparent; an `AppState` is provided to the app. Database and notification initialization run concurrently, followed by scheduling loaded reminders.
2. **Theme:** dark Material 3 theme with navy/charcoal surfaces, blue primary accent, aqua secondary accent, and `Avenir Next` font-family request.
3. **Navigation:** a bottom `NavigationBar` switches among four tabs using local selected-index state and animated page transitions.
4. **Persistence:** `openDatabase` opens `autosphere.db`, enables foreign keys and applies schema creation/upgrade. Lists are loaded into `AppState`.
5. **UI updates:** screens use `context.watch<AppState>()` to rebuild from state and `context.read<AppState>()` for actions.
6. **Date handling:** stored date values are strings parsed with `DateTime.tryParse`; displayed labels use abbreviated month names. Activity form dates include current local hour/minute; reminder/document expiry values are date-only.
7. **Document size protection:** selected document bytes are streamed into a builder and size-checked before inserting in SQLite.
8. **HTTP:** API payloads are JSON with a `Content-Type: application/json` header for POST; API response status and shape are checked in the client.
9. **Schema migrations:** `onUpgrade` handles old versions and adds service interval in version 4 if absent.
10. **Not implemented as separate layers:** no dedicated data-transfer objects, typed DB models, repository interfaces, service locator, or separate domain package are present.

## 21. Algorithms and Logic Used

### 21.1 Service interval estimate

For interval `I` (positive, default 5,000 km), current odometer `M`, and most recent service odometer `S`:

- Baseline = `S` when present; otherwise `M - (M mod I)`.
- Distance since service = `max(M - baseline, 0)`.
- Progress through interval = `(distance since service mod I) / I`.
- Remaining distance = `I - (distance since service mod I)`.
- Displayed next service odometer = `M + remaining distance`.

This is a simple distance-based estimate. It is not a prediction model and does not consider time, vehicle make, or manufacturer service schedules. The `lastServiceMileage` getter uses the first service record from the current date-descending list.

### 21.2 Fuel efficiency

For adjacent fuel entries ordered by odometer:

`efficiency (km/L) = (current odometer − previous odometer) / current entry quantity in litres`

Rows with non-increasing distance or non-positive quantity are skipped. This is an approximate full-interval method; the code does not model partial fills, fuel tank capacity, or reset events.

### 21.3 Service-cycle distance

For adjacent service records sorted by odometer:

`service cycle (km) = current service odometer − previous service odometer`

Only positive differences are charted.

### 21.4 Spending aggregation

- Overall sum: add `cost` from all activity rows.
- Monthly sum: include rows whose parsed year and month match one of the six calendar months from the current month backwards.
- Category total: include only positive costs, grouped by `category` (missing category maps to `Other`).
- Currency formatting rounds to a whole rupee and inserts comma grouping; no locale-aware formatting library is used.

### 21.5 Cloud-sync idempotency

`backend_id` columns identify vehicles and service activities already linked to remote objects. Sync uploads local service activity rows only when `backend_id IS NULL`, then saves the returned ID. This is a basic retry-avoidance mechanism, not transactional or conflict-resolving two-way synchronization.

## 22. UI Design and Screen Descriptions

| Screen / UI state | Description and feature evidence |
|---|---|
| Garage dashboard | Vehicle card, mileage/service indicator, optional multi-vehicle selector, quick actions, spend/service statistics, renewal panel, optional forecast, maintenance spend and recent activity. |
| Add/Edit Vehicle dialog | Profile fields, fuel dropdown, image selection and validation. |
| Service Interval dialog | Positive integer interval editing and derived next service mileage. |
| Add Maintenance Record dialog | Simple service title, optional cost and past service date. |
| Activity type bottom sheet | Offers Fuel fill, Service visit, Expense, and Reminder. |
| Fuel form | Station/description, total cost, litres, odometer, date, optional notes. |
| Service form | Description, optional cost, odometer, service center, category, date and notes. |
| Expense form | Description, required cost, optional odometer, category, date and notes. |
| Timeline tab | All-vehicle activity feed with six type filters and swipe-to-delete entries. |
| Analytics tab | Total cost/vehicles/current odometer, fuel-efficiency and service-cycle charts, six-month spend bars, category totals. |
| Document Vault tab | On-device document metadata list; add/import, details, export, and delete actions. |
| Save Document dialog | Name, type and optional expiry date. |
| Reminder dialog | Name, type, due date and optional notes. |
| Loading state | Centered progress indicator while `AppState.isLoading` is true. |
| Empty states | Timeline, document vault, fuel-efficiency chart, maintenance-cycle chart, and no-service-record views. |

The visual theme is dark with a fixed set of brand colors. There are no separate XML layout files because the application UI is composed in Flutter/Dart widgets.

## 23. Navigation Flow

```text
Application launch
  └── Database/notification initialization
      └── Garage dashboard
          ├── Add/Edit vehicle dialog
          ├── Set service interval dialog
          ├── Quick action: Fuel / Service / Expense / Reminder
          ├── Add record (maintenance) dialog
          └── Bottom navigation
              ├── Garage
              ├── Timeline → filters → activity entry/delete
              ├── Analytics → charts and summaries
              └── Documents → import → metadata/expiry → details/export/delete
```

The tabs are switched within the root dashboard; the visible code does not define a separate named-route system.

## 24. Testing Strategy

### 24.1 Existing automated checks

- `test/api_test.dart` uses `MockClient` to inspect outgoing vehicle and maintenance requests. It does not contact a real server.
- `test/widget_test.dart` uses a test-specific `AppState` and fake record data to exercise dashboard rendering, selected-tab behavior, forms, validation, service interval setting, fuel activity entry, and the vehicle cap.
- Native iOS and macOS `RunnerTests.swift` files contain template example tests, not meaningful application tests.
- No tests are present for database migrations/integration, notification delivery, actual image/file picker behavior, live backend sync/prediction, or platform release builds.

### 24.2 Execution result observed during this analysis

`flutter test` completed successfully: **9 tests passed** (1 API client test and 8 widget tests). This result applies to the test suite as executed in the current workspace environment and does not establish device-level acceptance or a live-backend result.

### 24.3 Recommended additional verification

Test database creation/upgrades and cascade deletion on each supported platform; validate document size boundary and empty files; test date/time-zone and notification permission behavior on physical Android/iOS devices; test API unavailable/timeout/404/retry cases against a staging backend; and build/run platform targets that the project intends to support.

## 25. Test Cases

### 25.1 Automated tests with verifiable actual results

| ID | Test scenario | Expected result | Actual result |
|---|---|---|---|
| T-01 | API client creates vehicle and maintenance with schema-compatible fields | Correct paths and JSON field names/values are sent. | **Passed** in mocked HTTP test. |
| T-02 | Attempt to add fourth vehicle | `addVehicle` rejects before inserting; throws state error. | **Passed** in widget/state test. |
| T-03 | Render dashboard with a vehicle and sample history | Garage identity, cost summary, count, and formatted maintenance date appear. | **Passed** in widget test. |
| T-04 | Change service interval to zero | Validation message indicates value must be greater than zero. | **Passed** in widget test. |
| T-05 | Change interval to 7,500 km | New interval and next service odometer are displayed. | **Passed** in widget test. |
| T-06 | Submit maintenance form with blank description | Form displays “Enter a description” and does not submit. | **Passed** in widget test. |
| T-07 | Navigate to Timeline, Analytics, and Documents | Each tab renders its expected heading/content. | **Passed** in widget test. |
| T-08 | Switch feature tabs | Only the selected tab's content is built/displayed. | **Passed** in widget test. |
| T-09 | Submit empty fuel form | Required-field validation is shown for four required entries. | **Passed** in widget test. |
| T-10 | Reach vehicle limit and tap add control | Add-vehicle affordance is disabled and `canAddVehicle` is false. | **Passed** in widget test. |

### 25.2 Recommended manual/integration tests (not executed here)

| ID | Scenario / input | Expected result | Actual result |
|---|---|---|---|
| M-01 | Create a new profile, close/relaunch app | Profile and selected data persist in SQLite. | **Not run; requires app/device runtime.** |
| M-02 | Add fuel entries with increasing odometers and valid litres | Fuel efficiency trend and units match the implemented km/L formula. | **Not run; requires populated runtime database.** |
| M-03 | Add two or more service rows with odometers | Service-cycle chart shows positive odometer differences. | **Not run.** |
| M-04 | Import a document under 20 MiB with and without expiry | Document appears; expiry case creates a reminder and schedules where permitted. | **Not run; requires file picker and OS notification integration.** |
| M-05 | Import empty or >20 MiB document | User receives an error and no document is stored. | **Not run.** |
| M-06 | Export then delete a saved document | Exported bytes match the source; deletion removes the document row. | **Not run.** |
| M-07 | Save a future reminder and inspect at due time | Notification is scheduled at 09:00 local time and delivered according to OS policy. | **Not run; requires device notification permission.** |
| M-08 | Delete a vehicle with dependent records | Activity/document/reminder rows cascade and related scheduled notices are cancelled by UI flow. | **Not run; database integration test needed.** |
| M-09 | Configure a reachable staging API and sync | User/vehicles/services are created once and prediction appears for selected vehicle. | **Not run; backend source and endpoint are unavailable here.** |

## 26. Expected and Actual Results

### 26.1 Verified results

The only measured execution result available from this analysis is the automated `flutter test` run: all nine tests passed. Those tests establish the assertions listed in Section 25.1 only.

### 26.2 Results that cannot be claimed

- No screenshots or on-device interaction recording were present in the workspace.
- No API server was run or contacted; cloud sync and prediction responses are not verified.
- No notification was observed on a physical device.
- No release build, app-store deployment, performance benchmark, battery test, or user acceptance study was performed in this analysis.
- Database persistence across an actual app restart was not covered by the widget suite.

## 27. Results and Discussion

The source implements an end-to-end local data workflow spanning vehicle profiles, activity records, reminders, document bytes, and derived dashboard/analytics views. The local schema and UI make offline entry and review the primary design. The included test suite gives positive but narrow evidence for core widget paths and the request payload contract.

The code also establishes meaningful scope boundaries: the backend is optional; only selected vehicle/service information is synchronized; fuel, expenses, documents, and reminders remain local; and charts are derived from locally recorded data. Service interval display is a deterministic distance formula, while the separate forecast card depends on an external API response. It is therefore inaccurate to describe both as an AI or predictive model without inspecting the server implementation.

An academic results chapter should supplement this source-level analysis with device screenshots, a test environment description, actual manual/integration results, and—if the project claims usability or performance benefits—measured evaluation data.

## 28. Advantages

- Core workflows are designed around local SQLite storage and do not inherently require a live cloud service.
- Vehicle records and activities are centralized in one interface.
- A database foreign-key relationship and cascading deletion maintain vehicle-child record ownership.
- Forms provide field validation, and document import has a 20 MiB size guard.
- The maximum garage size is checked both in UI/state and within a database transaction.
- Timeline and analytics offer cross-record review and summaries.
- Reminder dates can be associated with notifications, and the notification helper handles time zones when available.
- API requests use a timeout, JSON parsing, status checks, and typed `ApiException` reporting.

## 29. Limitations

- The three-vehicle maximum is fixed in source.
- No login/sign-in interface or user identity management exists; cloud user creation is automatic.
- No two-way sync, deletion propagation, update API, conflict handling, or remote sync for most data types is implemented.
- Backend implementation and API contract documentation are absent from this workspace.
- Default API endpoints use plain HTTP loopback addresses; a production HTTPS deployment is not demonstrated.
- Documents/photos are stored as raw local BLOBs; no app-level encryption or backup is implemented.
- A stored document can be exported but is not previewed in-app.
- Deleting a document leaves its generated reminder and activity history in place.
- Fuel efficiency is based on adjacent odometer readings and current-entry litres, which may be inaccurate for partial fills or irregular logging.
- Service interval display is distance-only and does not use a manufacturer specification or time-based interval.
- Notification initialization catches failures without exposing a UI error; permission behavior is platform-dependent.
- Startup database failure is not surfaced as a dedicated error state.
- No automated tests cover SQLite integration, real notifications, native pickers, or live backend behavior.
- Android application ID/namespace is `com.example.autosphere`; iOS Xcode project settings show `com.sudarshan.autosphere` in Runner configurations, while README describes a placeholder identifier. Platform identifiers must be checked and deliberately finalized before distribution.
- Flutter runner scaffolds exist for web, Windows, and Linux, but app-level database/plugin support is not demonstrated uniformly. Generated Linux/Windows plugin registrants do not show the same database integration visible in Android/iOS/macOS registrants; web has no demonstrated SQLite persistence implementation.
- No named-device hardware requirements, measured resource usage, or cross-platform compatibility matrix is provided.

## 30. Future Enhancements

The following are proposals, **not implemented features**:

1. Add typed data models and a repository/service boundary between UI, persistence, and networking.
2. Add database integration/migration tests and stronger initialization error handling.
3. Add document preview and richer metadata/search; define cleanup behavior for expiry reminders when documents are deleted.
4. Add activity editing and explicit reminder/document association.
5. Add configurable service rules that can account for date as well as odometer, with manufacturer-specific schedules entered or verified by the user.
6. Improve fuel-economy calculations for partial-fill and tank-full workflows and explain the assumptions in the interface.
7. Implement secure account setup, backend authentication, HTTPS production configuration, sync conflict handling, and remote update/delete operations if cloud sync is a requirement.
8. Decide and test the supported platform matrix; implement suitable storage on web/Windows/Linux or explicitly constrain distribution to supported mobile targets.
9. Add integration tests for local storage, document limits, notifications, API failure paths, and platform permission flows.
10. Conduct usability testing and gather evidence before making claims about user benefit.

## 31. Conclusion

AutoSphere is a Flutter vehicle-management application with a local SQLite foundation and a multi-tab interface for garage records, activity history, analytics, documents, and reminders. The source demonstrates operational UI flows and a limited optional REST integration for vehicle/service history and remote maintenance prediction. The automated test suite executed during this analysis passed nine tests, although those tests do not verify native integrations or a live backend.

The most important qualifications for a final academic submission are to describe cloud integration as partial and optional, distinguish the deterministic odometer interval estimate from a backend prediction, identify seeded demonstration data, verify platform support and application identifiers, and report only test results actually obtained on the stated environment.

## 32. References

The following are genuine technology/package documentation sources relevant to technologies declared or used by the project. They are references, not evidence that every platform capability was tested.

1. Flutter documentation, [Flutter](https://docs.flutter.dev/).
2. Dart documentation, [Dart](https://dart.dev/guides).
3. Flutter package, [`provider`](https://pub.dev/packages/provider).
4. Flutter package, [`sqflite`](https://pub.dev/packages/sqflite).
5. Flutter package, [`http`](https://pub.dev/packages/http).
6. Flutter package, [`fl_chart`](https://pub.dev/packages/fl_chart).
7. Flutter package, [`image_picker`](https://pub.dev/packages/image_picker).
8. Flutter package, [`file_picker`](https://pub.dev/packages/file_picker).
9. Flutter package, [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications).
10. Flutter package, [`timezone`](https://pub.dev/packages/timezone).
11. Flutter package, [`flutter_timezone`](https://pub.dev/packages/flutter_timezone).
12. Android Developers, [Request runtime permissions](https://developer.android.com/training/permissions/requesting).
13. FastAPI documentation, [FastAPI](https://fastapi.tiangolo.com/) — relevant only because the README describes a linked FastAPI backend; backend source is not included here.

---

# End Matter

## A. Complete Inventory of Relevant Project Files

The following inventory covers the application source, declared tests, project metadata, platform runner/configuration files, and bundled platform branding assets discovered during the workspace scan. Binary files are listed by name/group; generated registrants and machine-generated Flutter build products are identified separately. `build/`, `.dart_tool/`, `.venv/`, and platform `ephemeral/` outputs are build/cache or local-environment artifacts rather than application source and are not expanded here.

### A.1 Root project files

- `.gitignore`
- `.metadata`
- `README.md`
- `analysis_options.yaml`
- `autosphere.iml`
- `pubspec.yaml`
- `pubspec.lock`

### A.2 Dart application source

- `lib/main.dart`
- `lib/api.dart`
- `lib/state.dart`
- `lib/screens.dart`
- `lib/feature_screens.dart`
- `lib/reminder_notifications.dart`

### A.3 Automated tests

- `test/api_test.dart`
- `test/widget_test.dart`
- `ios/RunnerTests/RunnerTests.swift` (template test)
- `macos/RunnerTests/RunnerTests.swift` (template test)

### A.4 Android project

- `android/.gitignore`
- `android/autosphere_android.iml`
- `android/build.gradle.kts`
- `android/gradle.properties`
- `android/gradlew`
- `android/gradlew.bat`
- `android/gradle/wrapper/gradle-wrapper.jar`
- `android/gradle/wrapper/gradle-wrapper.properties`
- `android/local.properties` (machine-local SDK path/configuration; values not reproduced)
- `android/settings.gradle.kts`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/debug/AndroidManifest.xml`
- `android/app/src/profile/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/autosphere/MainActivity.kt`
- `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` (generated)
- `android/app/src/main/res/xml/network_security_config.xml`
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-v21/launch_background.xml`
- `android/app/src/main/res/values/styles.xml`
- `android/app/src/main/res/values-night/styles.xml`
- Launcher icon assets: `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`

### A.5 iOS project and assets

- `ios/.gitignore`
- `ios/Flutter/AppFrameworkInfo.plist`
- `ios/Flutter/Debug.xcconfig`
- `ios/Flutter/Generated.xcconfig` (generated)
- `ios/Flutter/Release.xcconfig`
- `ios/Flutter/flutter_export_environment.sh` (generated/local)
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/SceneDelegate.swift`
- `ios/Runner/Info.plist`
- `ios/Runner/Runner-Bridging-Header.h`
- `ios/Runner/GeneratedPluginRegistrant.h` and `ios/Runner/GeneratedPluginRegistrant.m` (generated)
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- `ios/Runner/Base.lproj/Main.storyboard`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`
- App icon PNGs in that app-icon set: `Icon-App-20x20@1x.png`, `Icon-App-20x20@2x.png`, `Icon-App-20x20@3x.png`, `Icon-App-29x29@1x.png`, `Icon-App-29x29@2x.png`, `Icon-App-29x29@3x.png`, `Icon-App-40x40@1x.png`, `Icon-App-40x40@2x.png`, `Icon-App-40x40@3x.png`, `Icon-App-60x60@2x.png`, `Icon-App-60x60@3x.png`, `Icon-App-76x76@1x.png`, `Icon-App-76x76@2x.png`, `Icon-App-83.5x83.5@2x.png`, `Icon-App-1024x1024@1x.png`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json`
- Launch images: `LaunchImage.png`, `LaunchImage@2x.png`, `LaunchImage@3x.png`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata`
- `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`
- `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings`
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`
- `ios/Runner.xcworkspace/contents.xcworkspacedata`
- `ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`
- `ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings`

### A.6 macOS project and assets

- `macos/.gitignore`
- `macos/Flutter/Flutter-Debug.xcconfig`
- `macos/Flutter/Flutter-Release.xcconfig`
- `macos/Flutter/GeneratedPluginRegistrant.swift` (generated)
- `macos/Runner/AppDelegate.swift`
- `macos/Runner/MainFlutterWindow.swift`
- `macos/Runner/Info.plist`
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`
- `macos/Runner/Base.lproj/MainMenu.xib`
- `macos/Runner/Configs/AppInfo.xcconfig`
- `macos/Runner/Configs/Debug.xcconfig`
- `macos/Runner/Configs/Release.xcconfig`
- `macos/Runner/Configs/Warnings.xcconfig`
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`
- macOS icon PNGs in that set: `app_icon_16.png`, `app_icon_32.png`, `app_icon_64.png`, `app_icon_128.png`, `app_icon_256.png`, `app_icon_512.png`, `app_icon_1024.png`
- `macos/Runner.xcodeproj/project.pbxproj`
- `macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`
- `macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`
- `macos/Runner.xcworkspace/contents.xcworkspacedata`
- `macos/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`

### A.7 Web project

- `web/index.html`
- `web/manifest.json`
- `web/favicon.png`
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/icons/Icon-maskable-192.png`
- `web/icons/Icon-maskable-512.png`

### A.8 Linux runner scaffold

- `linux/.gitignore`
- `linux/CMakeLists.txt`
- `linux/flutter/CMakeLists.txt`
- `linux/flutter/generated_plugin_registrant.cc` (generated)
- `linux/flutter/generated_plugin_registrant.h` (generated)
- `linux/flutter/generated_plugins.cmake` (generated)
- `linux/runner/CMakeLists.txt`
- `linux/runner/main.cc`
- `linux/runner/my_application.cc`
- `linux/runner/my_application.h`

### A.9 Windows runner scaffold

- `windows/.gitignore`
- `windows/CMakeLists.txt`
- `windows/flutter/CMakeLists.txt`
- `windows/flutter/generated_plugin_registrant.cc` (generated)
- `windows/flutter/generated_plugin_registrant.h` (generated)
- `windows/flutter/generated_plugins.cmake` (generated)
- `windows/runner/CMakeLists.txt`
- `windows/runner/Runner.rc`
- `windows/runner/flutter_window.cpp`
- `windows/runner/flutter_window.h`
- `windows/runner/main.cpp`
- `windows/runner/resource.h`
- `windows/runner/runner.exe.manifest`
- `windows/runner/utils.cpp`
- `windows/runner/utils.h`
- `windows/runner/win32_window.cpp`
- `windows/runner/win32_window.h`
- `windows/runner/resources/app_icon.ico`

### A.10 Supporting utility

- `tool/generate_ios_brand_assets.swift` (generates iOS icon and launch image assets; it is not part of runtime application logic)

## B. Mapping of Report Sections to Supporting Source Files

| Report content | Principal supporting files |
|---|---|
| Project name, abstract, problem domain, scope | `README.md`, `pubspec.yaml`, all `lib/*.dart` |
| Objectives, proposed system and feature list | `lib/screens.dart`, `lib/feature_screens.dart`, `lib/state.dart`, `README.md` |
| Software / technology requirements | `pubspec.yaml`, `pubspec.lock`, `android/app/build.gradle.kts`, `android/settings.gradle.kts`, `ios/Runner.xcodeproj/project.pbxproj`, `macos/Runner.xcodeproj/project.pbxproj` |
| Architecture and data flow | `lib/main.dart`, `lib/state.dart`, `lib/api.dart`, `lib/reminder_notifications.dart`, `lib/screens.dart`, `lib/feature_screens.dart` |
| Modules, functions and screens | `lib/screens.dart`, `lib/feature_screens.dart` |
| Database schema, migrations, seed and CRUD | `lib/state.dart` |
| API routes, payloads, errors, base URL | `lib/api.dart`, `lib/state.dart`, `README.md`, `test/api_test.dart` |
| Reminder scheduling | `lib/reminder_notifications.dart`, `lib/state.dart`, `lib/feature_screens.dart`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` |
| UI theme / app bootstrap | `lib/main.dart`, `lib/screens.dart`, `lib/feature_screens.dart` |
| Permissions and platform configuration | `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/xml/network_security_config.xml`, `ios/Runner/Info.plist`, `macos/Runner/Info.plist`, platform Gradle/Xcode projects |
| Test cases and execution evidence | `test/api_test.dart`, `test/widget_test.dart`, observed `flutter test` execution |
| Platform and branding inventory | `android/`, `ios/`, `macos/`, `web/`, `linux/`, `windows/`, `tool/generate_ios_brand_assets.swift` |

## C. Missing Information to Provide Manually

1. Institution, department, course/semester, academic year, student name(s), roll number(s), guide, and submission date.
2. Confirmation of the final approved project title and any required institutional report template.
3. Intended deployment platforms and tested device models/OS versions.
4. Real hardware and development-machine configuration used for validation.
5. Backend repository/API documentation, deployed URL, authentication/security design, database schema, and prediction algorithm if those are to be described.
6. Real-device results for notification permission and delivery, persistence, file import/export, and supported-platform builds.
7. Actual screenshots captured from the running app and any manually executed test results.
8. Budget, schedule, user survey, comparative study, or evaluation data if required by the academic format.
9. Confirmation whether the demo seed vehicle/records should remain in the submitted application/report.
10. Final Android/iOS/macOS bundle identifiers and signing/distribution configuration.

## D. Suggested Screenshots Checklist

No screenshots were found or generated during source analysis. Capture these from a running build; redact personal information and use non-sensitive sample data.

- [ ] Garage dashboard at launch, showing vehicle profile, odometer/service indicator, stats, forecast card, and recent activity.
- [ ] Add vehicle form with representative profile details and image selected.
- [ ] Vehicle selector showing at least two vehicles and the three-vehicle cap behavior (optional).
- [ ] Set service interval dialog and resulting next-service display.
- [ ] Fuel entry form and saved fuel activity.
- [ ] Service entry form with odometer/service center and saved timeline entry.
- [ ] Expense form and a representative saved expense.
- [ ] Timeline with All filter and at least one entry from multiple vehicles.
- [ ] Timeline filter state (for example Fuel or Documents).
- [ ] Analytics screen showing fuel efficiency, maintenance cycles, monthly spending, and spending categories using sufficient sample records.
- [ ] Document Vault with a saved document, type, size, and expiry (use a fictitious file).
- [ ] Document details and export action, if the platform permits.
- [ ] Reminder form and dashboard due-date panel.
- [ ] OS notification as delivered on a test device, only if actually observed.
- [ ] Cloud sync success/failure and prediction response, only against a documented test backend and with non-sensitive sample data.
- [ ] Empty states (timeline, vault, analytics) if the report explains them.

## E. Questions to Answer Before Finalizing the Academic Report

1. What are the required institution, author, supervisor, and submission details?
2. Is the academic project intended to be Android-only, Android/iOS, or genuinely cross-platform?
3. Was a real backend developed separately? If so, where is its source/API schema and what prediction logic does it use?
4. Which platform/device builds and real-world flows were actually tested, and what were the observed outcomes?
5. Are the demo seed records intentional report examples or should they be distinguished from test data?
6. Should the report describe the API sync as a prototype capability or as an operational deployed feature?
7. What citation style, page/word limits, and institutional diagram conventions must the final submission follow?

# AutoSphere

AutoSphere is an offline-first Flutter app for organizing vehicle ownership in one place.

## Features

- Manage up to three vehicles with nicknames, registration details, fuel type, odometer, and photos.
- Keep a chronological timeline of fuel fills, services, expenses, documents, and reminders.
- Track fuel quantity, cost, and odometer readings; review fuel efficiency and set a service interval for each vehicle.
- Store registration, insurance, PUC, warranty, and service documents on-device, with optional expiry reminders.
- Review monthly spending, category totals, and total costs across the garage.
- Receive local notifications for saved renewal and maintenance dates.

Vehicle profiles, activity, documents, and reminders are stored in a local SQLite database. Photo and document contents remain on-device. Cloud sync is optional and is not required for the core workflows.

## Run

```sh
flutter pub get
flutter run
```

Run the widget tests with:

```sh
flutter test
```

## iOS Expo Build

The unsigned device build is produced with:

```sh
flutter build ios --release --no-codesign
```

For an installable IPA or TestFlight upload, open `ios/Runner.xcworkspace` in Xcode, set a unique bundle identifier in the Runner target, and select your Apple Development/Distribution Team under **Signing & Capabilities**. Then run:

```sh
flutter build ipa --release
```

The current project uses the placeholder identifier `com.example.autosphere`; replace it with an identifier registered to your Apple Developer account before distribution. The unsigned app bundle is written to `build/ios/iphoneos/Runner.app`.

## FastAPI Backend

Run the linked backend from its repository root with `uvicorn main:app --reload --host 0.0.0.0 --port 8000`. The app defaults to `127.0.0.1:8000` on Apple platforms and `10.0.2.2:8000` on the Android emulator. Set another endpoint with `--dart-define=AUTOSPHERE_API_BASE_URL=https://your-api-host` for a deployed or physical-device backend.

Cloud sync creates one backend user for this installation, registers each local vehicle once, uploads service history, and retrieves the selected vehicle's maintenance prediction. The current backend has no update/delete endpoints and no APIs for fuel, expenses, documents, or reminders; those remain local in SQLite.
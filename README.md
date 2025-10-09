
# Mictlan Client Prototype (Flutter)

Prototype app for citizens (clients) to:
- Report a problem from a Google Map with a bento menu of incident types.
- Consult a report by folio without login.
- Each installation auto-generates a device identity and optionally creates a backend user.

## Stack
- UI kit: Flutter Material 3 components with custom theme controller.
- Maps: `google_maps_flutter`
- Secure identity: `flutter_secure_storage` + `uuid` + `device_info_plus`
- HTTP: `http`

## Setup
1. **Flutter SDK**: 3.22+ recommended.
2. **Google Maps keys**:
   - Android: define `MAPS_API_KEY` in `android/local.properties` or export it in your shell before running Gradle/Flutter. The
     client detecta en tiempo de ejecución si la clave falta y mostrará instrucciones en pantalla.
   - iOS: add to `ios/Runner/AppDelegate.swift` or `AppDelegate.m` following the plugin readme.
3. **Backend base URL**: set in `lib/config.dart`.
4. Bootstrap the Android Gradle wrapper (only needed once per clone):
   ```bash
   dart run tool/setup_gradle_wrapper.dart
   ```
5. Run:
   ```bash
   flutter pub get
   flutter run
   ```
6. If Gradle reports a stale `journal-1.lock`, run the cleaner:
   ```bash
   dart run tool/gradle_lock_cleaner.dart
   ```
   The tool now auto-detects the standard Gradle cache path. Use `--lock` to point at a custom location if needed.

## Endpoints expected
- `GET /api/v1/catalog/incident-types`
- `POST /api/v1/reports` body: `{ type, message, lat, lng, client_id }`
- `GET /api/v1/folios/{folio}`

Adjust in `services/api.dart` as needed for your Go repo.

## Notes
- Offline-capable identity stored in secure storage under key `mictlan_identity`.
- Theme supports light/dark and color schemes.
- This is a prototype. Add error handling, retries, and auth hardening before prod.

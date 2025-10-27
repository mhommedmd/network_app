# GitHub Copilot Instructions

## Big-picture architecture
- Flutter app serving two personas (network owner vs POS vendor) with Yemen-specific UX; see `lib/features/**` for feature-scoped presentation code and `core/` for cross-cutting services.
- `core/providers/auth_provider.dart` centralizes Firebase Auth + Firestore integration, converts Yemeni phone numbers to synthetic emails (`<digits>@networkapp.app`), and persists enriched user profiles in `users` documents.
- Navigation flows are defined via `GoRouter` in `lib/core/router/app_router.dart` with guard redirects (unauthenticated users forced to `/login`, authenticated users redirected off auth routes).
- App-wide localization, theming, and responsive scaling live under `core/localization`, `core/theme`, and `flutter_screenutil` setup in `main.dart`.

## Key patterns to follow
- Use the existing Provider setup (`MultiProvider` in `main.dart`) for state; new shared state should extend `ChangeNotifier` and be registered there.
- Forms follow a multi-step pattern similar to `features/auth/presentation/pages/register_page.dart`: local `GlobalKey<FormState>` per step, controller disposal in `dispose()`, and explicit `FocusScope.of(context).unfocus()` before validation.
- UI widgets lean on `shared/widgets/app_button.dart` and `AppTypography`; prefer extending these rather than introducing ad-hoc styling.
- Phone inputs are normalized without leading zero and validated via `_isValidYemeniPhone`; reuse that helper from `AuthProvider` instead of duplicating logic.
- Firestore writes use `SetOptions(merge: true)` and store the same field names (`accountType`, `entityName`, etc.); keep payloads consistent for downstream analytics.
- Registration no longer enforces OTP, but `AuthProvider.resetRegistrationOtpState()` still clears legacy state—call it when altering registration flows to avoid stale data.

## Firebase & platform setup
- `lib/main.dart` initializes Firebase, forces portrait orientation, and activates `FirebaseAppCheck` with the debug provider (`AndroidProvider.debug`/`AppleProvider.debug`). Keep this call early to satisfy App Check before any Auth requests.
- When App Check enforcement blocks local testing, generate a debug token via `firebase appcheck:debug --app <APP_ID>` and add it under Firebase Console → App Check → Debug tokens.
- Package name / applicationId is `com.example.network_app`; ensure any Firebase-side configuration (SHA hashes, App Check settings) uses this value.

## Workflows & commands
- Standard run/build: `flutter pub get`, `flutter run`, `flutter build apk`. No custom scripts currently.
- Tests live in `test/`; run with `flutter test`. Integration with Firebase means many flows require network access and configured App Check.
- L10n: AR/EN strings come from `assets/translations/*.arb`; regenerate via `flutter gen-l10n` (watch `l10n.yaml`).

## Gotchas & conventions
- GoRouter expects `AuthProvider.isAuthenticated` to be up-to-date; always update `_user` and call `notifyListeners()` on auth state changes.
- ScreenUtil is seeded with `designSize: Size(375, 812)`; use `.w/.h/.sp` extensions for sizing to maintain consistency.
- Many widgets assume RTL awareness (text strings in Arabic). When adding English copy, rely on `LanguageProvider` getters to keep automatic switching working.
- Firebase exceptions are surfaced via `authProvider.error` and toasted with `Fluttertoast.showToast`; set `_error` before returning false so UI displays meaningful messages.

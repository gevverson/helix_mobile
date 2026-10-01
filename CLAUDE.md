# CLAUDE.md — helix_mobile

Flutter client for **Helix**, a genetic-compatibility dating app (photos stay blurred until a
mutual, genetically compatible match). Android is the only working target today.

**Sister repo:** the FastAPI backend lives at `../helix-core` (github.com/gevverson/helix-core).
The two ship together — every response is parsed by hand here, so check backend schemas
(`../helix-core/app/schemas.py`) before reading or adding a field. See "Cross-repo contract" below.

## Commands

Flutter SDK is at `~/flutter/bin` and is **not on PATH** — use `~/flutter/bin/flutter` (or
`export PATH=$HOME/flutter/bin:$PATH`).

| Task | Command |
|---|---|
| Analyze | `~/flutter/bin/flutter analyze` (must be clean) |
| Tests | `~/flutter/bin/flutter test` |
| Run (dev, emulator → local backend) | `~/flutter/bin/flutter run --dart-define-from-file=flavors/dev.json` |
| Build check | `~/flutter/bin/flutter build apk --debug --dart-define-from-file=flavors/dev.json` |
| E2E contract test (app services → a running helix-core; creates users — local/dev only) | `~/flutter/bin/flutter test test/e2e --dart-define=HELIX_E2E=true --dart-define=API_BASE_URL=http://localhost:8000` |
| Release + Firebase App Distribution | `./scripts/distribute.sh "release notes"` (needs `flutter` + `firebase` on PATH; see `docs/DISTRIBUTE.md`) |

Config is **compile-time only** via `--dart-define-from-file=flavors/{dev,staging,prod}.json`
(`API_BASE_URL`, `GOOGLE_CLIENT_ID`, `APP_FLAVOR`). Default base URL is `http://10.0.2.2:8000`
(Android emulator → host). Staging and prod both currently point at `https://helix-api-wc16.onrender.com`.

## Layout

- `lib/main.dart` — `Firebase.initializeApp()`, `MultiProvider`, `MaterialApp.router`.
- `lib/config/` — `app_constants.dart` (env values, colours/gradients, disclaimer text, prefs keys), `app_theme.dart`.
- `lib/services/` — static-method service classes (`AuthService`, `ProfileService`, `DatingService`,
  `PushService`) on top of `ApiClient.instance` (http_interceptor). `api_interceptor.dart` does the
  connectivity check, headers and 401 → `SessionManager`. Retries live in `IdempotentRetryClient`
  (`api_client.dart`): GET/HEAD/PUT/DELETE only — **never retry POST/PATCH** (duplicates messages, likes, sign-ups).
- `lib/providers/` — `ChangeNotifier`s. Only `AuthProvider` is actually used; `Scan/Match/ProfileProvider` are dead.
- `lib/routes/app_router.dart` — go_router; guard only checks a token exists. `MainShell` = PageView with
  4 tabs (Discovery, Matches, Scan, Profile). Chat and Blocked Users are pushed with `Navigator.push`.
- `lib/screens/`, `lib/widgets/` (`GlassCard`, `HelixButton`, `HelixTextField`, `GeneticDisclaimer`, `safety_menu`, ...).
- `lib/models/` — hand-written `fromJson` (`User`, `ScanResult`, `MatchResult`). Newer dating features pass `Map<String, dynamic>`.
- `test/` — `widget_test.dart` (screens + models), `session_manager_test.dart`, `token_store_test.dart`,
  `api_client_test.dart`, and `e2e/api_contract_e2e_test.dart` (opt-in, see Commands).

## Auth & session

- JWT (30 min, no refresh token) lives in `TokenStore` (flutter_secure_storage, in-memory cache). Never put
  tokens in SharedPreferences; `TokenStore` migrates a legacy prefs token on first read.
- `auth_method` pref (`'google'` / `'password'`) records how the session started.
- On a 401 for a request that carried a Bearer token, the interceptor calls
  `SessionManager.onUnauthorized(token)`. It ignores stale 401s (token no longer stored), silently renews
  **only Google sessions** (`signInSilently` + `POST /auth/google`), and otherwise clears the session and
  flips `sessionExpired` (MainShell resets it on mount and navigates to login).
- Logout calls `GoogleSignIn.signOut()`. After account deletion use `logout(unregisterDevice: false)` —
  the token is dead and the backend already erased device tokens.

## Firebase / push — dependency gotcha

Pinned **firebase_core 3.15 / firebase_messaging 15.2.10** on purpose. `firebase_messaging 16.4.x` does
not compile against `firebase_core 4.12` (references the removed `FirebasePlugin` type), and 16.4.3
conflicts with the web packages. Don't bump these without a full `flutter build apk` check.
`firebase_auth` is intentionally **not** a dependency. Android uses the committed `google-services.json`;
there is no `firebase_options.dart` / iOS plist, so iOS won't start.

## Conventions

- Files snake_case (`*_screen.dart`), private state `_XState`.
- Services: static methods, URLs built inline as `Uri.parse('${AppConstants.baseUrl}/api/v1/...')`,
  return `bool` / nullable model / `[]` rather than throwing (exception: `checkMatch` throws).
- Screens: `StatefulWidget` with `_loading`/`_busy` flags; always `if (!mounted) return;` after an `await`.
  Tabs use `AutomaticKeepAliveClientMixin` (call `super.build(context)`).
- Colours/gradients only from `AppConstants` (dark palette). Use `withValues(alpha:)`, not `withOpacity`.
- Section comments `// ── Header ──`. Logging: `debugPrint` inside `if (kDebugMode)` (`avoid_print` is on).
- Feedback via floating SnackBars. Navigation: `context.go(AppRouter.x)` for top-level routes; grab
  `GoRouter.of(context)` before an async logout.
- Genetic results are **educational, not diagnostic** — show `GeneticDisclaimer` wherever a compatibility
  result appears. No GPS: city is user-typed.
- **Never show anything derived from another user's genotype before a mutual match** (no compatibility in
  Discovery — it leaks health data; backend DPIA R9).
- `ProfileService.updateProfile` returns `null` on success or a user-facing error (e.g. the backend's
  30-day genotype-change cooldown) — show it.
- Commits: conventional (`feat(auth): ...`, `fix: ...`, `docs: ...`), one PR per `feat/<name>` branch.

## Cross-repo contract

All calls go to `{API_BASE_URL}/api/v1/...`: `auth/token` (form-encoded `username`/`password`),
`auth/google`, `auth/forgot-password`, `auth/reset-password`, `users`, `users/me`, `users/me/consent`,
`users/me/profile`, `users/me/dating-profile`, `users/me/photos`, `users/me/devices`, `scan-report`,
`check-match`, `discovery`, `likes/{id}`, `matches`, `matches/{id}/messages`, `blocks`, `reports/{id}`.
- Enum values must match backend `Literal`s exactly: genotype `AA|AS|SS|AC|SC`, blood group `A+ … AB-`,
  rhesus `POS|NEG`, gender `male|female|other`, seeking `male|female|everyone`. Omit unset fields — never send `''` or `'Unknown'` (→ 422).
- Errors: read `detail`; it is a string for HTTPException but a **list** for 422 validation errors.
- New endpoint? Merge + deploy the backend PR first, then the mobile PR.

## Known issues (open, as of 2026-10-01)

- Most services still swallow errors (`catch (_) => null/[]/false`), so Discovery/Matches/Blocked show empty states instead of errors; a failed like silently advances the card.
- No consent gate in the router (only the splash checks `needsConsent`; the backend still enforces it).
- iOS won't start: no `firebase_options.dart` / `GoogleService-Info.plist`. `Platform.isAndroid` in `push_service.dart` breaks web.
- Dead code: `ScanProvider`, `MatchProvider`, `ProfileProvider`, `MatchScreen`, `DashboardScreen`, `StatCard`;
  stray `android/app/google-services .json` (with a space); spoofed browser User-Agent in the interceptor.

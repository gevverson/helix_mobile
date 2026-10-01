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
| Release + Firebase App Distribution | `./scripts/distribute.sh "release notes"` (needs `flutter` + `firebase` on PATH; see `docs/DISTRIBUTE.md`) |

Config is **compile-time only** via `--dart-define-from-file=flavors/{dev,staging,prod}.json`
(`API_BASE_URL`, `GOOGLE_CLIENT_ID`, `APP_FLAVOR`). Default base URL is `http://10.0.2.2:8000`
(Android emulator → host). Staging and prod both currently point at `https://helix-api-wc16.onrender.com`.

## Layout

- `lib/main.dart` — `Firebase.initializeApp()`, `MultiProvider`, `MaterialApp.router`.
- `lib/config/` — `app_constants.dart` (env values, colours/gradients, disclaimer text, prefs keys), `app_theme.dart`.
- `lib/services/` — static-method service classes (`AuthService`, `ProfileService`, `DatingService`,
  `PushService`) on top of `ApiClient.instance` (http_interceptor). `api_interceptor.dart` does the
  connectivity check, headers, 401 → `SessionManager`, and the retry policy.
- `lib/providers/` — `ChangeNotifier`s. Only `AuthProvider` is actually used; `Scan/Match/ProfileProvider` are dead.
- `lib/routes/app_router.dart` — go_router; guard only checks a token exists. `MainShell` = PageView with
  4 tabs (Discovery, Matches, Scan, Profile). Chat and Blocked Users are pushed with `Navigator.push`.
- `lib/screens/`, `lib/widgets/` (`GlassCard`, `HelixButton`, `HelixTextField`, `GeneticDisclaimer`, `safety_menu`, ...).
- `lib/models/` — hand-written `fromJson` (`User`, `ScanResult`, `MatchResult`). Newer dating features pass `Map<String, dynamic>`.
- `test/widget_test.dart` — the only test file.

## Auth & session

- JWT (30 min, no refresh token) stored in SharedPreferences key `auth_token`.
- On 401 the interceptor calls `SessionManager.onUnauthorized()`, which tries Google `signInSilently()` +
  `POST /auth/google`; on failure it clears the token and flips the `sessionExpired` notifier that `MainShell` listens to.
- Each service builds its own `Authorization: Bearer` header from prefs.

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
- Commits: conventional (`feat(auth): ...`, `fix: ...`, `docs: ...`), one PR per `feat/<name>` branch.

## Cross-repo contract

All calls go to `{API_BASE_URL}/api/v1/...`: `auth/token` (form-encoded `username`/`password`),
`auth/google`, `auth/forgot-password`, `auth/reset-password`, `users`, `users/me`, `users/me/consent`,
`users/me/profile`, `users/me/dating-profile`, `users/me/photos`, `users/me/devices`, `scan-report`,
`check-match`, `discovery`, `likes/{id}`, `matches`, `matches/{id}/messages`, `blocks`, `reports/{id}`.
- Enum values must match backend `Literal`s exactly: genotype `AA|AS|SS|AC|SC`, blood group `A+ … AB-`,
  rhesus `POS|NEG`, gender `male|female|other`, seeking `male|female|everyone`. Send `null`/omit — never `''` or `'Unknown'` (→ 422).
- Errors: read `detail`; it is a string for HTTPException but a **list** for 422 validation errors.
- New endpoint? Merge + deploy the backend PR first, then the mobile PR.

## Known issues (as of 2026-10-01 review)

- Forgot-password screen displays the backend's `demo_code` (paired with a critical backend bug).
- Any 401 (incl. wrong password on login, or unregistering a device after account deletion) triggers silent
  Google re-auth; logout never calls `GoogleSignIn.signOut()` → can sign in as / re-create a Google account.
  `sessionExpired` is never reset to `false`.
- Profile/scan save sends `''`/`'Unknown'` for unset fields → 422, and the Profile sheet shows no error.
- Retry policy retries non-idempotent POSTs (messages, likes, register) and multipart uploads (always fails on retry).
- Chat poll replaces the list with `[]` on any error; services swallow errors so screens show empty states instead of errors.
- JWT in plaintext SharedPreferences (move to flutter_secure_storage).
- 2 stale widget tests fail (register button is disabled until consents + genotype are set).
- Dead code: `ScanProvider`, `MatchProvider`, `ProfileProvider`, `MatchScreen`, `DashboardScreen`, `StatCard`;
  stray `android/app/google-services .json` (with a space).

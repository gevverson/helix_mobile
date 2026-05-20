# Helix Mobile

Flutter client for the Helix biological compatibility platform. Lets users scan medical reports, manage their health profile, and check genetic compatibility with a partner.

## Features

- **Authentication** — email/password login, Google Sign-In with silent session refresh
- **OCR scan** — upload a medical report image; genotype and blood group are extracted and can be saved to your profile in one tap
- **Compatibility check** — select a partner's genotype and rhesus factor; the app posts to the Helix API and displays a colour-coded result (`safe` / `caution` / `danger`) with per-child risk details
- **Session management** — on 401 the app silently re-authenticates Google users; email/password users are redirected to login with a snackbar
- **Connectivity guard** — every API request checks network state first and surfaces a clear offline message instead of waiting for a TCP timeout
- **Route guards** — go_router redirects unauthenticated users to login and prevents logged-in users from landing on the auth screens

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter / Dart |
| State management | Provider (`AuthProvider`, `ProfileProvider`, `ScanProvider`, `MatchProvider`) |
| Routing | go_router with auth redirect guard |
| HTTP | http_interceptor (shared `ApiClient` singleton with retry + 401 detection) |
| Storage | shared_preferences (JWT token) |
| Auth | google_sign_in + firebase_auth |
| Network detection | connectivity_plus |
| CI config | `analysis_options.yaml` with `avoid_print` |

## Project Structure

```
lib/
  config/           # AppConstants (compile-time env vars), AppTheme
  models/           # User, ScanResult, MatchResult
  providers/        # AuthProvider, ProfileProvider, ScanProvider, MatchProvider
  routes/           # AppRouter (go_router + auth guard)
  screens/          # SplashScreen, LoginScreen, RegisterScreen, MainShell,
  │                 # DashboardScreen, ScanScreen, MatchScreen, ProfileScreen
  services/         # ApiClient, HelixApiInterceptor, AuthService,
  │                 # ProfileService, SessionManager, NetworkGuard
  widgets/          # Shared UI components
flavors/            # dev.json, staging.json, prod.json (dart-define values)
.vscode/
  launch.json       # Pre-configured VS Code run targets for each flavor
test/               # Widget + unit tests
```

## Environment Setup

The app reads all environment-specific values at **compile time** via `--dart-define-from-file`. No runtime config file is needed.

### Flavor files

| File | API target |
|---|---|
| `flavors/dev.json` | `http://10.0.2.2:8000` (Android emulator loopback) |
| `flavors/staging.json` | `https://helix-core-staging.onrender.com` |
| `flavors/prod.json` | `https://helix-core.onrender.com` |

Fill in `GOOGLE_CLIENT_ID` in each file before running.

### Available variables

| Key | Description |
|---|---|
| `API_BASE_URL` | Backend base URL |
| `GOOGLE_CLIENT_ID` | Google OAuth server client ID |
| `APP_FLAVOR` | Active flavor name (`dev` / `staging` / `prod`) |

## Run Locally

```bash
flutter pub get
```

**Android emulator (dev):**

```bash
flutter run --dart-define-from-file=flavors/dev.json
```

**Physical device or staging backend:**

```bash
flutter run --dart-define-from-file=flavors/staging.json
```

VS Code users can use the pre-configured launch targets in `.vscode/launch.json` — select *Helix (dev)*, *Helix (staging)*, or *Helix (prod — profile build)* from the Run and Debug panel.

## Build

```bash
# Android APK
flutter build apk --dart-define-from-file=flavors/prod.json

# Android App Bundle
flutter build appbundle --dart-define-from-file=flavors/prod.json

# iOS
flutter build ipa --dart-define-from-file=flavors/prod.json
```

## Running Tests

```bash
flutter test
```

```bash
flutter analyze
```

## Architecture Notes

### Shared API client

`ApiClient.instance` is an `InterceptedClient` singleton used by both `AuthService` and `ProfileService`. All cross-cutting concerns live in one place:

- **`HelixApiInterceptor`** — checks connectivity before every request; logs request/response in debug mode; fires `SessionManager.onUnauthorized()` on 401
- **`HelixRetryPolicy`** — retries on 5xx up to 3 times; never retries on `NetworkOfflineException` or `SocketException`

### Session management

`SessionManager.onUnauthorized()` is called (fire-and-forget) on every 401:

1. Tries `GoogleSignIn.signInSilently()` to get a fresh ID token
2. If successful, re-authenticates with the backend and saves the new JWT — the user sees nothing
3. If not (email/password user, or Google unavailable), clears the stored token and sets `SessionManager.sessionExpired = true`

`MainShell` listens to `sessionExpired` and navigates to login with a snackbar.

### State management

Each feature area has a dedicated `ChangeNotifier` provider:

| Provider | Responsibilities |
|---|---|
| `AuthProvider` | Login, Google Sign-In, registration, logout |
| `ProfileProvider` | Fetch and cache user profile, update profile |
| `ScanProvider` | OCR upload, file-byte cache for retry, save-to-profile |
| `MatchProvider` | Compatibility check, result state, error handling |

### Scan error recovery

After a successful file pick the bytes are cached in `ScanProvider`. On failure the screen shows two buttons: **Retry Same File** (replays the upload from cache without reopening the picker) and **Choose Different File** (opens the picker again).

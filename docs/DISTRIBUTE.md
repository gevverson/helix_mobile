# Distributing test builds to friends (Firebase App Distribution)

Instead of re-sending APK files, push a new build and your testers get a **phone
notification to update**. Free.

## One-time setup

1. **Tools on PATH.** Flutter and the Firebase CLI must be runnable. On this
   machine they live at:
   ```bash
   export PATH="/home/viper/flutter/bin:$HOME/.local/bin:$PATH"
   ```
   (Add that line to `~/.bashrc` so it sticks. `firebase` is the standalone
   binary at `~/.local/bin/firebase`.)

2. **Log in once** (opens a browser):
   ```bash
   firebase login
   ```

3. **Create the tester group.** Firebase console → your **Helix** project →
   **Release & Monitor → App Distribution → Testers & Groups** → create a group
   named **`testers`** → add your friends' email addresses.
   (First time, App Distribution may ask you to register the Android app — use
   package `com.helix.mobile`; it should already exist from Firebase Auth.)

## Every time you want to ship a build to testers

```bash
./scripts/distribute.sh "Fixed the compatibility bug and added consent"
```

That builds the release APK and uploads it. Your testers get an email/notification;
after they install the **App Tester** app once, future builds just notify them.

## Notes
- The Android app id is baked into the script (`1:270036019497:android:…`).
- To send to a different group: `DISTRIBUTE_GROUP=vips ./scripts/distribute.sh "…"`.
- For the real public launch, the Google Play Store handles auto-updates instead.

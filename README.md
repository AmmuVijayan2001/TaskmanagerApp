# Smart Task Manager

An offline-first Flutter task manager using Firebase Authentication, Cloud Firestore, Riverpod, Dio, Hive, and the Task Manager REST API.

## Features

- Email/password registration, sign-in, persistent session, and sign-out
- Firestore user profile with saved light, dark, or system theme
- Task creation, editing, completion, deletion, search, filters, and sorting
- API pagination and pull-to-refresh
- Hive task cache with offline fallback and automatic refresh on reconnection
- Material 3 UI and error-specific task loading states

## Setup

1. Install Flutter and Android Studio (JDK 17).
2. Create a Firebase project and add the Android application ID from `android/app/build.gradle.kts`.
3. Put `google-services.json` in `android/app/`.
4. Enable **Email/Password** in Firebase Authentication.
5. Create Firestore and publish the rules from the project setup instructions.
6. Run:

```powershell
flutter pub get
flutter run
```

## Architecture

```text
lib/
  core/             errors, networking, presentation theme
  features/
    auth/           Firebase auth and Firestore profile
    tasks/          REST API, Hive cache, Riverpod state, task UI
  app/              application root
```

The UI only renders state and forwards user intent. Repositories own Firebase, API, and cache access; Riverpod controllers own state transitions and optimistic updates.

## API

Base URL: `https://taskmanager.uat-lplusltd.com`

Every task request sends the signed-in Firebase UID as `user_id`.

## Release APK

Create a signing keystore and configure it in `android/key.properties` (do not commit that file), then build:

```powershell
flutter build apk --release
```

The output is `build/app/outputs/flutter-apk/app-release.apk`.

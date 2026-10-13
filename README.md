# ExamArchive — Android App

Native Android companion to [examarchive-v3](https://github.com/Omdas11/examarchive-v3).
Built with **Flutter**, powered by the same **Appwrite** backend as the website —
same accounts, same papers, same syllabus.

## Download

Grab the latest beta APK from [Releases](https://github.com/Omdas11/examarchive-android/releases).
Pick the build for your device (most modern phones: `arm64-v8a`):

| File | Devices |
|------|---------|
| `ExamArchive-v0.1.0-beta-arm64-v8a.apk` | Most Android phones (2017+) |
| `ExamArchive-v0.1.0-beta-armeabi-v7a.apk` | Older 32-bit phones |
| `ExamArchive-v0.1.0-beta-x86_64.apk` | Emulators / x86 devices |

## Features

- **Papers** — browse, search and filter all 615 exam papers by department, year and semester
- **Paper details** — metadata, syllabus units per paper, PDF view and download
- **Syllabus library** — FYUG departmental syllabi with PDF opening
- **Account** — sign up / log in with your ExamArchive account (shared with the website)
- **5 themes** — System, Light, Dark, AMOLED black, Emerald

## Tech

- Flutter + Dart, Material 3
- Appwrite SDK (auth directly against the shared Appwrite project)
- PDF download via the website's JWT-gated `/api/app/*` endpoints

## Build it yourself

```bash
flutter pub get
flutter build apk --release --split-per-abi
```

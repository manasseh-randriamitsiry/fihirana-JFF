# Fihirana — Jesosy Famonjena Fahamarinantsika

An offline-first Android and iOS app for the Fihirana hymnal and the Malagasy
Bible: sing along with audio, follow the reading, highlight and share a passage,
record a song, keep playlists, and get a daily verse. The interface is available
in Malagasy, French and English, and every screen runs on twelve switchable
colour schemes and eight selectable reading fonts, on phones and tablets.

## Requirements

- Flutter 3.44 or newer (the app is built and tested on 3.44.2 stable)
- Dart 3.2 or newer, pulled in by the Flutter SDK
- Android SDK 24+ for an Android build, or Xcode 15+ for iOS
- ~40 MB of bundled assets: the hymnal, the full Malagasy Bible, fonts and animations

## Installation

```bash
git clone https://github.com/manasseh-randriamitsiry/fihirana-JFF.git
cd fihirana-JFF

flutter pub get                       # dependencies
flutter gen-l10n                      # regenerate lib/l10n from the .arb files
flutter pub run build_runner build    # generate the JSON serialisers
flutter run                           # on the connected device or emulator
```

To ship a release build:

```bash
flutter build apk          # Android, build/app/outputs/flutter-apk/app-release.apk
flutter build ios --release
```

Firebase backs sync, sign-in and crash reporting (`cloud_firestore`,
`firebase_auth`, `firebase_crashlytics`). The config files are gitignored: for
Android, place your own `android/app/google-services.json`, and for iOS your own
`ios/Runner/GoogleService-Info.plist`. The app also works with no
Firebase project at all: the hymnal, the Bible and the player are bundled and
run entirely offline.

## Tests

```bash
flutter analyze --no-fatal-infos
flutter test
```

`test/design_goldens_test.dart` renders the screens the design system is judged
on; regenerate them with
`flutter test --update-goldens test/design_goldens_test.dart` after an intended
visual change.

## Project layout

- `lib/features/<feature>/` — one folder per feature: `data`, `domain`, `presentation`
- `lib/core/design_system/` — the tokens (`AppSurfaces`, `AppScale`, `AppTypography`) and the shared components every screen is built from
- `lib/l10n/` — the three translation catalogs
- `assets/` — the hymnal, the Bible corpus, fonts, images and animations

## Open source

This is an open source project: read it, run it, fork it and send changes back.
No LICENSE file has been added to the repository yet, so all rights are
currently reserved by the author — open an issue if you need a licence for your
own use, or a pull request with one you would like to see adopted.

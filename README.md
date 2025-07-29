# Mana Reader

Mana Reader aims to be a lightweight, cross‑platform manga and doujinshi reader built with Flutter. The project provides a simple foundation for organizing and viewing local comic archives.

## Current Features

- **SQLite library**: stores imported books with title, language, tags and last read page.
- **Library screen**: shows all imported books in a grid layout.
- **Cross‑platform boilerplate**: Android project files are present and stubs exist for iOS, Linux, macOS and Windows.

## Requirements

- **Dart**: >=2.17.0 <3.0.0
- **Flutter**: tested with Flutter 3; newer versions in the same major series should work.

## Development Setup

1. [Install Flutter](https://docs.flutter.dev/get-started/install) and verify the
   installation with `flutter doctor`.
2. From the repository root run `flutter pub get` to fetch project
   dependencies.
3. After dependencies are installed you can build or test the project using
   `flutter build` or `flutter test`.

## Running

From the repository root run `flutter run` and select the desired target device.

- **Android**: ensure an emulator or physical device is available.
- **iOS / macOS**: project folders are included but contain only placeholders. Platform support will be added later.
- **Linux / Windows**: similarly include placeholder folders for future desktop support.

Icon images have been removed from version control. During development you can generate them with `flutter create --platforms=<platform>` or tools like `flutter_launcher_icons`. Large binary assets should be stored using Git LFS, which is configured for common image formats in this repository.

## Platform Icons

Platform icon files are not stored in this repository. Generate them locally with `flutter create .` or copy your own icons into the platform asset folders before building. If you wish to keep custom icons under version control, add them via Git LFS so only optimized binaries are tracked.

## Platform Setup

These folders contain only minimal stubs. Generate the full project files with
`flutter create --platforms=<platform> .` if they are missing before adjusting
identifiers or signing settings.

### iOS

- Open `ios/Runner.xcodeproj` in Xcode.
- Update **PRODUCT_BUNDLE_IDENTIFIER** under **Signing & Capabilities**.
- Select your Apple developer team or manually configure provisioning in the same
  tab.
- Build the app with:

```bash
flutter build ios     # debug or profile
flutter build ipa     # release archive
```

### macOS

- Generate the macOS folder if needed and open `macos/Runner.xcodeproj`.
- Change **PRODUCT_BUNDLE_IDENTIFIER** and signing options in Xcode.
- Build with:

```bash
flutter build macos
```

### Linux

- The bundle identifier for Linux is defined as the binary name in
  `linux/CMakeLists.txt`.
- After editing, build the desktop binary with:

```bash
flutter build linux
```

### Windows

- If the Windows folder is not present, run `flutter create --platforms=windows .`.
- Edit `windows/runner/CMakeLists.txt` and `windows/runner/Runner.rc` to adjust
  the executable name and company info.
- Optional code signing can be performed using `signtool` after building.
- Build with:

```bash
flutter build windows
```

## Roadmap

Upcoming features include:

- A dedicated reader UI for viewing pages and tracking progress.
- Metadata plugins to fetch information from sources like online databases.
- File importers for common archive formats.
- Localization so the UI can be translated into multiple languages.

Mana Reader is still in an early stage, but contributions and ideas are welcome!


```bash
flutter run
```

## Running Tests

To run the analyzer and test suite locally:

```bash
flutter analyze
flutter test
```

Make sure you have the Flutter SDK installed and dependencies fetched with `flutter pub get`.

## Continuous Integration

Every pull request runs the workflow in `.github/workflows/ci.yml` which sets up
Flutter, checks code formatting, runs `flutter analyze`, and executes the test
suite. This helps ensure that all contributed code is properly formatted and
tested before merging.


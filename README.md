# Mana Reader

Mana Reader aims to be a lightweight, cross‑platform manga and doujinshi reader built with Flutter. The project provides a simple foundation for organizing and viewing local comic archives.

## Current Features

- **SQLite library**: stores imported books with title, language, tags and last read page.
- **Library screen**: shows all imported books in a grid layout.
- **Cross‑platform boilerplate**: Android project files are present and stubs exist for iOS, Linux, macOS and Windows.

## Requirements

- **Dart**: >=2.17.0 <3.0.0
- **Flutter**: tested with Flutter 3; newer versions in the same major series should work.

## Running

From the repository root run `flutter run` and select the desired target device.

- **Android**: ensure an emulator or physical device is available.
- **iOS / macOS**: project folders are included but contain only placeholders. Platform support will be added later.
- **Linux / Windows**: similarly include placeholder folders for future desktop support.

Icon images have been removed from version control. During development you can generate them with `flutter create --platforms=<platform>` or tools like `flutter_launcher_icons`. Large binary assets should be stored using Git LFS, which is configured for common image formats in this repository.

## Platform Icons

Platform icon files are not stored in this repository. Generate them locally with `flutter create .` or copy your own icons into the platform asset folders before building. If you wish to keep custom icons under version control, add them via Git LFS so only optimized binaries are tracked.

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


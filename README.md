# Mana Reader

Mana Reader aims to be a lightweight, mobile manga and doujinshi reader built with Flutter. Currently the app supports only Android and iOS. The desktop platform folders (Linux, macOS and Windows) have been removed for now but will be reintroduced later.

## Current Features

- **SQLite library**: stores imported books with title, language, tags and last read page.
- **Library screen**: shows all imported books in a grid layout.
- **Mobile boilerplate**: Android and iOS project files are present. Desktop platform folders will return once support for them is reintroduced.

## Requirements

- **Dart**: >=2.17.0 <3.0.0
- **Flutter**: tested with Flutter 3; newer versions in the same major series should work.
- **7-Zip**: required for importing `.cb7`/`.7z` archives. Install `7z` and ensure it is available in your `PATH` (e.g. `sudo apt-get install p7zip-full`).

## Development Setup

1. [Install Flutter](https://docs.flutter.dev/get-started/install) and verify the
   installation with `flutter doctor`.
2. From the repository root run `flutter pub get` to fetch project
   dependencies.
3. After dependencies are installed you can build or test the project using
   `flutter build` or `flutter test`.

## Running

From the repository root run `flutter run` and select an Android emulator, physical device or an iOS simulator/connected device. Desktop platforms are currently unsupported and their folders have been removed; they will be reintroduced in a future release.

Icon images have been removed from version control. During development you can generate them with `flutter create --platforms=<platform>` or tools like `flutter_launcher_icons`. Large binary assets should be stored using Git LFS, which is configured for common image formats in this repository.

## Sample Book

A small three-page dummy book is available at `assets/sample_books/dummy_story.pdf`. Use the app's import feature to load it and verify reading and library management behaviour.

## Platform Icons

Platform icon files are not stored in this repository. Generate them locally with `flutter create .` or copy your own icons into the platform asset folders before building. If you wish to keep custom icons under version control, add them via Git LFS so only optimized binaries are tracked.

## Platform Setup

Only Android and iOS project files are tracked in this repository. If you need to
regenerate them, run `flutter create --platforms=android,ios .` before adjusting
identifiers or signing settings. Desktop platform folders have been removed but
will be reintroduced later; when support returns, they can be recreated with
`flutter create --platforms=linux,macos,windows .`.

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
./tool/test.sh
```

The test script generates `build/test-results/flutter-junit.xml` for reporting.
Install the converter with `dart pub global activate junitreport` if `tojunit` is
not already available in your PATH.

Make sure you have the Flutter SDK installed and dependencies fetched with `flutter pub get`.

## Continuous Integration

Every pull request runs the workflow in `.github/workflows/ci.yml` which sets up
Flutter, checks code formatting, runs `flutter analyze`, and executes the test
suite. This helps ensure that all contributed code is properly formatted and
tested before merging.


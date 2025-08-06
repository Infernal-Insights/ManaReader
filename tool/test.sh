#!/usr/bin/env bash
# Runs Flutter tests with coverage and outputs a JUnit XML report.
set -e
mkdir -p build/test-results
flutter test --coverage --machine | tojunit --output build/test-results/flutter-junit.xml
dart run tool/coverage_check.dart 80

#!/usr/bin/env bash
# Runs Flutter tests and outputs a JUnit XML report.
set -e
mkdir -p build/test-results
flutter test --machine | tojunit --output build/test-results/flutter-junit.xml

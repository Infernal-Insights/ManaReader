// Reader screen tests updated for new architecture.
// Full widget tests require a real database; unit tests cover the logic layers.
import 'package:flutter_test/flutter_test.dart';
import 'package:mana_reader/features/reader/reader_settings.dart';

void main() {
  group('ReaderSettings', () {
    test('defaults to paged LTR', () {
      const s = ReaderSettings();
      expect(s.mode, ReadingMode.paged);
      expect(s.direction, ReadingDirection.ltr);
      expect(s.nightMode, isFalse);
    });

    test('copyWith changes individual fields', () {
      const s = ReaderSettings();
      final rtl = s.copyWith(direction: ReadingDirection.rtl);
      expect(rtl.direction, ReadingDirection.rtl);
      expect(rtl.mode, ReadingMode.paged);
    });

    test('serialises and deserialises', () {
      const s = ReaderSettings(
        direction: ReadingDirection.rtl,
        mode: ReadingMode.vertical,
        nightMode: true,
      );
      final json = s.toJson();
      final restored = ReaderSettings.fromJson(json);
      expect(restored.direction, s.direction);
      expect(restored.mode, s.mode);
      expect(restored.nightMode, s.nightMode);
    });
  });
}

import 'package:flutter/foundation.dart';

enum ReadingDirection { ltr, rtl }
enum ReadingMode { paged, vertical }

/// Per-series reading settings.
@immutable
class ReaderSettings {
  final ReadingDirection direction;
  final ReadingMode mode;
  final double brightness; // 0.0 - 1.0, null = system
  final bool nightMode;

  const ReaderSettings({
    this.direction = ReadingDirection.ltr,
    this.mode = ReadingMode.paged,
    this.brightness = 1.0,
    this.nightMode = false,
  });

  ReaderSettings copyWith({
    ReadingDirection? direction,
    ReadingMode? mode,
    double? brightness,
    bool? nightMode,
  }) {
    return ReaderSettings(
      direction: direction ?? this.direction,
      mode: mode ?? this.mode,
      brightness: brightness ?? this.brightness,
      nightMode: nightMode ?? this.nightMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'direction': direction.name,
        'mode': mode.name,
        'brightness': brightness,
        'nightMode': nightMode,
      };

  factory ReaderSettings.fromJson(Map<String, dynamic> json) {
    return ReaderSettings(
      direction: ReadingDirection.values.byName(
          json['direction'] as String? ?? ReadingDirection.ltr.name),
      mode: ReadingMode.values
          .byName(json['mode'] as String? ?? ReadingMode.paged.name),
      brightness: (json['brightness'] as num?)?.toDouble() ?? 1.0,
      nightMode: json['nightMode'] as bool? ?? false,
    );
  }
}

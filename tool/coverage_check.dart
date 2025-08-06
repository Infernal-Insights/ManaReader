import 'dart:io';

void main(List<String> args) {
  const coveragePath = 'coverage/lcov.info';
  final coverageFile = File(coveragePath);
  if (!coverageFile.existsSync()) {
    stderr.writeln('Coverage file not found at $coveragePath. Run `flutter test --coverage` first.');
    exit(1);
  }

  final lines = coverageFile.readAsLinesSync();
  var totalFound = 0;
  var totalHit = 0;

  for (final line in lines) {
    if (line.startsWith('LF:')) {
      totalFound += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      totalHit += int.parse(line.substring(3));
    }
  }

  final coverage = totalFound == 0 ? 0 : (totalHit / totalFound * 100);
  final threshold = args.isNotEmpty ? double.tryParse(args.first) ?? 80.0 : 80.0;

  if (coverage < threshold) {
    stderr.writeln(
      'Coverage ${coverage.toStringAsFixed(2)}% is below the threshold of ${threshold.toStringAsFixed(2)}%.'
    );
    exit(1);
  } else {
    stdout.writeln(
      'Coverage check passed: ${coverage.toStringAsFixed(2)}% >= ${threshold.toStringAsFixed(2)}%.'
    );
  }
}

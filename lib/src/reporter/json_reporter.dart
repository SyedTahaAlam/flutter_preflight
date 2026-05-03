import 'dart:convert';
import 'dart:io';

import '../models/ci_report.dart';

class JsonReporter {
  /// Write the JSON report to [outputPath], creating parent directories as needed.
  void write(CiReport report, String outputPath) {
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    final encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(report.toJson()));
  }
}

import 'dart:io';

import 'package:test/test.dart';

import 'package:flutter_local_ci/flutter_local_ci.dart';

void main() {
  group('AnalyzeCheck', () {
    late AnalyzeCheck check;

    setUp(() => check = AnalyzeCheck());

    test('has correct name and description', () {
      expect(check.name, equals('Flutter Analyze'));
      expect(check.description, isNotEmpty);
    });

    test('returns skipped when disabled', () async {
      final config = CiConfig(
        checks: ChecksConfig(analyze: AnalyzeConfig(enabled: false)),
      );

      final result = await check.run(
        projectPath: Directory.systemTemp.path,
        config: config,
      );

      expect(result.status, equals(CheckStatus.skipped));
      expect(result.checkName, equals('Flutter Analyze'));
    });

    test('result has expected shape when enabled', () async {
      final config = CiConfig(
        checks: ChecksConfig(analyze: AnalyzeConfig(enabled: true)),
      );

      final result = await check.run(
        projectPath: Directory.systemTemp.path,
        config: config,
      );

      expect(result.checkName, equals('Flutter Analyze'));
      expect(result.duration, isNotNull);
      expect(result.output, isA<String>());
      expect(result.status, anyOf(CheckStatus.passed, CheckStatus.failed));
    });
  });
}

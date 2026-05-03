import 'dart:io';

import 'package:test/test.dart';

import 'package:flutter_local_ci/flutter_local_ci.dart';

void main() {
  group('FormatCheck', () {
    late FormatCheck check;

    setUp(() => check = FormatCheck());

    test('has correct name and description', () {
      expect(check.name, equals('Dart Format'));
      expect(check.description, isNotEmpty);
    });

    test('returns skipped when disabled', () async {
      final config = CiConfig(
        checks: ChecksConfig(format: FormatConfig(enabled: false)),
      );

      final result = await check.run(
        projectPath: Directory.systemTemp.path,
        config: config,
      );

      expect(result.status, equals(CheckStatus.skipped));
      expect(result.checkName, equals('Dart Format'));
    });

    test('result has expected shape when enabled', () async {
      final config = CiConfig(
        checks: ChecksConfig(
          format: FormatConfig(enabled: true, lineLength: 80),
        ),
      );

      final result = await check.run(
        projectPath: Directory.systemTemp.path,
        config: config,
      );

      expect(result.checkName, equals('Dart Format'));
      expect(result.duration, isNotNull);
      expect(
        result.status,
        anyOf(CheckStatus.passed, CheckStatus.failed),
      );
    });
  });
}

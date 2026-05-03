import 'dart:io';

import 'package:test/test.dart';

import 'package:flutter_local_ci/flutter_local_ci.dart';

void main() {
  group('TestCheck', () {
    late TestCheck check;

    setUp(() => check = TestCheck());

    test('has correct name and description', () {
      expect(check.name, equals('Flutter Test'));
      expect(check.description, isNotEmpty);
    });

    test('returns skipped when disabled', () async {
      final config = CiConfig(
        checks: ChecksConfig(test: TestConfig(enabled: false)),
      );

      final result = await check.run(
        projectPath: Directory.systemTemp.path,
        config: config,
      );

      expect(result.status, equals(CheckStatus.skipped));
      expect(result.checkName, equals('Flutter Test'));
    });

    test('result has expected shape when enabled', () async {
      final config = CiConfig(
        checks: ChecksConfig(test: TestConfig(enabled: true)),
      );

      final result = await check.run(
        projectPath: Directory.systemTemp.path,
        config: config,
      );

      expect(result.checkName, equals('Flutter Test'));
      expect(result.duration, isNotNull);
      expect(result.output, isA<String>());
      expect(result.status, anyOf(CheckStatus.passed, CheckStatus.failed));
    });
  });
}

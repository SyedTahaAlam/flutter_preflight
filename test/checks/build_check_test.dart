import 'dart:io';

import 'package:test/test.dart';

import 'package:flutter_local_ci/flutter_local_ci.dart';

void main() {
  group('BuildCheck', () {
    late BuildCheck check;

    setUp(() => check = BuildCheck());

    test('has correct name and description', () {
      expect(check.name, equals('Flutter Build'));
      expect(check.description, isNotEmpty);
    });

    test('returns skipped when disabled', () async {
      final config = CiConfig(
        checks: ChecksConfig(build: BuildConfig(enabled: false)),
      );

      final result = await check.run(
        projectPath: Directory.systemTemp.path,
        config: config,
      );

      expect(result.status, equals(CheckStatus.skipped));
      expect(result.checkName, equals('Flutter Build'));
    });

    test('returns skipped when no platforms configured', () async {
      final config = CiConfig(
        checks: ChecksConfig(build: BuildConfig(enabled: true, platforms: [])),
      );

      final result = await check.run(
        projectPath: Directory.systemTemp.path,
        config: config,
      );

      expect(result.status, equals(CheckStatus.skipped));
    });

    test('skips ios on non-macOS', () async {
      if (Platform.isMacOS) return;

      final config = CiConfig(
        checks: ChecksConfig(
          build: BuildConfig(enabled: true, platforms: ['ios']),
        ),
      );

      final result = await check.run(
        projectPath: Directory.systemTemp.path,
        config: config,
      );

      expect(result.status, equals(CheckStatus.skipped));
    });
  });
}

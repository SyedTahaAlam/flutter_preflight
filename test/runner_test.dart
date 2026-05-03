import 'dart:io';

import 'package:flutter_local_ci/src/hooks/git_hook_installer.dart';
import 'package:test/test.dart';

import 'package:flutter_local_ci/flutter_local_ci.dart';

void main() {
  group('CiRunner', () {
    CiConfig allDisabled() => const CiConfig(
          checks: ChecksConfig(
            analyze: AnalyzeConfig(enabled: false),
            format: FormatConfig(enabled: false),
            test: TestConfig(enabled: false),
            build: BuildConfig(enabled: false),
          ),
        );

    test('run() returns a CiReport with skipped results', () async {
      final runner = CiRunner(
        config: allDisabled(),
        projectPath: Directory.systemTemp.path,
      );

      final report = await runner.run();

      expect(report, isA<CiReport>());
      expect(report.results.length, equals(4));
      expect(
        report.results.every((r) => r.status == CheckStatus.skipped),
        isTrue,
      );
      expect(report.isSuccess, isTrue);
    });

    test('run() with only filter runs subset', () async {
      final runner = CiRunner(
        config: allDisabled(),
        projectPath: Directory.systemTemp.path,
        only: ['Flutter Analyze'],
      );

      final report = await runner.run();

      expect(report.results.length, equals(1));
      expect(report.results.first.checkName, equals('Flutter Analyze'));
    });

    test('run() with skip filter excludes check', () async {
      final runner = CiRunner(
        config: allDisabled(),
        projectPath: Directory.systemTemp.path,
        skip: ['Flutter Analyze'],
      );

      final report = await runner.run();

      expect(report.results.length, equals(3));
      expect(
        report.results.map((r) => r.checkName),
        isNot(contains('Flutter Analyze')),
      );
    });

    test('CiReport toJson() has expected structure', () {
      final report = CiReport(
        generatedAt: DateTime(2024, 1, 1),
        projectPath: '/some/path',
        totalDuration: const Duration(seconds: 5),
        results: const [
          CheckResult(
            checkName: 'Flutter Analyze',
            status: CheckStatus.passed,
            output: 'No issues found.',
            duration: Duration(seconds: 2),
          ),
        ],
      );

      final json = report.toJson();
      expect(json['overall_status'], equals('passed'));
      expect(json['summary']['passed'], equals(1));
      expect(json['summary']['failed'], equals(0));
      expect((json['checks'] as List).length, equals(1));
    });

    test('CiReport isSuccess is false when a check failed', () {
      final report = CiReport(
        generatedAt: DateTime.now(),
        projectPath: '.',
        totalDuration: Duration.zero,
        results: const [
          CheckResult(
            checkName: 'Dart Format',
            status: CheckStatus.failed,
            output: '',
            duration: Duration.zero,
            errorMessage: 'Files need formatting.',
          ),
        ],
      );

      expect(report.isSuccess, isFalse);
      expect(report.failed, equals(1));
    });
  });

  group('GitHookInstaller', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('flutter_local_ci_hook_');
      // Create a fake .git/hooks directory
      Directory('${tempDir.path}/.git/hooks').createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('isInstalled() returns false before install', () {
      final installer = GitHookInstaller(tempDir.path);
      expect(installer.isInstalled(), isFalse);
    });

    test('install() creates hook file', () {
      final installer = GitHookInstaller(tempDir.path);
      installer.install();
      expect(installer.isInstalled(), isTrue);
    });

    test('uninstall() removes hook file', () {
      final installer = GitHookInstaller(tempDir.path);
      installer.install();
      installer.uninstall();
      expect(installer.isInstalled(), isFalse);
    });

    test('install() is idempotent', () {
      final installer = GitHookInstaller(tempDir.path);
      installer.install();
      installer.install(); // should not throw
      expect(installer.isInstalled(), isTrue);
    });
  });
}

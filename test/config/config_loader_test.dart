import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_local_ci/flutter_local_ci.dart';

void main() {
  group('ConfigLoader', () {
    late Directory tempDir;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('flutter_local_ci_config_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('defaults() returns a valid CiConfig', () {
      final config = ConfigLoader.defaults();
      expect(config, isA<CiConfig>());
      expect(config.checks.analyze.enabled, isTrue);
      expect(config.checks.format.enabled, isTrue);
      expect(config.checks.test.enabled, isTrue);
      expect(config.checks.build.enabled, isFalse);
    });

    test('load() returns defaults when file does not exist', () {
      final config =
          ConfigLoader.load(p.join(tempDir.path, 'missing.yaml'));
      expect(config.checks.analyze.enabled, isTrue);
    });

    test('load() returns defaults when file is empty', () {
      File(p.join(tempDir.path, 'flutter_ci.yaml')).writeAsStringSync('');
      final config =
          ConfigLoader.load(p.join(tempDir.path, 'flutter_ci.yaml'));
      expect(config.checks.analyze.enabled, isTrue);
    });

    test('load() parses a full config correctly', () {
      const yaml = '''
version: 1

checks:
  analyze:
    enabled: false
    fatal_warnings: false
    fatal_infos: true
  format:
    enabled: true
    line_length: 120
  test:
    enabled: true
    coverage:
      enabled: true
      minimum_percent: 80
  build:
    enabled: true
    platforms:
      - apk
      - web

output:
  terminal:
    enabled: true
    verbose: true
  html_report:
    enabled: true
    output_path: reports/ci.html
  json_report:
    enabled: true
    output_path: reports/ci.json

hooks:
  pre_push:
    enabled: true
    on_failure: ask
    auto_install: true
''';
      final file = File(p.join(tempDir.path, 'flutter_ci.yaml'));
      file.writeAsStringSync(yaml);

      final config = ConfigLoader.load(file.path);

      expect(config.version, equals(1));
      expect(config.checks.analyze.enabled, isFalse);
      expect(config.checks.analyze.fatalInfos, isTrue);
      expect(config.checks.analyze.fatalWarnings, isFalse);
      expect(config.checks.format.lineLength, equals(120));
      expect(config.checks.test.coverage.enabled, isTrue);
      expect(config.checks.test.coverage.minimumPercent, equals(80));
      expect(config.checks.build.enabled, isTrue);
      expect(config.checks.build.platforms, containsAll(['apk', 'web']));
      expect(config.output.terminal.verbose, isTrue);
      expect(config.output.htmlReport.enabled, isTrue);
      expect(config.output.htmlReport.outputPath, equals('reports/ci.html'));
      expect(config.output.jsonReport.enabled, isTrue);
      expect(config.hooks.prePush.enabled, isTrue);
      expect(config.hooks.prePush.onFailure, equals(OnFailure.ask));
      expect(config.hooks.prePush.autoInstall, isTrue);
    });

    test('load() handles partial config gracefully', () {
      const yaml = '''
version: 1
checks:
  analyze:
    enabled: false
''';
      final file = File(p.join(tempDir.path, 'flutter_ci.yaml'));
      file.writeAsStringSync(yaml);

      final config = ConfigLoader.load(file.path);

      expect(config.checks.analyze.enabled, isFalse);
      expect(config.checks.format.enabled, isTrue);
      expect(config.checks.test.enabled, isTrue);
    });
  });
}

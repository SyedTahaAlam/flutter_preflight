import 'dart:io';

import 'package:yaml/yaml.dart';

import 'ci_config.dart';

class ConfigLoader {
  /// Load config from [filePath]. Falls back to defaults for missing fields.
  static CiConfig load(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return defaults();

    final content = file.readAsStringSync();
    final yaml = loadYaml(content);
    if (yaml == null || yaml is! YamlMap) return defaults();

    return _parse(yaml);
  }

  /// Return the default [CiConfig].
  static CiConfig defaults() => const CiConfig();

  static CiConfig _parse(YamlMap root) {
    return CiConfig(
      version: _int(root, 'version', 1),
      checks: _parseChecks(_map(root, 'checks')),
      output: _parseOutput(_map(root, 'output')),
      hooks: _parseHooks(_map(root, 'hooks')),
    );
  }

  static ChecksConfig _parseChecks(YamlMap? m) {
    if (m == null) return const ChecksConfig();
    return ChecksConfig(
      analyze: _parseAnalyze(_map(m, 'analyze')),
      format: _parseFormat(_map(m, 'format')),
      test: _parseTest(_map(m, 'test')),
      build: _parseBuild(_map(m, 'build')),
    );
  }

  static AnalyzeConfig _parseAnalyze(YamlMap? m) {
    if (m == null) return const AnalyzeConfig();
    return AnalyzeConfig(
      enabled: _bool(m, 'enabled', true),
      fatalInfos: _bool(m, 'fatal_infos', false),
      fatalWarnings: _bool(m, 'fatal_warnings', true),
    );
  }

  static FormatConfig _parseFormat(YamlMap? m) {
    if (m == null) return const FormatConfig();
    return FormatConfig(
      enabled: _bool(m, 'enabled', true),
      lineLength: _int(m, 'line_length', 80),
    );
  }

  static TestConfig _parseTest(YamlMap? m) {
    if (m == null) return const TestConfig();
    return TestConfig(
      enabled: _bool(m, 'enabled', true),
      coverage: _parseCoverage(_map(m, 'coverage')),
      exclude: _stringList(m, 'exclude'),
    );
  }

  static CoverageConfig _parseCoverage(YamlMap? m) {
    if (m == null) return const CoverageConfig();
    return CoverageConfig(
      enabled: _bool(m, 'enabled', false),
      minimumPercent: _double(m, 'minimum_percent', 0),
    );
  }

  static BuildConfig _parseBuild(YamlMap? m) {
    if (m == null) return const BuildConfig();
    return BuildConfig(
      enabled: _bool(m, 'enabled', false),
      platforms: _stringList(m, 'platforms', defaultValue: ['apk']),
    );
  }

  static OutputConfig _parseOutput(YamlMap? m) {
    if (m == null) return const OutputConfig();
    return OutputConfig(
      terminal: _parseTerminalOutput(_map(m, 'terminal')),
      htmlReport: _parseHtmlReport(_map(m, 'html_report')),
      jsonReport: _parseJsonReport(_map(m, 'json_report')),
    );
  }

  static TerminalOutputConfig _parseTerminalOutput(YamlMap? m) {
    if (m == null) return const TerminalOutputConfig();
    return TerminalOutputConfig(
      enabled: _bool(m, 'enabled', true),
      verbose: _bool(m, 'verbose', false),
    );
  }

  static HtmlReportConfig _parseHtmlReport(YamlMap? m) {
    if (m == null) return const HtmlReportConfig();
    return HtmlReportConfig(
      enabled: _bool(m, 'enabled', false),
      outputPath: _string(m, 'output_path', 'ci_report.html'),
    );
  }

  static JsonReportConfig _parseJsonReport(YamlMap? m) {
    if (m == null) return const JsonReportConfig();
    return JsonReportConfig(
      enabled: _bool(m, 'enabled', false),
      outputPath: _string(m, 'output_path', 'ci_report.json'),
    );
  }

  static HooksConfig _parseHooks(YamlMap? m) {
    if (m == null) return const HooksConfig();
    return HooksConfig(prePush: _parsePrePush(_map(m, 'pre_push')));
  }

  static PrePushConfig _parsePrePush(YamlMap? m) {
    if (m == null) return const PrePushConfig();
    return PrePushConfig(
      enabled: _bool(m, 'enabled', false),
      onFailure: _parseOnFailure(_string(m, 'on_failure', 'block')),
      autoInstall: _bool(m, 'auto_install', false),
    );
  }

  static OnFailure _parseOnFailure(String value) {
    switch (value) {
      case 'warn':
        return OnFailure.warn;
      case 'ask':
        return OnFailure.ask;
      default:
        return OnFailure.block;
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static YamlMap? _map(YamlMap m, String key) {
    final v = m[key];
    return v is YamlMap ? v : null;
  }

  static bool _bool(YamlMap m, String key, bool fallback) {
    final v = m[key];
    return v is bool ? v : fallback;
  }

  static int _int(YamlMap m, String key, int fallback) {
    final v = m[key];
    return v is int ? v : fallback;
  }

  static double _double(YamlMap m, String key, double fallback) {
    final v = m[key];
    return v is num ? v.toDouble() : fallback;
  }

  static String _string(YamlMap m, String key, String fallback) {
    final v = m[key];
    return v is String ? v : fallback;
  }

  static List<String> _stringList(
    YamlMap m,
    String key, {
    List<String> defaultValue = const [],
  }) {
    final v = m[key];
    if (v is YamlList) return v.map((e) => e.toString()).toList();
    return defaultValue;
  }
}

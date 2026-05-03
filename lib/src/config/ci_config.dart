enum OnFailure { block, warn, ask }

class AnalyzeConfig {
  final bool enabled;
  final bool fatalInfos;
  final bool fatalWarnings;

  const AnalyzeConfig({
    this.enabled = true,
    this.fatalInfos = false,
    this.fatalWarnings = true,
  });
}

class FormatConfig {
  final bool enabled;
  final int lineLength;

  const FormatConfig({
    this.enabled = true,
    this.lineLength = 80,
  });
}

class CoverageConfig {
  final bool enabled;
  final double minimumPercent;

  const CoverageConfig({
    this.enabled = false,
    this.minimumPercent = 0,
  });
}

class TestConfig {
  final bool enabled;
  final CoverageConfig coverage;
  final List<String> exclude;

  const TestConfig({
    this.enabled = true,
    this.coverage = const CoverageConfig(),
    this.exclude = const [],
  });
}

class BuildConfig {
  final bool enabled;
  final List<String> platforms;

  const BuildConfig({
    this.enabled = false,
    this.platforms = const ['apk'],
  });
}

class TerminalOutputConfig {
  final bool enabled;
  final bool verbose;

  const TerminalOutputConfig({
    this.enabled = true,
    this.verbose = false,
  });
}

class HtmlReportConfig {
  final bool enabled;
  final String outputPath;

  const HtmlReportConfig({
    this.enabled = false,
    this.outputPath = 'ci_report.html',
  });
}

class JsonReportConfig {
  final bool enabled;
  final String outputPath;

  const JsonReportConfig({
    this.enabled = false,
    this.outputPath = 'ci_report.json',
  });
}

class OutputConfig {
  final TerminalOutputConfig terminal;
  final HtmlReportConfig htmlReport;
  final JsonReportConfig jsonReport;

  const OutputConfig({
    this.terminal = const TerminalOutputConfig(),
    this.htmlReport = const HtmlReportConfig(),
    this.jsonReport = const JsonReportConfig(),
  });
}

class PrePushConfig {
  final bool enabled;
  final OnFailure onFailure;
  final bool autoInstall;

  const PrePushConfig({
    this.enabled = false,
    this.onFailure = OnFailure.block,
    this.autoInstall = false,
  });
}

class HooksConfig {
  final PrePushConfig prePush;

  const HooksConfig({
    this.prePush = const PrePushConfig(),
  });
}

class ChecksConfig {
  final AnalyzeConfig analyze;
  final FormatConfig format;
  final TestConfig test;
  final BuildConfig build;

  const ChecksConfig({
    this.analyze = const AnalyzeConfig(),
    this.format = const FormatConfig(),
    this.test = const TestConfig(),
    this.build = const BuildConfig(),
  });
}

class CiConfig {
  final int version;
  final ChecksConfig checks;
  final OutputConfig output;
  final HooksConfig hooks;

  const CiConfig({
    this.version = 1,
    this.checks = const ChecksConfig(),
    this.output = const OutputConfig(),
    this.hooks = const HooksConfig(),
  });
}

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_local_ci/flutter_local_ci.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<int>(
    'flutter_local_ci',
    'A local CI pipeline for Flutter — run checks before pushing.',
  )
    ..addCommand(RunCommand())
    ..addCommand(InstallCommand())
    ..addCommand(UninstallCommand())
    ..addCommand(StatusCommand())
    ..addCommand(InitCommand());

  try {
    final result = await runner.run(arguments);
    exit(result ?? 0);
  } on UsageException catch (e) {
    print(e.message);
    print('');
    print(e.usage);
    exit(64);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

// ── run ───────────────────────────────────────────────────────────────────────

class RunCommand extends Command<int> {
  @override
  String get name => 'run';

  @override
  String get description => 'Run all configured CI checks.';

  RunCommand() {
    argParser
      ..addOption(
        'project-path',
        abbr: 'p',
        help: 'Path to the Flutter project.',
        defaultsTo: Directory.current.path,
      )
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to flutter_ci.yaml.',
        defaultsTo: 'flutter_ci.yaml',
      )
      ..addFlag('verbose',
          abbr: 'v', help: 'Show full check output.', defaultsTo: false)
      ..addFlag('no-hook',
          help: 'Skip the interactive push prompt.', defaultsTo: false)
      ..addFlag('report-html',
          help: 'Generate an HTML report.', defaultsTo: false)
      ..addFlag('report-json',
          help: 'Generate a JSON report.', defaultsTo: false)
      ..addOption('only',
          help: 'Comma-separated checks to run (analyze,format,test,build).',
          defaultsTo: '')
      ..addOption('skip',
          help: 'Comma-separated checks to skip.',
          defaultsTo: '');
  }

  @override
  Future<int> run() async {
    final projectPath =
        p.canonicalize(argResults!['project-path'] as String);
    final configArg = argResults!['config'] as String;
    final configPath =
        p.isAbsolute(configArg) ? configArg : p.join(projectPath, configArg);
    final verbose = argResults!['verbose'] as bool;
    final noHook = argResults!['no-hook'] as bool;
    final reportHtml = argResults!['report-html'] as bool;
    final reportJson = argResults!['report-json'] as bool;
    final onlyRaw = argResults!['only'] as String;
    final skipRaw = argResults!['skip'] as String;

    final only = onlyRaw.isEmpty
        ? null
        : onlyRaw.split(',').map((s) => s.trim()).toList();
    final skip = skipRaw.isEmpty
        ? null
        : skipRaw.split(',').map((s) => s.trim()).toList();

    CiConfig config;
    try {
      config = ConfigLoader.load(configPath);
    } catch (_) {
      print('Warning: Could not load $configPath — using defaults.');
      config = ConfigLoader.defaults();
    }

    // Auto-install hook if configured
    if (config.hooks.prePush.autoInstall) {
      final installer = GitHookInstaller(projectPath);
      if (!installer.isInstalled()) {
        try {
          installer.install();
          print(
            '\x1B[36mℹ  Pre-push hook installed automatically. '
            "Run 'flutter_local_ci uninstall' to remove.\x1B[0m",
          );
        } catch (_) {
          // Non-fatal
        }
      }
    }

    final reporter = TerminalReporter(verbose: verbose);
    reporter.printHeader();

    final allChecks = _buildChecks(config, only, skip);
    final results = <CheckResult>[];
    final stopwatch = Stopwatch()..start();

    for (final check in allChecks) {
      reporter.printRunning(check.name);
      final result =
          await check.run(projectPath: projectPath, config: config);
      results.add(result);
      reporter.printResult(result);
    }

    stopwatch.stop();

    final report = CiReport(
      generatedAt: DateTime.now(),
      projectPath: projectPath,
      totalDuration: stopwatch.elapsed,
      results: results,
    );

    reporter.printFooter(report);

    if (reportHtml || config.output.htmlReport.enabled) {
      final htmlPath =
          p.join(projectPath, config.output.htmlReport.outputPath);
      HtmlReporter().write(report, htmlPath);
      print('HTML report written to $htmlPath');
    }

    if (reportJson || config.output.jsonReport.enabled) {
      final jsonPath =
          p.join(projectPath, config.output.jsonReport.outputPath);
      JsonReporter().write(report, jsonPath);
      print('JSON report written to $jsonPath');
    }

    if (report.isSuccess) return 0;

    // on_failure handling
    if (!noHook) {
      final onFailure = config.hooks.prePush.onFailure;
      if (onFailure == OnFailure.warn) {
        print('\x1B[33m⚠  CI checks failed, but continuing (warn mode).\x1B[0m');
        return 0;
      } else if (onFailure == OnFailure.ask) {
        if (stdin.hasTerminal) {
          stdout.write('❌ CI failed. Push anyway? (y/N): ');
          final answer = stdin.readLineSync() ?? '';
          if (answer.toLowerCase() == 'y') return 0;
        }
        // non-interactive → block
      }
    }

    return 1;
  }

  List<BaseCheck> _buildChecks(
    CiConfig config,
    List<String>? only,
    List<String>? skip,
  ) {
    final all = <BaseCheck>[
      AnalyzeCheck(),
      FormatCheck(),
      TestCheck(),
      BuildCheck(),
    ];

    var filtered = all;

    if (only != null && only.isNotEmpty) {
      final keys = only.map(_normalize).toSet();
      filtered =
          filtered.where((c) => keys.contains(_normalize(c.name))).toList();
    }

    if (skip != null && skip.isNotEmpty) {
      final keys = skip.map(_normalize).toSet();
      filtered =
          filtered.where((c) => !keys.contains(_normalize(c.name))).toList();
    }

    return filtered;
  }

  String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');
}

// ── install ───────────────────────────────────────────────────────────────────

class InstallCommand extends Command<int> {
  @override
  String get name => 'install';

  @override
  String get description => 'Install the git pre-push hook.';

  InstallCommand() {
    argParser.addOption(
      'project-path',
      abbr: 'p',
      help: 'Path to the Flutter project.',
      defaultsTo: Directory.current.path,
    );
  }

  @override
  Future<int> run() async {
    final projectPath =
        p.canonicalize(argResults!['project-path'] as String);
    try {
      GitHookInstaller(projectPath).install();
      print('\x1B[32m✔  Pre-push hook installed.\x1B[0m');
      return 0;
    } catch (e) {
      print('\x1B[31m✘  Failed to install hook: $e\x1B[0m');
      return 1;
    }
  }
}

// ── uninstall ─────────────────────────────────────────────────────────────────

class UninstallCommand extends Command<int> {
  @override
  String get name => 'uninstall';

  @override
  String get description => 'Remove the git pre-push hook.';

  UninstallCommand() {
    argParser.addOption(
      'project-path',
      abbr: 'p',
      help: 'Path to the Flutter project.',
      defaultsTo: Directory.current.path,
    );
  }

  @override
  Future<int> run() async {
    final projectPath =
        p.canonicalize(argResults!['project-path'] as String);
    try {
      GitHookInstaller(projectPath).uninstall();
      print('\x1B[32m✔  Pre-push hook removed.\x1B[0m');
      return 0;
    } catch (e) {
      print('\x1B[31m✘  Failed to remove hook: $e\x1B[0m');
      return 1;
    }
  }
}

// ── status ────────────────────────────────────────────────────────────────────

class StatusCommand extends Command<int> {
  @override
  String get name => 'status';

  @override
  String get description => 'Show hook installation status and config summary.';

  StatusCommand() {
    argParser
      ..addOption('project-path',
          abbr: 'p',
          help: 'Path to the Flutter project.',
          defaultsTo: Directory.current.path)
      ..addOption('config',
          abbr: 'c',
          help: 'Path to flutter_ci.yaml.',
          defaultsTo: 'flutter_ci.yaml');
  }

  @override
  Future<int> run() async {
    final projectPath =
        p.canonicalize(argResults!['project-path'] as String);
    final configArg = argResults!['config'] as String;
    final configPath =
        p.isAbsolute(configArg) ? configArg : p.join(projectPath, configArg);

    final hookStatus = GitHookInstaller(projectPath).isInstalled()
        ? '\x1B[32minstalled\x1B[0m'
        : '\x1B[90mnot installed\x1B[0m';
    print('Pre-push hook: $hookStatus');

    CiConfig config;
    try {
      config = ConfigLoader.load(configPath);
      print('Config:        $configPath');
    } catch (_) {
      config = ConfigLoader.defaults();
      print('Config:        defaults (could not load $configPath)');
    }

    print('');
    print('Checks:');
    print(
        '  analyze : ${config.checks.analyze.enabled ? 'enabled' : 'disabled'}');
    print(
        '  format  : ${config.checks.format.enabled ? 'enabled' : 'disabled'}');
    print(
        '  test    : ${config.checks.test.enabled ? 'enabled' : 'disabled'}');
    final buildLabel = config.checks.build.enabled
        ? 'enabled (${config.checks.build.platforms.join(', ')})'
        : 'disabled';
    print('  build   : $buildLabel');

    return 0;
  }
}

// ── init ──────────────────────────────────────────────────────────────────────

class InitCommand extends Command<int> {
  @override
  String get name => 'init';

  @override
  String get description =>
      'Create a default flutter_ci.yaml in the current directory.';

  InitCommand() {
    argParser.addOption(
      'project-path',
      abbr: 'p',
      help: 'Path to the Flutter project.',
      defaultsTo: Directory.current.path,
    );
  }

  @override
  Future<int> run() async {
    final projectPath =
        p.canonicalize(argResults!['project-path'] as String);
    final dest = p.join(projectPath, 'flutter_ci.yaml');

    if (File(dest).existsSync()) {
      print('flutter_ci.yaml already exists at $dest');
      return 1;
    }

    File(dest).writeAsStringSync(_defaultConfig);
    print('\x1B[32m✔  Created $dest\x1B[0m');
    return 0;
  }

  static const _defaultConfig = '''version: 1

checks:
  analyze:
    enabled: true
    fatal_warnings: true
    fatal_infos: false

  format:
    enabled: true
    line_length: 80

  test:
    enabled: true
    coverage:
      enabled: false
      minimum_percent: 0

  build:
    enabled: false
    platforms:
      - apk

output:
  terminal:
    enabled: true
    verbose: false
  html_report:
    enabled: false
    output_path: ci_report.html
  json_report:
    enabled: false
    output_path: ci_report.json

hooks:
  pre_push:
    enabled: false
    on_failure: block
    auto_install: false
''';
}

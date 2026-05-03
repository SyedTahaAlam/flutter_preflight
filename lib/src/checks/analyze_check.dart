import 'dart:io';

import '../config/ci_config.dart';
import '../models/check_result.dart';
import 'base_check.dart';

class AnalyzeCheck extends BaseCheck {
  @override
  String get name => 'Flutter Analyze';

  @override
  String get description => 'Runs flutter analyze to find static issues.';

  @override
  Future<CheckResult> run({
    required String projectPath,
    required CiConfig config,
  }) async {
    final analyzeConfig = config.checks.analyze;

    if (!analyzeConfig.enabled) {
      return const CheckResult(
        checkName: 'Flutter Analyze',
        status: CheckStatus.skipped,
        output: 'Analyze check is disabled.',
        duration: Duration.zero,
      );
    }

    final args = ['analyze'];
    if (analyzeConfig.fatalWarnings) args.add('--fatal-warnings');
    if (analyzeConfig.fatalInfos) args.add('--fatal-infos');

    final stopwatch = Stopwatch()..start();
    try {
      final result = await Process.run(
        'flutter',
        args,
        workingDirectory: projectPath,
        runInShell: true,
      );
      stopwatch.stop();

      final output = _combined(result);
      final passed = result.exitCode == 0;

      return CheckResult(
        checkName: name,
        status: passed ? CheckStatus.passed : CheckStatus.failed,
        output: output,
        duration: stopwatch.elapsed,
        errorMessage: passed
            ? null
            : 'flutter analyze exited with code ${result.exitCode}',
      );
    } catch (e) {
      stopwatch.stop();
      return CheckResult(
        checkName: name,
        status: CheckStatus.failed,
        output: '',
        duration: stopwatch.elapsed,
        errorMessage: 'Failed to run flutter analyze: $e',
      );
    }
  }

  String _combined(ProcessResult r) {
    final out = r.stdout.toString().trim();
    final err = r.stderr.toString().trim();
    return [if (out.isNotEmpty) out, if (err.isNotEmpty) err].join('\n');
  }
}

import 'dart:io';

import '../config/ci_config.dart';
import '../models/check_result.dart';
import 'base_check.dart';

class FormatCheck extends BaseCheck {
  @override
  String get name => 'Dart Format';

  @override
  String get description =>
      'Verifies that all Dart files are correctly formatted.';

  @override
  Future<CheckResult> run({
    required String projectPath,
    required CiConfig config,
  }) async {
    final formatConfig = config.checks.format;

    if (!formatConfig.enabled) {
      return const CheckResult(
        checkName: 'Dart Format',
        status: CheckStatus.skipped,
        output: 'Format check is disabled.',
        duration: Duration.zero,
      );
    }

    final args = [
      'format',
      '--set-exit-if-changed',
      '--line-length',
      '${formatConfig.lineLength}',
      '.',
    ];

    final stopwatch = Stopwatch()..start();
    try {
      final result = await Process.run(
        'dart',
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
            : 'Some files need formatting. Run `dart format .` to fix.',
      );
    } catch (e) {
      stopwatch.stop();
      return CheckResult(
        checkName: name,
        status: CheckStatus.failed,
        output: '',
        duration: stopwatch.elapsed,
        errorMessage: 'Failed to run dart format: $e',
      );
    }
  }

  String _combined(ProcessResult r) {
    final out = r.stdout.toString().trim();
    final err = r.stderr.toString().trim();
    return [if (out.isNotEmpty) out, if (err.isNotEmpty) err].join('\n');
  }
}

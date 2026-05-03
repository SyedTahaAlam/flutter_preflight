import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/ci_config.dart';
import '../models/check_result.dart';
import 'base_check.dart';

class TestCheck extends BaseCheck {
  @override
  String get name => 'Flutter Test';

  @override
  String get description => 'Runs flutter test with optional coverage check.';

  @override
  Future<CheckResult> run({
    required String projectPath,
    required CiConfig config,
  }) async {
    final testConfig = config.checks.test;

    if (!testConfig.enabled) {
      return const CheckResult(
        checkName: 'Flutter Test',
        status: CheckStatus.skipped,
        output: 'Test check is disabled.',
        duration: Duration.zero,
      );
    }

    final args = ['test'];
    if (testConfig.coverage.enabled) args.add('--coverage');

    final stopwatch = Stopwatch()..start();
    try {
      final result = await Process.run(
        'flutter',
        args,
        workingDirectory: projectPath,
        runInShell: true,
      );
      stopwatch.stop();

      final rawOutput = _combined(result);

      if (result.exitCode != 0) {
        return CheckResult(
          checkName: name,
          status: CheckStatus.failed,
          output: rawOutput,
          duration: stopwatch.elapsed,
          errorMessage: 'flutter test exited with code ${result.exitCode}',
        );
      }

      var output = rawOutput;

      if (testConfig.coverage.enabled) {
        final coverageResult = _checkCoverage(
          projectPath: projectPath,
          testConfig: testConfig,
        );
        output = '$output\n${coverageResult.message}'.trim();
        if (!coverageResult.passed) {
          return CheckResult(
            checkName: name,
            status: CheckStatus.failed,
            output: output,
            duration: stopwatch.elapsed,
            errorMessage: coverageResult.message,
          );
        }
      }

      return CheckResult(
        checkName: name,
        status: CheckStatus.passed,
        output: output,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return CheckResult(
        checkName: name,
        status: CheckStatus.failed,
        output: '',
        duration: stopwatch.elapsed,
        errorMessage: 'Failed to run flutter test: $e',
      );
    }
  }

  _CoverageResult _checkCoverage({
    required String projectPath,
    required TestConfig testConfig,
  }) {
    final lcovPath = p.join(projectPath, 'coverage', 'lcov.info');
    final lcovFile = File(lcovPath);
    if (!lcovFile.existsSync()) {
      return _CoverageResult(
        passed: true,
        message: 'Coverage file not found at $lcovPath; skipping threshold.',
      );
    }

    final lines = lcovFile.readAsLinesSync();
    var linesFound = 0;
    var linesHit = 0;

    for (final line in lines) {
      if (line.startsWith('LF:')) {
        linesFound += int.tryParse(line.substring(3)) ?? 0;
      } else if (line.startsWith('LH:')) {
        linesHit += int.tryParse(line.substring(3)) ?? 0;
      }
    }

    if (linesFound == 0) {
      return _CoverageResult(
        passed: true,
        message: 'No coverable lines found; skipping threshold.',
      );
    }

    final percent = (linesHit / linesFound) * 100;
    final minimum = testConfig.coverage.minimumPercent;
    final percentStr = percent.toStringAsFixed(1);

    if (minimum > 0 && percent < minimum) {
      return _CoverageResult(
        passed: false,
        message:
            'Coverage $percentStr% is below the minimum threshold of $minimum%.',
      );
    }

    return _CoverageResult(
      passed: true,
      message:
          'Coverage: $percentStr%${minimum > 0 ? ' (minimum: $minimum%)' : ''}',
    );
  }

  String _combined(ProcessResult r) {
    final out = r.stdout.toString().trim();
    final err = r.stderr.toString().trim();
    return [if (out.isNotEmpty) out, if (err.isNotEmpty) err].join('\n');
  }
}

class _CoverageResult {
  final bool passed;
  final String message;
  const _CoverageResult({required this.passed, required this.message});
}

import '../models/check_result.dart';
import '../models/ci_report.dart';
import '../version.dart';

// ANSI color codes
const _reset = '\x1B[0m';
const _bold = '\x1B[1m';
const _green = '\x1B[32m';
const _red = '\x1B[31m';
const _yellow = '\x1B[33m';
const _gray = '\x1B[90m';
const _cyan = '\x1B[36m';

class TerminalReporter {
  final bool verbose;

  const TerminalReporter({this.verbose = false});

  void printHeader() {
    const border = '─' * 45;
    print('$_cyan┌$border┐$_reset');
    print(
      '$_cyan│$_reset'
      '$_bold       flutter_local_ci  v$packageVersion          $_reset'
      '$_cyan│$_reset',
    );
    print('$_cyan└$border┘$_reset');
    print('');
  }

  void printRunning(String checkName) {
    print('  $_gray⠿$_reset  Running $checkName...');
  }

  void printResult(CheckResult result) {
    final icon = _icon(result.status);
    final color = _color(result.status);
    final label = result.status.name.padRight(8);
    final duration =
        '(${(result.duration.inMilliseconds / 1000).toStringAsFixed(1)}s)';

    print(
      '  $color$icon$_reset  '
      '${result.checkName.padRight(24)} '
      '$color$label$_reset '
      '$_gray$duration$_reset',
    );

    if (verbose && result.output.isNotEmpty) {
      for (final line in result.output.split('\n')) {
        print('     $_gray$line$_reset');
      }
    } else if (result.status == CheckStatus.failed &&
        result.errorMessage != null) {
      print('     $_red→ ${result.errorMessage}$_reset');
      if (result.output.isNotEmpty) {
        for (final line in result.output.split('\n').take(20)) {
          print('     $_gray$line$_reset');
        }
      }
    }
  }

  void printFooter(CiReport report) {
    const border = '─' * 45;
    print('$_gray$border$_reset');

    final passedStr = '$_green${report.passed} passed$_reset';
    final failedStr = report.failed > 0
        ? '$_red${report.failed} failed$_reset'
        : '${report.failed} failed';
    final skippedStr = '$_gray${report.skipped} skipped$_reset';

    print('  $passedStr  ·  $failedStr  ·  $skippedStr');

    final totalSec =
        (report.totalDuration.inMilliseconds / 1000).toStringAsFixed(1);
    print('  Total time: ${totalSec}s');
    print('');

    if (report.isSuccess) {
      print('$_green${_bold}✔  All checks passed!$_reset');
    } else {
      print(
          '$_red${_bold}✘  CI failed — ${report.failed} check(s) did not pass.$_reset');
    }
    print('');
  }

  String _icon(CheckStatus status) => switch (status) {
        CheckStatus.passed => '✔',
        CheckStatus.failed => '✘',
        CheckStatus.skipped => '○',
        CheckStatus.warning => '⚠',
      };

  String _color(CheckStatus status) => switch (status) {
        CheckStatus.passed => _green,
        CheckStatus.failed => _red,
        CheckStatus.skipped => _gray,
        CheckStatus.warning => _yellow,
      };
}

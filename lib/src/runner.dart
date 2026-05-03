import 'models/check_result.dart';
import 'models/ci_report.dart';
import 'config/ci_config.dart';
import 'checks/base_check.dart';
import 'checks/analyze_check.dart';
import 'checks/format_check.dart';
import 'checks/test_check.dart';
import 'checks/build_check.dart';

class CiRunner {
  final CiConfig config;
  final String projectPath;

  /// If set, only run checks whose normalised name is in this list.
  final List<String>? only;

  /// If set, skip checks whose normalised name is in this list.
  final List<String>? skip;

  CiRunner({
    required this.config,
    required this.projectPath,
    this.only,
    this.skip,
  });

  Future<CiReport> run() async {
    final checks = _filterChecks(_buildChecks());

    final stopwatch = Stopwatch()..start();
    final results = <CheckResult>[];

    for (final check in checks) {
      results.add(await check.run(projectPath: projectPath, config: config));
    }

    stopwatch.stop();

    return CiReport(
      generatedAt: DateTime.now(),
      projectPath: projectPath,
      totalDuration: stopwatch.elapsed,
      results: results,
    );
  }

  List<BaseCheck> _buildChecks() => [
        AnalyzeCheck(),
        FormatCheck(),
        TestCheck(),
        BuildCheck(),
      ];

  List<BaseCheck> _filterChecks(List<BaseCheck> checks) {
    var filtered = checks;

    if (only != null && only!.isNotEmpty) {
      final keys = only!.map(_normalize).toSet();
      filtered = filtered.where((c) => keys.contains(_normalize(c.name))).toList();
    }

    if (skip != null && skip!.isNotEmpty) {
      final keys = skip!.map(_normalize).toSet();
      filtered = filtered.where((c) => !keys.contains(_normalize(c.name))).toList();
    }

    return filtered;
  }

  String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');
}

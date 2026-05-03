import 'check_result.dart';

class CiReport {
  final DateTime generatedAt;
  final String projectPath;
  final Duration totalDuration;
  final List<CheckResult> results;

  const CiReport({
    required this.generatedAt,
    required this.projectPath,
    required this.totalDuration,
    required this.results,
  });

  int get passed =>
      results.where((r) => r.status == CheckStatus.passed).length;
  int get failed =>
      results.where((r) => r.status == CheckStatus.failed).length;
  int get skipped =>
      results.where((r) => r.status == CheckStatus.skipped).length;
  int get warnings =>
      results.where((r) => r.status == CheckStatus.warning).length;
  bool get isSuccess => failed == 0;

  Map<String, dynamic> toJson() => {
        'generated_at': generatedAt.toIso8601String(),
        'project_path': projectPath,
        'total_duration_ms': totalDuration.inMilliseconds,
        'overall_status': isSuccess ? 'passed' : 'failed',
        'summary': {
          'passed': passed,
          'failed': failed,
          'skipped': skipped,
        },
        'checks': results.map((r) => r.toJson()).toList(),
      };
}

import '../config/ci_config.dart';
import '../models/check_result.dart';

/// Base class for all CI checks.
abstract class BaseCheck {
  /// Human-readable name shown in reports.
  String get name;

  /// Short description of what this check does.
  String get description;

  /// Execute the check and return a [CheckResult].
  Future<CheckResult> run({
    required String projectPath,
    required CiConfig config,
  });
}

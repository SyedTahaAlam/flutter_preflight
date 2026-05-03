/// flutter_local_ci — public API barrel export.
library flutter_local_ci;

export 'src/models/check_result.dart';
export 'src/models/ci_report.dart';
export 'src/config/ci_config.dart';
export 'src/config/config_loader.dart';
export 'src/checks/base_check.dart';
export 'src/checks/analyze_check.dart';
export 'src/checks/format_check.dart';
export 'src/checks/test_check.dart';
export 'src/checks/build_check.dart';
export 'src/runner.dart';
export 'src/reporter/terminal_reporter.dart';
export 'src/reporter/html_reporter.dart';
export 'src/reporter/json_reporter.dart';
export 'src/hooks/git_hook_installer.dart';

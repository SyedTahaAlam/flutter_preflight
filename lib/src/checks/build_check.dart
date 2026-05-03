import 'dart:io';

import '../config/ci_config.dart';
import '../models/check_result.dart';
import 'base_check.dart';

class BuildCheck extends BaseCheck {
  @override
  String get name => 'Flutter Build';

  @override
  String get description =>
      'Builds the app for each configured platform in debug mode.';

  @override
  Future<CheckResult> run({
    required String projectPath,
    required CiConfig config,
  }) async {
    final buildConfig = config.checks.build;

    if (!buildConfig.enabled) {
      return const CheckResult(
        checkName: 'Flutter Build',
        status: CheckStatus.skipped,
        output: 'Build check is disabled.',
        duration: Duration.zero,
      );
    }

    if (buildConfig.platforms.isEmpty) {
      return const CheckResult(
        checkName: 'Flutter Build',
        status: CheckStatus.skipped,
        output: 'No platforms configured for build.',
        duration: Duration.zero,
      );
    }

    final stopwatch = Stopwatch()..start();
    final platformResults = <_PlatformResult>[];

    for (final platform in buildConfig.platforms) {
      platformResults.add(await _buildPlatform(
        platform: platform,
        projectPath: projectPath,
      ));
    }

    stopwatch.stop();

    final outputLines = platformResults.map((r) {
      final label = r.status.name.toUpperCase();
      return '[$label] ${r.platform}\n${r.output}';
    }).join('\n\n');

    final anyFailed =
        platformResults.any((r) => r.status == CheckStatus.failed);
    final allSkipped =
        platformResults.every((r) => r.status == CheckStatus.skipped);

    final overallStatus = anyFailed
        ? CheckStatus.failed
        : allSkipped
            ? CheckStatus.skipped
            : CheckStatus.passed;

    final failedPlatforms = platformResults
        .where((r) => r.status == CheckStatus.failed)
        .map((r) => r.platform)
        .join(', ');

    return CheckResult(
      checkName: name,
      status: overallStatus,
      output: outputLines,
      duration: stopwatch.elapsed,
      errorMessage:
          anyFailed ? 'Build failed for platform(s): $failedPlatforms' : null,
    );
  }

  Future<_PlatformResult> _buildPlatform({
    required String platform,
    required String projectPath,
  }) async {
    if (!_isPlatformSupported(platform)) {
      return _PlatformResult(
        platform: platform,
        status: CheckStatus.skipped,
        output:
            'Platform $platform is not supported on ${Platform.operatingSystem}.',
      );
    }

    try {
      final result = await Process.run(
        'flutter',
        ['build', platform, '--debug'],
        workingDirectory: projectPath,
        runInShell: true,
      );

      final out = result.stdout.toString().trim();
      final err = result.stderr.toString().trim();
      final output =
          [if (out.isNotEmpty) out, if (err.isNotEmpty) err].join('\n');

      return _PlatformResult(
        platform: platform,
        status: result.exitCode == 0 ? CheckStatus.passed : CheckStatus.failed,
        output: output,
      );
    } catch (e) {
      return _PlatformResult(
        platform: platform,
        status: CheckStatus.failed,
        output: 'Failed to run flutter build $platform: $e',
      );
    }
  }

  bool _isPlatformSupported(String platform) {
    if (Platform.isMacOS) return true; // macOS supports all platforms
    if (platform == 'ios' || platform == 'macos') return false;
    if (platform == 'windows') return Platform.isWindows;
    if (platform == 'linux') return Platform.isLinux;
    // android / apk / web are cross-platform
    return true;
  }
}

class _PlatformResult {
  final String platform;
  final CheckStatus status;
  final String output;

  const _PlatformResult({
    required this.platform,
    required this.status,
    required this.output,
  });
}

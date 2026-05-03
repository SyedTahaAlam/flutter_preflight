import 'dart:io';

import 'package:path/path.dart' as p;

class GitHookInstaller {
  final String projectPath;

  GitHookInstaller(this.projectPath);

  String get _hooksDir => p.join(projectPath, '.git', 'hooks');
  String get _hookPath => p.join(_hooksDir, 'pre-push');
  String get _hookBatPath => p.join(_hooksDir, 'pre-push.bat');

  static const _hookScript = '#!/bin/sh\n'
      'dart run flutter_local_ci run --no-hook\n'
      r'exit $?'
      '\n';

  static const _hookBatScript = '@echo off\r\n'
      'dart run flutter_local_ci run --no-hook\r\n'
      'exit /b %ERRORLEVEL%\r\n';

  /// Install the pre-push git hook.
  void install() {
    final dir = Directory(_hooksDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);

    File(_hookPath).writeAsStringSync(_hookScript);

    if (!Platform.isWindows) {
      Process.runSync('chmod', ['+x', _hookPath]);
    } else {
      File(_hookBatPath).writeAsStringSync(_hookBatScript);
    }
  }

  /// Remove the pre-push git hook.
  void uninstall() {
    final hook = File(_hookPath);
    if (hook.existsSync()) hook.deleteSync();

    final bat = File(_hookBatPath);
    if (bat.existsSync()) bat.deleteSync();
  }

  /// Returns true if the pre-push hook file is installed.
  bool isInstalled() => File(_hookPath).existsSync();
}

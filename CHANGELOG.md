# Changelog

## 0.1.0

- Initial release
- **Flutter Analyze** check (`flutter analyze`, optional `--fatal-warnings` / `--fatal-infos`)
- **Dart Format** check (`dart format --set-exit-if-changed .`)
- **Flutter Test** check (`flutter test --coverage`) with lcov coverage threshold
- **Multi-platform Build** check — OS-aware platform gating (ios/macos → macOS only, windows → Windows only, linux → Linux only)
- **Terminal reporter** with ANSI colors
- **HTML reporter** — self-contained single-file report
- **JSON reporter**
- **Git pre-push hook** installer/uninstaller (Unix shell + Windows `.bat`)
- **CLI** with `run` / `install` / `uninstall` / `status` / `init` commands
- Auto-install hook support (`auto_install: true`)
- Interactive push prompt on failure (`on_failure: ask`)

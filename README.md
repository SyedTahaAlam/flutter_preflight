# flutter_local_ci

[![pub.dev](https://img.shields.io/pub/v/flutter_local_ci)](https://pub.dev/packages/flutter_local_ci)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A **local CI pipeline** for Flutter — run quality checks before pushing to your repository.

`flutter_local_ci` brings the CI experience to your local machine. Run `flutter analyze`, `dart format`, `flutter test`, and `flutter build` checks with a single command, generate HTML/JSON reports, and optionally install a git pre-push hook to prevent broken code from ever reaching your remote.

---

## Table of Contents

1. [Installation](#installation)
2. [Quick Start](#quick-start)
3. [Git Hook Setup](#git-hook-setup)
4. [Configuration Reference](#configuration-reference)
5. [CI Server Usage](#ci-server-usage)
6. [Commands Reference](#commands-reference)
7. [Contributing](#contributing)

---

## Installation

### Global activation (recommended)

```bash
dart pub global activate flutter_local_ci
```

### As a dev dependency

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_local_ci: ^0.1.0
```

Then run `dart pub get`.

---

## Quick Start

1. **Initialise** a config file in your project:

```bash
flutter_local_ci init
# or: dart run flutter_local_ci init
```

2. **Run** all checks:

```bash
flutter_local_ci run
```

3. View the coloured terminal output and fix any issues before pushing.

---

## Git Hook Setup

Install a git pre-push hook so checks run automatically before every `git push`:

```bash
flutter_local_ci install
```

Remove it at any time:

```bash
flutter_local_ci uninstall
```

Alternatively, set `auto_install: true` in `flutter_ci.yaml` and the hook is installed the first time you run `flutter_local_ci run`.

---

## Configuration Reference

Place `flutter_ci.yaml` at your project root. All fields are optional — missing fields fall back to sensible defaults.

```yaml
version: 1

checks:
  analyze:
    enabled: true          # Run flutter analyze
    fatal_warnings: true   # --fatal-warnings flag
    fatal_infos: false     # --fatal-infos flag

  format:
    enabled: true          # Run dart format --set-exit-if-changed
    line_length: 80        # --line-length value

  test:
    enabled: true          # Run flutter test
    coverage:
      enabled: false       # Pass --coverage and parse lcov.info
      minimum_percent: 0   # Fail if coverage < N% (0 = disabled)
    exclude:               # Glob patterns to exclude (informational)
      - "**/*.g.dart"
      - "**/*.freezed.dart"

  build:
    enabled: false         # Run flutter build <platform> --debug
    platforms:             # Platforms to build (OS-aware)
      - apk                # all OSes
      - ios                # macOS only
      - web                # all OSes
      - windows            # Windows only
      - macos              # macOS only
      - linux              # Linux only

output:
  terminal:
    enabled: true
    verbose: false         # true = print full subprocess output

  html_report:
    enabled: false
    output_path: "ci_reports/report.html"

  json_report:
    enabled: false
    output_path: "ci_reports/report.json"

hooks:
  pre_push:
    enabled: true
    on_failure: ask        # block | warn | ask
    auto_install: true     # auto-install hook on first run
```

### `on_failure` values

| Value   | Behaviour |
|---------|-----------|
| `block` | Always exit 1 — push is prevented (default) |
| `warn`  | Print a warning but exit 0 — push proceeds |
| `ask`   | Interactive prompt; auto-blocks in non-TTY environments |

---

## CI Server Usage

Use `flutter_local_ci` in your CI pipeline alongside (or instead of) your remote CI:

### GitHub Actions

```yaml
- name: Run flutter_local_ci
  run: |
    dart pub global activate flutter_local_ci
    flutter_local_ci run --no-hook --report-json
```

### Bitbucket Pipelines

```yaml
- step:
    name: Local CI checks
    script:
      - dart pub global activate flutter_local_ci
      - flutter_local_ci run --no-hook
```

> **Tip:** Pass `--no-hook` in CI to skip the interactive prompt and always exit 1 on failure.

---

## Commands Reference

```
flutter_local_ci <command> [options]

Commands:
  run          Run all configured CI checks (default)
  install      Install the git pre-push hook
  uninstall    Remove the git pre-push hook
  status       Show hook status and config summary
  init         Create a default flutter_ci.yaml in the project directory
```

### `run` options

| Flag / Option      | Default           | Description |
|--------------------|-------------------|-------------|
| `--project-path`   | current directory | Path to the Flutter project |
| `--config`         | `flutter_ci.yaml` | Path to config file |
| `--verbose`        | `false`           | Show full subprocess output |
| `--no-hook`        | `false`           | Skip interactive push prompt |
| `--report-html`    | `false`           | Force-generate HTML report |
| `--report-json`    | `false`           | Force-generate JSON report |
| `--only`           | _(all)_           | Comma-separated checks to run |
| `--skip`           | _(none)_          | Comma-separated checks to skip |

**Examples:**

```bash
# Run only analyze and format
flutter_local_ci run --only analyze,format

# Skip the build check
flutter_local_ci run --skip build

# Run verbosely with both reports
flutter_local_ci run --verbose --report-html --report-json

# Point at a different project
flutter_local_ci run --project-path ../my_app
```

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make your changes and add tests
4. Run `dart analyze` and `dart format .`
5. Run `dart test`
6. Submit a pull request

### Development setup

```bash
git clone https://github.com/SyedTahaAlam/flutter_preflight.git flutter_local_ci
cd flutter_local_ci
dart pub get
dart analyze
dart test
```

### Code style

- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- All public APIs must have doc comments
- New checks must extend `BaseCheck` and include unit tests
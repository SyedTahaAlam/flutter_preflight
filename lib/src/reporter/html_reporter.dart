import 'dart:io';

import '../models/check_result.dart';
import '../models/ci_report.dart';

class HtmlReporter {
  /// Write a self-contained HTML report to [outputPath].
  void write(CiReport report, String outputPath) {
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(_buildHtml(report));
  }

  String _buildHtml(CiReport report) {
    final checksHtml = report.results.map(_checkCard).join('\n');
    final statusClass = report.isSuccess ? 'success' : 'failure';
    final statusText =
        report.isSuccess ? '✔  All checks passed' : '✘  CI Failed';
    final totalSec =
        (report.totalDuration.inMilliseconds / 1000).toStringAsFixed(1);

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>flutter_local_ci Report</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:#0d1117;color:#c9d1d9;padding:2rem}
    h1{color:#58a6ff;margin-bottom:.25rem}
    .meta{color:#8b949e;font-size:.85rem;margin-bottom:2rem}
    .banner{padding:1rem 1.5rem;border-radius:8px;font-size:1.1rem;font-weight:600;margin-bottom:2rem}
    .banner.success{background:#0d4429;color:#3fb950;border:1px solid #238636}
    .banner.failure{background:#3d1017;color:#f85149;border:1px solid #da3633}
    .summary{display:flex;gap:1.5rem;margin-bottom:2rem}
    .stat{background:#161b22;border:1px solid #30363d;border-radius:8px;padding:.75rem 1.5rem;text-align:center}
    .stat .num{font-size:2rem;font-weight:700}
    .stat .label{font-size:.75rem;color:#8b949e;text-transform:uppercase}
    .passed .num{color:#3fb950}.failed .num{color:#f85149}.skipped .num{color:#8b949e}
    .card{background:#161b22;border:1px solid #30363d;border-radius:8px;margin-bottom:1rem;overflow:hidden}
    .card-header{display:flex;align-items:center;gap:.75rem;padding:.85rem 1.25rem;cursor:pointer;user-select:none}
    .card-header:hover{background:#1c2128}
    .badge{padding:.2rem .6rem;border-radius:12px;font-size:.75rem;font-weight:600}
    .badge-passed{background:#0d4429;color:#3fb950}
    .badge-failed{background:#3d1017;color:#f85149}
    .badge-skipped{background:#21262d;color:#8b949e}
    .badge-warning{background:#2d2a00;color:#d29922}
    .card-name{font-weight:600;flex:1}
    .duration{color:#8b949e;font-size:.85rem}
    .card-body{display:none;padding:1rem 1.25rem;border-top:1px solid #30363d}
    .card-body.open{display:block}
    pre{background:#0d1117;border:1px solid #30363d;border-radius:6px;padding:1rem;overflow-x:auto;font-size:.8rem;white-space:pre-wrap;word-break:break-word}
    .error-msg{color:#f85149;font-size:.85rem;margin-bottom:.5rem}
  </style>
</head>
<body>
  <h1>flutter_local_ci</h1>
  <p class="meta">
    Generated: ${report.generatedAt.toIso8601String()} &nbsp;|&nbsp;
    Project: ${_esc(report.projectPath)} &nbsp;|&nbsp;
    Total time: ${totalSec}s
  </p>

  <div class="banner $statusClass">$statusText</div>

  <div class="summary">
    <div class="stat passed"><div class="num">${report.passed}</div><div class="label">Passed</div></div>
    <div class="stat failed"><div class="num">${report.failed}</div><div class="label">Failed</div></div>
    <div class="stat skipped"><div class="num">${report.skipped}</div><div class="label">Skipped</div></div>
  </div>

  $checksHtml

  <script>
    document.querySelectorAll('.card-header').forEach(function(h){
      h.addEventListener('click',function(){
        var b=h.nextElementSibling;
        if(b)b.classList.toggle('open');
      });
    });
  </script>
</body>
</html>''';
  }

  String _checkCard(CheckResult result) {
    final badge = 'badge-${result.status.name}';
    final durationSec =
        (result.duration.inMilliseconds / 1000).toStringAsFixed(1);
    final errorHtml = result.errorMessage != null
        ? '<p class="error-msg">${_esc(result.errorMessage!)}</p>'
        : '';
    final outputHtml =
        result.output.isNotEmpty ? '<pre>${_esc(result.output)}</pre>' : '';
    final openClass =
        result.status == CheckStatus.failed ? ' open' : '';

    return '''
  <div class="card">
    <div class="card-header">
      <span class="badge $badge">${result.status.name}</span>
      <span class="card-name">${_esc(result.checkName)}</span>
      <span class="duration">${durationSec}s</span>
    </div>
    <div class="card-body$openClass">
      $errorHtml
      $outputHtml
    </div>
  </div>''';
  }

  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

enum CheckStatus { passed, failed, skipped, warning }

class CheckResult {
  final String checkName;
  final CheckStatus status;
  final String output;
  final Duration duration;
  final String? errorMessage;

  const CheckResult({
    required this.checkName,
    required this.status,
    required this.output,
    required this.duration,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
        'name': checkName,
        'status': status.name,
        'duration_ms': duration.inMilliseconds,
        'output': output,
        'error_message': errorMessage,
      };
}

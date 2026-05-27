/// Result of a single /license/verify call. Mirrors the backend's
/// VerifyLicenseResponseDto shape so it can be built from the raw
/// JSON without an intermediate adapter.
class LicenseResult {
  const LicenseResult({
    required this.valid,
    this.expiresAt,
    this.mode,
    this.daysRemaining,
    this.reason,
  });

  factory LicenseResult.fromJson(Map<String, dynamic> j) => LicenseResult(
        valid: j['valid'] as bool,
        expiresAt: j['expiresAt'] as String?,
        mode: j['mode'] as String?,
        daysRemaining: (j['daysRemaining'] as num?)?.toInt(),
        reason: j['reason'] as String?,
      );

  final bool valid;
  final String? expiresAt;
  final String? mode;
  final int? daysRemaining;
  final String? reason;
}

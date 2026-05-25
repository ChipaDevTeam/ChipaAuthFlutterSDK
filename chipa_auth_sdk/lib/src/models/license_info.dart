enum LicenseStatus { active, trial, expired, suspended, cancelled, unknown }

class LicenseInfo {
  final String id;
  final String userId;
  final String? licenseKey;
  final LicenseStatus status;
  final String plan;
  final String billingCycle;
  final DateTime? expiresAt;

  const LicenseInfo({
    required this.id,
    required this.userId,
    this.licenseKey,
    required this.status,
    required this.plan,
    required this.billingCycle,
    this.expiresAt,
  });

  factory LicenseInfo.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? '';
    return LicenseInfo(
      id: json['id'] as String,
      userId: json['userId'] as String,
      licenseKey: json['licenseKey'] as String?,
      status: LicenseStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => LicenseStatus.unknown,
      ),
      plan: json['plan'] as String? ?? 'free',
      billingCycle: json['billingCycle'] as String? ?? 'monthly',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
    );
  }

  bool get isActive =>
      status == LicenseStatus.active || status == LicenseStatus.trial;
}

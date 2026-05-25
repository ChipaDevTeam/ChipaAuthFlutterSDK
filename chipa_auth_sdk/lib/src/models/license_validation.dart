class LicenseValidation {
  final bool isValid;
  final int? daysUntilExpiry;
  final String message;

  const LicenseValidation({
    required this.isValid,
    this.daysUntilExpiry,
    required this.message,
  });

  factory LicenseValidation.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return LicenseValidation(
      isValid: (data['isValid'] as bool?) ?? false,
      daysUntilExpiry:
          (data['paymentStatus'] as Map?)?['daysUntilExpiry'] as int?,
      message: data['message'] as String? ?? '',
    );
  }
}

import 'chipa_user.dart';
import 'license_info.dart';

class ChipaAuthResult {
  final ChipaUser user;
  final String token;
  final LicenseInfo? license;

  const ChipaAuthResult({
    required this.user,
    required this.token,
    this.license,
  });
}

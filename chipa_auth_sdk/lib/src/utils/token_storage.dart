import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage so the rest of the SDK never touches raw keys.
class TokenStorage {
  static const _tokenKey = 'chipa_auth_token';
  static const _userKey = 'chipa_auth_user';
  static const _licenseKey = 'chipa_auth_license';

  final FlutterSecureStorage _store;

  const TokenStorage([FlutterSecureStorage? store])
      : _store = store ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) =>
      _store.write(key: _tokenKey, value: token);
  Future<String?> loadToken() => _store.read(key: _tokenKey);
  Future<void> saveUser(String json) =>
      _store.write(key: _userKey, value: json);
  Future<String?> loadUser() => _store.read(key: _userKey);
  Future<void> saveLicense(String json) =>
      _store.write(key: _licenseKey, value: json);
  Future<String?> loadLicense() => _store.read(key: _licenseKey);

  Future<void> clear() async {
    await Future.wait([
      _store.delete(key: _tokenKey),
      _store.delete(key: _userKey),
      _store.delete(key: _licenseKey),
    ]);
  }
}

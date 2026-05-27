import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

import '../models/chipa_auth_error.dart';
import '../models/chipa_auth_result.dart';
import '../models/chipa_user.dart';
import '../models/license_info.dart';
import '../models/license_validation.dart';
import '../utils/token_storage.dart';

/// Singleton SDK entry-point.
///
/// Initialise once in main():
///   ChipaAuth.init(
///     apiUrl: 'https://auth.chipatrade.com',
///     apiKey: 'YOUR_CHIPA_LICENSE_KEY',
///   );
class ChipaAuth {
  // ─── Singleton ────────────────────────────────────────────────────────────
  static ChipaAuth? _instance;
  static ChipaAuth get instance {
    assert(_instance != null,
        'Call ChipaAuth.init() before accessing ChipaAuth.instance');
    return _instance!;
  }

  static void init({
    required String apiUrl,
    required String apiKey,
    String callbackScheme = 'chipaauth',
    Duration tokenRefreshBuffer = const Duration(minutes: 5),
    int maxRetries = 3,
  }) {
    _instance = ChipaAuth._(
      apiUrl: apiUrl.endsWith('/')
          ? apiUrl.substring(0, apiUrl.length - 1)
          : apiUrl,
      apiKey: apiKey,
      callbackScheme: callbackScheme,
      tokenRefreshBuffer: tokenRefreshBuffer,
      maxRetries: maxRetries,
    );
  }

  // ─── Fields ───────────────────────────────────────────────────────────────
  final String _apiUrl;
  final String _apiKey;
  final String _callbackScheme;
  final Duration _tokenRefreshBuffer;
  final int _maxRetries;
  final TokenStorage _storage;

  ChipaUser? _currentUser;
  LicenseInfo? _currentLicense;
  String? _currentToken;
  Timer? _refreshTimer;

  final _authState = StreamController<ChipaUser?>.broadcast();

  ChipaAuth._({
    required String apiUrl,
    required String apiKey,
    required String callbackScheme,
    required Duration tokenRefreshBuffer,
    required int maxRetries,
    TokenStorage? storage,
  })  : _apiUrl = apiUrl,
        _apiKey = apiKey,
        _callbackScheme = callbackScheme,
        _tokenRefreshBuffer = tokenRefreshBuffer,
        _maxRetries = maxRetries,
        _storage = storage ?? const TokenStorage();

  // ─── Public getters ───────────────────────────────────────────────────────
  ChipaUser? get currentUser => _currentUser;
  LicenseInfo? get currentLicense => _currentLicense;
  String? get currentToken => _currentToken;
  bool get isSignedIn => _currentUser != null;
  Stream<ChipaUser?> get authStateChanges => _authState.stream;

  // ─── Sign in ──────────────────────────────────────────────────────────────

  Future<ChipaAuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final json = await _post(
        '/api/auth/login', jsonEncode({'email': email, 'password': password}));
    return _handleAuthResponse(json);
  }

  Future<ChipaAuthResult> signInWithIdToken(String idToken) async {
    final json =
        await _post('/api/auth/login', jsonEncode({'idToken': idToken}));
    return _handleAuthResponse(json);
  }

  // ─── Google OAuth (hosted — no Firebase SDK needed) ───────────────────────
  /// The ChipaAuth backend handles the full OAuth exchange.
  /// Opens the system browser, waits for the deep-link callback,
  /// then completes the login with a single /api/auth/login call.
  Future<ChipaAuthResult> signInWithGoogle() =>
      _oauthSignIn('/api/auth/oauth/google/init');

  // ─── GitHub OAuth (hosted — no Firebase SDK needed) ───────────────────────
  Future<ChipaAuthResult> signInWithGithub() =>
      _oauthSignIn('/api/auth/oauth/github/init');

  Future<ChipaAuthResult> _oauthSignIn(String initEndpoint) async {
    // 1. Ask the backend for the OAuth consent-page URL
    final initJson = await _post(
      initEndpoint,
      jsonEncode({'callbackScheme': _callbackScheme}),
    );

    final oauthUrl = initJson['url'] as String?;
    if (oauthUrl == null) throw const ChipaAuthError('No OAuth URL returned');

    // 2. Subscribe to the deep-link stream BEFORE opening the browser so
    //    we can never miss the callback, regardless of how fast it arrives.
    final callbackCompleter = Completer<Uri>();
    final appLinks = AppLinks();
    final sub = appLinks.uriLinkStream.listen((uri) {
      // Accept any URI with our custom scheme — covers both
      // chipaauth://callback?... and chipaauth:///callback?... variants.
      if (uri.scheme == _callbackScheme && !callbackCompleter.isCompleted) {
        callbackCompleter.complete(uri);
      }
    });

    // 3. Open the system browser
    final uri = Uri.parse(oauthUrl);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw ChipaAuthError('Could not open browser: $oauthUrl');
      }
    } catch (e) {
      await sub.cancel();
      rethrow;
    }

    // 4. Wait for the deep-link callback with a cancellable 5-minute timeout
    final timer = Timer(const Duration(minutes: 5), () {
      if (!callbackCompleter.isCompleted) {
        callbackCompleter.completeError(const ChipaAuthError(
            'OAuth timed out — user did not complete sign-in'));
      }
    });

    final Uri deepLink;
    try {
      deepLink = await callbackCompleter.future;
    } finally {
      timer.cancel();
      await sub.cancel();
    }

    final error = deepLink.queryParameters['error'];
    if (error != null) throw ChipaAuthError(error);

    final idToken = deepLink.queryParameters['idToken'];
    if (idToken == null || idToken.isEmpty) {
      throw const ChipaAuthError('No idToken in OAuth callback');
    }

    // 5. Exchange idToken with the backend to get the full session + license
    return signInWithIdToken(idToken);
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  Future<ChipaAuthResult> register({
    required String email,
    required String password,
    String? displayName,
    String? phoneNumber,
  }) async {
    final json = await _post(
      '/api/auth/register',
      jsonEncode({
        'email': email,
        'password': password,
        if (displayName != null) 'displayName': displayName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      }),
    );
    return _handleAuthResponse(json);
  }

  // ─── Token ────────────────────────────────────────────────────────────────

  Future<ChipaUser?> verifyToken(String token) async {
    try {
      final json =
          await _post('/api/auth/verify', jsonEncode({'idToken': token}));
      if (json['success'] == true && json['user'] != null) {
        return ChipaUser.fromJson(json['user'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  /// Restore a previously saved session from secure storage.
  /// Call in main() after ChipaAuth.init() to resume sessions.
  Future<ChipaUser?> restoreSession() async {
    final token = await _storage.loadToken();
    final userJson = await _storage.loadUser();
    if (token == null || userJson == null) return null;

    final user = await verifyToken(token);
    if (user == null) {
      await _storage.clear();
      return null;
    }

    _currentToken = token;
    _currentUser = user;

    final licJson = await _storage.loadLicense();
    if (licJson != null) {
      _currentLicense = LicenseInfo.fromJson(
          jsonDecode(licJson) as Map<String, dynamic>);
    }

    _authState.add(_currentUser);
    _scheduleTokenRefresh(token);
    return user;
  }

  // ─── License ──────────────────────────────────────────────────────────────

  Future<List<LicenseInfo>> getMyLicenses() async {
    _requireSignedIn();
    final json = await _get('/api/licenses/my');
    final list = json['licenses'] as List? ?? [];
    return list.cast<Map<String, dynamic>>().map(LicenseInfo.fromJson).toList();
  }

  Future<LicenseValidation> validateLicense(String licenseKey) async {
    final json = await _post(
        '/api/licenses/validate', jsonEncode({'licenseKey': licenseKey}));
    return LicenseValidation.fromJson(json);
  }

  // ─── Sign out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    _refreshTimer?.cancel();
    _currentUser = _currentLicense = _currentToken = null;
    await _storage.clear();
    _authState.add(null);
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  Future<ChipaAuthResult> _handleAuthResponse(
      Map<String, dynamic> json) async {
    if (json['success'] != true) {
      throw ChipaAuthError(
        json['message'] as String? ?? 'Authentication failed',
        statusCode: 401,
      );
    }

    final user = ChipaUser.fromJson(json['user'] as Map<String, dynamic>);
    final token =
        json['idToken'] as String? ?? json['token'] as String? ?? '';
    final license = json['license'] != null
        ? LicenseInfo.fromJson(json['license'] as Map<String, dynamic>)
        : null;

    _currentUser = user;
    _currentToken = token;
    _currentLicense = license;

    await _storage.saveToken(token);
    await _storage.saveUser(jsonEncode(json['user']));
    if (license != null) {
      await _storage.saveLicense(jsonEncode(json['license']));
    }

    _authState.add(user);
    _scheduleTokenRefresh(token);
    return ChipaAuthResult(user: user, token: token, license: license);
  }

  void _scheduleTokenRefresh(String token) {
    _refreshTimer?.cancel();
    const tokenLifetime = Duration(hours: 1); // Firebase ID tokens last 1 hour
    final refreshIn = tokenLifetime - _tokenRefreshBuffer;
    _refreshTimer = Timer(refreshIn, () {
      _storage.loadToken().then((t) {
        if (t != null) {
          verifyToken(t).then((u) {
            if (u == null) signOut();
          });
        }
      });
    });
  }

  void _requireSignedIn() {
    if (!isSignedIn) {
      throw const ChipaAuthError('Not signed in', statusCode: 401);
    }
  }

  /// All requests include the ChipaLicense key as X-API-Key.
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': _apiKey,
        if (_currentToken != null) 'Authorization': 'Bearer $_currentToken',
      };

  Future<Map<String, dynamic>> _get(String path) =>
      _request('GET', path, null);
  Future<Map<String, dynamic>> _post(String path, String body) =>
      _request('POST', path, body);

  Future<Map<String, dynamic>> _request(
      String method, String path, String? body,
      {int attempt = 0}) async {
    final uri = Uri.parse('$_apiUrl$path');
    try {
      final http.Response response;
      if (method == 'GET') {
        response = await http.get(uri, headers: _headers);
      } else {
        response = await http.post(uri, headers: _headers, body: body);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 500 && attempt < _maxRetries) {
        await Future.delayed(Duration(seconds: 1 << attempt));
        return _request(method, path, body, attempt: attempt + 1);
      }

      if (response.statusCode >= 400) {
        throw ChipaAuthError(
          json['message'] as String? ?? 'Request failed',
          statusCode: response.statusCode,
        );
      }

      return json;
    } on ChipaAuthError {
      rethrow;
    } catch (e) {
      if (attempt < _maxRetries) {
        await Future.delayed(Duration(seconds: 1 << attempt));
        return _request(method, path, body, attempt: attempt + 1);
      }
      throw ChipaAuthError('Network error', cause: e);
    }
  }

  void dispose() {
    _refreshTimer?.cancel();
    _authState.close();
  }
}

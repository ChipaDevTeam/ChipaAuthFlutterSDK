import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'chipa_auth_sdk_method_channel.dart';

abstract class ChipaAuthSdkPlatform extends PlatformInterface {
  /// Constructs a ChipaAuthSdkPlatform.
  ChipaAuthSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static ChipaAuthSdkPlatform _instance = MethodChannelChipaAuthSdk();

  /// The default instance of [ChipaAuthSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelChipaAuthSdk].
  static ChipaAuthSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ChipaAuthSdkPlatform] when
  /// they register themselves.
  static set instance(ChipaAuthSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

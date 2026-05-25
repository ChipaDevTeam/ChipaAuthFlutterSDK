import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'chipa_auth_sdk_platform_interface.dart';

/// An implementation of [ChipaAuthSdkPlatform] that uses method channels.
class MethodChannelChipaAuthSdk extends ChipaAuthSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('chipa_auth_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chipa_auth_sdk/chipa_auth_sdk.dart';
import 'package:chipa_auth_sdk/chipa_auth_sdk_platform_interface.dart';
import 'package:chipa_auth_sdk/chipa_auth_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockChipaAuthSdkPlatform
    with MockPlatformInterfaceMixin
    implements ChipaAuthSdkPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ChipaAuthSdkPlatform initialPlatform = ChipaAuthSdkPlatform.instance;

  test('$MethodChannelChipaAuthSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelChipaAuthSdk>());
  });

  test('getPlatformVersion', () async {
    ChipaAuthSdk chipaAuthSdkPlugin = ChipaAuthSdk();
    MockChipaAuthSdkPlatform fakePlatform = MockChipaAuthSdkPlatform();
    ChipaAuthSdkPlatform.instance = fakePlatform;

    expect(await chipaAuthSdkPlugin.getPlatformVersion(), '42');
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chipa_auth_sdk/chipa_auth_sdk_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelChipaAuthSdk platform = MethodChannelChipaAuthSdk();
  const MethodChannel channel = MethodChannel('chipa_auth_sdk');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}

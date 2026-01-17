import 'package:flutter_test/flutter_test.dart';
import 'package:sk2helper/sk2helper.dart';
import 'package:sk2helper/sk2helper_platform_interface.dart';
import 'package:sk2helper/sk2helper_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSk2helperPlatform
    with MockPlatformInterfaceMixin
    implements Sk2helperPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final Sk2helperPlatform initialPlatform = Sk2helperPlatform.instance;

  test('$MethodChannelSk2helper is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSk2helper>());
  });

  test('getPlatformVersion', () async {
    Sk2helper sk2helperPlugin = Sk2helper();
    MockSk2helperPlatform fakePlatform = MockSk2helperPlatform();
    Sk2helperPlatform.instance = fakePlatform;

    expect(await sk2helperPlugin.getPlatformVersion(), '42');
  });
}

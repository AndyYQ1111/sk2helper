import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sk2helper_platform_interface.dart';

/// An implementation of [Sk2helperPlatform] that uses method channels.
class MethodChannelSk2helper extends Sk2helperPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sk2helper');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sk2helper_method_channel.dart';

abstract class Sk2helperPlatform extends PlatformInterface {
  /// Constructs a Sk2helperPlatform.
  Sk2helperPlatform() : super(token: _token);

  static final Object _token = Object();

  static Sk2helperPlatform _instance = MethodChannelSk2helper();

  /// The default instance of [Sk2helperPlatform] to use.
  ///
  /// Defaults to [MethodChannelSk2helper].
  static Sk2helperPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [Sk2helperPlatform] when
  /// they register themselves.
  static set instance(Sk2helperPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConfig {
  // Android emulator reaches host via 10.0.2.2; real device uses LAN IP.
  static const String _mobileIp = '10.0.2.2';

  static String get serverIp {
    if (kIsWeb) return 'localhost';
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'localhost';
    }
    return _mobileIp;
  }

  static String get baseUrl   => 'http://$serverIp:8080';
  static String get ragUrl    => 'http://$serverIp:3001/api';
  static String get socketUrl => 'http://$serverIp:8080';
}

import 'package:flutter/services.dart';

class BatteryChannel {
  const BatteryChannel();

  static const MethodChannel _channel = MethodChannel(
    'com.example.offline_notes_sync/battery',
  );

  Future<int?> getBatteryLevel() async {
    try {
      return await _channel.invokeMethod<int>('getBatteryLevel');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

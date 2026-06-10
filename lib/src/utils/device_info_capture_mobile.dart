import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Reads hardware identifiers from the host device.
Future<Map<String, dynamic>> captureDeviceDetails() async {
  final plugin = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final info = await plugin.androidInfo;
    final manufacturer = info.manufacturer.trim();
    final model = info.model.trim();
    final label = [manufacturer, model]
        .where((part) => part.isNotEmpty)
        .join(' ');

    return {
      if (model.isNotEmpty) 'device_model': model,
      if (manufacturer.isNotEmpty) 'device_manufacturer': manufacturer,
      if (label.isNotEmpty) 'device_name': label,
    };
  }

  if (Platform.isIOS) {
    final info = await plugin.iosInfo;
    final machine = info.utsname.machine.trim();
    final userName = info.name.trim();

    return {
      if (machine.isNotEmpty) 'device_model': machine,
      if (userName.isNotEmpty) 'device_name': userName,
      'os_version': info.systemVersion,
    };
  }

  return const {};
}

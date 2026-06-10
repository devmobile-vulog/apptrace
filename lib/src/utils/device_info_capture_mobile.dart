import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Reads hardware identifiers from the host device.
Future<Map<String, dynamic>> captureDeviceDetails() async {
  final plugin = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final info = await plugin.androidInfo;
    final manufacturer = info.manufacturer.trim();
    final brand = info.brand.trim();
    final model = info.model.trim();
    final device = info.device.trim();
    final displayModel = model.isNotEmpty ? model : device;
    final label = [
      if (manufacturer.isNotEmpty) manufacturer else brand,
      displayModel,
    ].where((part) => part.isNotEmpty).join(' ');

    return {
      if (displayModel.isNotEmpty) 'device_model': displayModel,
      if (manufacturer.isNotEmpty)
        'device_manufacturer': manufacturer
      else if (brand.isNotEmpty)
        'device_manufacturer': brand,
      if (label.isNotEmpty) 'device_name': label,
      'os_version': info.version.release,
    };
  }

  if (Platform.isIOS) {
    final info = await plugin.iosInfo;
    final machine = info.utsname.machine.trim();
    final userName = info.name.trim();
    final localizedModel = info.localizedModel.trim();

    return {
      if (machine.isNotEmpty) 'device_model': machine,
      if (localizedModel.isNotEmpty) 'device_label': localizedModel,
      if (userName.isNotEmpty) 'device_name': userName,
      'os_version': info.systemVersion,
    };
  }

  return const {};
}

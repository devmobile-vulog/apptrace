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
    final product = info.product.trim();
    final displayModel = model.isNotEmpty
        ? model
        : product.isNotEmpty
            ? product
            : device;
    final resolvedManufacturer = manufacturer.isNotEmpty
        ? manufacturer
        : brand.isNotEmpty
            ? brand
            : '';
    final label = [
      if (resolvedManufacturer.isNotEmpty) resolvedManufacturer,
      displayModel,
    ].where((part) => part.isNotEmpty).join(' ');
    final deviceId = [
      resolvedManufacturer,
      displayModel,
      device,
    ].where((part) => part.isNotEmpty).join('|').toLowerCase();

    return {
      if (deviceId.isNotEmpty) 'device_id': deviceId,
      if (displayModel.isNotEmpty) 'device_model': displayModel,
      if (resolvedManufacturer.isNotEmpty)
        'device_manufacturer': resolvedManufacturer,
      if (label.isNotEmpty) ...{
        'device_name': label,
        'device_label': label,
      },
      'os_version': info.version.release,
    };
  }

  if (Platform.isIOS) {
    final info = await plugin.iosInfo;
    final machine = info.utsname.machine.trim();
    final userName = info.name.trim();
    final localizedModel = info.localizedModel.trim();
    final vendorId = info.identifierForVendor?.trim();

    return {
      if (vendorId != null && vendorId.isNotEmpty)
        'device_id': vendorId
      else if (machine.isNotEmpty)
        'device_id': machine,
      if (machine.isNotEmpty) 'device_model': machine,
      if (localizedModel.isNotEmpty) 'device_label': localizedModel,
      if (userName.isNotEmpty) 'device_name': userName,
      'os_version': info.systemVersion,
    };
  }

  return const {};
}

import 'package:flutter/foundation.dart';

import 'device_info_capture_stub.dart'
    if (dart.library.io) 'device_info_capture_mobile.dart';
import 'platform_details_stub.dart'
    if (dart.library.io) 'platform_details_io.dart';

Map<String, dynamic> _cachedDeviceDetails = const {};
Future<void>? _warmingDeviceDetails;

/// Loads hardware metadata once during [AppTrace.initialize].
Future<void> warmDeviceMetadata() async {
  _warmingDeviceDetails ??= _loadDeviceDetails();
  await _warmingDeviceDetails;
}

Future<void> _loadDeviceDetails() async {
  try {
    _cachedDeviceDetails = await captureDeviceDetails();
  } catch (_) {
    _cachedDeviceDetails = const {};
  }
}

bool _isEmptyMetadataValue(Object? value) {
  if (value == null) {
    return true;
  }
  if (value is String) {
    return value.trim().isEmpty;
  }
  return false;
}

void _putIfEmpty(Map<String, dynamic> target, String key, Object? value) {
  if (_isEmptyMetadataValue(value)) {
    return;
  }
  if (_isEmptyMetadataValue(target[key])) {
    target[key] = value;
  }
}

/// Merges host [userMetadata] with automatic capture fields.
///
/// Sets `platform` when the host app did not provide one (`android`, `ios`, …).
Map<String, dynamic> mergeCaptureMetadata(Map<String, dynamic> userMetadata) {
  if (_cachedDeviceDetails.isEmpty) {
    warmDeviceMetadata();
  }

  final merged = Map<String, dynamic>.from(userMetadata);

  if (!merged.containsKey('platform')) {
    merged['platform'] = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.fuchsia => 'fuchsia',
      TargetPlatform.linux => 'linux',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
    };
  }

  for (final entry in capturePlatformDetails().entries) {
    _putIfEmpty(merged, entry.key, entry.value);
  }

  for (final entry in _cachedDeviceDetails.entries) {
    _putIfEmpty(merged, entry.key, entry.value);
  }

  const hardwareKeys = {
    'device_id',
    'device_model',
    'device_manufacturer',
    'device_name',
    'device_label',
    'os_version',
  };
  for (final key in hardwareKeys) {
    final value = _cachedDeviceDetails[key];
    if (!_isEmptyMetadataValue(value)) {
      merged[key] = value;
    }
  }

  return merged;
}

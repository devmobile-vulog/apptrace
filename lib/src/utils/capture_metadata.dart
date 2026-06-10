import 'package:flutter/foundation.dart';

import 'device_info_capture_stub.dart'
    if (dart.library.io) 'device_info_capture_mobile.dart';
import 'platform_details_stub.dart'
    if (dart.library.io) 'platform_details_io.dart';

Map<String, dynamic> _cachedDeviceDetails = const {};

/// Loads hardware metadata once during [AppTrace.initialize].
Future<void> warmDeviceMetadata() async {
  try {
    _cachedDeviceDetails = await captureDeviceDetails();
  } catch (_) {
    _cachedDeviceDetails = const {};
  }
}

/// Merges host [userMetadata] with automatic capture fields.
///
/// Sets `platform` when the host app did not provide one (`android`, `ios`, …).
Map<String, dynamic> mergeCaptureMetadata(Map<String, dynamic> userMetadata) {
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
    merged.putIfAbsent(entry.key, () => entry.value);
  }

  for (final entry in _cachedDeviceDetails.entries) {
    merged.putIfAbsent(entry.key, () => entry.value);
  }

  return merged;
}

import 'package:flutter/foundation.dart';

import 'platform_details_stub.dart'
    if (dart.library.io) 'platform_details_io.dart';

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

  return merged;
}

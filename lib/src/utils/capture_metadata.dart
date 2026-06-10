import 'package:flutter/foundation.dart';

/// Merges host [userMetadata] with automatic capture fields.
///
/// Sets `platform` when the host app did not provide one (`android`, `ios`, …).
Map<String, dynamic> mergeCaptureMetadata(Map<String, dynamic> userMetadata) {
  if (userMetadata.containsKey('platform')) {
    return Map<String, dynamic>.from(userMetadata);
  }

  final platform = switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.fuchsia => 'fuchsia',
    TargetPlatform.linux => 'linux',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
  };

  return {
    ...userMetadata,
    'platform': platform,
  };
}

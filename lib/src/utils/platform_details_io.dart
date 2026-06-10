import 'dart:io';

/// Native OS details attached to each captured log.
Map<String, dynamic> capturePlatformDetails() {
  return {
    'os_version': Platform.operatingSystemVersion,
    'os_label':
        '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
  };
}

const _sensitiveHeaderNames = {
  'authorization',
  'cookie',
  'set-cookie',
  'x-api-key',
  'api-key',
  'x-auth-token',
  'proxy-authorization',
};

/// Redacts sensitive HTTP header values.
Map<String, String> redactHeaders(
  Map<String, dynamic> headers, {
  bool enabled = true,
}) {
  if (!enabled) {
    return headers.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );
  }

  return headers.map((key, value) {
    final normalizedKey = key.toLowerCase();
    if (_sensitiveHeaderNames.contains(normalizedKey)) {
      return MapEntry(key, '[REDACTED]');
    }
    return MapEntry(key, value?.toString() ?? '');
  });
}

/// Truncates large bodies to keep payloads lightweight.
String? truncateBody(String? body, {required int maxLength}) {
  if (body == null) {
    return null;
  }
  if (body.length <= maxLength) {
    return body;
  }
  return '${body.substring(0, maxLength)}… [truncated]';
}

/// Serializes arbitrary request/response data to a string.
String? serializeBody(Object? data, {required int maxLength}) {
  if (data == null) {
    return null;
  }

  final String serialized;
  if (data is String) {
    serialized = data;
  } else if (data is List<int>) {
    serialized = String.fromCharCodes(data);
  } else {
    serialized = data.toString();
  }

  return truncateBody(serialized, maxLength: maxLength);
}

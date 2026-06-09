/// A single captured HTTP exchange.
class NetworkLog {
  /// Creates a network log entry.
  NetworkLog({
    required this.method,
    required this.url,
    this.statusCode,
    this.requestHeaders = const {},
    this.responseHeaders = const {},
    this.requestBody,
    this.responseBody,
    this.durationMs,
    this.error,
    this.appId,
    this.sessionId,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// HTTP method (GET, POST, …).
  final String method;

  /// Request URL.
  final String url;

  /// Response status code, if available.
  final int? statusCode;

  /// Outgoing request headers.
  final Map<String, String> requestHeaders;

  /// Incoming response headers.
  final Map<String, String> responseHeaders;

  /// Serialized request body.
  final String? requestBody;

  /// Serialized response body.
  final String? responseBody;

  /// Round-trip duration in milliseconds.
  final int? durationMs;

  /// Error message when the request failed.
  final String? error;

  /// Optional application identifier.
  final String? appId;

  /// Optional session identifier.
  final String? sessionId;

  /// Arbitrary metadata attached by the host app.
  final Map<String, dynamic> metadata;

  /// When the exchange was captured.
  final DateTime timestamp;

  /// Converts this log to a Supabase-compatible JSON map.
  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'url': url,
      if (statusCode != null) 'status_code': statusCode,
      'request_headers': requestHeaders,
      'response_headers': responseHeaders,
      if (requestBody != null) 'request_body': requestBody,
      if (responseBody != null) 'response_body': responseBody,
      if (durationMs != null) 'duration_ms': durationMs,
      if (error != null) 'error': error,
      if (appId != null) 'app_id': appId,
      if (sessionId != null) 'session_id': sessionId,
      if (metadata.isNotEmpty) 'metadata': metadata,
      'created_at': timestamp.toUtc().toIso8601String(),
    };
  }
}

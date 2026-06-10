import 'package:http/http.dart' as http;

import '../config/apptrace_config.dart';
import '../models/network_log.dart';
import '../services/log_dispatcher.dart';
import '../utils/capture_metadata.dart';
import '../utils/redactor.dart';

/// Wraps an [http.Client] and captures outgoing traffic for AppTrace.
class AppTraceHttpClient extends http.BaseClient {
  /// Creates a tracing HTTP client.
  AppTraceHttpClient({
    required LogDispatcher dispatcher,
    required AppTraceConfig config,
    http.Client? inner,
  })  : _dispatcher = dispatcher,
        _config = config,
        _inner = inner ?? http.Client();

  final LogDispatcher _dispatcher;
  final AppTraceConfig _config;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!_config.enabled) {
      return _inner.send(request);
    }

    final startedAt = DateTime.now();
    final requestBody = request is http.Request ? request.body : null;

    try {
      final streamedResponse = await _inner.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      _dispatcher.enqueue(
        NetworkLog(
          method: request.method.toUpperCase(),
          url: request.url.toString(),
          statusCode: response.statusCode,
          requestHeaders: redactHeaders(
            request.headers,
            enabled: _config.redactSensitiveHeaders,
          ),
          responseHeaders: redactHeaders(
            response.headers,
            enabled: _config.redactSensitiveHeaders,
          ),
          requestBody: serializeBody(
            requestBody,
            maxLength: _config.maxBodyLength,
          ),
          responseBody: serializeBody(
            response.body,
            maxLength: _config.maxBodyLength,
          ),
          durationMs: DateTime.now().difference(startedAt).inMilliseconds,
          appId: _config.appId,
          sessionId: _config.sessionId,
          metadata: mergeCaptureMetadata(_config.metadata),
        ),
      );

      return http.StreamedResponse(
        Stream.value(response.bodyBytes),
        response.statusCode,
        contentLength: response.bodyBytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (error) {
      _dispatcher.enqueue(
        NetworkLog(
          method: request.method.toUpperCase(),
          url: request.url.toString(),
          requestHeaders: redactHeaders(
            request.headers,
            enabled: _config.redactSensitiveHeaders,
          ),
          requestBody: serializeBody(
            requestBody,
            maxLength: _config.maxBodyLength,
          ),
          durationMs: DateTime.now().difference(startedAt).inMilliseconds,
          error: error.toString(),
          appId: _config.appId,
          sessionId: _config.sessionId,
          metadata: mergeCaptureMetadata(_config.metadata),
        ),
      );
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
  }
}

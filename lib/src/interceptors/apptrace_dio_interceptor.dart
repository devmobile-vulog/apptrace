import 'package:dio/dio.dart';

import '../config/apptrace_config.dart';
import '../models/network_log.dart';
import '../services/log_dispatcher.dart';
import '../utils/capture_metadata.dart';
import '../utils/redactor.dart';

/// Dio interceptor that captures HTTP traffic for AppTrace.
class AppTraceDioInterceptor extends Interceptor {
  /// Creates an interceptor bound to a [LogDispatcher].
  AppTraceDioInterceptor({
    required LogDispatcher dispatcher,
    required AppTraceConfig config,
  })  : _dispatcher = dispatcher,
        _config = config;

  final LogDispatcher _dispatcher;
  final AppTraceConfig _config;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['_apptrace_started_at'] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _capture(
      method: response.requestOptions.method,
      url: response.requestOptions.uri.toString(),
      statusCode: response.statusCode,
      requestHeaders: response.requestOptions.headers,
      responseHeaders: response.headers.map,
      requestBody: response.requestOptions.data,
      responseBody: response.data,
      startedAt: _startedAt(response.requestOptions),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    _capture(
      method: err.requestOptions.method,
      url: err.requestOptions.uri.toString(),
      statusCode: response?.statusCode,
      requestHeaders: err.requestOptions.headers,
      responseHeaders: response?.headers.map ?? const {},
      requestBody: err.requestOptions.data,
      responseBody: response?.data,
      startedAt: _startedAt(err.requestOptions),
      error: err.message ?? err.type.name,
    );
    handler.next(err);
  }

  DateTime? _startedAt(RequestOptions options) {
    return options.extra['_apptrace_started_at'] as DateTime?;
  }

  void _capture({
    required String method,
    required String url,
    required Map<String, dynamic> requestHeaders,
    required Map<String, List<String>> responseHeaders,
    required Object? requestBody,
    required Object? responseBody,
    required DateTime? startedAt,
    int? statusCode,
    String? error,
  }) {
    if (!_config.enabled) {
      return;
    }

    final durationMs = startedAt == null
        ? null
        : DateTime.now().difference(startedAt).inMilliseconds;

    _dispatcher.enqueue(
      NetworkLog(
        method: method.toUpperCase(),
        url: url,
        statusCode: statusCode,
        requestHeaders: redactHeaders(
          requestHeaders,
          enabled: _config.redactSensitiveHeaders,
        ),
        responseHeaders: redactHeaders(
          _flattenResponseHeaders(responseHeaders),
          enabled: _config.redactSensitiveHeaders,
        ),
        requestBody: serializeBody(
          requestBody,
          maxLength: _config.maxBodyLength,
        ),
        responseBody: serializeBody(
          responseBody,
          maxLength: _config.maxBodyLength,
        ),
        durationMs: durationMs,
        error: error,
        appId: _config.appId,
        sessionId: _config.sessionId,
        metadata: mergeCaptureMetadata(_config.metadata),
      ),
    );
  }

  Map<String, dynamic> _flattenResponseHeaders(
    Map<String, List<String>> headers,
  ) {
    return headers.map(
      (key, values) => MapEntry(key, values.join(', ')),
    );
  }
}

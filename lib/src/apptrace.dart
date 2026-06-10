import 'package:dio/dio.dart';

import 'clients/apptrace_http_client.dart';
import 'config/apptrace_config.dart';
import 'interceptors/apptrace_dio_interceptor.dart';
import 'services/log_dispatcher.dart';
import 'setup/supabase_setup.dart';
import 'sinks/supabase_log_sink.dart';
import 'utils/capture_metadata.dart';

/// Entry point for capturing app network traffic and sending it to Supabase.
class AppTrace {
  AppTrace._({
    required AppTraceConfig config,
    required LogDispatcher dispatcher,
  })  : _config = config,
        _dispatcher = dispatcher;

  static AppTrace? _instance;

  final AppTraceConfig _config;
  final LogDispatcher _dispatcher;

  /// Returns the initialized singleton instance.
  static AppTrace get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'AppTrace is not initialized. Call AppTrace.initialize() first.',
      );
    }
    return instance;
  }

  /// Whether [AppTrace.initialize] has been called.
  static bool get isInitialized => _instance != null;

  /// Initializes AppTrace with the given configuration.
  static Future<AppTrace> initialize(
    AppTraceConfig config, {
    bool verifySetup = false,
  }) async {
    if (verifySetup) {
      await verifySupabaseSetup(config);
    }

    await warmDeviceMetadata();

    final existing = _instance;
    if (existing != null) {
      await existing.dispose();
    }

    final dispatcher = LogDispatcher(
      config: config,
      sink: SupabaseLogSink(config),
    );

    _instance = AppTrace._(
      config: config,
      dispatcher: dispatcher,
    );
    return _instance!;
  }

  /// Current configuration.
  AppTraceConfig get config => _config;

  /// Attaches network tracing to a [Dio] instance.
  void attachToDio(Dio dio) {
    dio.interceptors.add(
      AppTraceDioInterceptor(
        dispatcher: _dispatcher,
        config: _config,
      ),
    );
  }

  /// Creates an [http.Client] wrapper that captures traffic.
  AppTraceHttpClient createHttpClient() {
    return AppTraceHttpClient(
      dispatcher: _dispatcher,
      config: _config,
    );
  }

  /// Sends queued logs immediately.
  Future<void> flush() => _dispatcher.flush();

  /// Stops logging and releases resources.
  Future<void> dispose() async {
    await _dispatcher.dispose();
    _instance = null;
  }
}

import 'package:supabase/supabase.dart';

typedef AppTraceErrorHandler = void Function(
  Object error,
  StackTrace stackTrace,
);

/// Configuration for [AppTrace].
class AppTraceConfig {
  /// Creates package configuration.
  const AppTraceConfig({
    required this.supabaseClient,
    this.tableName = 'network_logs',
    this.enabled = true,
    this.appId,
    this.sessionId,
    this.maxBodyLength = 8192,
    this.redactSensitiveHeaders = true,
    this.batchSize = 10,
    this.flushInterval = const Duration(seconds: 5),
    this.metadata = const {},
    this.onError,
  });

  /// Supabase client used to persist logs.
  final SupabaseClient supabaseClient;

  /// Supabase table that stores network logs.
  final String tableName;

  /// When false, traffic is not captured or sent.
  final bool enabled;

  /// Optional application identifier stored on each log row.
  final String? appId;

  /// Optional session identifier stored on each log row.
  final String? sessionId;

  /// Maximum number of characters kept for request/response bodies.
  final int maxBodyLength;

  /// When true, sensitive header values are replaced with `[REDACTED]`.
  final bool redactSensitiveHeaders;

  /// Number of logs sent to Supabase in one insert.
  final int batchSize;

  /// Maximum delay before queued logs are flushed.
  final Duration flushInterval;

  /// Metadata merged into every captured log.
  final Map<String, dynamic> metadata;

  /// Called when log delivery fails. [AppTrace.flush] also rethrows.
  final AppTraceErrorHandler? onError;

  /// Creates a config from Supabase URL and anon key.
  factory AppTraceConfig.fromCredentials({
    required String supabaseUrl,
    required String supabaseAnonKey,
    String tableName = 'network_logs',
    bool enabled = true,
    String? appId,
    String? sessionId,
    int maxBodyLength = 8192,
    bool redactSensitiveHeaders = true,
    int batchSize = 10,
    Duration flushInterval = const Duration(seconds: 5),
    Map<String, dynamic> metadata = const {},
    AppTraceErrorHandler? onError,
  }) {
    return AppTraceConfig(
      supabaseClient: SupabaseClient(supabaseUrl, supabaseAnonKey),
      tableName: tableName,
      enabled: enabled,
      appId: appId,
      sessionId: sessionId,
      maxBodyLength: maxBodyLength,
      redactSensitiveHeaders: redactSensitiveHeaders,
      batchSize: batchSize,
      flushInterval: flushInterval,
      metadata: metadata,
      onError: onError,
    );
  }

  AppTraceConfig copyWith({
    SupabaseClient? supabaseClient,
    String? tableName,
    bool? enabled,
    String? appId,
    String? sessionId,
    int? maxBodyLength,
    bool? redactSensitiveHeaders,
    int? batchSize,
    Duration? flushInterval,
    Map<String, dynamic>? metadata,
    AppTraceErrorHandler? onError,
  }) {
    return AppTraceConfig(
      supabaseClient: supabaseClient ?? this.supabaseClient,
      tableName: tableName ?? this.tableName,
      enabled: enabled ?? this.enabled,
      appId: appId ?? this.appId,
      sessionId: sessionId ?? this.sessionId,
      maxBodyLength: maxBodyLength ?? this.maxBodyLength,
      redactSensitiveHeaders:
          redactSensitiveHeaders ?? this.redactSensitiveHeaders,
      batchSize: batchSize ?? this.batchSize,
      flushInterval: flushInterval ?? this.flushInterval,
      metadata: metadata ?? this.metadata,
      onError: onError ?? this.onError,
    );
  }
}

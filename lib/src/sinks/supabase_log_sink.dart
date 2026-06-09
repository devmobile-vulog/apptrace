import '../config/apptrace_config.dart';
import '../models/network_log.dart';
import 'log_sink.dart';

/// Persists logs to a Supabase table.
class SupabaseLogSink implements LogSink {
  /// Creates a Supabase-backed log sink.
  SupabaseLogSink(this._config);

  final AppTraceConfig _config;

  @override
  Future<void> send(List<NetworkLog> logs) async {
    if (logs.isEmpty) {
      return;
    }

    final payload = logs.map((log) => log.toJson()).toList(growable: false);
    await _config.supabaseClient.from(_config.tableName).insert(payload);
  }

  @override
  Future<void> dispose() async {}
}

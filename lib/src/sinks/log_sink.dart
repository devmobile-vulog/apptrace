import '../models/network_log.dart';

/// Persists captured network logs.
abstract class LogSink {
  /// Sends one or more logs to the backing store.
  Future<void> send(List<NetworkLog> logs);

  /// Releases resources held by the sink.
  Future<void> dispose();
}

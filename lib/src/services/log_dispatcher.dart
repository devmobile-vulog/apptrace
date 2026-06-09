import 'dart:async';

import '../config/apptrace_config.dart';
import '../models/network_log.dart';
import '../sinks/log_sink.dart';

/// Buffers logs and sends them asynchronously in batches.
class LogDispatcher {
  LogDispatcher({
    required AppTraceConfig config,
    required LogSink sink,
  })  : _config = config,
        _sink = sink;

  final AppTraceConfig _config;
  final LogSink _sink;
  final List<NetworkLog> _queue = [];
  Timer? _flushTimer;
  Future<void>? _ongoingFlush;
  bool _isDisposed = false;

  /// Enqueues a log for delivery.
  void enqueue(NetworkLog log) {
    if (!_config.enabled || _isDisposed) {
      return;
    }

    _queue.add(log);
    if (_queue.length >= _config.batchSize) {
      unawaited(flush());
      return;
    }

    _flushTimer ??= Timer(_config.flushInterval, () {
      unawaited(flush());
    });
  }

  /// Sends all queued logs immediately.
  Future<void> flush() async {
    if (_isDisposed || _queue.isEmpty) {
      return;
    }

    if (_ongoingFlush != null) {
      await _ongoingFlush;
      if (_isDisposed || _queue.isEmpty) {
        return;
      }
    }

    _ongoingFlush = _flushNow();
    try {
      await _ongoingFlush;
    } finally {
      _ongoingFlush = null;
    }
  }

  Future<void> _flushNow() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    final batch = List<NetworkLog>.from(_queue);
    _queue.clear();

    try {
      await _sink.send(batch);
    } catch (error, stackTrace) {
      _queue.insertAll(0, batch);
      _config.onError?.call(error, stackTrace);
      if (_queue.isNotEmpty && !_isDisposed) {
        _flushTimer = Timer(_config.flushInterval, () {
          unawaited(flush());
        });
      }
      rethrow;
    }
  }

  /// Stops the dispatcher and flushes pending logs.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _flushTimer?.cancel();
    _flushTimer = null;
    await flush();
    await _sink.dispose();
  }
}

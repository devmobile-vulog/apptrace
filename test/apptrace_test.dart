import 'package:apptrace/apptrace.dart';
import 'package:apptrace/src/utils/redactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('redactor', () {
    test('redacts sensitive headers', () {
      final headers = redactHeaders({
        'Authorization': 'Bearer secret',
        'Content-Type': 'application/json',
      });

      expect(headers['Authorization'], '[REDACTED]');
      expect(headers['Content-Type'], 'application/json');
    });

    test('truncates large bodies', () {
      final body = truncateBody('abcdefghij', maxLength: 5);

      expect(body, 'abcde… [truncated]');
    });
  });

  group('NetworkLog', () {
    test('serializes to Supabase JSON', () {
      final log = NetworkLog(
        method: 'GET',
        url: 'https://example.com',
        statusCode: 200,
        requestHeaders: const {'accept': 'application/json'},
        responseHeaders: const {'content-type': 'application/json'},
        durationMs: 42,
        appId: 'demo',
      );

      final json = log.toJson();

      expect(json['method'], 'GET');
      expect(json['url'], 'https://example.com');
      expect(json['status_code'], 200);
      expect(json['duration_ms'], 42);
      expect(json['app_id'], 'demo');
      expect(json['created_at'], isNotNull);
    });
  });
}

import 'package:supabase/supabase.dart';

import '../config/apptrace_config.dart';

/// Verifies that the configured Supabase table accepts inserts.
Future<void> verifySupabaseSetup(AppTraceConfig config) async {
  try {
    await config.supabaseClient.from(config.tableName).insert({
      'method': 'SETUP',
      'url': 'apptrace://setup-check',
      'request_headers': <String, String>{},
      'response_headers': <String, String>{},
    });
  } on PostgrestException catch (error) {
    if (error.code == 'PGRST205') {
      throw StateError(
        "Supabase table '${config.tableName}' was not found. "
        'Run supabase/setup.sql in the Supabase SQL editor.',
      );
    }

    throw StateError(
      "Unable to insert into Supabase table '${config.tableName}': "
      '${error.message}',
    );
  }
}

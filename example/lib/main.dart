import 'package:apptrace/apptrace.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  Dio? _dio;
  bool _isBootstrapping = true;
  String? _setupError;
  String _status = 'Checking Supabase setup…';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isBootstrapping = true;
      _setupError = null;
      _status = 'Checking Supabase setup…';
    });

    try {
      await AppTrace.initialize(
        AppTraceConfig(
          supabaseClient: Supabase.instance.client,
          appId: 'apptrace-example',
          sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
          metadata: const {'environment': 'example'},
        ),
        verifySetup: true,
      );

      final dio = Dio();
      AppTrace.instance.attachToDio(dio);

      if (!mounted) {
        return;
      }

      setState(() {
        _dio = dio;
        _isBootstrapping = false;
        _status = 'Tap the button to send a traced HTTP request.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _dio = null;
        _isBootstrapping = false;
        _setupError = error.toString();
        _status = 'Supabase is not ready yet.';
      });
    }
  }

  Future<void> _sendRequest(Future<Response<String>> Function(Dio dio) call) async {
    final dio = _dio;
    if (dio == null) {
      return;
    }

    setState(() => _status = 'Sending request…');

    try {
      final response = await call(dio);

      try {
        await AppTrace.instance.flush();
        setState(
          () => _status =
              'HTTP ${response.statusCode} OK and log sent to Supabase.',
        );
      } catch (error) {
        setState(
          () => _status =
              'HTTP ${response.statusCode} OK, but Supabase upload failed: '
              '$error',
        );
      }
    } catch (error) {
      setState(() => _status = 'Request failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSendRequest =
        !_isBootstrapping && _setupError == null && _dio != null;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('AppTrace Example')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isBootstrapping) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
              ],
              if (_setupError != null) ...[
                Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Supabase setup required',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _setupError!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Run supabase/setup.sql in the Supabase SQL editor, '
                          'then tap Retry setup.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _bootstrap,
                  child: const Text('Retry setup'),
                ),
                const SizedBox(height: 16),
              ],
              Text(_status),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: canSendRequest
                        ? () => _sendRequest(
                              (dio) => dio.get<String>(
                                'https://jsonplaceholder.typicode.com/posts/1',
                              ),
                            )
                        : null,
                    child: const Text('GET'),
                  ),
                  FilledButton(
                    onPressed: canSendRequest
                        ? () => _sendRequest(
                              (dio) => dio.post<String>(
                                'https://jsonplaceholder.typicode.com/posts',
                                data: {
                                  'title': 'AppTrace',
                                  'body': 'demo',
                                  'userId': 1,
                                },
                              ),
                            )
                        : null,
                    child: const Text('POST'),
                  ),
                  FilledButton(
                    onPressed: canSendRequest
                        ? () => _sendRequest(
                              (dio) => dio.put<String>(
                                'https://jsonplaceholder.typicode.com/posts/1',
                                data: {'title': 'Updated'},
                              ),
                            )
                        : null,
                    child: const Text('PUT'),
                  ),
                  FilledButton(
                    onPressed: canSendRequest
                        ? () => _sendRequest(
                              (dio) => dio.patch<String>(
                                'https://jsonplaceholder.typicode.com/posts/1',
                                data: {'title': 'Patched'},
                              ),
                            )
                        : null,
                    child: const Text('PATCH'),
                  ),
                  FilledButton(
                    onPressed: canSendRequest
                        ? () => _sendRequest(
                              (dio) => dio.delete<String>(
                                'https://jsonplaceholder.typicode.com/posts/1',
                              ),
                            )
                        : null,
                    child: const Text('DELETE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dio?.close();
    super.dispose();
  }
}

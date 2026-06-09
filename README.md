# AppTrace

Lightweight Flutter package that captures HTTP network traffic from your app
and sends structured logs to a Supabase project.

## Features

- Dio interceptor for automatic request/response capture
- Optional `http.Client` wrapper for apps using `package:http`
- Batched, asynchronous delivery to Supabase
- Sensitive header redaction (`Authorization`, cookies, API keys, …)
- Configurable body truncation to keep payloads small

## Supabase setup

**Required before running the example.** Without this step, HTTP requests succeed
but log uploads fail.

1. Create a Supabase project at [supabase.com](https://supabase.com).
2. Enable the **pg_cron** extension under **Database → Extensions** (needed for
   automatic cleanup).
3. Open **SQL Editor** in the Supabase dashboard.
4. Paste and run the full contents of [`supabase/setup.sql`](supabase/setup.sql).
5. Confirm the `network_logs` table appears under **Table Editor**.
6. Copy your project URL and anon key from **Project Settings → API**.

The setup script also schedules a weekly job that deletes logs older than 7 days.
To run cleanup manually: `select public.apptrace_cleanup_old_network_logs(7);`

The migration creates a `network_logs` table and an RLS policy that allows
anonymous inserts (required when using the anon key from mobile/web clients).

## Getting started

Add the dependency:

```yaml
dependencies:
  apptrace: ^0.0.1
```

Initialize AppTrace once at app startup:

```dart
import 'package:apptrace/apptrace.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);

await AppTrace.initialize(
  AppTraceConfig(
    supabaseClient: Supabase.instance.client,
    appId: 'my-app',
    sessionId: 'session-123',
  ),
  verifySetup: true, // optional: fail fast if the table is missing
);
```

Or initialize with credentials directly:

```dart
await AppTrace.initialize(
  AppTraceConfig.fromCredentials(
    supabaseUrl: 'YOUR_SUPABASE_URL',
    supabaseAnonKey: 'YOUR_SUPABASE_ANON_KEY',
  ),
);
```

## Usage

### Dio

```dart
final dio = Dio();
AppTrace.instance.attachToDio(dio);

final response = await dio.get('https://api.example.com/users');
await AppTrace.instance.flush(); // optional: send immediately
```

### package:http

```dart
final client = AppTrace.instance.createHttpClient();
final response = await client.get(Uri.parse('https://api.example.com/users'));
client.close();
```

### Disable logging

```dart
await AppTrace.initialize(
  AppTraceConfig(
    supabaseClient: Supabase.instance.client,
    enabled: false,
  ),
);
```

## Example app

The [`example/`](example/) app demonstrates Dio integration.

Run it with your Supabase credentials:

```bash
chmod +x scripts/run_example.sh

# Via environment variables
SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  ./scripts/run_example.sh

# Via flags
./scripts/run_example.sh \
  --url https://YOUR_PROJECT.supabase.co \
  --key YOUR_ANON_KEY

# Via example/.env (copy from example/.env.example)
cp example/.env.example example/.env
./scripts/run_example.sh

# Pass extra flutter run args after --
./scripts/run_example.sh -- -d macos
```

## Configuration

| Option | Default | Description |
| --- | --- | --- |
| `tableName` | `network_logs` | Supabase table name |
| `enabled` | `true` | Toggle capture on/off |
| `maxBodyLength` | `8192` | Max characters stored per body |
| `redactSensitiveHeaders` | `true` | Redact auth/cookie headers |
| `batchSize` | `10` | Logs sent per insert |
| `flushInterval` | `5s` | Max delay before batch flush |

## Dashboard

A Flutter web dashboard lives in [`dashboard/`](dashboard/). See
[`dashboard/README.md`](dashboard/README.md) for local run and Vercel deployment.

Quick start:

```bash
cp dashboard/.env.example dashboard/.env
./scripts/run_dashboard.sh
```

Create a Supabase Auth user, then sign in. If logs do not appear, run
[`supabase/dashboard_policies.sql`](supabase/dashboard_policies.sql).

## Additional information

Logs are sent in the background and never block your HTTP calls. Failed
Supabase inserts are retried on the next flush cycle, and [AppTrace.flush]
reports upload errors when called explicitly.

For production, review RLS policies and consider restricting inserts to
authenticated users or service roles depending on your security model.

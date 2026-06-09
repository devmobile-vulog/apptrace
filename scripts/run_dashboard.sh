#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DASHBOARD_DIR="$ROOT/dashboard"
DEFAULT_ENV_FILE="$DASHBOARD_DIR/.env"

usage() {
  cat <<'EOF'
Run the AppTrace dashboard on web (defaults to Chrome).

Usage:
  ./scripts/run_dashboard.sh [options] [-- flutter-run-args]

Options:
  --url <url>     Supabase project URL
  --key <key>     Supabase anon/publishable key
  --env <file>    Load variables from a .env file (default: dashboard/.env)
  -h, --help      Show this help message

Environment variables:
  SUPABASE_URL
  SUPABASE_ANON_KEY
EOF
}

load_env_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    return 0
  fi

  set -a
  # shellcheck disable=SC1090
  source "$file"
  set +a
}

has_flutter_device_arg() {
  local arg
  for arg in "$@"; do
    if [[ "$arg" == "-d" || "$arg" == --device-id=* ]]; then
      return 0
    fi
  done
  return 1
}

SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
ENV_FILE="$DEFAULT_ENV_FILE"
CLI_URL=""
CLI_KEY=""
FLUTTER_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)
      CLI_URL="${2:-}"
      shift 2
      ;;
    --key)
      CLI_KEY="${2:-}"
      shift 2
      ;;
    --env)
      ENV_FILE="${2:-}"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      FLUTTER_ARGS+=("$@")
      break
      ;;
    *)
      FLUTTER_ARGS+=("$1")
      shift
      ;;
  esac
done

load_env_file "$ENV_FILE"

if [[ -n "$CLI_URL" ]]; then
  SUPABASE_URL="$CLI_URL"
fi
if [[ -n "$CLI_KEY" ]]; then
  SUPABASE_ANON_KEY="$CLI_KEY"
fi

if [[ -z "$SUPABASE_URL" || -z "$SUPABASE_ANON_KEY" ]]; then
  echo "Error: SUPABASE_URL and SUPABASE_ANON_KEY are required." >&2
  echo >&2
  usage >&2
  exit 1
fi

if command -v fvm >/dev/null 2>&1; then
  FLUTTER=(fvm flutter)
else
  FLUTTER=(flutter)
fi

cd "$DASHBOARD_DIR"

CMD=("${FLUTTER[@]}" run \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY")

if ((${#FLUTTER_ARGS[@]} > 0)); then
  CMD+=("${FLUTTER_ARGS[@]}")
fi

if ((${#FLUTTER_ARGS[@]} == 0)) || ! has_flutter_device_arg "${FLUTTER_ARGS[@]}"; then
  CMD+=(-d chrome)
fi

exec "${CMD[@]}"

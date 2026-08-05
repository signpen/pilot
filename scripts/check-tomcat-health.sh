#!/usr/bin/env bash
# Copy this script to the Tomcat server, for example:
#   /app/deploy/check-tomcat-health.sh
# Then make it executable:
#   chmod 750 /app/deploy/check-tomcat-health.sh
#
# Usage:
#   check-tomcat-health.sh [url] [initial_delay_sec] [retry_interval_sec] [timeout_sec]
#
# Example:
#   check-tomcat-health.sh http://127.0.0.1:8080/ 15 10 300
#
# Exit codes:
#   0: Tomcat HTTP connector responded with an accepted status.
#   1: No accepted response arrived before the overall timeout.
#   2: Invalid arguments or curl is unavailable.

set -u

url="${1:-http://127.0.0.1:8080/}"
initial_delay_sec="${2:-15}"
retry_interval_sec="${3:-10}"
timeout_sec="${4:-300}"

is_nonnegative_integer() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

for value in "$initial_delay_sec" "$retry_interval_sec" "$timeout_sec"; do
    if ! is_nonnegative_integer "$value"; then
        echo "ERROR: delay and timeout arguments must be non-negative integers." >&2
        exit 2
    fi
done

if [ "$retry_interval_sec" -eq 0 ]; then
    echo "ERROR: retry_interval_sec must be greater than zero." >&2
    exit 2
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is required on the Tomcat server." >&2
    exit 2
fi

response_file="$(mktemp /tmp/tomcat-healthcheck.XXXXXX)"
trap 'rm -f "$response_file"' EXIT

echo "Tomcat health check: ${url}"
echo "Initial delay: ${initial_delay_sec}s, retry interval: ${retry_interval_sec}s, timeout: ${timeout_sec}s"

# WAR expansion and Spring initialization can make the first startup slow.
sleep "$initial_delay_sec"
deadline=$(( $(date +%s) + timeout_sec ))
attempt=1

while true; do
    http_code="$(curl --silent --show-error \
        --output "$response_file" \
        --write-out '%{http_code}' \
        --connect-timeout 3 \
        --max-time 10 \
        "$url" || true)"

    # When no dedicated application health endpoint exists, 401/403/404 still prove
    # that the Tomcat HTTP connector is listening and responding. For an application
    # context URL or /health endpoint, narrow this policy to 2xx/3xx if desired.
    case "$http_code" in
        2*|3*|401|403|404)
            echo "PASS: attempt ${attempt}, HTTP ${http_code}, URL=${url}"
            # Keep Jenkins/server logs bounded even if the URL returns a large HTML page.
            head -c 1024 "$response_file" || true
            printf '\n'
            exit 0
            ;;
    esac

    now=$(date +%s)
    if [ "$now" -ge "$deadline" ]; then
        echo "FAIL: no accepted HTTP response within ${timeout_sec}s." >&2
        echo "Last HTTP code: ${http_code:-curl connection failure}" >&2
        exit 1
    fi

    remaining=$(( deadline - now ))
    echo "WAIT: attempt ${attempt}, HTTP ${http_code:-000}; retrying in ${retry_interval_sec}s (${remaining}s remaining)." >&2
    attempt=$(( attempt + 1 ))
    sleep "$retry_interval_sec"
done

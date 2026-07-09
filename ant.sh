#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export JAVA_HOME="$SCRIPT_DIR/.tools/jdk8"
export PATH="$SCRIPT_DIR/.tools/ant/bin:$JAVA_HOME/bin:$PATH"
exec ant "$@"

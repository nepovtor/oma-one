#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo 'Running OMA ONE deterministic verification suite...'
node --test tests/proof-engine.test.mjs tests/proof-api.test.mjs tests/engine.test.mjs tests/ios-native-static.test.mjs tests/ui-static.test.mjs
node scripts/generate-evidence.mjs
echo 'Opening DEMO-only lab at http://localhost:8790'
node proof-server.mjs

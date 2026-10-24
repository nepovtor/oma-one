#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo 'Running OMA ONE deterministic verification suite...'
npm run test:proof
npm run evidence:report
echo 'Opening DEMO-only lab at http://localhost:8790'
npm run evidence

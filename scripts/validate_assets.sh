#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCES_DIR="${ROOT_DIR}/Sources/CafeVeloz/Resources"
INDEX_FILE="${RESOURCES_DIR}/assets_index.json"

if [ ! -f "${INDEX_FILE}" ]; then
    echo "[validate_assets] ERROR: assets_index.json not found at ${INDEX_FILE}"
    exit 1
fi

MISSING=0

while IFS= read -r rel_path; do
    full_path="${RESOURCES_DIR}/${rel_path}"
    if [ ! -f "${full_path}" ]; then
        echo "[validate_assets] MISSING: ${rel_path}"
        MISSING=$((MISSING + 1))
    fi
done < <(python3 -c "
import json, sys
with open('${INDEX_FILE}') as f:
    index = json.load(f)
for asset in index['assets']:
    for file_entry in asset.get('files', []):
        print(file_entry['path'])
")

if [ "${MISSING}" -gt 0 ]; then
    echo "[validate_assets] ERROR: ${MISSING} asset(s) missing"
    exit 1
fi

echo "[validate_assets] OK — all assets present"

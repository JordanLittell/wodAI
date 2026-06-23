#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Fetching schema from localhost:3000..."
./apollo-ios-cli fetch-schema --path apollo-codegen-config.json

echo "Generating Swift types..."
./apollo-ios-cli generate --path apollo-codegen-config.json

echo "Done. Build in Xcode (Cmd+B) to pick up changes."

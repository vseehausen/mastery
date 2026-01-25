#!/bin/bash
# Full release build with dylib bundling
# This handles the cargo build + path fixup + tauri bundle sequence

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DESKTOP_DIR="$(dirname "$SCRIPT_DIR")"
TAURI_DIR="$DESKTOP_DIR/src-tauri"

cd "$DESKTOP_DIR"

echo "=== Step 1: Bundle dylibs from homebrew ==="
bash "$TAURI_DIR/scripts/bundle-dylibs.sh"

echo ""
echo "=== Step 2: Build frontend ==="
pnpm build

echo ""
echo "=== Step 3: Build Rust binary ==="
cd "$TAURI_DIR"
cargo build --release

echo ""
echo "=== Step 4: Fix binary dylib paths ==="
bash "$TAURI_DIR/scripts/fix-binary-paths.sh"

echo ""
echo "=== Step 5: Create app bundle ==="
cd "$DESKTOP_DIR"
# Use tauri CLI directly for bundling only
CI=false npx tauri bundle

echo ""
echo "=== Build complete! ==="
echo "App bundle: $TAURI_DIR/target/release/bundle/macos/Mastery.app"

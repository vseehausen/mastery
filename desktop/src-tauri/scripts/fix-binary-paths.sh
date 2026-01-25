#!/bin/bash
# Fix dylib paths in the release binary before bundling
# This must run after cargo build but before tauri bundle

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAURI_DIR="$(dirname "$SCRIPT_DIR")"
LIBS_DIR="$TAURI_DIR/libs"
BINARY="$TAURI_DIR/target/release/desktop"

if [ ! -f "$BINARY" ]; then
    echo "Release binary not found, skipping path fixup"
    exit 0
fi

if [ ! -f "$LIBS_DIR/.brew_libmtp_path" ]; then
    echo "Brew path not found, skipping path fixup"
    exit 0
fi

BREW_LIBMTP=$(cat "$LIBS_DIR/.brew_libmtp_path")

echo "Fixing dylib paths in release binary..."
echo "  Binary: $BINARY"
echo "  Homebrew libmtp: $BREW_LIBMTP"

# Change the reference from homebrew to bundled framework
install_name_tool -change \
    "$BREW_LIBMTP" \
    "@executable_path/../Frameworks/libmtp.9.dylib" \
    "$BINARY"

# Also try Intel path just in case
install_name_tool -change \
    "/usr/local/opt/libmtp/lib/libmtp.9.dylib" \
    "@executable_path/../Frameworks/libmtp.9.dylib" \
    "$BINARY" 2>/dev/null || true

echo "Binary paths fixed!"
otool -L "$BINARY" | grep -E "(mtp|Frameworks)" || true

#!/bin/bash
# Bundle libmtp and libusb dylibs for macOS distribution
# These are copied and patched so users don't need homebrew

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAURI_DIR="$(dirname "$SCRIPT_DIR")"
LIBS_DIR="$TAURI_DIR/libs"

# Homebrew paths (arm64)
LIBMTP_SRC="/opt/homebrew/opt/libmtp/lib/libmtp.9.dylib"
LIBUSB_SRC="/opt/homebrew/opt/libusb/lib/libusb-1.0.0.dylib"
BREW_LIBMTP="/opt/homebrew/opt/libmtp/lib/libmtp.9.dylib"
BREW_LIBUSB="/opt/homebrew/opt/libusb/lib/libusb-1.0.0.dylib"

# Check for Intel Mac
if [ ! -f "$LIBMTP_SRC" ]; then
    LIBMTP_SRC="/usr/local/opt/libmtp/lib/libmtp.9.dylib"
    LIBUSB_SRC="/usr/local/opt/libusb/lib/libusb-1.0.0.dylib"
    BREW_LIBMTP="/usr/local/opt/libmtp/lib/libmtp.9.dylib"
    BREW_LIBUSB="/usr/local/opt/libusb/lib/libusb-1.0.0.dylib"
fi

if [ ! -f "$LIBMTP_SRC" ]; then
    echo "Error: libmtp not found. Install with: brew install libmtp"
    exit 1
fi

echo "Bundling dylibs from homebrew..."

# Create libs directory
mkdir -p "$LIBS_DIR"

# Remove existing dylibs (they may be read-only after install_name_tool)
rm -f "$LIBS_DIR/libmtp.9.dylib" "$LIBS_DIR/libusb-1.0.0.dylib"

# Copy dylibs
cp "$LIBMTP_SRC" "$LIBS_DIR/libmtp.9.dylib"
cp "$LIBUSB_SRC" "$LIBS_DIR/libusb-1.0.0.dylib"

# Ensure writable for install_name_tool
chmod +w "$LIBS_DIR/libmtp.9.dylib" "$LIBS_DIR/libusb-1.0.0.dylib"

# Fix libmtp to use bundled libusb (use @loader_path for dylib-to-dylib reference)
install_name_tool -change "$BREW_LIBUSB" "@loader_path/libusb-1.0.0.dylib" "$LIBS_DIR/libmtp.9.dylib" 2>/dev/null || true
install_name_tool -change "/usr/local/opt/libusb/lib/libusb-1.0.0.dylib" "@loader_path/libusb-1.0.0.dylib" "$LIBS_DIR/libmtp.9.dylib" 2>/dev/null || true

# Fix the install names to use @executable_path for app bundle
install_name_tool -id "@executable_path/../Frameworks/libmtp.9.dylib" "$LIBS_DIR/libmtp.9.dylib"
install_name_tool -id "@executable_path/../Frameworks/libusb-1.0.0.dylib" "$LIBS_DIR/libusb-1.0.0.dylib"

# Also fix libmtp's reference to libusb for the Frameworks path
install_name_tool -change "@loader_path/libusb-1.0.0.dylib" "@executable_path/../Frameworks/libusb-1.0.0.dylib" "$LIBS_DIR/libmtp.9.dylib" 2>/dev/null || true

echo "Dylibs bundled to: $LIBS_DIR"
echo "  - libmtp.9.dylib"
echo "  - libusb-1.0.0.dylib"

# Store brew paths for post-build fixup
echo "$BREW_LIBMTP" > "$LIBS_DIR/.brew_libmtp_path"

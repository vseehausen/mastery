# Mastery Desktop

Tauri desktop application for importing Kindle vocabulary.

## Prerequisites (Development Only)

Users don't need to install anything - the app bundles all dependencies.

For development, install:
```bash
brew install libmtp
```

## Development

```bash
pnpm install
pnpm tauri dev
```

## Release Build

```bash
bash scripts/build-release.sh
```

This creates:
- `src-tauri/target/release/bundle/macos/Mastery.app`
- `src-tauri/target/release/bundle/dmg/Mastery_0.1.0_aarch64.dmg`

The build script bundles `libmtp` and `libusb` dylibs so users don't need homebrew.

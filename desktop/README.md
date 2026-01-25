# Mastery Desktop

Tauri desktop application for importing Kindle vocabulary.

## Features

- Pure Rust MTP implementation (no external dependencies)
- Automatic Kindle detection
- vocab.db sync with admin password prompt

## Development

```bash
pnpm install
pnpm tauri dev
```

## Release Build

```bash
pnpm tauri build
```

Creates:
- `src-tauri/target/release/bundle/macos/Mastery.app`
- `src-tauri/target/release/bundle/dmg/Mastery_0.1.0_aarch64.dmg`

No external dependencies needed - pure Rust binary.

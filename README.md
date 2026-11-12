# Code Locker

A tiny Mac app for two-factor login codes. Like Google Authenticator, on your desktop.

- Add an account with its secret key, or paste an `otpauth://` link.
- Click a row to copy the code.
- Right-click a row to delete it.
- Secrets are stored in the macOS Keychain.

Built with SwiftUI. No outside libraries. Needs macOS 15 or newer.

## Install

```bash
bin/deploy
```

This builds the production app, puts it in `/Applications`, and launches it.

Signing uses a Developer ID certificate. To build it yourself, change
`DEVELOPMENT_TEAM` in the Xcode project to your own team.

## Develop

Open `CodeLocker.xcodeproj` and press ⌘R. Debug builds are a separate app
("Code Locker Debug") with their own accounts and an orange strip at the bottom.

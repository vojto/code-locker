# Code Locker

A tiny Mac app for two-factor login codes that you can lock away for a while.

It is for accounts you want to stay out of most of the time. You keep a way
back in, but not in a weak moment.

Website: [rinik.net/code-locker](https://rinik.net/code-locker)

## Download

**[Download Code Locker](https://github.com/vojto/code-locker/releases/latest/download/Code-Locker.zip)**

Needs macOS 15 or newer on Apple silicon.

Unzip it and drag Code Locker to your Applications folder. It keeps itself up
to date after that.

## What it does

- Add an account with its secret key, or paste an `otpauth://` link.
- Click a row to copy the code.
- Right-click a row and choose Lock… to lock it for minutes, hours, days or weeks.
- While it is locked, nothing on your Mac can unlock it. When the time has
  passed, it opens by itself.
- Lock it again any time. It suggests the same period as last time.

## How the lock works

A locked secret is saved with [time-lock encryption](https://docs.drand.love/docs/timelock-encryption/).
The key that opens it is published by the public [drand](https://drand.love) network
at the moment you picked. Before that, the key does not exist anywhere. So reading
the app's files, changing the Mac's clock or rebuilding the app does not help.

An unlocked secret is saved as plain text.

Everything lives in one file, `accounts.json`, in the app's private iCloud
folder. If you lose your Mac, install the app on a new one, sign in to iCloud,
and your accounts come back. Locked ones still open on time.

Things to know:

- A lock cannot be undone or shortened. Check the date before you click Lock.
- The app needs internet to unlock.
- Unlocked secrets sit in iCloud as plain text. Turn on Advanced Data
  Protection if you want only your own devices to be able to read them.
- An old backup of the file (Time Machine) can hold a secret from when it was
  unlocked.
- Don't keep the setup key anywhere else, or the lock is pointless.
- Very long locks depend on drand still running when they end.
- The time-lock library ([tlock](https://github.com/thibmeu/tlock-rs)) has not
  been audited.

## Build from source

Needs macOS 15 or newer on Apple silicon, Xcode, and [Rust](https://rustup.rs).

```bash
bin/deploy
```

This builds the production app, puts it in `/Applications`, and launches it.

Signing uses a Developer ID certificate and a provisioning profile named
"Code Locker Developer ID" that allows iCloud. To build it yourself, change
`DEVELOPMENT_TEAM`, the bundle ID and the iCloud container to your own.

## Releases

Updates use [Sparkle 2](https://sparkle-project.org/). The app reads a signed feed from
[GitHub Pages](https://vojto.github.io/code-locker/appcast.xml) (the `gh-pages` branch)
and downloads the zip from GitHub Releases. Debug builds never start the updater.

To release, bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the Xcode
project, commit and push, then:

```bash
bin/release            # optional: build the notarized zip and the feed locally
```

```bash
bin/release --publish  # also create the GitHub release and push the feed
```

It needs the [asc](https://github.com/rudrankriyam/App-Store-Connect-CLI) tool signed
in with an App Store Connect API key, a signed-in `gh`, and the Sparkle private key in
the login Keychain under the account `code-locker`. Its public half is `SUPublicEDKey`
in `CodeLocker/Info.plist`. To move the key to another Mac, export it with Sparkle's
`generate_keys --account code-locker -x <file>` and import it with `-f <file>`. Keep
that file out of the repository.

## Develop

Open `CodeLocker.xcodeproj` and press ⌘R. Debug builds are a separate app
("Code Locker Debug") with an orange strip at the bottom. They keep their
accounts in a local file, not in iCloud. Lock something for 1 minute to watch
the whole cycle.

The app is SwiftUI. The time-lock maths is a small Rust library in `Timelock/`,
built automatically by `bin/build-timelock`.

## License

MIT. See [LICENSE](LICENSE).

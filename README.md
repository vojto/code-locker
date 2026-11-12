# Code Locker

A tiny Mac app for two-factor login codes that only shows them on Sundays.

It is for accounts you want to stay out of most of the time. You keep a way
back in, but not in a weak moment.

- Add an account with its secret key, or paste an `otpauth://` link.
- On Sundays, click a row to copy the code.
- On other days the codes are locked, and nothing on your Mac can unlock them.

## How the lock works

Each secret is saved with [time-lock encryption](https://docs.drand.love/docs/timelock-encryption/).
The key that opens it is published by the public [drand](https://drand.love) network
on Sunday at midnight. Before that, the key does not exist anywhere. So reading
the app's files, changing the Mac's clock or rebuilding the app does not help.

When Sunday ends, the app locks everything again for the next Sunday. It has to
be running to do that, so it starts at login and keeps running when you close
its window.

Things to know:

- The app needs internet to unlock.
- On a Sunday the secrets are readable. That is the point.
- If the app does not run at all after a Sunday, the saved file stays openable
  until the next time it runs.
- Don't keep the setup key anywhere else, or the lock is pointless.
- The time-lock library ([tlock](https://github.com/thibmeu/tlock-rs)) has not
  been audited.

## Install

Needs macOS 15 or newer, Xcode, and [Rust](https://rustup.rs).

```bash
bin/deploy
```

This builds the production app, puts it in `/Applications`, and launches it.

Signing uses a Developer ID certificate. To build it yourself, change
`DEVELOPMENT_TEAM` in the Xcode project to your own team.

## Develop

Open `CodeLocker.xcodeproj` and press ⌘R. Debug builds are a separate app
("Code Locker Debug") with their own accounts and an orange strip at the bottom.
They open for 1 minute in every 3, so you can watch the whole lock cycle.

The app is SwiftUI. The time-lock maths is a small Rust library in `Timelock/`,
built automatically by `bin/build-timelock`.

# FiestaBoard for iPhone

A small iPhone app for a [FiestaBoard](https://github.com/Fiestaboard/FiestaBoard)
install, in the look of Vestaboard's own app.

- **The board live on top**: "Live on My Board", what it shows and since
  when. Tap it for it large, with whether it is paused or follows its
  schedule, and to copy it into a new message, keep it as a favorite or share it.
- **History, Favorites and Drafts** below, as cards: who put a message there
  and when, the ribbon to keep it as a favorite, and a bar to copy it into a
  new message, send it again, share it, or delete it. Sort them by recent or
  oldest, and by who sent them.
- **Writing a message** with the round button: the board above shows where
  the text will land as you type, the colour tiles below put one in, and
  Send says whether it reached the board or why not — a paused board, or one
  in its quiet time, which holds it until that ends. Save Draft, next to
  Send, keeps it for later.

FiestaBoard keeps no history, favorites or drafts, so the app keeps them on
the iPhone: History is what you sent from the app ("You") and what the board
showed while the app was open ("FiestaBoard").

It uses FiestaBoard's public API, version 1 (`/api/v1`), and nothing of the
web UI's own.

## What it needs

- FiestaBoard reachable from where the iPhone is, in one of two ways:
  - **At home, or through a VPN**: its address on the home network,
    `10.0.1.10:4420` say, over plain http. From away, a VPN such as
    WireGuard or Tailscale that reaches the home network makes the same
    address work. The first time, iOS asks whether the app may use the local
    network; allow it.
  - **From anywhere**: an **https://** address, behind a reverse proxy with a
    certificate, say.

  Plain http is only taken for an address that cannot be reached from the
  internet: 10.x, 172.16–31.x, 192.168.x, 100.64–127.x (Tailscale's range),
  a `.local` name, a name without a dot, or a private IPv6 address. Anything
  else has to be https, as the token goes with every request. An address
  typed without `http://` or `https://` gets the one that fits.
- An **API token**: in FiestaBoard, **Settings → AI**. It opens the whole
  API, so it is kept in the iPhone's Keychain and only sent to the address
  set in the app. Keep FiestaBoard's login switched on wherever it can be
  reached from the internet.

On first start the app asks for both, tries them, and keeps them only once
FiestaBoard has answered. The gear button changes them later.

## Building

Open `FiestaBoard.xcodeproj` in Xcode 27 or later, choose your team under
**Signing & Capabilities**, and run it on an iPhone. iOS 18 or later. Not on
the App Store.

The files in `FiestaBoard/` are the project: Xcode picks up whatever is in
the folder.

A debug build started with the argument `-demo` shows sample content
without a FiestaBoard, and with `-demoCompose` too, the compose screen.

## The icon

The app icon is FiestaBoard's own taco (`fiesta-icon.png` in the FiestaBoard
repository, MIT licence), on white. `tools/make-icon.swift` makes it:

```sh
swift tools/make-icon.swift <path to fiesta-icon.png> FiestaBoard/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

## Licence

MIT, see [LICENSE](LICENSE). The icon is FiestaBoard's, under its own MIT
licence. This app is not made by the FiestaBoard project.

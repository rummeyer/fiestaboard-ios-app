# FiestaBoard for iPhone

A small iPhone app for a [FiestaBoard](https://github.com/Fiestaboard/FiestaBoard)
install: it shows what the board shows, and sends it a message. Nothing else.

- **The board** as it looks: its characters and colour tiles, read again every
  15 seconds while the app is open, and on pulling down. With more than one
  board, the grid button picks one. Below it, whether the board is paused,
  until when a timed message stays, or whether it follows its schedule.
- **A message**, word-wrapped by FiestaBoard to the board. The app says whether
  it reached the board, or why not: a paused board, or one in its quiet time,
  which holds it until that ends.

It uses FiestaBoard's public API, version 1 (`/api/v1`), and nothing of the
web UI's own.

## What it needs

- FiestaBoard reachable over **HTTPS** from where the iPhone is: behind a
  reverse proxy with a certificate, say. The app talks to nothing else.
- **Login switched on** in FiestaBoard, as for anything on the internet, and
  an **API token**: in FiestaBoard, **Settings → AI**. The token opens the
  whole API, so it is kept in the iPhone's Keychain and only sent to the
  address set in the app.

On first start the app asks for both, tries them, and keeps them only once
FiestaBoard has answered. The gear button changes them later.

## Building

Open `FiestaBoard.xcodeproj` in Xcode 27 or later, choose your team under
**Signing & Capabilities**, and run it on an iPhone. iOS 18 or later. Not on
the App Store.

The files in `FiestaBoard/` are the project: Xcode picks up whatever is in
the folder.

## The icon

The app icon is FiestaBoard's own taco (`fiesta-icon.png` in the FiestaBoard
repository, MIT licence), on white. `tools/make-icon.swift` makes it:

```sh
swift tools/make-icon.swift <path to fiesta-icon.png> FiestaBoard/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

## Licence

MIT, see [LICENSE](LICENSE). The icon is FiestaBoard's, under its own MIT
licence. This app is not made by the FiestaBoard project.

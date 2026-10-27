# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [semantic versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- FiestaBoard's look: its colours from its web UI, light or dark as the
  iPhone is, its orange for whatever is primary or chosen, Archivo for words
  and Spline Sans Mono for the board, Lucide's icons as in its web UI, and
  the board drawn as FiestaBoard draws it.
- The board live on a card on top, large on tapping it, read again every 15
  seconds while the app is open and on pulling down, with a picker for more
  than one board; whether it is paused, until when a timed message stays, or
  whether it follows its schedule.
- History, Favorites and Drafts as cards, with the ribbon for a favorite and
  a bar to copy into a new message, send again, share or delete; sorting by
  recent or oldest and by sender. Kept on the iPhone, as FiestaBoard keeps
  none: what was sent from the app, and what the board showed while it was open.
- Writing a message with the board above it showing where the text lands,
  laid out as FiestaBoard does, how many tiles it takes, the colour tiles to
  put in, Save Draft beside Send, and whether it reached the board: sent,
  held until the board's quiet time ends, or FiestaBoard's reason for not.
- Settings for FiestaBoard's address and an API token, tried before they are
  kept; the token in the Keychain. https:// from anywhere, or plain http://
  to an address on the home network or reached through a VPN — private IPv4
  and IPv6 addresses, 100.64–127.x as Tailscale uses, .local names and names
  without a dot — and nowhere else.
- Labels on one line at any text size.
- FiestaBoard's own taco as the app icon, on white.
- `-demo`, `-demoLive`, `-demoCompose` and `-demoSettings` in a debug build:
  sample content without a FiestaBoard, apart from the real history.
- README with screenshots, and how to reach FiestaBoard at home, through a
  VPN, or from anywhere over HTTPS with Caddy; how to put the app on an iPhone.

[Unreleased]: https://github.com/rummeyer/fiestaboard-ios-app/commits/main

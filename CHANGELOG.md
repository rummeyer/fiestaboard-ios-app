# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [semantic versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Tips, in Settings under Donation: two coffees through In-App Purchase,
  and a StoreKit configuration to try them from Xcode.
- Buy Me a Coffee in the README.

### Removed

- The link to the source code, in Settings under About.

## [1.0.0] - 2026-10-27

The first release.

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
- A visual editor beside the text: the board as a canvas, painted with a
  colour or the eraser by tapping or dragging, letters typed from the tile
  chosen, undo and redo, sent tile for tile. Text carries over both ways;
  visual drafts and messages copied from what the board showed open in it.
- How each board looks, in Settings: a white board or a black one, and
  whether its code 62 is a heart or a degree sign — FiestaBoard's API does
  not say. On a white board the white and black tiles show the other way
  round, as FiestaBoard draws them, and the colour tiles to put in follow.
- Settings in groups — Connection, Boards, Demo, About with the version and
  a link to the source — without long explanations under the fields.
- Settings for FiestaBoard's address and an API token, tried before they are
  kept; the token in the Keychain. https:// from anywhere, or plain http://
  to an address on the home network or reached through a VPN — private IPv4
  and IPv6 addresses, 100.64–127.x as Tailscale uses, .local names and names
  without a dot — and nowhere else.
- A message for 15 minutes, an hour, 4 or 8 hours, held against the
  schedule or carousel and then gone by itself; until the next refresh by
  default. The live card says until when, and Back to the schedule ends it
  sooner.
- Every board FiestaBoard drives, picked in the row of boards on top, each drawn as it
  looks: a split-flap board with its flaps, an LED panel lit on black.
  History per board; Favorites and Drafts the same for all, sent to any.
- Add demo board, in Settings: a board simulated in the app, beside
  FiestaBoard's or alone without one, that takes messages as FiestaBoard does
  and keeps what it shows; a Demo tag on the live card.
- English, German, French and Spanish, as the iPhone is set, with
  FiestaBoard's own names for its menus in each.
- Labels on one line at any text size.
- FiestaBoard's own taco as the app icon, on white.
- `-demo`, `-demoLive`, `-demoCompose` and `-demoSettings` in a debug build:
  sample content without a FiestaBoard, apart from the real history.
- README with screenshots, and how to reach FiestaBoard at home, through a
  VPN, or from anywhere over HTTPS with Caddy; how to put the app on an iPhone.

[Unreleased]: https://github.com/rummeyer/fiestaboard-ios-app/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/rummeyer/fiestaboard-ios-app/releases/tag/v1.0.0

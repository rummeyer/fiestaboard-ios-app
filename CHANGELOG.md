# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [semantic versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- README: what the app is for — a replacement for Vestaboard's own app, and
  with it Vestaboard's cloud — screenshots, and how to reach FiestaBoard at
  home, through a VPN, or from anywhere over HTTPS with Caddy; how to put it
  on an iPhone.
- `-demoLive` and `-demoSettings`, and sample content apart from the real history.
- The look of Vestaboard's own app: the board live on a white card on top,
  large on tapping it; History, Favorites and Drafts as light cards with the
  ribbon for a favorite and a bar to copy, send again, share or delete;
  sorting by recent or oldest and by sender; the round button to write.
- Writing a message with the board above it showing where the text lands,
  laid out as FiestaBoard does, how many tiles it takes, the colour tiles to
  put in, and Save Draft beside Send.
- History, favorites and drafts kept on the iPhone, as FiestaBoard keeps none.
- `-demo` and `-demoCompose` in a debug build: sample content without a FiestaBoard.
- The board as it looks: its characters and colour tiles, read again every
  15 seconds while the app is open and on pulling down, with a picker for
  more than one board. Below it, whether it is paused, until when a timed
  message stays, or whether it follows its schedule.
- A message to the board, and whether it reached it: sent, held until the
  board's quiet time ends, or FiestaBoard's reason for not sending it.
- Settings for the server's address and an API token, tried before they
  are kept; the token in the Keychain. https:// from anywhere, or plain
  http:// to an address on the home network or reached through a VPN —
  private IPv4 and IPv6 addresses, 100.64–127.x as Tailscale uses, .local
  names and names without a dot — and nowhere else.
- FiestaBoard's own taco as the app icon, on white.

[Unreleased]: https://github.com/rummeyer/fiestaboard-ios-app/commits/main

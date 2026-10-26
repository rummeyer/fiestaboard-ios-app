# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [semantic versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

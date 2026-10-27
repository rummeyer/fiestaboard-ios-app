<p align="center">
  <img src="docs/icon.png" alt="The app icon: FiestaBoard's pixel taco" width="128">
</p>

<h1 align="center">FiestaBoard for iPhone</h1>

<p align="center">
  <a href="https://buymeacoffee.com/rummeyer"><img src="https://img.shields.io/badge/donate-Buy%20Me%20a%20Coffee-yellow" alt="Buy Me a Coffee"></a>
</p>

<p align="center">
  Your <a href="https://github.com/Fiestaboard/FiestaBoard">FiestaBoard</a> in your pocket, in FiestaBoard's own look:<br>
  <b>what your board shows</b>, live, and <b>a message to it</b> in a few taps — at home, through a VPN, or from anywhere.
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/home-dark.png">
    <img src="docs/screenshots/home-light.png" alt="Home: the row of boards on top, the board live on a card, then History, Favorites and Drafts, with message cards below and the orange button to write" width="200">
  </picture>
  &nbsp;
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/clock-dark.png">
    <img src="docs/screenshots/clock-light.png" alt="A second board, an LED pixel clock, chosen in the row of boards on top and drawn lit on black, with its own history" width="200">
  </picture>
  &nbsp;
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/compose-dark.png">
    <img src="docs/screenshots/compose-light.png" alt="Writing a message: the board above showing where the text lands, the text, how long it shows and 19/45 tiles, Cancel, Clear and the orange Send in one row, and the colour tiles" width="200">
  </picture>
  &nbsp;
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/visual-dark.png">
    <img src="docs/screenshots/visual-light.png" alt="The visual editor: the board drawn tile by tile, COFFEE IS READY between two rainbows, undo and redo, and below the colours, the eraser and the letters" width="200">
  </picture>
  &nbsp;
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/settings-dark.png">
    <img src="docs/screenshots/settings-light.png" alt="The first start: Connection, with FiestaBoard's address and the API token, and Demo, to add the demo board" width="200">
  </picture>
</p>

---

## Why

[FiestaBoard](https://github.com/Fiestaboard/FiestaBoard) runs your display on your own network — a split-flap board, an LED matrix, a TV — from your own pages, schedules and plugins. This app puts it in your pocket: no account somewhere else, no cloud in between. It talks only to your FiestaBoard, and your history, favorites and drafts stay on your iPhone.

## What it does

**The board, live.** On top, a card shows what your board shows right now and since when, read again every 15 seconds while the app is open and on pulling down. Tap it for the board large: whether it is paused or follows its schedule, and buttons to copy the message into a new one, keep it as a favorite or share it.

**History, Favorites and Drafts.** Below, as cards: who put a message there and when, the ribbon in the corner to keep it as a favorite, and a bar to copy it into a new message, send it again, share it or delete it. Sort by recent or oldest, and by who sent it. FiestaBoard keeps no history of its own, so the app keeps it on the iPhone, per board: what you sent from the app (*You*) and what the board showed while the app was open (*FiestaBoard*).

**Writing a message.** The round button opens it. The board above shows where your text will land as you type — laid out as FiestaBoard lays it out: from the top left, word-wrapped, a line break where you type one — with how many tiles it takes. The colour tiles below put one in. **Send** says whether it reached the board or why not: a paused board, or one in its quiet time, which holds the message until that ends. **Save Draft**, next to Send, keeps it for later.

**Tile by tile.** Switch from **Text** to **Visual** and the board is your canvas: choose a colour or the eraser and tap or drag across the tiles, or choose the letters, tap a tile and type from there — backspace goes back, return to the next row. Undo and redo as you go. What you wrote as text carries over, and back. A visual message is sent tile for tile, exactly as drawn; a visual draft opens visually again, and so does a message copied from what the board showed.

**For a while, then the schedule again.** A message stays until the board's next refresh — the next page of its schedule or carousel — unless you choose, beside the tile count, to show it for 15 minutes, an hour, 4 or 8 hours. It then holds against the schedule, and the board goes back to it by itself once the time is up; the live card says until when, and **Back to the schedule** ends it sooner. Sending a card from History, Favorites or Drafts asks the same first. FiestaBoard holds a message for a while only on its primary board, so on another one the app offers no durations; and as it holds only text, a message drawn tile by tile goes as one line of text per row, which comes out as the same tiles.

**All your boards.** Every display your FiestaBoard drives — a split-flap board, an LED panel such as a pixel clock — each drawn as it looks, picked in the row of boards on top. History is per board; Favorites and Drafts are the same whichever board is chosen, and go to any of them, laid out anew for its size.

**White or black.** FiestaBoard's API does not say what colour a board is, or whether its code 62 flap is a heart or a degree sign, so you say it in Settings, board by board: Black or White beside its name, and Heart or Degree sign for code 62. A Note starts out white with a heart, a Flagship black with a degree sign. On a white board the white and black tiles show the other way round — a black tile is white there — and the app draws them as they look, as FiestaBoard does.

**A demo board.** Without a FiestaBoard, or to try something out: **Add demo board** in Settings, and a board simulated in the app joins yours — or stands alone, with no FiestaBoard at all. It works as a real one does: it takes messages as FiestaBoard does, keeps what it shows, and has a history of its own.

**In your language.** English, German, French and Spanish, as the iPhone is set — or for this app alone under Settings → FiestaBoard → Language. It calls FiestaBoard's menus by the names FiestaBoard gives them in that language.

It talks to nothing but your FiestaBoard, over its public API (`/api/v1`), with an API token.

## What you need

- A **FiestaBoard** install, with **login switched on** wherever it can be reached from the internet.
- An **API token**: in FiestaBoard, **Settings → AI**. It opens FiestaBoard's whole API, so the app keeps it in the iPhone's Keychain and sends it only to the address you set.
- **A way to reach FiestaBoard** from where the iPhone is — one of the three below.
- **Xcode 27** on a Mac to put the app on the iPhone, which needs **iOS 18** or later. It is not on the App Store.

## Reaching FiestaBoard

The app takes an `https://` address from anywhere, and a plain `http://` one only where it cannot be reached from the internet: 10.x, 172.16–31.x, 192.168.x, 100.64–127.x (Tailscale's range), a `.local` name, a name without a dot, or a private IPv6 address. Typed without `http://` or `https://`, an address gets the one that fits.

### At home

FiestaBoard's address on your network, such as `10.0.1.10:4420`. The first time, iOS asks whether the app may use the local network; allow it.

### Through a VPN

The same address from anywhere, with a VPN into your home network: **WireGuard** on the router (a FritzBox has it built in), or **Tailscale** on the FiestaBoard machine and the iPhone, then its `100.x.y.z:4420`. Nothing is opened to the internet.

### From anywhere, over HTTPS

A name of your own, a certificate, and only the API passed through to FiestaBoard. [Caddy](https://caddyserver.com) does all three and fetches and renews a Let's Encrypt certificate by itself. Here it runs in Docker beside FiestaBoard, as on a Raspberry Pi.

**1. A name for your home.** At your domain's DNS provider, an **A record** such as `fiestaboard.example.com` → your home's public IP address. If that address changes, keep the record up to date with your provider's DynDNS, which a FritzBox can update.

**2. Caddy's configuration**, in `~/caddy/Caddyfile`: only `/api/v1/…` goes on to FiestaBoard, and everything else — its web UI, its login — answers 404.

```caddyfile
fiestaboard.example.com {
	@api path /api/v1/*
	handle @api {
		reverse_proxy fiestaboard:3000
	}
	handle {
		respond 404
	}
}
```

**3. Caddy in Docker**, in FiestaBoard's Docker network, so it reaches the container as `fiestaboard:3000`. Ports 80 and 443 are often taken on the machine already — by deCONZ or a web server, say — so Caddy gets two free ones:

```sh
docker run -d --name caddy --restart unless-stopped \
  --network fiestaboard_default \
  -p 8081:80 -p 8443:443 \
  -v ~/caddy/Caddyfile:/etc/caddy/Caddyfile:ro \
  -v ~/caddy/data:/data -v ~/caddy/config:/config \
  caddy:2.10
```

`fiestaboard_default` is the network FiestaBoard's Docker Compose made; `docker network ls` lists it.

**4. Two port forwards on the router**, to the machine Caddy runs on (on a FritzBox: Internet → Freigaben → Portfreigaben):

| From the internet | To the machine |
|---|---|
| TCP 443 | 8443 |
| TCP 80 | 8081 |

Port 80 is only for Let's Encrypt, to hand out and renew the certificate.

**5. Check it** from outside your network — on the iPhone with Wi-Fi off — at `https://fiestaboard.example.com/api/v1/health`: `{"status":"ok", …}`, without a certificate warning. Until the name and the ports work, Caddy keeps trying for the certificate and waits longer each time; `docker restart caddy` makes it try at once, and `docker logs caddy` says how it went.

In the app: `https://fiestaboard.example.com` and your token.

## Putting it on your iPhone

1. Connect the iPhone to the Mac with a cable, unlock it and trust the computer.
2. Open `FiestaBoard.xcodeproj` in Xcode. Under the **FiestaBoard** target → **Signing & Capabilities**, choose your Apple ID as the **Team**. If Xcode says the bundle identifier is taken, change it to one of your own.
3. Choose the iPhone as the run destination and press **Run**.
4. The first time, Xcode says the iPhone needs **Developer Mode**: on the iPhone, **Settings → Privacy & Security → Developer Mode** (it appears only once Xcode has tried), switch it on, let it restart, and press Run again.
5. The first time the app starts, iOS asks you to trust your certificate: **Settings → General → VPN & Device Management** → your Apple ID → **Trust**.

With a free Apple ID the app runs for 7 days and is then put on again the same way; its history, favorites and drafts stay. With the paid Apple Developer Program it runs for a year, and TestFlight puts it on iPhones without a cable.

## Building

The files in `FiestaBoard/` are the project: Xcode picks up whatever is in the folder. A debug build started with these arguments shows sample content, without a FiestaBoard and apart from the real history:

| Argument | Shows |
|---|---|
| `-demo` | Home, with a sample board, history, favorite and draft |
| `-demo -demoLive` | the board large |
| `-demo -board sample-clock` | a second board, an LED pixel clock |
| `-demo -demoCompose` | writing a message |
| `-demo -demoVisual` | the visual editor |
| `-demo -demoSettings` | the first start |

All of them run on the demo board and a sample LED clock beside it, with sample content of their own.

### Tips

Settings → Donation offers two coffees as tips, through In-App Purchase: consumables that unlock nothing. Their product IDs are `de.rummeyer.fiestaboard.tip.small` and `.medium`; in App Store Connect they are created as consumable in-app purchases with these IDs. `FiestaBoard.storekit` has them for Xcode, chosen in the shared scheme, so that a run from Xcode shows and buys them without App Store Connect. Elsewhere, until the App Store has them, Settings shows no tips at all.

### Versions

The app follows [semantic versioning](https://semver.org): MAJOR.MINOR.PATCH, the patch for fixes, the minor for something new, the major for a change that breaks what was there. Settings → About shows it with the build number, which counts up with every version. `scripts/version.sh` prints both; `scripts/version.sh 1.1.0` sets the version and the next build. What changed is in [CHANGELOG.md](CHANGELOG.md); each version is tagged `vX.Y.Z` and has a release on GitHub.

## Icon, colours, typefaces and icons

All of them are FiestaBoard's:

- **The icon** is FiestaBoard's taco (`fiesta-icon.png` in the FiestaBoard repository, MIT licence), on white. `tools/make-icon.swift` makes it:

  ```sh
  swift tools/make-icon.swift <path to fiesta-icon.png> FiestaBoard/Assets.xcassets/AppIcon.appiconset/AppIcon.png
  ```

- **The colours** are those of FiestaBoard's web UI (`@fiestaboard/ui`), in light and dark: warm beige or warm near-black, and FiestaBoard orange for whatever is primary or chosen.
- **The typefaces** are FiestaBoard's: Archivo for words and Spline Sans Mono for the board, both under the SIL Open Font License.
- **The icons** are [Lucide](https://lucide.dev)'s, as in FiestaBoard's web UI, under the ISC licence.

Their licences are in `FiestaBoard/Licenses/`, and go with the app.

## Licence

MIT, see [LICENSE](LICENSE). The icon is FiestaBoard's, under its own MIT licence. This app is not made by the FiestaBoard project.

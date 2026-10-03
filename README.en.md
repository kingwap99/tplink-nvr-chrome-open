# tplink-nvr-chrome-open

> **中文文档请见 [README.md](README.md)（本仓库以中文為主）。**

Open a TP-Link NVR web UI (AWTK/WebAssembly canvas interface) in Google Chrome on macOS — including the models that refuse to render on Apple Silicon Macs.

## The problem

These NVRs gate their entire web UI behind a User-Agent sniff in `awtk_asm.js`:

```js
let is64Bit = () => /Win64|x86_64/.test(navigator.userAgent);
TBrowser.loadAWTK = function () {
  return is64Bit() && TBrowser.supportWebAssembly()
    ? TBrowser.loadScript("web-static/dynaform/js/awtk_asm.js")
    : alert("当前浏览器不支持此功能，请使用64位的Edge浏览器或Chrome浏览器，且版本高于127.0");
};
```

A Chrome UA on Apple Silicon contains neither `Win64` nor `x86_64`, so the page stays blank white behind that alert — even though Chrome itself is perfectly capable of rendering the UI.

Two extra traps:

1. `--user-agent` is **silently ignored** when a Chrome instance is already running, so it must be paired with a dedicated `--user-data-dir`.
2. The UI is rendered into `<canvas id="awtk-lcd">` — there are no DOM form fields until you click a canvas field, which spawns an `#awtk_edit` proxy input.

## Install

```bash
git clone https://github.com/kingwap99/tplink-nvr-chrome-open.git
cd tplink-nvr-chrome-open
chmod +x tplink-nvr-chrome-open lib/probe.sh
install -m 755 tplink-nvr-chrome-open ~/.local/bin/   # or: /usr/local/bin (needs sudo)
```

Keep `lib/probe.sh` next to the main script (it is invoked by the LAN scanner).

## Usage

```bash
tplink-nvr-chrome-open                  # auto-scan the LAN, open the first NVR found
tplink-nvr-chrome-open 192.168.31.11  # open a specific host
tplink-nvr-chrome-open 192.168.31.11:8080
tplink-nvr-chrome-open --scan           # scan only, print candidates
```

| Option | Description |
| --- | --- |
| `--port N` | Probe/serve port (default: `80`) |
| `--scan` | Scan and list candidates, do not open Chrome |
| `--subnet a.b.c.0/24` | Override the auto-detected /24 subnet |
| `--parallel N` | Scan concurrency (default: `64`) |
| `--no-cache` | Ignore the cached host and force a fresh scan |

### Auto-scan

With no host argument the script derives every active /24 from your interfaces (default-route first), probes `http://host:80/` on all 254 addresses in parallel, and matches responses containing `awtk` or `<title>NVR`. A full /24 scan takes ~7 s. The last successful target is cached in `~/.tplink-nvr-chrome-open/last_host` and reused (liveness-checked) on the next run.

## How it works

```bash
open -n -a "Google Chrome" --args \
  --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" \
  --user-data-dir="$HOME/.tplink-nvr-chrome-open/profile-<host>" \
  --no-first-run \
  "http://<host>/"
```

- `--user-agent` spoofs the Windows x64 token the NVR checks for.
- `--user-data-dir` gives each target its own profile so the flag actually applies (and login state persists per NVR).
- `open -n` forces a new instance even if Chrome is already open.

## Requirements

- macOS (`open`, `ipconfig`, `networksetup`, BSD `xargs`)
- Google Chrome at `/Applications/Google Chrome.app`
- `curl`, `awk`, `seq` (all preinstalled)

## Notes

- The spoofed profile is isolated: bookmarks/passwords from your normal Chrome do not appear there, but the NVR login session persists in its profile directory.
- Port `8000` on some firmware builds accepts TCP but returns an empty reply to HTTP GET — that is a private SDK/ISAPI socket, not the web UI. The web UI lives on port `80`.
- Scanning touches only HTTP GETs against your own LAN; keep it to networks you own.

## License

MIT

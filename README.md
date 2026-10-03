# tplink-nvr-chrome-open

在 macOS 上用 Google Chrome 開啟 TP-Link NVR 網頁介面（AWTK/WebAssembly canvas 界面）——包括那些在 Apple Silicon Mac 上只給你一片空白的機型。

English: [README.en.md](README.en.md)

## 問題出在哪

這些 NVR 在 `awtk_asm.js` 裡用 User-Agent 檢查擋掉了整個網頁介面：

```js
let is64Bit = () => /Win64|x86_64/.test(navigator.userAgent);
TBrowser.loadAWTK = function () {
  return is64Bit() && TBrowser.supportWebAssembly()
    ? TBrowser.loadScript("web-static/dynaform/js/awtk_asm.js")
    : alert("当前浏览器不支持此功能，请使用64位的Edge浏览器或Chrome浏览器，且版本高于127.0");
};
```

Apple Silicon 上的 Chrome UA 裡同時沒有 `Win64` 和 `x86_64` 這兩個字，所以頁面只會在「当前浏览器不支持」的警告後面留一整片空白——儘管你的 Chrome 其實完全有能力渲染這個介面。

另外還有兩個坑：

1. 只要已經有一個 Chrome 實例在跑，`--user-agent` 就會被**無聲忽略**，所以必須搭配獨立的 `--user-data-dir`。
2. 整個 UI 是渲染在 `<canvas id="awtk-lcd">` 上的——DOM 裡沒有任何表單欄位，必須先點擊 canvas 上的輸入框，它才會生成一個 `#awtk_edit` 代理輸入元素。

## 安裝

```bash
git clone https://github.com/kingwap99/tplink-nvr-chrome-open.git
cd tplink-nvr-chrome-open
chmod +x tplink-nvr-chrome-open lib/probe.sh
install -m 755 tplink-nvr-chrome-open ~/.local/bin/   # 或 /usr/local/bin（需要 sudo）
```

`lib/probe.sh` 要留在主腳本旁邊（內網掃描器會呼叫它）。

## 用法

```bash
tplink-nvr-chrome-open                  # 沒帶參數 → 自動掃描內網，開啟第一台找到的 NVR
tplink-nvr-chrome-open 192.168.31.11  # 指定 IP
tplink-nvr-chrome-open 192.168.31.11:8080
tplink-nvr-chrome-open --scan           # 只掃描、列出候選，不開 Chrome
```

| 選項 | 說明 |
| --- | --- |
| `--port N` | 探測／開啟的端口（預設 `80`） |
| `--scan` | 只掃描並列出候選，不開 Chrome |
| `--subnet a.b.c.0/24` | 手動指定網段，跳過自動偵測 |
| `--parallel N` | 掃描並行數（預設 `64`） |
| `--no-cache` | 忽略快取的舊主機，強制重新掃描 |

### 自動掃描

不帶 IP 時，腳本會從你的網路介面推導出所有活躍的 /24 網段（預設路由優先），平行探測每個網段的 254 個 `http://IP:80/`，回應內容包含 `awtk` 或 `<title>NVR` 就認定是 NVR，並開啟第一台。掃完整個 /24 約 7 秒。成功的目標會快取在 `~/.tplink-nvr-chrome-open/last_host`，下次執行先做存活檢查再沿用。

## 原理

```bash
open -n -a "Google Chrome" --args \
  --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" \
  --user-data-dir="$HOME/.tplink-nvr-chrome-open/profile-<host>" \
  --no-first-run \
  "http://<host>/"
```

- `--user-agent` 偽造 NVR 要檢查的 Windows x64 字樣。
- `--user-data-dir` 讓每個目標有自己的 profile，參數才會生效（而且各台 NVR 的登入狀態分開持久保存）。
- `open -n` 強制開新實例，即使 Chrome 已經開著。

## 環境需求

- macOS（用到 `open`、`ipconfig`、`networksetup`、BSD `xargs`）
- `/Applications/Google Chrome.app`
- `curl`、`awk`、`seq`（系統內建）

## 注意事項

- 這個偽造 UA 的 profile 是獨立的：你一般 Chrome 的書籤／密碼不會出現在這裡，但 NVR 的登入狀態會存在它自己的 profile 目錄裡。
- 某些韌體的 8000 端口會接受 TCP 連線但對 HTTP GET 回空包——那是廠商的 SDK／ISAPI socket，不是網頁介面。網頁介面在 80 端口。
- 掃描只對自己內網的 IP 發 HTTP GET；請只在你有授權的網路使用。

## 授權

MIT

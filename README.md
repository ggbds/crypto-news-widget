# 幣圈美股快訊 · 桌面小工具

Windows 桌面小工具，即時顯示**幣圈**與**美股**的重要快訊、行情與美國經濟數據。不用安裝任何其他軟體，Windows 10 / 11 內建功能就能執行。

## 下載安裝

👉 **[下載最新版安裝檔](https://github.com/ggbds/crypto-news-widget/releases/latest/download/CryptoNewsWidget-Setup.exe)**

1. 下載 `CryptoNewsWidget-Setup.exe` 後直接執行。
2. Windows 可能跳出「**Windows 已保護您的電腦**」，這是因為安裝檔沒有付費的程式碼簽章。點「**其他資訊**」→「**仍要執行**」即可。
3. 裝好後桌面和開始功能表會出現「幣圈美股快訊」，小工具也會自動開啟。

不需要系統管理員權限，程式裝在 `%LOCALAPPDATA%\CryptoNewsWidget`。

## 更新

小工具每 6 小時會自動檢查有沒有新版。有新版時，視窗下方會出現藍色的「有新版本」提示，**點一下就會自動下載並安裝**，你的設定（選的幣種、字體、視窗位置…）都會保留。

也可以隨時到 [Releases](https://github.com/ggbds/crypto-news-widget/releases) 下載最新安裝檔，直接覆蓋安裝。

## 功能

- **即時快訊**：華爾街見聞 7x24、鉅亨快訊、動區、鏈新聞、CoinDesk、Decrypt、CNBC，英文自動翻成繁體中文
- **只看重要**：價格暴漲暴跌、政策、數據公布、重要人物、戰爭等會影響市場的消息
- **利多 / 利空標示**：依關鍵字與經濟數據種類自動判斷（僅供參考）
- **行情列**：幣安報價（加密貨幣）、CNBC 報價（美股 / 指數），可在 ⚙ 自選要顯示的項目
- **📅 美國數據公布**：CPI、非農、FOMC 等經濟行事曆，含實際值 / 預期 / 前值與倒數
- **通知**：突發新聞、自選標的的重要新聞、急漲急跌、重要數據公布時跳出通知
- 深色 / 淺色主題、字體大小可調、四邊可拉動調整大小

## 移除

設定 → 應用程式 → 已安裝的應用程式 → 幣圈美股快訊 → 解除安裝。

## 免責聲明

快訊與利多 / 利空判斷皆由程式自動抓取、翻譯與判斷，可能有誤，**不構成任何投資建議**。

---

## 發布新版（維護者）

1. 修改 `news-widget.ps1`，把開頭的 `$AppVersion` 改大（例如 `1.1.0` → `1.2.0`）。
2. 打包安裝檔：`powershell -ExecutionPolicy Bypass -File installer\build.ps1`
3. 推上 GitHub 並建立 Release（版號要跟 `$AppVersion` 一樣）：
   ```
   git commit -am "v1.2.0：更新內容"
   git push
   gh release create v1.2.0 "安裝檔\CryptoNewsWidget-Setup.exe" --title "v1.2.0" --notes "更新內容…"
   ```
4. 朋友的小工具會在 6 小時內偵測到新版並提示更新。

# ============================================================
#  幣圈 & 美股 即時新聞桌面小工具 (Windows / PowerShell + WPF)
#  - 不需安裝任何套件，Windows 內建即可執行
#  - 雙擊桌面「幣圈美股快訊」捷徑開啟
# ============================================================

# ------------------------- 設定區 ---------------------------
$RefreshSeconds   = 60      # 幾秒更新一次
$MaxItems         = 120     # 列表最多顯示幾則
$FontSize         = 16      # 預設字體大小（可在 ⚙ 設定裡調整，12～24）
$TranslateEnglish = $true   # 英文標題自動翻譯成繁體中文
$MaxAlertsPerRefresh = 3    # 每次更新最多通知幾則突發新聞

# 版本與自動更新：發布新版時把 AppVersion 改大，再到 GitHub 建立同版號的 Release（附上安裝檔）
$AppVersion   = '1.1.0'
$UpdateRepo   = 'ggbds/crypto-news-widget'                    # GitHub 上的「帳號/儲存庫」
$UpdateAsset  = 'CryptoNewsWidget-Setup.exe'          # Release 裡安裝檔的檔名

# 配色：深色 / 淺色（在 ⚙ 設定裡切換）。Up / Down = 漲跌顏色（目前是綠漲紅跌，想改回紅漲綠跌就對調）
$Themes = @{
    dark = @{
        WinBg = '#F0121620'; WinBorder = '#30FFFFFF'; Title = '#FFFFFF'; Text = '#E6EAF0'; Muted = '#9AA4B2'; Dim = '#6B7685'; Time = '#7D8896'
        Card = '#181E28'; CardNew = '#1F2A3A'; CardBreak = '#2A1C22'; TabBg = '#1E2530'; TabFg = '#9AA4B2'; ImpOnBg = '#2B3A2E'; ImpOnFg = '#7EE29B'
        CryptoTagBg = '#33F7931A'; CryptoTagFg = '#F7B34D'; StockTagBg = '#332F81F7'; StockTagFg = '#6CA8FF'; TransBg = '#22FFFFFF'; TransFg = '#9AA4B2'
        Hover = '#22FFFFFF'; DlgBg = '#FA121620'; Panel = '#1A212C'; InputBg = '#26303D'; InputBorder = '#40FFFFFF'; BtnBg = '#26303D'; BtnFg = '#E6EAF0'
        Up = '#2ECC71'; Down = '#FF5A5F'
    }
    light = @{
        WinBg = '#F7FBFCFD'; WinBorder = '#26000000'; Title = '#111827'; Text = '#1F2937'; Muted = '#5B6573'; Dim = '#7A8494'; Time = '#6B7280'
        Card = '#EEF1F5'; CardNew = '#FFF4E0'; CardBreak = '#FDEAEA'; TabBg = '#E3E8EF'; TabFg = '#4B5563'; ImpOnBg = '#D8F1E0'; ImpOnFg = '#1E7B3C'
        CryptoTagBg = '#26F7931A'; CryptoTagFg = '#A85A00'; StockTagBg = '#222F81F7'; StockTagFg = '#1D5FD1'; TransBg = '#14000000'; TransFg = '#5B6573'
        Hover = '#14000000'; DlgBg = '#FCFFFFFF'; Panel = '#EEF1F5'; InputBg = '#FFFFFF'; InputBorder = '#40000000'; BtnBg = '#E3E8EF'; BtnFg = '#1F2937'
        Up = '#178A48'; Down = '#E0282E'
    }
}

# 「突發」判斷：標題含有下列任一關鍵字 → 視為突發，會語音播報 + 跳出通知
$BreakingKeywords = @(
    '突發','緊急','重磅','快訊》','快訊：',
    '暴跌','崩跌','崩盤','閃崩','急跌','急漲','跳水','重挫','熔斷','暫停交易','暫停充提','停止出塊','停牌',
    '遭駭','被駭','被盜','盜走','駭客攻擊','遭攻擊',
    '爆倉','破產','倒閉','擠兌','脫鉤','清算潮',
    '逮捕','開戰','空襲',
    '宣布升息','宣布降息','意外升息','意外降息','緊急升息','緊急降息','利率決議','緊急會議',
    'breaking','urgent','plunge','crash','tumble','hacked','exploited','halts','bankrupt','depeg'
)
# 含有下列字眼的屬於「總結 / 整理 / 專欄」類，一律不通知
# 「只看重要」：列表只顯示符合下列任一類別的新聞（其餘一律隱藏）
# 由上往下比對，標籤會顯示第一個符合的類別。想多看/少看什麼，改這裡的關鍵字即可
$OnlyImportant = $true
$ImportantRules = [ordered]@{
    '戰爭' = '戰爭|開戰|宣戰|空襲|導彈|飛彈|遇襲|遭襲|襲擊|軍事行動|停火|停戰|武裝衝突|軍事入侵|入侵(烏克蘭|台灣|領空)|恐襲|核武|胡塞|解放軍|台海|伊朗.{0,30}(美國|以色列|談判|停火|核|霍爾木茲)|(?<![A-Za-z])war(?![A-Za-z])|missile|airstrike|ceasefire|invasion'
    '價格' = '暴漲|暴跌|崩跌|崩盤|閃崩|急跌|急漲|跳水|重挫|飆漲|狂飆|大漲|大跌|創新高|創新低|歷史新高|熔斷|爆倉|(跌破|突破|失守|站上|站穩|重回)\s*\d|plunge|crash|soar|surge|tumble|slump|record high|all-time high'
    '政策' = '聯準會|美聯儲|FOMC|鮑爾|央行|利率決議|升息|降息|加息|減息|縮表|購債|(?<![A-Za-z])(SEC|CFTC|OCC|Fed)(?![A-Za-z])|白宮|行政命令|法案|立法|監管|批准|核准|禁令|關稅|制裁|美國財長|美財長|美國財政部長|國會|參議院|眾議院|Powell|rate cut|rate hike|tariff|sanction|executive order|regulat|approv|Congress|Senate'
    '數據' = 'CPI|PPI|PCE|非農|就業|失業|初請|GDP|零售銷售|ISM|PMI|消費者信心|通膨|通脹|財報|營收|EPS|EIA|原油庫存|payroll|jobs report|unemployment|inflation|earnings|retail sales'
    '人物' = '川普|特朗普|拜登|萬斯|貝森特|耶倫|馬斯克|黃仁勳|黃仁勛|巴菲特|木頭姐|趙長鵬|賽勒|Saylor|Vitalik|普丁|普京|習近平|澤倫斯基|內塔尼亞胡|Trump|Musk|Bessent|Buffett|Putin'
}
# 開頭是其他國家/地區、且內容跟美國或幣圈無關的消息，不算重要（例如歐股收盤、德國監管）
$OtherRegionPattern = '^(周.（.+?）)?(德國|法國|英國|意大利|義大利|西班牙|荷蘭|瑞士|北歐|歐盟|歐洲|歐元區|日本|日銀|加拿大|澳洲|澳大利亞|紐西蘭|韓國|印度|何立峰|法意|英債|長端英債)'
$UsCryptoPattern    = '美國|美股|美聯儲|聯準會|美元|川普|特朗普|比特|以太|加密|幣|伊朗|以色列|俄|烏'
# 指數 / 大幣漲跌 2% 以上也算「價格」類
$IndexMovePattern = '(納指|納斯達克|標普|道指|道瓊|費城半導體|比特幣|以太坊|BTC|ETH).{0,14}(漲|跌)(幅)?(超過|超|逾|達|擴大至|擴大到)?\s*([2-9]|[1-9]\d)(\.\d+)?\s*%'

$ExcludeKeywords = @(
    '日報','週報','周報','早報','晚報','早盤','午盤','盤前','盤後','收盤','總結','回顧','精選','懶人包',
    '一週','本週','每日','週末','前瞻','專欄','觀點','教學','指南','預測','展望','分析','策略','構想','提案',
    '？','?','如何','為何','為什麼','怎麼','該不該','是否','現場新聞','直播',
    'daily','weekly','recap','roundup','newsletter','morning','week ahead','podcast','opinion','what to know','explained'
)

# 新聞來源（不要的來源在行首加 # 即可停用）
$Sources = @(
    # 即時快訊（幾分鐘內更新）
    @{ Name = '華爾街見聞'; Cat = 'stock';  Type = 'wscn';  Lang = 'zh'; Url = 'https://api-one-wscn.awtmt.com/apiv1/content/lives?channel=us-stock-channel&limit=40' }
    @{ Name = '鉅亨快訊';   Cat = 'auto';   Type = 'cnyes'; Lang = 'zh'; Url = 'https://api.cnyes.com/media/api/v1/newslist/category/bc_live?limit=40' }
    # 新聞報導
    @{ Name = '動區';       Cat = 'crypto'; Type = 'rss';   Lang = 'zh'; Url = 'https://www.blocktempo.com/feed/' }
    @{ Name = '鏈新聞';     Cat = 'crypto'; Type = 'rss';   Lang = 'zh'; Url = 'https://abmedia.io/feed' }
    @{ Name = 'CoinDesk';   Cat = 'crypto'; Type = 'rss';   Lang = 'en'; Url = 'https://www.coindesk.com/arc/outboundfeeds/rss' }
    @{ Name = 'Decrypt';    Cat = 'crypto'; Type = 'rss';   Lang = 'en'; Url = 'https://decrypt.co/feed' }
    @{ Name = 'CNBC';       Cat = 'stock';  Type = 'rss';   Lang = 'en'; Url = 'https://www.cnbc.com/id/15839069/device/rss/rss.html' }
    @{ Name = 'CNBC';       Cat = 'stock';  Type = 'rss';   Lang = 'en'; Url = 'https://www.cnbc.com/id/20910258/device/rss/rss.html' }
)

# 行情列：加密貨幣用 Binance，美股 / 指數用 CNBC
# Alert = 在 $SpikeMinutes 分鐘內漲跌超過幾 % 就發出「急漲/急跌」通知（設 0 = 不通知）
$SpikeMinutes = 10
# 可選清單：在小工具裡按 ⚙（或點行情列）勾選要顯示哪些；On = 第一次使用時預設顯示
# 清單裡沒有的，也可以在 ⚙ 視窗裡自行輸入代號新增
$CryptoCatalog = @(
    @{ Label = 'BTC';  Name = '比特幣';     Symbol = 'BTCUSDT';  Alert = 1.5; On = $true }
    @{ Label = 'ETH';  Name = '以太幣';     Symbol = 'ETHUSDT';  Alert = 2;   On = $true }
    @{ Label = 'SOL';  Name = 'Solana';     Symbol = 'SOLUSDT';  Alert = 3;   On = $true }
    @{ Label = 'BNB';  Name = '幣安幣';     Symbol = 'BNBUSDT';  Alert = 3;   On = $true }
    @{ Label = 'XRP';  Name = '瑞波幣';     Symbol = 'XRPUSDT';  Alert = 3;   On = $true }
    @{ Label = 'DOGE'; Name = '狗狗幣';     Symbol = 'DOGEUSDT'; Alert = 4;   On = $true }
    @{ Label = 'ADA';  Name = '艾達幣';     Symbol = 'ADAUSDT';  Alert = 4;   On = $true }
    @{ Label = 'AVAX'; Name = 'Avalanche';  Symbol = 'AVAXUSDT'; Alert = 4;   On = $true }
    @{ Label = 'LINK'; Name = 'Chainlink';  Symbol = 'LINKUSDT'; Alert = 4;   On = $true }
    @{ Label = 'TRX';  Name = '波場';       Symbol = 'TRXUSDT';  Alert = 4;   On = $false }
    @{ Label = 'TON';  Name = 'Toncoin';    Symbol = 'TONUSDT';  Alert = 4;   On = $false }
    @{ Label = 'SUI';  Name = 'Sui';        Symbol = 'SUIUSDT';  Alert = 5;   On = $false }
    @{ Label = 'DOT';  Name = '波卡';       Symbol = 'DOTUSDT';  Alert = 4;   On = $false }
    @{ Label = 'LTC';  Name = '萊特幣';     Symbol = 'LTCUSDT';  Alert = 4;   On = $false }
    @{ Label = 'BCH';  Name = '比特幣現金'; Symbol = 'BCHUSDT';  Alert = 4;   On = $false }
    @{ Label = 'SHIB'; Name = '柴犬幣';     Symbol = 'SHIBUSDT'; Alert = 5;   On = $false }
    @{ Label = 'PEPE'; Name = 'Pepe';       Symbol = 'PEPEUSDT'; Alert = 5;   On = $false }
    @{ Label = 'NEAR'; Name = 'NEAR';       Symbol = 'NEARUSDT'; Alert = 5;   On = $false }
    @{ Label = 'APT';  Name = 'Aptos';      Symbol = 'APTUSDT';  Alert = 5;   On = $false }
    @{ Label = 'ARB';  Name = 'Arbitrum';   Symbol = 'ARBUSDT';  Alert = 5;   On = $false }
    @{ Label = 'OP';   Name = 'Optimism';   Symbol = 'OPUSDT';   Alert = 5;   On = $false }
    @{ Label = 'UNI';  Name = 'Uniswap';    Symbol = 'UNIUSDT';  Alert = 5;   On = $false }
    @{ Label = 'ATOM'; Name = 'Cosmos';     Symbol = 'ATOMUSDT'; Alert = 5;   On = $false }
    @{ Label = 'INJ';  Name = 'Injective';  Symbol = 'INJUSDT';  Alert = 5;   On = $false }
    @{ Label = 'HYPE'; Name = 'Hyperliquid'; Symbol = 'HYPEUSDT'; Alert = 5;  On = $false }
    @{ Label = 'WLD';  Name = 'Worldcoin';  Symbol = 'WLDUSDT';  Alert = 5;   On = $false }
    @{ Label = 'ENA';  Name = 'Ethena';     Symbol = 'ENAUSDT';  Alert = 5;   On = $false }
    @{ Label = 'TAO';  Name = 'Bittensor';  Symbol = 'TAOUSDT';  Alert = 5;   On = $false }
    @{ Label = 'ONDO'; Name = 'Ondo';       Symbol = 'ONDOUSDT'; Alert = 5;   On = $false }
    @{ Label = 'FET';  Name = 'Fetch.ai';   Symbol = 'FETUSDT';  Alert = 5;   On = $false }
)
$StockCatalog = @(
    @{ Label = 'S&P500'; Name = '標普500';     Symbol = '^GSPC'; Alert = 1;   On = $true }
    @{ Label = 'NASDAQ'; Name = '那斯達克';    Symbol = '^IXIC'; Alert = 1.2; On = $true }
    @{ Label = 'DOW';    Name = '道瓊';        Symbol = '^DJI';  Alert = 1;   On = $true }
    @{ Label = 'SOX';    Name = '費城半導體';  Symbol = '^SOX';  Alert = 2;   On = $false }
    @{ Label = 'VIX';    Name = '恐慌指數';    Symbol = '^VIX';  Alert = 15;  On = $false }
    @{ Label = 'SPY';    Name = 'SPY ETF';     Symbol = 'SPY';   Alert = 1;   On = $false }
    @{ Label = 'QQQ';    Name = 'QQQ ETF';     Symbol = 'QQQ';   Alert = 1.2; On = $false }
    @{ Label = 'NVDA';   Name = '輝達';        Symbol = 'NVDA';  Alert = 3;   On = $true }
    @{ Label = 'AAPL';   Name = '蘋果';        Symbol = 'AAPL';  Alert = 3;   On = $false }
    @{ Label = 'MSFT';   Name = '微軟';        Symbol = 'MSFT';  Alert = 3;   On = $false }
    @{ Label = 'GOOGL';  Name = 'Google';      Symbol = 'GOOGL'; Alert = 3;   On = $false }
    @{ Label = 'AMZN';   Name = '亞馬遜';      Symbol = 'AMZN';  Alert = 3;   On = $false }
    @{ Label = 'META';   Name = 'Meta';        Symbol = 'META';  Alert = 3;   On = $false }
    @{ Label = 'TSLA';   Name = '特斯拉';      Symbol = 'TSLA';  Alert = 4;   On = $false }
    @{ Label = 'AMD';    Name = 'AMD';         Symbol = 'AMD';   Alert = 4;   On = $false }
    @{ Label = 'AVGO';   Name = '博通';        Symbol = 'AVGO';  Alert = 3;   On = $false }
    @{ Label = 'TSM';    Name = '台積電ADR';   Symbol = 'TSM';   Alert = 3;   On = $false }
    @{ Label = 'NFLX';   Name = '網飛';        Symbol = 'NFLX';  Alert = 4;   On = $false }
    @{ Label = 'PLTR';   Name = 'Palantir';    Symbol = 'PLTR';  Alert = 5;   On = $false }
    @{ Label = 'COIN';   Name = 'Coinbase';    Symbol = 'COIN';  Alert = 5;   On = $false }
    @{ Label = 'MSTR';   Name = 'Strategy';    Symbol = 'MSTR';  Alert = 5;   On = $false }
)

# 「自選標的新聞」：新聞提到你在 ⚙ 勾選的幣/股票時，會標上 ★ 並顯示；若同時是突發或重要新聞就通知
# 這裡是每個標的在新聞裡常見的叫法（4 個字元以內的英文代號會區分大小寫，避免 LINK/OP/SOL 誤抓一般英文字）
# 自己新增的標的會自動用它的代號和名稱比對
$WatchAliases = @{
    'BTCUSDT'  = '比特幣','BTC','Bitcoin'
    'ETHUSDT'  = '以太幣','以太坊','ETH','Ethereum','Ether'
    'SOLUSDT'  = 'Solana','SOL'
    'BNBUSDT'  = 'BNB','幣安幣'
    'XRPUSDT'  = 'XRP','瑞波','Ripple'
    'DOGEUSDT' = '狗狗幣','DOGE','Dogecoin'
    'ADAUSDT'  = 'ADA','Cardano','艾達幣'
    'AVAXUSDT' = 'AVAX','Avalanche','雪崩協議'
    'LINKUSDT' = 'Chainlink','LINK'
    'TRXUSDT'  = 'TRX','TRON','Tron','波場'
    'TONUSDT'  = 'TON','Toncoin'
    'SUIUSDT'  = 'SUI','Sui'
    'DOTUSDT'  = 'DOT','Polkadot','波卡'
    'LTCUSDT'  = 'LTC','Litecoin','萊特幣'
    'BCHUSDT'  = 'BCH','比特幣現金','Bitcoin Cash'
    'SHIBUSDT' = 'SHIB','柴犬幣','Shiba'
    'PEPEUSDT' = 'PEPE','Pepe'
    'NEARUSDT' = 'NEAR'
    'APTUSDT'  = 'APT','Aptos'
    'ARBUSDT'  = 'ARB','Arbitrum'
    'OPUSDT'   = 'OP','Optimism'
    'UNIUSDT'  = 'UNI','Uniswap'
    'ATOMUSDT' = 'ATOM','Cosmos'
    'INJUSDT'  = 'INJ','Injective'
    'HYPEUSDT' = 'HYPE','Hyperliquid'
    'WLDUSDT'  = 'WLD','Worldcoin'
    'ENAUSDT'  = 'ENA','Ethena'
    'TAOUSDT'  = 'TAO','Bittensor'
    'ONDOUSDT' = 'ONDO','Ondo'
    'FETUSDT'  = 'FET','Fetch.ai'
    '^GSPC'    = '標普','S&P','SPX'
    '^IXIC'    = '納指','那指','納斯達克','Nasdaq'
    '^DJI'     = '道瓊','道指','Dow'
    '^SOX'     = '費城半導體','費半','SOX'
    '^VIX'     = 'VIX','恐慌指數'
    'SPY'      = 'SPY'
    'QQQ'      = 'QQQ'
    'NVDA'     = '輝達','英偉達','NVIDIA','Nvidia','NVDA','黃仁勳','黃仁勛'
    'AAPL'     = '蘋果','Apple','AAPL'
    'MSFT'     = '微軟','Microsoft','MSFT'
    'GOOGL'    = '谷歌','Google','Alphabet','GOOGL'
    'AMZN'     = '亞馬遜','Amazon','AMZN'
    'META'     = 'Meta','META','臉書'
    'TSLA'     = '特斯拉','Tesla','TSLA'
    'AMD'      = 'AMD','超微'
    'AVGO'     = '博通','Broadcom','AVGO'
    'TSM'      = '台積電','臺積電','TSMC','TSM'
    'NFLX'     = '網飛','Netflix','NFLX'
    'PLTR'     = 'Palantir','PLTR'
    'COIN'     = 'Coinbase','COIN'
    'MSTR'     = 'MicroStrategy','MSTR','Saylor','賽勒','微策略'
}
# -----------------------------------------------------------

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Speech, System.Windows.Forms, System.Drawing

# 單一實例
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\CryptoUsStockNewsWidget', [ref]$createdNew)
if (-not $createdNew) { exit }

$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$SettingsPath = Join-Path $ScriptDir 'settings.json'
$IconPath     = Join-Path $ScriptDir 'icon.ico'

# ------------------------- 背景抓取 -------------------------
$FetchScript = {
    param($Sources, $CryptoSymbols, $StockSymbols, $Translate, $TransCache)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    [Net.ServicePointManager]::DefaultConnectionLimit = 16

    function New-Client {
        $wc = New-Object Net.WebClient
        $wc.Encoding = [Text.Encoding]::UTF8
        $wc.Headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) NewsWidget/1.0'
        return $wc
    }
    function Get-Text([string]$url) {
        $wc = New-Client
        try { return $wc.DownloadString($url) } finally { $wc.Dispose() }
    }
    function Parse-Date([string]$s) {
        if (-not $s) { return Get-Date }
        $s = $s.Trim() -replace ' EST$', ' -0500' -replace ' EDT$', ' -0400' -replace ' (GMT|UTC|Z)$', ' +0000'
        $d = [DateTimeOffset]::MinValue
        if ([DateTimeOffset]::TryParse($s, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$d)) { return $d.LocalDateTime }
        return Get-Date
    }
    function Clean([string]$s) {
        if (-not $s) { return '' }
        $s = [Net.WebUtility]::HtmlDecode($s)
        $s = $s -replace '<[^>]+>', '' -replace '\s+', ' '
        return $s.Trim()
    }
    # Google 翻譯（免金鑰端點）：每批多行，所有批次同時送出
    function Get-TransUrl([string[]]$lines) {
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=zh-TW&dt=t&q=' + [Uri]::EscapeDataString(($lines -join "`n"))
    }
    function Parse-Trans([string]$raw) {
        $j = $raw | ConvertFrom-Json
        $txt = (@($j[0]) | ForEach-Object { $_[0] }) -join ''
        return @($txt -split "`n" | ForEach-Object { $_.Trim() })
    }
    function Translate-All([string[]]$need, $cache) {
        Add-Type -AssemblyName System.Net.Http
        $hc = New-Object System.Net.Http.HttpClient
        $hc.Timeout = [TimeSpan]::FromSeconds(25)
        [void]$hc.DefaultRequestHeaders.UserAgent.TryParseAdd('Mozilla/5.0 (Windows NT 10.0; Win64; x64)')
        try {
            # 每則標題各自翻譯（不把多則串在一起，避免斷行錯位造成標題被截斷）
            # 一次同時送出 10 則，分波進行
            for ($i = 0; $i -lt $need.Count; $i += 10) {
                $wave = @($need[$i..([Math]::Min($i + 9, $need.Count - 1))])
                $jobs = foreach ($l in $wave) { [pscustomobject]@{ Line = $l; Task = $hc.GetStringAsync((Get-TransUrl @($l))) } }
                foreach ($j in $jobs) {
                    try {
                        $zh = ((Parse-Trans $j.Task.Result) -join ' ').Trim()
                        # 合理性檢查：譯文太短（例如只剩一個字）就不採用，保留英文原文，下次更新再試
                        $minLen = [Math]::Max(2, [Math]::Floor($j.Line.Length / 8))
                        if ($zh.Length -ge $minLen) { $cache[$j.Line] = $zh }
                    } catch { }
                }
            }
        } finally { $hc.Dispose() }
    }

    $items  = New-Object System.Collections.ArrayList
    $errors = New-Object System.Collections.ArrayList

    foreach ($src in $Sources) {
        try {
            if ($src.Type -eq 'cnyes') {
                $j = (Get-Text $src.Url) | ConvertFrom-Json
                foreach ($d in $j.items.data) {
                    $title = Clean $d.title
                    $cat = $src.Cat
                    if ($cat -eq 'auto') {
                        # 鉅亨快訊混有幣圈與美股，依內容自動分類
                        $cryptoStrong = '比特|BTC|ETH|以太|幣|代幣|鏈|DeFi|NFT|Web3'
                        $cryptoAny    = $cryptoStrong + '|USDT|USDC|挖礦|錢包|爆倉|加密|Coinbase|Binance|OKX|Tether|Circle|Ripple|Strategy|波場|(?<![A-Za-z])(SOL|XRP|AVAX|BNB|DOGE|ADA|TRX|TON|SUI|APT|ARB|INJ|Injective|Solana)(?![A-Za-z])'
                        $stockStrong  = '美股|納指|那指|納斯達克|標普|道瓊|道指|費城半導體|美聯儲|聯準會|美債|原油|油價|木頭姐|高盛|摩根'
                        $stockAny     = $stockStrong + '|Fed|輝達|英偉達|蘋果|特斯拉|微軟|財報|盤前|盤中|美元|黃金|關稅|CPI|非農|川普|伊朗'
                        $cat = if ($title -match $stockStrong -and $title -notmatch $cryptoStrong) { 'stock' }
                               elseif ($title -match $cryptoAny) { 'crypto' }
                               elseif ($title -match $stockAny)  { 'stock' }
                               else { 'crypto' }
                    }
                    [void]$items.Add([pscustomobject]@{
                        Id = "cnyes:$($d.newsId)"; Title = $title; Original = ''
                        Url = "https://news.cnyes.com/news/id/$($d.newsId)"
                        Time = [DateTimeOffset]::FromUnixTimeSeconds([int64]$d.publishAt).LocalDateTime
                        Source = $src.Name; Cat = $cat; Lang = $src.Lang; Important = $false
                    })
                }
            }
            elseif ($src.Type -eq 'wscn') {
                # 華爾街見聞 7x24 快訊（簡體 → 繁體，本機轉換）
                Add-Type -AssemblyName Microsoft.VisualBasic
                $j = (Get-Text $src.Url) | ConvertFrom-Json
                foreach ($d in $j.data.items) {
                    $t = if ($d.title) { $d.title } else { $d.content_text }
                    $t = Clean $t
                    if (-not $t) { continue }
                    if ($t.Length -gt 110) { $t = $t.Substring(0, 108) + '…' }
                    $t = [Microsoft.VisualBasic.Strings]::StrConv($t, [Microsoft.VisualBasic.VbStrConv]::TraditionalChinese, 2052)
                    [void]$items.Add([pscustomobject]@{
                        Id = "wscn:$($d.id)"; Title = $t; Original = ''
                        Url = if ($d.uri) { $d.uri } else { "https://wallstreetcn.com/livenews/$($d.id)" }
                        Time = [DateTimeOffset]::FromUnixTimeSeconds([int64]$d.display_time).LocalDateTime
                        Source = $src.Name; Cat = $src.Cat; Lang = $src.Lang
                        Important = ([int]$d.score -ge 2)   # 華爾街見聞標記為「重要」的快訊
                    })
                }
            }
            else {
                [xml]$x = (Get-Text $src.Url).Trim()
                foreach ($n in $x.SelectNodes('//item')) {
                    $title = Clean ($n.SelectSingleNode('title').InnerText)
                    $link  = $n.SelectSingleNode('link')
                    $link  = if ($link) { $link.InnerText.Trim() } else { '' }
                    $pub   = $n.SelectSingleNode('pubDate')
                    $pub   = if ($pub) { $pub.InnerText } else { '' }
                    if (-not $title) { continue }
                    [void]$items.Add([pscustomobject]@{
                        Id = if ($link) { $link } else { "$($src.Name):$title" }; Title = $title; Original = ''; Url = $link
                        Time = (Parse-Date $pub); Source = $src.Name; Cat = $src.Cat; Lang = $src.Lang; Important = $false
                    })
                }
            }
        } catch { [void]$errors.Add($src.Name) }
    }

    # 翻譯英文標題（有快取，翻過的不會再翻）
    if ($Translate) {
        $need = @($items | Where-Object { $_.Lang -ne 'zh' -and -not $TransCache.ContainsKey($_.Title) } | ForEach-Object { $_.Title } | Select-Object -Unique)
        if ($need.Count) {
            try { Translate-All $need $TransCache } catch { }
            if (@($need | Where-Object { -not $TransCache.ContainsKey($_) }).Count -eq $need.Count) { [void]$errors.Add('翻譯') }
        }
        foreach ($it in $items) {
            if ($it.Lang -ne 'zh' -and $TransCache.ContainsKey($it.Title)) { $it.Original = $it.Title; $it.Title = $TransCache[$it.Title] }
        }
    }

    $prices = New-Object System.Collections.ArrayList
    if (@($CryptoSymbols).Count) {
        $res = $null
        try {
            $syms = '[' + ((@($CryptoSymbols) | ForEach-Object { '"' + $_.Symbol + '"' }) -join ',') + ']'
            # PowerShell 5.1 的 ConvertFrom-Json 會把整個 JSON 陣列當成一個物件輸出，用 ForEach-Object 攤平
            $res = @((Get-Text ('https://api.binance.com/api/v3/ticker/24hr?symbols=' + [Uri]::EscapeDataString($syms))) | ConvertFrom-Json | ForEach-Object { $_ })
        } catch {
            # 整批失敗（例如某個幣下架）時，改成一個一個抓，壞掉的跳過
            $res = @(foreach ($c in $CryptoSymbols) {
                try { (Get-Text ('https://api.binance.com/api/v3/ticker/24hr?symbol=' + $c.Symbol)) | ConvertFrom-Json } catch { [void]$errors.Add($c.Label) }
            })
        }
        foreach ($c in $CryptoSymbols) {
            $r = $res | Where-Object { $_.symbol -eq $c.Symbol } | Select-Object -First 1
            if ($r) { [void]$prices.Add([pscustomobject]@{ Symbol = $c.Symbol; Label = $c.Label; Name = $c.Name; Alert = $c.Alert; Price = [double]$r.lastPrice; Pct = [double]$r.priceChangePercent }) }
        }
    }
    # 美股 / 指數：CNBC 報價（一次請求抓全部；指數代號 ^GSPC → CNBC 用 .SPX 這種格式）
    if (@($StockSymbols).Count) {
        function ConvertTo-CnbcSymbol([string]$s) {
            switch ($s) { '^GSPC' { return '.SPX' } '^IXIC' { return '.IXIC' } '^DJI' { return '.DJI' } }
            if ($s.StartsWith('^')) { return '.' + $s.Substring(1) }
            return $s
        }
        function To-Num([string]$s) {
            $s = $s -replace '[,%+\s]', ''
            $n = 0.0
            if ([double]::TryParse($s, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$n)) { return $n }
            return $null
        }
        try {
            $syms = (@($StockSymbols) | ForEach-Object { ConvertTo-CnbcSymbol $_.Symbol }) -join '|'
            $url = 'https://quote.cnbc.com/quote-html-webservice/restQuote/symbolType/symbol?symbols=' + [Uri]::EscapeDataString($syms) + '&requestMethod=itv&noform=1&partnerId=2&fund=1&exthrs=1&output=json'
            $q = @((Get-Text $url | ConvertFrom-Json).FormattedQuoteResult.FormattedQuote | ForEach-Object { $_ })
            foreach ($s in $StockSymbols) {
                $cs = ConvertTo-CnbcSymbol $s.Symbol
                $r = $q | Where-Object { $_.symbol -eq $cs } | Select-Object -First 1
                $p = if ($r -and [string]$r.code -eq '0') { To-Num $r.last } else { $null }
                if ($null -ne $p) {
                    $pct = To-Num $r.change_pct
                    if ($null -eq $pct) { $pct = 0 }
                    [void]$prices.Add([pscustomobject]@{ Symbol = $s.Symbol; Label = $s.Label; Name = $s.Name; Alert = $s.Alert; Price = $p; Pct = $pct })
                } else { [void]$errors.Add($s.Label) }
            }
        } catch { [void]$errors.Add('CNBC 美股報價') }
    }

    [pscustomobject]@{ Items = $items; Prices = $prices; Errors = $errors }
}

# ------------------------- 介面 -------------------------
$fs  = $FontSize
$fsS = [Math]::Round($fs * 0.8, 1)    # 小字（來源、時間、行情）
$fsH = [Math]::Round($fs * 1.05, 1)   # 標題列

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="幣圈美股快訊" Width="430" Height="660" MinWidth="320" MinHeight="300"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Topmost="True" ResizeMode="CanResizeWithGrip" ShowInTaskbar="True"
        FontFamily="Microsoft JhengHei UI, Segoe UI" FontSize="$fs">
  <!-- 無邊框視窗也能從四個邊和四個角拖曳調整大小 -->
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="0" ResizeBorderThickness="7" GlassFrameThickness="0" CornerRadius="0" UseAeroCaptionButtons="False"/>
  </WindowChrome.WindowChrome>
  <Window.Resources>
    <!-- 這三個顏色會依深色/淺色主題在程式裡替換 -->
    <SolidColorBrush x:Key="IconFg"  Color="#9AA4B2"/>
    <SolidColorBrush x:Key="HoverBg" Color="#22FFFFFF"/>
    <SolidColorBrush x:Key="HoverFg" Color="#FFFFFF"/>
    <Style x:Key="IconBtn" TargetType="Button">
      <Setter Property="Foreground" Value="{DynamicResource IconFg}"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Width" Value="32"/>
      <Setter Property="Height" Value="30"/>
      <Setter Property="FontSize" Value="$fs"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="6">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Background" Value="{DynamicResource HoverBg}"/>
                <Setter Property="Foreground" Value="{DynamicResource HoverFg}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="TabBtn" TargetType="Button" BasedOn="{StaticResource IconBtn}">
      <Setter Property="Width" Value="Auto"/>
      <Setter Property="Padding" Value="14,3"/>
      <Setter Property="Margin" Value="0,0,6,0"/>
      <Setter Property="FontSize" Value="$fsS"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="15" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Opacity" Value="0.8"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border x:Name="RootBorder" CornerRadius="12" Background="#F0121620" BorderBrush="#30FFFFFF" BorderThickness="1">
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
      </Grid.RowDefinitions>

      <!-- 標題列（可拖曳） -->
      <Grid x:Name="Header" Grid.Row="0" Background="Transparent" Margin="12,8,8,2">
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
          <Ellipse x:Name="LiveDot" Width="9" Height="9" Fill="#FF4D4F" Margin="0,0,8,0"/>
          <TextBlock x:Name="HeaderTitle" Text="幣圈 · 美股 即時快訊" Foreground="White" FontWeight="SemiBold" FontSize="$fsH"/>
        </StackPanel>
        <StackPanel x:Name="HeaderBtns" Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="BtnCal"     Style="{StaticResource IconBtn}" ToolTip="美國數據公布行事曆（CPI、非農、FOMC…）" Content="📅"/>
          <Button x:Name="BtnVoice"   Style="{StaticResource IconBtn}" ToolTip="突發通知（跳出通知）開/關"/>
          <Button x:Name="BtnPin"     Style="{StaticResource IconBtn}" ToolTip="置頂 開/關"/>
          <Button x:Name="BtnSettings" Style="{StaticResource IconBtn}" ToolTip="設定：字體大小、深色/淺色、要顯示的幣與美股" Content="⚙"/>
          <Button x:Name="BtnRefresh" Style="{StaticResource IconBtn}" ToolTip="立即更新" Content="⟳"/>
          <Button x:Name="BtnMin"     Style="{StaticResource IconBtn}" ToolTip="縮到右下角通知區（點圖示叫回）" Content="—"/>
          <Button x:Name="BtnClose"   Style="{StaticResource IconBtn}" ToolTip="關閉" Content="✕"/>
        </StackPanel>
      </Grid>

      <!-- 行情列 -->
      <WrapPanel x:Name="Ticker" Grid.Row="1" Margin="12,4,12,4"/>

      <!-- 分類 -->
      <WrapPanel x:Name="Tabs" Grid.Row="2" Orientation="Horizontal" Margin="12,4,12,2">
        <Button x:Name="TabAll"      Style="{StaticResource TabBtn}" Content="全部"   Margin="0,0,6,6" MinHeight="30"/>
        <Button x:Name="TabCrypto"   Style="{StaticResource TabBtn}" Content="幣圈"   Margin="0,0,6,6" MinHeight="30"/>
        <Button x:Name="TabStock"    Style="{StaticResource TabBtn}" Content="美股"   Margin="0,0,6,6" MinHeight="30"/>
        <Button x:Name="TabBreaking" Style="{StaticResource TabBtn}" Content="⚡ 突發" Margin="0,0,6,6" MinHeight="30"/>
        <Button x:Name="TabWatch"    Style="{StaticResource TabBtn}" Content="★ 自選" Margin="0,0,6,6" MinHeight="30" ToolTip="只看提到你在 ⚙ 勾選的幣/股票的新聞"/>
        <Button x:Name="TabImportant" Style="{StaticResource TabBtn}" Margin="0,0,6,6" MinHeight="30" ToolTip="只看重要：價格暴漲暴跌、政策、數據、重要人物、戰爭、突發，以及提到自選標的的新聞"/>
      </WrapPanel>

      <!-- 新聞列表 -->
      <ScrollViewer x:Name="Scroller" Grid.Row="3" VerticalScrollBarVisibility="Auto" Margin="6,0,4,0">
        <StackPanel x:Name="List" Margin="0,0,4,0"/>
      </ScrollViewer>

      <!-- 狀態列 -->
      <StackPanel Grid.Row="4">
        <!-- 有新版本時才出現 -->
        <Border x:Name="UpdateBar" Visibility="Collapsed" Margin="12,6,12,0" Padding="10,6" CornerRadius="8" Background="#2F81F7" Cursor="Hand">
          <TextBlock x:Name="UpdateText" Foreground="#FFFFFF" FontSize="$fsS" TextWrapping="Wrap"/>
        </Border>
        <TextBlock x:Name="Status" Foreground="#6B7685" FontSize="$fsS" Margin="12,6,24,8" TextTrimming="CharacterEllipsis"/>
      </StackPanel>
    </Grid>
  </Border>
</Window>
"@

$window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$ui = @{}
foreach ($n in 'RootBorder','HeaderTitle','HeaderBtns','Tabs','Header','LiveDot','BtnCal','BtnVoice','BtnPin','BtnSettings','BtnRefresh','BtnMin','BtnClose','Ticker','TabAll','TabCrypto','TabStock','TabBreaking','TabWatch','TabImportant','Scroller','List','Status','UpdateBar','UpdateText') {
    $ui[$n] = $window.FindName($n)
}
if (Test-Path $IconPath) { try { $window.Icon = [Windows.Media.Imaging.BitmapFrame]::Create([Uri]$IconPath) } catch {} }
$bc = New-Object Windows.Media.BrushConverter
function Brush([string]$hex) { $bc.ConvertFromString($hex) }

# ------------------------- 狀態 / 設定 -------------------------
$script:Filter     = 'all'
$script:AlertOn    = $true
$script:VoiceOn    = $false        # 通知時是否用語音念出來（預設不念）
$script:Theme      = 'dark'        # dark / light
$script:FontSz     = $FontSize
$script:T          = $Themes['dark']
$script:OnlyImportant = $OnlyImportant
$script:Items      = @{}
$script:FirstLoad  = $true
$script:Prices     = @()
$script:PriceHist  = @{}
$script:SpikeCool  = @{}
$script:LastErr    = @()
$script:LastOk     = $null
$script:Countdown  = $RefreshSeconds
$script:Job        = $null
$script:BalloonUrl = $null
$TransCache = [hashtable]::Synchronized(@{})

# 美國數據公布視窗
$script:Cal          = @()
$script:CalShown     = @()
$script:CalSeen      = @{}      # Id -> 上次看到的實際值（用來判斷「剛公布」）
$script:CalJob       = $null
$script:CalCountdown = 0
$script:CalFirst     = $true
$script:CalErr       = $null
$script:CalOk        = $null
$script:CalWin       = $null
$script:CalUi        = $null
$script:CalOnlyImp   = $false   # true = 只看 ★★★ 以上
$script:CalEvents    = $true    # 是否顯示官員談話等事件
$script:CalOpen      = $false   # 關閉小工具時視窗是否開著（下次自動打開）
$script:CalTopmost   = $true
$script:CalPos       = $null
$script:ShuttingDown = $false

# 行情列選擇（預設 = 清單裡 On 的項目；之後以 settings.json 為準）
$script:CustomCrypto = @()
$script:CustomStock  = @()
$script:SelCrypto = @($CryptoCatalog | Where-Object { $_.On } | ForEach-Object { $_.Symbol })
$script:SelStock  = @($StockCatalog  | Where-Object { $_.On } | ForEach-Object { $_.Symbol })

$saved = $null
if (Test-Path $SettingsPath) {
    try {
        $saved = Get-Content $SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($saved.Width -and $saved.Width -ge 320) { $window.Width = $saved.Width; $window.Height = $saved.Height }
        if ($saved.Filter) { $script:Filter = $saved.Filter }
        if ($null -ne $saved.AlertOn) { $script:AlertOn = [bool]$saved.AlertOn }
        if ($null -ne $saved.VoiceOn -and $null -ne $saved.Theme) { $script:VoiceOn = [bool]$saved.VoiceOn }   # 舊版的 VoiceOn 是別的意思，有 Theme 欄位才是新版設定
        if ($saved.Theme -and $Themes.ContainsKey([string]$saved.Theme)) { $script:Theme = [string]$saved.Theme }
        if ($saved.FontSize -and [double]$saved.FontSize -ge 12 -and [double]$saved.FontSize -le 24) { $script:FontSz = [double]$saved.FontSize }
        if ($null -ne $saved.OnlyImportant) { $script:OnlyImportant = [bool]$saved.OnlyImportant }
        if ($null -ne $saved.Topmost) { $window.Topmost = [bool]$saved.Topmost }
        if ($null -ne $saved.SelCrypto)    { $script:SelCrypto    = @($saved.SelCrypto) }
        if ($null -ne $saved.SelStock)     { $script:SelStock     = @($saved.SelStock) }
        if ($null -ne $saved.CustomCrypto) { $script:CustomCrypto = @($saved.CustomCrypto | ForEach-Object { @{ Label = $_.Label; Name = $_.Name; Symbol = $_.Symbol; Alert = [double]$_.Alert; Custom = $true } }) }
        if ($null -ne $saved.CalOnlyImp) { $script:CalOnlyImp = [bool]$saved.CalOnlyImp }
        if ($null -ne $saved.CalEvents)  { $script:CalEvents  = [bool]$saved.CalEvents }
        if ($null -ne $saved.CalOpen)    { $script:CalOpen    = [bool]$saved.CalOpen }
        if ($null -ne $saved.CalTopmost) { $script:CalTopmost = [bool]$saved.CalTopmost }
        if ($saved.CalPos) { $script:CalPos = @{ Left = [double]$saved.CalPos.Left; Top = [double]$saved.CalPos.Top; Width = [double]$saved.CalPos.Width; Height = [double]$saved.CalPos.Height } }
        if ($null -ne $saved.CustomStock)  { $script:CustomStock  = @($saved.CustomStock  | ForEach-Object { @{ Label = $_.Label; Name = $_.Name; Symbol = $_.Symbol; Alert = [double]$_.Alert; Custom = $true } }) }
    } catch { $saved = $null }
}
$window.WindowStartupLocation = 'Manual'
# 確認存下來的位置還在某個螢幕裡，不然就放回主螢幕右下角
$onScreen = $false
if ($saved -and $null -ne $saved.Left) {
    $vs = [System.Windows.SystemParameters]
    if ($saved.Left -ge $vs::VirtualScreenLeft -and $saved.Left -lt ($vs::VirtualScreenLeft + $vs::VirtualScreenWidth - 50) -and
        $saved.Top -ge $vs::VirtualScreenTop -and $saved.Top -lt ($vs::VirtualScreenTop + $vs::VirtualScreenHeight - 50)) {
        $window.Left = $saved.Left; $window.Top = $saved.Top; $onScreen = $true
    }
}
if (-not $onScreen) {
    $wa = [System.Windows.SystemParameters]::WorkArea
    $window.Left = $wa.Right - $window.Width - 16
    $window.Top  = $wa.Bottom - $window.Height - 16
}

function Save-Settings {
    try {
        [pscustomobject]@{
            Left = $window.Left; Top = $window.Top; Width = $window.ActualWidth; Height = $window.ActualHeight
            Filter = $script:Filter; AlertOn = $script:AlertOn; OnlyImportant = $script:OnlyImportant; Topmost = $window.Topmost
            Theme = $script:Theme; FontSize = $script:FontSz; VoiceOn = $script:VoiceOn
            CalOnlyImp = $script:CalOnlyImp; CalEvents = $script:CalEvents; CalOpen = $script:CalOpen; CalTopmost = $script:CalTopmost
            CalPos = $(if ($script:CalWin) { [pscustomobject]@{ Left = $script:CalWin.Left; Top = $script:CalWin.Top; Width = $script:CalWin.ActualWidth; Height = $script:CalWin.ActualHeight } }
                       elseif ($script:CalPos) { [pscustomobject]$script:CalPos } else { $null })
            SelCrypto = @($script:SelCrypto); SelStock = @($script:SelStock)
            CustomCrypto = @($script:CustomCrypto | ForEach-Object { [pscustomobject]@{ Label = $_.Label; Name = $_.Name; Symbol = $_.Symbol; Alert = $_.Alert } })
            CustomStock  = @($script:CustomStock  | ForEach-Object { [pscustomobject]@{ Label = $_.Label; Name = $_.Name; Symbol = $_.Symbol; Alert = $_.Alert } })
        } | ConvertTo-Json -Depth 5 | Set-Content $SettingsPath -Encoding UTF8
    } catch {}
}

# 目前要顯示的行情（依清單順序，自訂的排在後面）
function Get-ActiveCrypto { @(@($CryptoCatalog) + @($script:CustomCrypto) | Where-Object { $script:SelCrypto -contains $_.Symbol }) }
function Get-ActiveStock  { @(@($StockCatalog)  + @($script:CustomStock)  | Where-Object { $script:SelStock  -contains $_.Symbol }) }

# ------------------------- 通知：語音 + 系統通知 -------------------------
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.SetOutputToDefaultAudioDevice()
$voices  = $synth.GetInstalledVoices() | Where-Object Enabled | ForEach-Object VoiceInfo
$zhVoice = $voices | Where-Object { $_.Culture.Name -eq 'zh-TW' } | Select-Object -First 1
if (-not $zhVoice) { $zhVoice = $voices | Where-Object { $_.Culture.Name -like 'zh*' } | Select-Object -First 1 }

function Speak-Text([string]$text) {
    $pb = New-Object System.Speech.Synthesis.PromptBuilder
    if ($zhVoice) { $pb.StartVoice($zhVoice) }
    $pb.AppendText($text)
    if ($zhVoice) { $pb.EndVoice() }
    [void]$synth.SpeakAsync($pb)
}

# 右下角通知區圖示（突發時跳出通知、點圖示叫回視窗）
$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = if (Test-Path $IconPath) { New-Object System.Drawing.Icon $IconPath } else { [System.Drawing.SystemIcons]::Information }
$tray.Text = '幣圈美股快訊'
$tray.Visible = $true
function Show-Window { $window.Show(); $window.WindowState = 'Normal'; $window.Activate() | Out-Null }
$tray.Add_MouseClick({ param($s, $e) if ($e.Button -eq 'Left') { Show-Window } })
$tray.Add_BalloonTipClicked({ if ($script:BalloonUrl) { Start-Process $script:BalloonUrl } })

function Send-Alert([string]$head, [string]$body, [string]$url) {
    if (-not $script:AlertOn) { return }
    if ($script:VoiceOn) { Speak-Text ($head + '：' + $body) }   # 預設不念，可在 ⚙ 設定開啟
    $script:BalloonUrl = $url
    $tray.ShowBalloonTip(8000, $head, $body, [System.Windows.Forms.ToolTipIcon]::Warning)
}

# 突發判斷
$BreakRx   = [regex]::new(($BreakingKeywords | ForEach-Object { [regex]::Escape($_) }) -join '|', 'IgnoreCase')
$ExcludeRx = [regex]::new(($ExcludeKeywords  | ForEach-Object { [regex]::Escape($_) }) -join '|', 'IgnoreCase')
# 漲跌幅 ≥ 5% 的快訊也算突發，例如「英偉達跌超8%」「AVAX漲幅擴大至11%」
$BigMoveRx = [regex]'(漲|跌)(幅)?(超過|超|逾|達|擴大至|擴大到|重新超過)?\s*([5-9]|[1-9]\d)(\.\d+)?\s*%'
function Test-Breaking($it) {
    $text = $it.Title + ' ' + $it.Original
    if ($ExcludeRx.IsMatch($text)) { return $false }
    # 只看第一句，避免盤勢總結裡順帶提到某檔個股漲 5% 也被當成突發
    $first = ($it.Title -split '[，。,；;]')[0]
    if ($BigMoveRx.IsMatch($first)) { return $true }
    return $BreakRx.IsMatch($text)
}

# 重要性分類：回傳 '突發' / '戰爭' / '價格' / '政策' / '數據' / '人物'，都不符合回傳 $null
$KindRx = [ordered]@{}
foreach ($k in $ImportantRules.Keys) { $KindRx[$k] = [regex]::new($ImportantRules[$k], 'IgnoreCase') }
$IndexMoveRx = [regex]::new($IndexMovePattern, 'IgnoreCase')
$OtherRegionRx = [regex]::new($OtherRegionPattern)
$UsCryptoRx    = [regex]::new($UsCryptoPattern, 'IgnoreCase')
function Get-Kind($it) {
    if ($it.Breaking) { return '突發' }
    $text = $it.Title + ' ' + $it.Original
    if ($ExcludeRx.IsMatch($text)) { return $null }
    if ($OtherRegionRx.IsMatch($it.Title) -and -not $UsCryptoRx.IsMatch($it.Title)) { return $null }
    $first = ($it.Title -split '[，。,；;]')[0]
    foreach ($k in $KindRx.Keys) {
        if ($k -eq '價格' -and ($IndexMoveRx.IsMatch($first) -or $BigMoveRx.IsMatch($first))) { return $k }
        if ($KindRx[$k].IsMatch($text)) { return $k }
    }
    return $null
}

# 自選標的比對：依目前 ⚙ 勾選的標的建立比對規則
function Update-WatchRx {
    $list = New-Object System.Collections.ArrayList
    foreach ($w in @(Get-ActiveCrypto) + @(Get-ActiveStock)) {
        $aliases = @()
        $aliases += ($w.Label -replace '^\^', '')
        # 內建標的用別名表；自己新增的才用名稱（避免「Strategy」這種一般英文字誤抓）
        if ($WatchAliases.ContainsKey($w.Symbol)) { $aliases += $WatchAliases[$w.Symbol] }
        elseif ($w.Name) { $aliases += $w.Name }
        $parts = foreach ($a in ($aliases | Where-Object { $_ } | Select-Object -Unique)) {
            $e = [regex]::Escape($a)
            if ($a -match '^[\x00-\x7F]+$') {
                # 英文：前後不能接英文字母；4 字元以內區分大小寫（避免 LINK/OP/SOL 抓到一般英文單字）
                if ($a.Length -le 4) { "(?-i:(?<![A-Za-z])$e(?![A-Za-z]))" } else { "(?i:(?<![A-Za-z])$e(?![A-Za-z]))" }
            } else { $e }
        }
        [void]$list.Add([pscustomobject]@{ Label = ($w.Label -replace '^\^', ''); Rx = [regex]::new(($parts -join '|')) })
    }
    $script:WatchRx = $list
}
function Get-Watch($it) {
    $text = $it.Title + ' ' + $it.Original
    $hits = @($script:WatchRx | Where-Object { $_.Rx.IsMatch($text) } | ForEach-Object { $_.Label })
    if ($hits.Count) { return ($hits | Select-Object -First 3) -join ' ' }
    return $null
}
function Refresh-Watch {
    Update-WatchRx
    foreach ($it in $script:Items.Values) { $it.Watch = Get-Watch $it }
}
$script:WatchRx = @()

# ------------------------- 利多 / 利空 判斷（關鍵字規則，僅供參考）-------------------------
# 由上往下比對；比對到的字會被遮掉，所以「降息機率下降」這種組合要放在單純的「降息」前面
# 每條：@(正則, 方向 +1 利多 / -1 利空, 判斷依據)
$ImpactRules = @(
    # --- 貨幣政策的「預期變化」（要放在單純的降息/升息前面）---
    ,@('(降息|減息)(預期|機率|押注|希望|可能性)?.{0,6}(降低|下降|減弱|下修|消退|推遲|延後|落空|渺茫|降溫)', -1, '降息預期降溫')
    ,@('(升息|加息)(預期|機率|押注|可能性)?.{0,6}(降低|下降|減弱|下修|消退|推遲|延後|落空|渺茫|降溫)', 1, '升息預期降溫')
    ,@('(降息|減息)(預期|機率|押注|可能性).{0,6}(升高|上升|增加|升溫|大增|飆升)', 1, '降息預期升溫')
    ,@('(升息|加息)(預期|機率|押注|可能性).{0,6}(升高|上升|增加|升溫|大增|飆升)', -1, '升息預期升溫')
    # --- 通膨數據 ---
    ,@('(CPI|PPI|PCE|通膨|通脹|物價).{0,14}(高於預期|超預期|超出預期|超過預期|升溫|加速|意外上升|創.{0,4}新高)', -1, '通膨高於預期')
    ,@('(CPI|PPI|PCE|通膨|通脹|物價).{0,14}(低於預期|不及預期|遜於預期|降溫|放緩|回落|意外下降)', 1, '通膨低於預期')
    # --- 財報 / 評級 ---
    ,@('(財報|營收|獲利|盈利|淨利|每股收益|EPS|業績|財測|指引).{0,16}(超預期|優於預期|好於預期|高於預期|超出預期|創新高|創紀錄|上調|上修)', 1, '財報/財測優於預期')
    ,@('(財報|營收|獲利|盈利|淨利|每股收益|EPS|業績|財測|指引).{0,16}(不及預期|遜於預期|低於預期|下調|下修|疲軟|下滑|虧損擴大)', -1, '財報/財測不如預期')
    ,@('(上調|調升|上修).{0,8}(目標價|評級)|(目標價|評級).{0,6}(上調|調升|上修)|升級至.{0,4}(買入|增持|跑贏)', 1, '上調評級/目標價')
    ,@('(下調|調降|下修).{0,8}(目標價|評級)|(目標價|評級).{0,6}(下調|調降|下修)|降級至.{0,4}(賣出|減持|跑輸)', -1, '下調評級/目標價')
    # --- 關稅 / 地緣（緩和的放前面）---
    ,@('關稅.{0,8}(暫停|豁免|降低|下調|取消|延後|推遲|撤銷|休戰)|(暫停|豁免|降低|下調|取消|延後|推遲|撤銷).{0,8}關稅', 1, '關稅降溫')
    ,@('(加徵|提高|上調|徵收|威脅|揚言|宣布|擴大).{0,8}關稅|關稅.{0,4}(上調|提高|升級)', -1, '關稅升溫')
    ,@('停火|停戰|和談|和平協議|(貿易|關稅|核|停火|停戰)(協議|協定)|談判.{0,4}(進展|突破)|局勢緩和|緩和緊張', 1, '地緣緊張緩和')
    ,@('開戰|空襲|導彈|飛彈|轟炸|襲擊|入侵|軍事行動|戰爭升級|宣戰|發射.{0,4}(導彈|飛彈)', -1, '地緣衝突')
    ,@('(實施|宣布|加強|擴大|新一輪).{0,6}制裁', -1, '制裁升級')
    ,@('解除.{0,6}制裁', 1, '解除制裁')
    # --- ETF / 資金流 ---
    ,@('ETF.{0,10}(拒絕|否決|推遲|延後|駁回)|(拒絕|否決|推遲|延後|駁回).{0,10}ETF', -1, 'ETF 受阻')
    ,@('ETF.{0,10}(獲批|批准|核准|通過|獲准|上市)|(批准|核准|通過).{0,10}ETF', 1, 'ETF 獲批')
    ,@('淨流入|資金流入|大幅流入', 1, '資金淨流入')
    ,@('淨流出|資金流出|大幅流出', -1, '資金淨流出')
    # --- 交易所 ---
    ,@('(幣安|Binance|Coinbase|Upbit|OKX|Bithumb|Robinhood|Bybit|Kraken).{0,12}(上線|上架|上幣|新增.{0,6}交易對|將上線)', 1, '交易所上幣')
    ,@('下架|終止.{0,6}交易|暫停.{0,6}(交易|充提|提款|提幣)|停牌', -1, '下架/暫停交易')
    # --- 法律 / 監管（解除的放前面）---
    ,@('撤訴|撤銷.{0,15}(訴訟|起訴|指控)|駁回.{0,15}(訴訟|起訴)|達成和解|結束調查', 1, '訴訟/調查解除')
    ,@('(穩定幣|加密|數位資產|數字資產|比特幣|市場結構).{0,15}(法案|立法|行政令).{0,8}(通過|簽署|生效|獲批)|(通過|簽署).{0,8}(穩定幣|加密|數位資產).{0,8}(法案|行政令)', 1, '加密法案推進')
    ,@('戰略(比特幣)?儲備|納入.{0,6}儲備', 1, '納入戰略儲備')
    ,@('起訴|訴訟|立案調查|展開調查|罰款|指控|逮捕|傳喚|凍結資產', -1, '監管/法律風險')
    ,@('禁止|封禁|取締|打擊|全面禁', -1, '監管打壓')
    # --- 資安 / 信用風險 ---
    ,@('駭客|黑客|被駭|遭駭|被盜|遭盜|盜走|漏洞|遭攻擊|被攻擊|攻擊事件|exploit|hacked', -1, '資安事件')
    ,@('破產|倒閉|擠兌|違約|脫鉤|資不抵債', -1, '信用/流動性風險')
    ,@('爆倉|清算潮|多頭清算|大量清算', -1, '大量清算')
    ,@('政府停擺|關門危機', -1, '政府停擺')
    # --- 買賣力道 ---
    ,@('解鎖', -1, '代幣解鎖賣壓')
    ,@('增持|買入|購入|增購|加倉|建倉|買進|抄底|回購|購買了', 1, '大戶/機構買進')
    ,@('減持|拋售|拋壓|賣出|出售|清倉|砸盤|轉入.{0,8}交易所|充值至|轉入幣安', -1, '拋售壓力')
    # --- 貨幣政策（單純提到）---
    ,@('降息|減息|寬鬆|降準|放水|rate cut', 1, '降息/寬鬆')
    ,@('升息|加息|緊縮|縮表|鷹派|rate hike', -1, '升息/緊縮')
    ,@('鴿派', 1, '偏鴿派')
    # --- 價格本身的走勢 ---
    ,@('突破.{0,4}[\d,.]+\s*(美元|萬|點|關口|大關)|突破.{0,4}(關口|大關|阻力|前高)|(股價|幣價|價格).{0,4}創.{0,4}(新高|紀錄)|創.{0,4}歷史新高|大漲|飆升|暴漲|急漲|拉升|漲超|漲逾|強勢反彈|surge|soar|rall(y|ies)', 1, '價格走強')
    ,@('跌破|暴跌|崩盤|閃崩|重挫|跳水|大跌|急跌|下挫|創.{0,4}新低|跌超|跌逾|plunge|crash|tumble|slump', -1, '價格走弱')
)
# 簡轉繁有些字轉不完整（于、凈、后），規則裡的「於 / 淨」兩種寫法都接受
$ImpactRx  = @($ImpactRules | ForEach-Object { @{ Rx = [regex]::new(($_[0] -replace '於', '[於于]' -replace '淨', '[淨凈]'), 'IgnoreCase'); Dir = [int]$_[1]; Why = $_[2] } })
$EarnNumRx = [regex]'(營收|收入|每股收益|每股盈利|每ADS收益|EPS)[^，。；;\d]{0,16}([\d,]+(?:\.\d+)?)[^，。；;\d]{0,10}[，,]\s*(預估|預期|市場預期)\s*([\d,]+(?:\.\d+)?)'
# 關鍵字前面出現這些字 → 方向相反（例如「不會降息」「否認被駭」）
$NegateRx  = [regex]'(不|未|沒有|沒|否認|暫不|拒絕|無意|不會|不再|並未|尚未|難以|排除)(急於|急著|再|會|能|打算|考慮|計劃|願意?)?\s*$'

# ---- 美國經濟數據：實際 vs 預期，依「指標種類」決定高於預期是利多還是利空 ----
# 目前市場主要看聯準會利率路徑：通膨升溫 / 就業偏強 → 降息預期降溫（利空）；反之利多
# 景氣類（GDP、零售、PMI…）高於預期視為經濟數據優於預期（利多）
# 每條：@(指標關鍵字, 高於預期時的方向, 高於預期的說明, 低於預期的說明)
$DataRules = @(
    ,@('CPI|PPI|PCE|通膨|通脹|物價|時薪|薪資|工資|進口價格|出口價格|平減指數|通膨預期', -1, '通膨高於預期', '通膨低於預期')
    ,@('失業金|失業救濟|失業率|裁員|挑戰者', 1, '就業降溫、利於降息', '就業偏強、降息預期降溫')
    ,@('非農|就業人數|ADP|職位空缺|JOLTS|新增就業', -1, '就業偏強、降息預期降溫', '就業降溫、利於降息')
    ,@('GDP|零售|PMI|ISM|製造業|制造業|服務業|工業產出|工業生產|耐用品|消費者信心|密西根|費城|紐約聯|新屋|成屋|營建|房屋|樂觀|個人支出|個人收入|商業庫存', 1, '經濟數據優於預期', '經濟數據不如預期')
)
$DataRx = @($DataRules | ForEach-Object { @{ Rx = [regex]::new($_[0], 'IgnoreCase'); Dir = [int]$_[1]; Hi = $_[2]; Lo = $_[3] } })
# 「美國11月14日當周首次申請失業救濟人數 20.3萬人，預期 19.8萬人，前值 20萬人」
$DataNumRx = [regex]'(-?[\d,]+(?:\.\d+)?)\s*(%|萬人|萬戶|萬桶|萬|億美元|億|點)?\s*[，,]\s*預期(值)?\s*(-?[\d,]+(?:\.\d+)?)'

# 回傳 @{ Dir; Why }；不是可判斷的數據就回傳 $null
function Get-DataImpact([string]$name, [string]$actual, [string]$forecast) {
    $a = 0.0; $f = 0.0
    $ci = [Globalization.CultureInfo]::InvariantCulture
    if (-not [double]::TryParse(($actual -replace '[,%]', ''), 'Float', $ci, [ref]$a)) { return $null }
    if (-not [double]::TryParse(($forecast -replace '[,%]', ''), 'Float', $ci, [ref]$f)) { return $null }
    if ($a -eq $f) { return $null }
    foreach ($r in $DataRx) {
        if ($r.Rx.IsMatch($name)) {
            $hi = $a -gt $f
            $dir = if ($hi) { $r.Dir } else { -$r.Dir }
            return @{ Dir = $dir; Why = $(if ($hi) { '高於預期：' + $r.Hi } else { '低於預期：' + $r.Lo }) }
        }
    }
    return $null
}

# 回傳 @{ Dir = 1 / -1 / 0; Text = '偏利多' / '偏利空' / '多空交錯'; Why = '…' }，沒有判斷依據就回傳 $null
function Get-Impact($it) {
    # 只看前 150 個字，避免長篇快訊後面順帶提到的內容影響判斷
    $text = [string]$it.Title
    if ($text.Length -gt 150) { $text = $text.Substring(0, 150) }
    $sb = New-Object System.Text.StringBuilder $text
    $up = New-Object System.Collections.ArrayList
    $down = New-Object System.Collections.ArrayList
    # 美國經濟數據快訊「XX 20.3萬人，預期 19.8萬人」→ 依指標種類判斷
    if ($text -match '美國') {
        $dm = $DataNumRx.Match($text)
        if ($dm.Success) {
            $di = Get-DataImpact $text.Substring(0, $dm.Index) $dm.Groups[1].Value $dm.Groups[4].Value
            if ($di) {
                if ($di.Dir -gt 0) { [void]$up.Add($di.Why) } else { [void]$down.Add($di.Why) }
                # 數據快訊以數據本身為準，不再套用其他關鍵字
                return @{ Dir = $di.Dir; Text = $(if ($di.Dir -gt 0) { '偏利多' } else { '偏利空' }); Why = $di.Why }
            }
        }
    }
    # 財報常寫成「營收 1,888.4 億美元，預估 1,871.7 億美元」→ 直接比數字
    #    營收和每股收益各比一次（例如營收優於預估、但每股收益低於預估 → 多空交錯）
    $seen = @{}
    foreach ($em in $EarnNumRx.Matches([string]$it.Title)) {
        $a = 0.0; $f = 0.0
        if ([double]::TryParse(($em.Groups[2].Value -replace ',', ''), [ref]$a) -and [double]::TryParse(($em.Groups[4].Value -replace ',', ''), [ref]$f) -and $f -ne 0) {
            $name = if ($em.Groups[1].Value -match '營收|收入') { '營收' } else { '每股收益' }
            if ($seen.ContainsKey($name)) { continue }
            $seen[$name] = $true
            if ($a -gt $f) { [void]$up.Add("${name}高於預估") } elseif ($a -lt $f) { [void]$down.Add("${name}低於預估") }
        }
    }
    foreach ($r in $ImpactRx) {
        foreach ($m in $r.Rx.Matches($sb.ToString())) {
            $before = $sb.ToString(0, $m.Index)
            if ($before.Length -gt 6) { $before = $before.Substring($before.Length - 6) }
            $dir = if ($NegateRx.IsMatch($before)) { -$r.Dir } else { $r.Dir }
            $why = if ($dir -ne $r.Dir) { '否定：' + $r.Why } else { $r.Why }
            $list = $up
            if ($dir -lt 0) { $list = $down }
            if (-not $list.Contains($why)) { [void]$list.Add($why) }
            # 遮掉已比對的字，避免被後面較籠統的規則重複計算
            [void]$sb.Remove($m.Index, $m.Length).Insert($m.Index, ([string][char]0x2591) * $m.Length)
        }
    }
    if (-not $up.Count -and -not $down.Count) { return $null }
    $net = $up.Count - $down.Count
    if ($net -gt 0)     { return @{ Dir = 1;  Text = '偏利多';   Why = ($up -join '、') + $(if ($down.Count) { '（但也有：' + ($down -join '、') + '）' } else { '' }) } }
    elseif ($net -lt 0) { return @{ Dir = -1; Text = '偏利空';   Why = ($down -join '、') + $(if ($up.Count) { '（但也有：' + ($up -join '、') + '）' } else { '' }) } }
    else                { return @{ Dir = 0;  Text = '多空交錯'; Why = '利多：' + ($up -join '、') + '；利空：' + ($down -join '、') } }
}

# 依價格決定小數位數：BTC 75,000 / SOL 87.34 / XRP 1.057 / DOGE 0.06823
function Get-PriceFormat([double]$price) {
    if ($price -ge 1000) { return '{0:N0}' }
    if ($price -ge 10)   { return '{0:N2}' }
    if ($price -ge 1)    { return '{0:N3}' }
    if ($price -ge 0.01) { return '{0:N4}' }
    return '{0:N6}'
}
# 單價太小的幣（例如 LUNC 0.00006 會顯示成 0.0000）→ 自動乘 1000 並在名稱前加 1000，
# 跟幣安合約的 1000LUNC、1000PEPE、1000SHIB 寫法一樣；乘一次還是太小就再乘（1000000XXX）
function Get-PriceDisplay($p) {
    $price = [double]$p.Price; $label = $p.Label; $name = $p.Name; $mult = 1
    while ($price -gt 0 -and $price -lt 0.0001 -and $mult -lt 1000000) { $price *= 1000; $mult *= 1000 }
    if ($mult -gt 1) { $label = "$mult$label"; $name = "$mult$name" }
    return @{ Label = $label; Name = $name; Text = ((Get-PriceFormat $price) -f $price) }
}

# 價格急漲急跌偵測
function Check-Spikes {
    $now = Get-Date
    foreach ($p in $script:Prices) {
        if (-not $p.Alert -or -not $p.Price) { continue }
        if (-not $script:PriceHist.ContainsKey($p.Label)) { $script:PriceHist[$p.Label] = New-Object System.Collections.ArrayList }
        $h = $script:PriceHist[$p.Label]
        [void]$h.Add([pscustomobject]@{ T = $now; P = $p.Price })
        while ($h.Count -and ($now - $h[0].T).TotalMinutes -gt $SpikeMinutes) { $h.RemoveAt(0) }
        if ($h.Count -lt 2) { continue }
        if ($script:SpikeCool.ContainsKey($p.Label) -and ($now - $script:SpikeCool[$p.Label]).TotalMinutes -lt 30) { continue }
        $base = $h[0].P
        $chg = ($p.Price - $base) / $base * 100
        if ([Math]::Abs($chg) -ge $p.Alert) {
            $script:SpikeCool[$p.Label] = $now
            $mins = [int][Math]::Max(1, [Math]::Round(($now - $h[0].T).TotalMinutes))
            $word = if ($chg -gt 0) { '急漲' } else { '急跌' }
            $pd = Get-PriceDisplay $p
            Send-Alert ("行情警報｜$($pd.Name)$word") ("{0} {1} 分鐘內{2} {3:N2}%，目前 {4}" -f $pd.Name, $mins, $word, [Math]::Abs($chg), $pd.Text) $null
        }
    }
}

# ------------------------- 繪製 -------------------------
function Format-Ago([datetime]$t) {
    $d = (Get-Date) - $t
    if ($d.TotalMinutes -lt 1)  { return '剛剛' }
    if ($d.TotalMinutes -lt 60) { return ('{0} 分鐘前' -f [int][Math]::Floor($d.TotalMinutes)) }
    if ($d.TotalHours -lt 24)   { return ('{0} 小時前' -f [int][Math]::Floor($d.TotalHours)) }
    return $t.ToString('MM/dd HH:mm')
}

function Pass-Filter($it) {
    if ($script:OnlyImportant -and -not $it.Kind -and -not $it.Watch) { return $false }
    switch ($script:Filter) {
        'all'      { return $true }
        'breaking' { return [bool]$it.Breaking }
        'watch'    { return [bool]$it.Watch }
        default    { return $it.Cat -eq $script:Filter }
    }
}

function Render-Buttons {
    $ui.BtnVoice.Content = if ($script:AlertOn) { '🔔' } else { '🔕' }
    $ui.BtnPin.Content   = '📌'
    $ui.TabImportant.Content    = if ($script:OnlyImportant) { '✓ 只看重要' } else { '顯示全部' }
    $T = $script:T
    $ui.TabImportant.Background = Brush $(if ($script:OnlyImportant) { $T.ImpOnBg } else { $T.TabBg })
    $ui.TabImportant.Foreground = Brush $(if ($script:OnlyImportant) { $T.ImpOnFg } else { $T.TabFg })
    $ui.BtnPin.Opacity   = if ($window.Topmost) { 1 } else { 0.4 }
    foreach ($p in @(@('TabAll','all'), @('TabCrypto','crypto'), @('TabStock','stock'), @('TabBreaking','breaking'), @('TabWatch','watch'))) {
        $b = $ui[$p[0]]
        if ($script:Filter -eq $p[1]) {
            $b.Background = Brush $(if ($p[1] -eq 'breaking') { '#D9363E' } else { '#2F81F7' }); $b.Foreground = Brush '#FFFFFF'
        } else { $b.Background = Brush $T.TabBg; $b.Foreground = Brush $T.TabFg }
    }
}

# 套用字體大小與深色/淺色主題（啟動時、在 ⚙ 設定按儲存時呼叫）
function Set-FontSizes([double]$size) {
    $script:fs  = $size
    $script:fsS = [Math]::Round($size * 0.8, 1)    # 小字（來源、時間、行情、分頁）
    $script:fsH = [Math]::Round($size * 1.05, 1)   # 標題列
}
function Apply-Appearance {
    Set-FontSizes $script:FontSz
    $script:T = $Themes[$script:Theme]
    $T = $script:T
    $window.Resources['IconFg']  = Brush $T.Muted
    $window.Resources['HoverBg'] = Brush $T.Hover
    $window.Resources['HoverFg'] = Brush $T.Title
    $ui.RootBorder.Background  = Brush $T.WinBg
    $ui.RootBorder.BorderBrush = Brush $T.WinBorder
    $window.FontSize = $fs
    $ui.HeaderTitle.Foreground = Brush $T.Title
    $ui.HeaderTitle.FontSize   = $fsH
    foreach ($b in $ui.HeaderBtns.Children) { $b.FontSize = $fs }
    foreach ($b in $ui.Tabs.Children) { $b.FontSize = $fsS }
    $ui.Status.Foreground = Brush $T.Dim
    $ui.Status.FontSize   = $fsS
    Render-Buttons; Render-Ticker; Render-List
    # 數據視窗開著的話，用新的字體與配色重開一次
    if ($script:CalWin) { $script:CalWin.Close(); Show-CalWindow }
}

function Render-Ticker {
    $ui.Ticker.Children.Clear()
    $active = @(Get-ActiveCrypto) + @(Get-ActiveStock) | ForEach-Object { $_.Symbol }
    $shown = @($script:Prices | Where-Object { $active -contains $_.Symbol })
    if (-not $shown.Count) {
        $hint = New-Object Windows.Controls.TextBlock
        $hint.Text = if (@($active).Count) { '行情載入中…' } else { '沒有選擇任何幣或美股，點 ⚙ 選擇要顯示的項目' }
        $hint.Foreground = Brush $script:T.Dim; $hint.FontSize = $fsS
        [void]$ui.Ticker.Children.Add($hint)
    }
    foreach ($p in $shown) {
        $sp = New-Object Windows.Controls.StackPanel
        $sp.Orientation = 'Horizontal'; $sp.Margin = '0,2,14,2'
        $l = New-Object Windows.Controls.TextBlock
        $pd = Get-PriceDisplay $p
        $l.Text = $pd.Label + ' '; $l.Foreground = Brush $script:T.Muted; $l.FontSize = $fsS
        if ($pd.Label -ne $p.Label) { $sp.ToolTip = '{0} 實際單價 {1} 美元（價格太小，顯示為 {2} 枚的價格）' -f $p.Label, ([decimal]$p.Price).ToString(), ($pd.Label -replace [regex]::Escape($p.Label) + '$', '') }
        $v = New-Object Windows.Controls.TextBlock
        $arrow = if ($p.Pct -ge 0) { '▲' } else { '▼' }
        $v.Text = $pd.Text + (' {0}{1:N2}%' -f $arrow, [Math]::Abs($p.Pct))
        $v.FontSize = $fsS; $v.FontWeight = 'SemiBold'
        $v.Foreground = Brush $(if ($p.Pct -ge 0) { $script:T.Up } else { $script:T.Down })
        [void]$sp.Children.Add($l); [void]$sp.Children.Add($v)
        [void]$ui.Ticker.Children.Add($sp)
    }
}

function New-Tag([string]$text, [string]$bg, [string]$fg) {
    $tag = New-Object Windows.Controls.Border
    $tag.CornerRadius = '4'; $tag.Padding = '6,0,6,1'; $tag.Margin = '0,0,8,0'
    $tag.Background = Brush $bg
    $tt = New-Object Windows.Controls.TextBlock
    $tt.Text = $text; $tt.FontSize = $fsS; $tt.Foreground = Brush $fg
    $tag.Child = $tt
    return $tag
}

function Render-List {
    $ui.List.Children.Clear()
    $T = $script:T
    $now = Get-Date
    $list = $script:Items.Values | Where-Object { Pass-Filter $_ } | Sort-Object Time -Descending | Select-Object -First $MaxItems
    foreach ($it in $list) {
        $isNew = $it.IsNew -and (($now - $it.FirstSeen).TotalMinutes -lt 15)

        $card = New-Object Windows.Controls.Border
        $card.Margin = '6,0,0,7'; $card.Padding = '12,8,12,10'; $card.CornerRadius = '8'
        $card.Background = Brush $(if ($it.Breaking) { $T.CardBreak } elseif ($isNew) { $T.CardNew } else { $T.Card })
        $card.BorderThickness = '3,0,0,0'
        $card.BorderBrush = Brush $(if ($it.Breaking) { '#FF4D4F' } elseif ($isNew) { '#FFB020' } else { '#00000000' })
        $card.Cursor = 'Hand'
        $card.Tag = $it.Url
        $tip = $it.Title
        if ($it.Original) { $tip += "`n原文：" + $it.Original }
        $card.ToolTip = $tip + "`n" + $it.Time.ToString('yyyy/MM/dd HH:mm') + '  (點擊開啟原文)'

        $sp = New-Object Windows.Controls.StackPanel

        $meta = New-Object Windows.Controls.WrapPanel
        $meta.Margin = '0,0,0,4'
        if ($it.Watch) { [void]$meta.Children.Add((New-Tag ('★ ' + $it.Watch) '#C99A06' '#1A1400')) }
        if ($it.Breaking) { [void]$meta.Children.Add((New-Tag '⚡ 突發' '#D9363E' '#FFFFFF')) }
        elseif ($it.Kind) {
            $kc = switch ($it.Kind) { '戰爭' { '#B4472F' } '價格' { '#8A5A00' } '政策' { '#5B3FA8' } '數據' { '#1F6F6B' } default { '#44506A' } }
            [void]$meta.Children.Add((New-Tag $it.Kind $kc '#FFFFFF'))
        }
        # 對價格的影響（關鍵字判斷）：綠 = 偏利多、紅 = 偏利空，滑鼠移上去看依據
        if ($it.Impact) {
            $im = $it.Impact
            $itag = if ($im.Dir -gt 0) { New-Tag ('▲ ' + $im.Text) $T.Up '#FFFFFF' }
                    elseif ($im.Dir -lt 0) { New-Tag ('▼ ' + $im.Text) $T.Down '#FFFFFF' }
                    else { New-Tag ('⇅ ' + $im.Text) $T.TransBg $T.Text }
            $itag.ToolTip = '判斷依據：' + $im.Why + "`n（依關鍵字自動判斷，僅供參考，不構成投資建議）"
            [void]$meta.Children.Add($itag)
        }
        if ($it.Cat -eq 'crypto') { [void]$meta.Children.Add((New-Tag $it.Source $T.CryptoTagBg $T.CryptoTagFg)) }
        else { [void]$meta.Children.Add((New-Tag $it.Source $T.StockTagBg $T.StockTagFg)) }
        if ($it.Original) { [void]$meta.Children.Add((New-Tag '譯' $T.TransBg $T.TransFg)) }
        $time = New-Object Windows.Controls.TextBlock
        $time.Text = $it.Time.ToString('HH:mm') + ' · ' + (Format-Ago $it.Time)
        $time.FontSize = $fsS; $time.Foreground = Brush $T.Time; $time.VerticalAlignment = 'Center'
        [void]$meta.Children.Add($time)
        if ($isNew) {
            $nw = New-Object Windows.Controls.TextBlock
            $nw.Text = '  NEW'; $nw.FontSize = $fsS; $nw.FontWeight = 'Bold'; $nw.Foreground = Brush '#FFB020'; $nw.VerticalAlignment = 'Center'
            [void]$meta.Children.Add($nw)
        }

        $title = New-Object Windows.Controls.TextBlock
        $title.Text = $it.Title; $title.TextWrapping = 'Wrap'; $title.Foreground = Brush $T.Text
        $title.FontSize = $fs; $title.LineHeight = [Math]::Round($fs * 1.45)

        [void]$sp.Children.Add($meta); [void]$sp.Children.Add($title)
        $card.Child = $sp
        $card.Add_MouseEnter({ param($s, $e) $s.Opacity = 0.85 })
        $card.Add_MouseLeave({ param($s, $e) $s.Opacity = 1 })
        $card.Add_MouseLeftButtonUp({ param($s, $e) if ($s.Tag) { Start-Process $s.Tag } })
        [void]$ui.List.Children.Add($card)
    }
    if ($ui.List.Children.Count -eq 0) {
        $empty = New-Object Windows.Controls.TextBlock
        $empty.Text = if ($script:FirstLoad) { '載入中…（第一次要翻譯英文標題，約需 10 秒）' } elseif ($script:Filter -eq 'breaking') { '目前沒有突發新聞' } elseif ($script:Filter -eq 'watch') { '目前沒有提到自選標的的新聞（可按 ⚙ 調整要追蹤的幣與股票）' } elseif ($script:OnlyImportant) { '目前沒有重要新聞（可點「只看重要」切換成顯示全部）' } else { '目前沒有新聞' }
        $empty.Foreground = Brush $T.Dim; $empty.Margin = '12'; $empty.TextWrapping = 'Wrap'
        [void]$ui.List.Children.Add($empty)
    }
}

function Render-Status {
    $parts = @()
    if ($script:Job) { $parts += '更新中…' }
    elseif ($script:LastOk) { $parts += ('更新於 ' + $script:LastOk.ToString('HH:mm:ss') + (' · {0}s 後更新' -f $script:Countdown)) }
    if ($script:LastErr.Count) { $parts += ('無法連線：' + ($script:LastErr -join '、')) }
    $ui.Status.Text = $parts -join '   '
}

# ------------------------- 更新流程 -------------------------
function Start-Fetch {
    if ($script:Job) { return }
    if ($TransCache.Count -gt 3000) { $TransCache.Clear() }
    $ps = [PowerShell]::Create()
    [void]$ps.AddScript($FetchScript.ToString()).AddArgument($Sources).AddArgument(@(Get-ActiveCrypto)).AddArgument(@(Get-ActiveStock)).AddArgument($TranslateEnglish).AddArgument($TransCache)
    $script:Job = @{ PS = $ps; Handle = $ps.BeginInvoke() }
    $ui.LiveDot.Fill = Brush '#FFB020'
    Render-Status
}

function Complete-Fetch {
    $job = $script:Job
    $script:Job = $null
    $ui.LiveDot.Fill = Brush '#FF4D4F'
    try { $res = $job.PS.EndInvoke($job.Handle) | Select-Object -Last 1 } catch { $res = $null }
    $job.PS.Dispose()
    if (-not $res) { $script:LastErr = @('全部來源'); Render-Status; return }

    $now = Get-Date
    $fresh = New-Object System.Collections.ArrayList
    foreach ($it in $res.Items) {
        if ($script:Items.ContainsKey($it.Id)) {
            # 先前沒翻譯成功的，這次補上
            $old = $script:Items[$it.Id]
            if ($it.Original -and -not $old.Original) { $old.Title = $it.Title; $old.Original = $it.Original; $old.Breaking = (Test-Breaking $old); $old.Kind = (Get-Kind $old); $old.Watch = (Get-Watch $old); $old.Impact = (Get-Impact $old) }
            continue
        }
        $it | Add-Member -NotePropertyName FirstSeen -NotePropertyValue $now
        $it | Add-Member -NotePropertyName IsNew -NotePropertyValue (-not $script:FirstLoad)
        $it | Add-Member -NotePropertyName Breaking -NotePropertyValue (Test-Breaking $it)
        $it | Add-Member -NotePropertyName Kind -NotePropertyValue (Get-Kind $it)
        $it | Add-Member -NotePropertyName Watch -NotePropertyValue (Get-Watch $it)
        $it | Add-Member -NotePropertyName Impact -NotePropertyValue (Get-Impact $it)
        $script:Items[$it.Id] = $it
        # 只有最近 2 小時內發布的才算「新」的突發（避免來源補舊文時誤報）
        if (-not $script:FirstLoad -and ($now - $it.Time).TotalHours -lt 2) { [void]$fresh.Add($it) }
    }
    # 清掉太舊的，避免記憶體越長越大
    if ($script:Items.Count -gt 400) {
        $keep = $script:Items.Values | Sort-Object Time -Descending | Select-Object -First 300
        $script:Items = @{}; foreach ($k in $keep) { $script:Items[$k.Id] = $k }
    }

    if ($res.Prices.Count) { $script:Prices = $res.Prices }
    $script:LastErr = @($res.Errors)
    $script:LastOk = $now
    $script:Countdown = $RefreshSeconds

    # 通知（第一次載入不通知）：
    #  1. 突發新聞
    #  2. 提到自選標的、而且屬於重要類別（價格/政策/數據/人物/戰爭）的新聞
    if (-not $script:FirstLoad) {
        $alerts = $fresh | Where-Object { $_.Breaking -or ($_.Watch -and $_.Kind) } | Sort-Object Time -Descending | Select-Object -First $MaxAlertsPerRefresh
        foreach ($it in ($alerts | Sort-Object Time)) {
            $kind = if ($it.Watch) {
                        "★ $($it.Watch)｜" + $(if ($it.Breaking) { '突發' } else { $it.Kind })
                    } elseif ($it.Cat -eq 'crypto') { '幣圈突發' } else { '美股突發' }
            if ($it.Impact -and $it.Impact.Dir -ne 0) { $kind += '｜' + $(if ($it.Impact.Dir -gt 0) { '▲ ' } else { '▼ ' }) + $it.Impact.Text }
            Send-Alert $kind $it.Title $it.Url
        }
    }
    Check-Spikes
    $script:FirstLoad = $false

    Render-Ticker
    Render-List
    Render-Status
}

# ------------------------- 自訂行情列視窗 -------------------------
if (-not ('NwWin' -as [type])) {
    Add-Type @'
using System; using System.Runtime.InteropServices;
public static class NwWin {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
    [StructLayout(LayoutKind.Sequential)] public struct MONITORINFO { public int cbSize; public RECT rcMonitor; public RECT rcWork; public uint dwFlags; }
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] static extern IntPtr MonitorFromWindow(IntPtr h, uint flags);
    [DllImport("user32.dll")] static extern bool GetMonitorInfo(IntPtr m, ref MONITORINFO mi);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    // 把對話框放在 owner 所在螢幕上、水平置中於 owner，並確保整個在螢幕工作區內
    public static void PlaceNear(IntPtr owner, IntPtr dlg) {
        RECT o, d; GetWindowRect(owner, out o); GetWindowRect(dlg, out d);
        MONITORINFO mi = new MONITORINFO(); mi.cbSize = Marshal.SizeOf(typeof(MONITORINFO));
        GetMonitorInfo(MonitorFromWindow(owner, 2), ref mi);
        RECT w = mi.rcWork;
        int dw = d.R - d.L, dh = d.B - d.T;
        int x = (o.L + o.R) / 2 - dw / 2, y = o.T + 30;
        if (x + dw > w.R) x = w.R - dw; if (x < w.L) x = w.L;
        if (y + dh > w.B) y = w.B - dh; if (y < w.T) y = w.T;
        SetWindowPos(dlg, IntPtr.Zero, x, y, 0, 0, 0x0001 | 0x0004 | 0x0010);
    }
}
'@
}
# 查驗代號是否存在：幣 → 幣安 USDT 交易對；美股 → CNBC
function Test-NewSymbol([string]$kind, [string]$code) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $wc = New-Object Net.WebClient
    $wc.Encoding = [Text.Encoding]::UTF8
    $wc.Headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) NewsWidget/1.0'
    try {
        if ($kind -eq 'crypto') {
            $code = $code.ToUpper() -replace '[-/ ]', '' -replace 'USDT$', ''
            $sym = $code + 'USDT'
            $r = $wc.DownloadString("https://api.binance.com/api/v3/ticker/price?symbol=$sym") | ConvertFrom-Json
            if ($r.price) { return @{ Label = $code; Name = $code; Symbol = $sym; Alert = 5; Custom = $true } }
        } else {
            $code = $code.ToUpper().Trim()
            # CNBC 的指數代號用「.」開頭（例如 .SOX），使用者輸入 ^SOX 也接受
            $cs = if ($code.StartsWith('^')) { '.' + $code.Substring(1) } else { $code }
            $url = 'https://quote.cnbc.com/quote-html-webservice/restQuote/symbolType/symbol?symbols=' + [Uri]::EscapeDataString($cs) + '&requestMethod=itv&noform=1&partnerId=2&fund=1&exthrs=1&output=json'
            $r = @(($wc.DownloadString($url) | ConvertFrom-Json).FormattedQuoteResult.FormattedQuote | ForEach-Object { $_ })[0]
            if ($r -and [string]$r.code -eq '0' -and $r.last) {
                $name = if ($r.name) { $r.name } else { $code }
                return @{ Label = ($code -replace '^[\^.]', ''); Name = $name; Symbol = $code; Alert = 3; Custom = $true }
            }
        }
    } catch { } finally { $wc.Dispose() }
    return $null
}

function Show-SymbolDialog {
    $T = $script:T
    [xml]$dx = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="設定" Width="560" Height="740" MinWidth="420" MinHeight="400"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent" ResizeMode="CanResizeWithGrip"
        WindowStartupLocation="CenterOwner" ShowInTaskbar="False"
        FontFamily="Microsoft JhengHei UI, Segoe UI" FontSize="$fsS" Foreground="$($T.Text)">
  <!-- 無邊框視窗也能從四個邊和四個角拖曳調整大小 -->
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="0" ResizeBorderThickness="7" GlassFrameThickness="0" CornerRadius="0" UseAeroCaptionButtons="False"/>
  </WindowChrome.WindowChrome>
  <Window.Resources>
    <Style x:Key="Btn" TargetType="Button">
      <Setter Property="Foreground" Value="$($T.BtnFg)"/>
      <Setter Property="Background" Value="$($T.BtnBg)"/>
      <Setter Property="Padding" Value="14,5"/>
      <Setter Property="Margin" Value="6,0,0,0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.85"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="$($T.Text)"/>
      <Setter Property="VerticalContentAlignment" Value="Center"/>
      <Setter Property="Cursor" Value="Hand"/>
    </Style>
    <Style TargetType="RadioButton">
      <Setter Property="Foreground" Value="$($T.Text)"/>
      <Setter Property="VerticalContentAlignment" Value="Center"/>
      <Setter Property="Margin" Value="0,0,12,0"/>
      <Setter Property="Cursor" Value="Hand"/>
    </Style>
  </Window.Resources>
  <Border CornerRadius="12" Background="$($T.DlgBg)" BorderBrush="$($T.WinBorder)" BorderThickness="1">
    <Grid Margin="16,12,16,14">
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
      </Grid.RowDefinitions>

      <Grid x:Name="DlgHeader" Background="Transparent">
        <StackPanel>
          <TextBlock Text="設定" FontSize="$fsH" FontWeight="SemiBold" Foreground="$($T.Title)"/>
          <TextBlock Text="外觀、通知，以及要顯示在行情列的幣與美股（按「儲存」才會套用）" Foreground="$($T.Time)" Margin="0,2,0,0" TextWrapping="Wrap"/>
        </StackPanel>
      </Grid>

      <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="0,10,0,10">
        <StackPanel>
          <!-- 外觀與通知 -->
          <Border Background="$($T.Panel)" CornerRadius="8" Padding="12,10" Margin="0,0,0,14">
            <StackPanel>
              <TextBlock Text="外觀與通知" FontWeight="SemiBold" Margin="0,0,0,8"/>
              <DockPanel Margin="0,0,0,4">
                <TextBlock Text="字體大小" Width="72" VerticalAlignment="Center"/>
                <TextBlock x:Name="FontVal" DockPanel.Dock="Right" Width="36" TextAlignment="Right" VerticalAlignment="Center"/>
                <Slider x:Name="FontSlider" Minimum="12" Maximum="24" TickFrequency="1" IsSnapToTickEnabled="True" VerticalAlignment="Center" Margin="0,0,8,0" Cursor="Hand"/>
              </DockPanel>
              <TextBlock x:Name="FontPreview" Text="預覽：比特幣跌破 7 萬美元，輝達漲 3%" Margin="72,0,0,10" Foreground="$($T.Text)" TextWrapping="Wrap"/>
              <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
                <TextBlock Text="背景" Width="72" VerticalAlignment="Center"/>
                <RadioButton x:Name="ThemeDark"  Content="深色" GroupName="theme"/>
                <RadioButton x:Name="ThemeLight" Content="淺色" GroupName="theme"/>
              </StackPanel>
              <CheckBox x:Name="VoiceChk" Content="跳出通知時，同時用語音念出來"/>
            </StackPanel>
          </Border>

          <DockPanel Margin="0,0,0,6">
            <TextBlock Text="加密貨幣（幣安報價）" FontWeight="SemiBold" Foreground="$($T.CryptoTagFg)" VerticalAlignment="Center"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
              <Button x:Name="CryptoAll"  Style="{StaticResource Btn}" Content="全選"   Padding="8,2"/>
              <Button x:Name="CryptoNone" Style="{StaticResource Btn}" Content="全不選" Padding="8,2"/>
            </StackPanel>
          </DockPanel>
          <WrapPanel x:Name="CryptoPanel" Margin="0,0,0,14"/>
          <DockPanel Margin="0,0,0,6">
            <TextBlock Text="美股 / 指數（CNBC 報價）" FontWeight="SemiBold" Foreground="$($T.StockTagFg)" VerticalAlignment="Center"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
              <Button x:Name="StockAll"  Style="{StaticResource Btn}" Content="全選"   Padding="8,2"/>
              <Button x:Name="StockNone" Style="{StaticResource Btn}" Content="全不選" Padding="8,2"/>
            </StackPanel>
          </DockPanel>
          <WrapPanel x:Name="StockPanel"/>
        </StackPanel>
      </ScrollViewer>

      <!-- 新增自訂 -->
      <Border Grid.Row="2" Background="$($T.Panel)" CornerRadius="8" Padding="12,10" Margin="0,0,0,12">
        <StackPanel>
          <TextBlock Text="清單裡沒有？自己新增" FontWeight="SemiBold" Margin="0,0,0,6"/>
          <StackPanel Orientation="Horizontal">
            <RadioButton x:Name="AddCrypto" Content="幣" GroupName="kind" IsChecked="True"/>
            <RadioButton x:Name="AddStock"  Content="美股" GroupName="kind"/>
            <TextBox x:Name="AddCode" Width="140" Background="$($T.InputBg)" Foreground="$($T.Text)" BorderBrush="$($T.InputBorder)" CaretBrush="$($T.Text)" Padding="6,3" VerticalContentAlignment="Center"/>
            <Button x:Name="AddBtn" Style="{StaticResource Btn}" Content="新增" Background="#2F81F7" Foreground="#FFFFFF"/>
          </StackPanel>
          <TextBlock x:Name="AddMsg" Foreground="$($T.Time)" Margin="0,6,0,0" TextWrapping="Wrap"
                     Text="幣：輸入代號，例如 PEPE、WIF（需在幣安有 USDT 交易對）　美股：輸入股票代號，例如 AAPL、^SOX"/>
        </StackPanel>
      </Border>

      <DockPanel Grid.Row="3">
        <Button x:Name="ResetBtn" Style="{StaticResource Btn}" Content="恢復預設" Margin="0"/>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="CancelBtn" Style="{StaticResource Btn}" Content="取消"/>
          <Button x:Name="SaveBtn"   Style="{StaticResource Btn}" Content="儲存" Background="#2F81F7" Foreground="#FFFFFF"/>
        </StackPanel>
      </DockPanel>
    </Grid>
  </Border>
</Window>
"@
    $dlg = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $dx))
    $dlg.Owner = $window
    $dlg.Topmost = $window.Topmost
    # 多螢幕且縮放比例不同時，WPF 的「置中」會算錯跑到螢幕外；改用實際像素擺在小工具所在的螢幕上
    $dlg.WindowStartupLocation = 'Manual'
    $dlg.Left = $window.Left; $dlg.Top = $window.Top
    $dlg.Add_Loaded({
        try {
            $oh = (New-Object Windows.Interop.WindowInteropHelper $window).Handle
            $dh = (New-Object Windows.Interop.WindowInteropHelper $dlg).Handle
            [NwWin]::PlaceNear($oh, $dh)
        } catch {}
    })
    $d = @{}
    foreach ($n in 'DlgHeader','CryptoPanel','StockPanel','CryptoAll','CryptoNone','StockAll','StockNone','AddCrypto','AddStock','AddCode','AddBtn','AddMsg','ResetBtn','CancelBtn','SaveBtn','FontSlider','FontVal','FontPreview','ThemeDark','ThemeLight','VoiceChk') { $d[$n] = $dlg.FindName($n) }
    $d.DlgHeader.Add_MouseLeftButtonDown({ $dlg.DragMove() })

    # 外觀與通知：帶入目前設定，字體滑桿即時預覽
    $d.FontSlider.Value = $script:FontSz
    $d.FontVal.Text = [string][int]$script:FontSz
    $d.FontPreview.FontSize = $script:FontSz
    $d.FontSlider.Add_ValueChanged({ $d.FontVal.Text = [string][int]$d.FontSlider.Value; $d.FontPreview.FontSize = $d.FontSlider.Value })
    $d.ThemeDark.IsChecked  = ($script:Theme -eq 'dark')
    $d.ThemeLight.IsChecked = ($script:Theme -eq 'light')
    $d.VoiceChk.IsChecked   = $script:VoiceOn

    # 對話框內的暫存狀態（按「儲存」才套用）
    $st = @{
        CustomCrypto = New-Object System.Collections.ArrayList
        CustomStock  = New-Object System.Collections.ArrayList
        Checks       = @{}   # Symbol -> CheckBox
    }
    foreach ($c in $script:CustomCrypto) { [void]$st.CustomCrypto.Add($c) }
    foreach ($c in $script:CustomStock)  { [void]$st.CustomStock.Add($c) }

    $addChip = {
        param($panel, $item, [bool]$checked, $customList)
        $chip = New-Object Windows.Controls.Border
        $chip.CornerRadius = '6'; $chip.Padding = '8,4,6,4'; $chip.Margin = '0,0,8,8'
        $chip.Background = Brush $T.TabBg
        $sp = New-Object Windows.Controls.StackPanel
        $sp.Orientation = 'Horizontal'
        $cb = New-Object Windows.Controls.CheckBox
        $cb.IsChecked = $checked
        $label = $item.Label
        if ($item.Name -and $item.Name -ne $item.Label) { $label += '  ' + $item.Name }
        $cb.Content = $label
        $cb.Tag = $item.Symbol
        [void]$sp.Children.Add($cb)
        if ($customList) {
            $x = New-Object Windows.Controls.Button
            $x.Content = '✕'; $x.Margin = '6,0,0,0'; $x.Padding = '4,0'; $x.Cursor = 'Hand'
            $x.Background = Brush '#00000000'; $x.BorderThickness = '0'; $x.Foreground = Brush $T.Muted
            $x.ToolTip = '從清單移除這個自訂項目'
            $x.Tag = @{ Chip = $chip; Panel = $panel; Item = $item; List = $customList }
            $x.Add_Click({
                param($s, $e)
                $t = $s.Tag
                $t.Panel.Children.Remove($t.Chip)
                $t.List.Remove($t.Item)
                $st.Checks.Remove($t.Item.Symbol)
            })
            [void]$sp.Children.Add($x)
        }
        $chip.Child = $sp
        [void]$panel.Children.Add($chip)
        $st.Checks[$item.Symbol] = $cb
    }

    $fill = {
        param([bool]$useDefaults)
        $d.CryptoPanel.Children.Clear(); $d.StockPanel.Children.Clear(); $st.Checks.Clear()
        foreach ($c in $CryptoCatalog) { & $addChip $d.CryptoPanel $c $(if ($useDefaults) { $c.On } else { $script:SelCrypto -contains $c.Symbol }) $null }
        foreach ($c in @($st.CustomCrypto)) { & $addChip $d.CryptoPanel $c $(if ($useDefaults) { $false } else { $script:SelCrypto -contains $c.Symbol }) $st.CustomCrypto }
        foreach ($c in $StockCatalog) { & $addChip $d.StockPanel $c $(if ($useDefaults) { $c.On } else { $script:SelStock -contains $c.Symbol }) $null }
        foreach ($c in @($st.CustomStock)) { & $addChip $d.StockPanel $c $(if ($useDefaults) { $false } else { $script:SelStock -contains $c.Symbol }) $st.CustomStock }
    }
    & $fill $false

    $setAll = { param($panel, [bool]$v) foreach ($chip in $panel.Children) { $chip.Child.Children[0].IsChecked = $v } }
    $d.CryptoAll.Add_Click({  & $setAll $d.CryptoPanel $true })
    $d.CryptoNone.Add_Click({ & $setAll $d.CryptoPanel $false })
    $d.StockAll.Add_Click({   & $setAll $d.StockPanel $true })
    $d.StockNone.Add_Click({  & $setAll $d.StockPanel $false })
    $d.ResetBtn.Add_Click({ & $fill $true; $d.AddMsg.Text = '已恢復預設勾選（按「儲存」才會套用）' })
    $d.CancelBtn.Add_Click({ $dlg.Close() })

    $doAdd = {
        $code = $d.AddCode.Text.Trim()
        if (-not $code) { $d.AddMsg.Text = '請先輸入代號'; return }
        $kind = if ($d.AddCrypto.IsChecked) { 'crypto' } else { 'stock' }
        $d.AddMsg.Text = '查詢中…'
        $dlg.Cursor = 'Wait'
        # 讓「查詢中…」先畫出來再去查
        $dlg.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Render)
        $item = Test-NewSymbol $kind $code
        $dlg.Cursor = $null
        if (-not $item) {
            $d.AddMsg.Text = if ($kind -eq 'crypto') { "找不到「$code」：幣安沒有 $($code.ToUpper())USDT 這個交易對，請確認代號" } else { "找不到「$code」：CNBC 查無此代號，請確認（指數前面要加 ^，例如 ^SOX）" }
            return
        }
        if ($st.Checks.ContainsKey($item.Symbol)) {
            $st.Checks[$item.Symbol].IsChecked = $true
            $d.AddMsg.Text = "「$($item.Label)」已經在清單裡，幫你勾起來了"
        } else {
            if ($kind -eq 'crypto') { [void]$st.CustomCrypto.Add($item); & $addChip $d.CryptoPanel $item $true $st.CustomCrypto }
            else { [void]$st.CustomStock.Add($item); & $addChip $d.StockPanel $item $true $st.CustomStock }
            $d.AddMsg.Text = "已新增「$($item.Label)」（按「儲存」才會套用）"
        }
        $d.AddCode.Text = ''
    }
    $d.AddBtn.Add_Click($doAdd)
    $d.AddCode.Add_KeyDown({ param($s, $e) if ($e.Key -eq 'Return') { & $doAdd } })

    $d.SaveBtn.Add_Click({
        $script:CustomCrypto = @($st.CustomCrypto)
        $script:CustomStock  = @($st.CustomStock)
        $checked = @($st.Checks.Keys | Where-Object { $st.Checks[$_].IsChecked })
        $script:SelCrypto = @(@($CryptoCatalog) + @($script:CustomCrypto) | Where-Object { $checked -contains $_.Symbol } | ForEach-Object { $_.Symbol })
        $script:SelStock  = @(@($StockCatalog)  + @($script:CustomStock)  | Where-Object { $checked -contains $_.Symbol } | ForEach-Object { $_.Symbol })
        # 移除的項目立刻從行情列消失、也不再做急漲急跌偵測
        $active = @($script:SelCrypto) + @($script:SelStock)
        $script:Prices = @($script:Prices | Where-Object { $active -contains $_.Symbol })
        Refresh-Watch      # 依新的自選標的重新比對所有新聞
        # 外觀與通知
        $script:FontSz  = [double][int]$d.FontSlider.Value
        $script:Theme   = if ($d.ThemeLight.IsChecked) { 'light' } else { 'dark' }
        $script:VoiceOn = [bool]$d.VoiceChk.IsChecked
        if (-not $script:VoiceOn) { try { $synth.SpeakAsyncCancelAll() } catch {} }
        Save-Settings
        Apply-Appearance   # 重新套用字體與配色，並重畫行情列與新聞列表
        if ($script:Job) { $script:Countdown = 1 } else { Start-Fetch }   # 馬上抓新加入的報價
        $dlg.Close()
    })

    [void]$dlg.ShowDialog()
}

# ------------------------- 美國數據公布（經濟行事曆，獨立視窗）-------------------------
# 資料來源：華爾街見聞財經日曆（有實際值 / 預期值 / 前值 / 重要度），簡體自動轉繁體
$CalFetchScript = {
    param([long]$Start, [long]$End)
    Add-Type -AssemblyName Microsoft.VisualBasic
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $wc = New-Object Net.WebClient
    $wc.Encoding = [Text.Encoding]::UTF8
    $wc.Headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) NewsWidget/1.0'
    try { $raw = $wc.DownloadString("https://api-one-wscn.awtmt.com/apiv1/finance/macrodatas?start=$Start&end=$End") } finally { $wc.Dispose() }
    $tw = {
        param([string]$s)
        if (-not $s) { return '' }
        $s = [Microsoft.VisualBasic.Strings]::StrConv($s, [Microsoft.VisualBasic.VbStrConv]::TraditionalChinese, 2052)
        # 改成台灣慣用說法
        $s.Replace('當周', '當週').Replace('美聯儲', '聯準會').Replace('聯儲', '聯準會').Replace('英偉達', '輝達')
    }
    foreach ($x in @(($raw | ConvertFrom-Json).data.items | ForEach-Object { $_ })) {
        if ($x.country_id -ne 'US') { continue }
        $pd = [long]$x.public_date
        [pscustomobject]@{
            Id = [string]$x.id
            Time = [DateTimeOffset]::FromUnixTimeSeconds($pd).LocalDateTime
            AllDay = (($pd % 86400) -eq 14520)        # 沒有確切時間的整天事件（來源固定標在 UTC 04:02）
            Title = (& $tw ([string]$x.title)).Trim().TrimEnd('。')
            Imp = [int]$x.importance
            IsData = ($x.calendar_type -eq 'FD')       # FD = 數據；FE = 事件（官員談話、會議…）
            Actual = [string]$x.actual; Forecast = [string]$x.forecast; Previous = [string]$x.previous; Revised = [string]$x.revised
            Unit = [string]$x.unit; Url = [string]$x.uri
            Note = (& $tw ([string]$x.foresight)).Trim()
        }
    }
}

$Inv = [Globalization.CultureInfo]::InvariantCulture
$ZhTw = [Globalization.CultureInfo]::GetCultureInfo('zh-TW')
function Format-CalVal([string]$v, [string]$unit) {
    if ([string]::IsNullOrWhiteSpace($v)) { return '—' }
    if ($unit -eq '%') { return "$v%" }
    return $v
}
# 實際值跟預期比（沒有預期就跟前值比）
function Get-CalCmp($it) {
    $a = 0.0; $f = 0.0
    if (-not [double]::TryParse($it.Actual, 'Float', $Inv, [ref]$a)) { return $null }
    if ([double]::TryParse($it.Forecast, 'Float', $Inv, [ref]$f)) { $ref = '預期' }
    elseif ([double]::TryParse($it.Previous, 'Float', $Inv, [ref]$f)) { $ref = '前值' }
    else { return $null }
    if ($a -gt $f) { return @{ Dir = 1; Text = "高於$ref" } }
    if ($a -lt $f) { return @{ Dir = -1; Text = "低於$ref" } }
    return @{ Dir = 0; Text = "符合$ref" }
}
function Format-Span([TimeSpan]$s) {
    if ($s.TotalDays -ge 1)    { return ('{0} 天 {1} 小時' -f [int][Math]::Floor($s.TotalDays), $s.Hours) }
    if ($s.TotalHours -ge 1)   { return ('{0} 小時 {1:00} 分' -f [int][Math]::Floor($s.TotalHours), $s.Minutes) }
    if ($s.TotalMinutes -ge 10) { return ('{0} 分' -f $s.Minutes) }
    return ('{0} 分 {1:00} 秒' -f $s.Minutes, $s.Seconds)
}

function Start-CalFetch {
    if ($script:CalJob) { return }
    $today = (Get-Date).Date
    $s = ([DateTimeOffset]$today.AddDays(-2)).ToUnixTimeSeconds()
    $e = ([DateTimeOffset]$today.AddDays(8)).ToUnixTimeSeconds()
    $ps = [PowerShell]::Create()
    [void]$ps.AddScript($CalFetchScript.ToString()).AddArgument($s).AddArgument($e)
    $script:CalJob = @{ PS = $ps; Handle = $ps.BeginInvoke() }
    if ($script:CalUi) { $script:CalUi.CalStatus.Text = '更新中…' }
}

# 下次多久後再抓：平常 60 秒；重要數據公布前後改成 10 秒，並在公布時間一到就抓
function Get-CalInterval {
    $now = Get-Date
    $data = @($script:Cal | Where-Object { $_.IsData -and -not $_.AllDay -and $_.Imp -ge 2 })
    $hot = @($data | Where-Object { -not $_.Actual -and ($now - $_.Time).TotalMinutes -ge -1 -and ($now - $_.Time).TotalMinutes -le 10 })
    if ($hot.Count) { return 10 }
    $iv = 60
    $next = $data | Where-Object { $_.Time -gt $now } | Sort-Object Time | Select-Object -First 1
    if ($next) { $sec = [int](($next.Time - $now).TotalSeconds) + 3; if ($sec -lt $iv) { $iv = [Math]::Max(3, $sec) } }
    return $iv
}

function Complete-CalFetch {
    $job = $script:CalJob
    $script:CalJob = $null
    $items = $null
    try { $items = @($job.PS.EndInvoke($job.Handle) | Where-Object { $_.Id }) } catch { $items = $null }
    $job.PS.Dispose()
    if (-not $items -or -not $items.Count) {
        $script:CalErr = '無法連線到華爾街見聞，30 秒後重試'; $script:CalCountdown = 30; Render-Cal; return
    }
    $now = Get-Date
    $released = @()
    foreach ($it in $items) {
        $prev = $script:CalSeen[$it.Id]
        # 先前沒有實際值、這次有了 → 剛公布
        if ($it.Actual -and -not $prev -and -not $script:CalFirst -and $it.IsData -and $it.Imp -ge 3 -and ($now - $it.Time).TotalMinutes -lt 60) { $released += $it }
        $script:CalSeen[$it.Id] = $it.Actual
    }
    $script:Cal = $items
    $script:CalErr = $null
    $script:CalOk = $now
    $script:CalFirst = $false
    $script:CalCountdown = Get-CalInterval
    # 重要數據公布 → 跳通知（同一時間公布的合併成一則）
    if ($released.Count) {
        $lines = $released | Sort-Object @{ e = { -$_.Imp } } | Select-Object -First 4 | ForEach-Object {
            $cmp = Get-CalCmp $_
            $imp = Get-DataImpact $_.Title $_.Actual $_.Forecast
            '{0}：{1}（預期 {2}，前值 {3}）{4}{5}' -f $_.Title, (Format-CalVal $_.Actual $_.Unit), (Format-CalVal $_.Forecast $_.Unit), (Format-CalVal $_.Previous $_.Unit), $(if ($cmp) { ' ' + $cmp.Text } else { '' }), $(if ($imp) { $(if ($imp.Dir -gt 0) { ' ▲偏利多' } else { ' ▼偏利空' }) } else { '' })
        }
        Send-Alert '📊 美國數據公布' ($lines -join "`n") $released[0].Url
    }
    Render-Cal
}

function Update-CalNext {
    $c = $script:CalUi
    if (-not $c) { return }
    $now = Get-Date
    $pending = @($script:CalShown | Where-Object { -not $_.AllDay -and ($_.Time -gt $now -or ($_.IsData -and -not $_.Actual -and ($now - $_.Time).TotalMinutes -lt 10)) } | Sort-Object Time, @{ e = { -$_.Imp } })
    $n = $pending | Select-Object -First 1
    if (-not $n) { $c.NextBox.Visibility = 'Collapsed'; return }
    $c.NextBox.Visibility = 'Visible'
    $same = @($pending | Where-Object { $_.Time -eq $n.Time })
    $names = ($same | Select-Object -First 2 | ForEach-Object { $_.Title }) -join '、'
    if ($same.Count -gt 2) { $names += " 等 $($same.Count) 項" }
    $day = if ($n.Time.Date -eq $now.Date) { '今天' } elseif ($n.Time.Date -eq $now.Date.AddDays(1)) { '明天' } else { $n.Time.ToString('MM/dd ddd', $ZhTw) }
    $c.NextLabel.Text = '下一個  ' + $day + ' ' + $n.Time.ToString('HH:mm')
    $c.NextTitle.Text = $names
    $c.NextLeft.Text = if ($n.Time -le $now) { '公布中…' } else { '還有 ' + (Format-Span ($n.Time - $now)) }
}

function Render-Cal {
    $c = $script:CalUi
    if (-not $c) { return }
    $T = $script:T
    $now = Get-Date

    $c.CalImp.Content    = if ($script:CalOnlyImp) { '✓ 只看重要' } else { '重要 + 一般' }
    $c.CalImp.Background = Brush $(if ($script:CalOnlyImp) { $T.ImpOnBg } else { $T.TabBg })
    $c.CalImp.Foreground = Brush $(if ($script:CalOnlyImp) { $T.ImpOnFg } else { $T.TabFg })
    $c.CalEvt.Content    = if ($script:CalEvents) { '✓ 含官員談話 / 事件' } else { '只看數據' }
    $c.CalEvt.Background = Brush $(if ($script:CalEvents) { $T.ImpOnBg } else { $T.TabBg })
    $c.CalEvt.Foreground = Brush $(if ($script:CalEvents) { $T.ImpOnFg } else { $T.TabFg })
    $c.CalPin.Opacity    = if ($script:CalWin.Topmost) { 1 } else { 0.4 }

    $minImp = if ($script:CalOnlyImp) { 3 } else { 2 }
    $items = @($script:Cal | Where-Object { $_.Imp -ge $minImp -and ($script:CalEvents -or $_.IsData) } |
               Sort-Object @{ e = { $_.Time.Date } }, @{ e = { $_.AllDay } }, Time, @{ e = { -$_.Imp } })
    $script:CalShown = $items

    $offset = $c.CalScroller.VerticalOffset
    $c.CalList.Children.Clear()
    $nowRow = $null
    $lastDay = $null
    $tw = [Math]::Round($fs * 3.4)
    foreach ($it in $items) {
        if ($it.Time.Date -ne $lastDay) {
            $lastDay = $it.Time.Date
            $dh = New-Object Windows.Controls.TextBlock
            $rel = if ($lastDay -eq $now.Date) { ' · 今天' } elseif ($lastDay -eq $now.Date.AddDays(1)) { ' · 明天' } elseif ($lastDay -eq $now.Date.AddDays(-1)) { ' · 昨天' } elseif ($lastDay -eq $now.Date.AddDays(-2)) { ' · 前天' } else { '' }
            $dh.Text = $lastDay.ToString('MM/dd ddd', $ZhTw) + $rel
            $dh.FontWeight = 'SemiBold'; $dh.FontSize = $fsS; $dh.Margin = '8,10,0,6'
            $dh.Foreground = Brush $(if ($lastDay -eq $now.Date) { '#FFB020' } else { $T.Muted })
            [void]$c.CalList.Children.Add($dh)
        }
        $mins = ($now - $it.Time).TotalMinutes
        $justOut = $it.IsData -and $it.Actual -and -not $it.AllDay -and $mins -ge 0 -and $mins -lt 30
        $isPast  = if ($it.AllDay) { $it.Time.Date -lt $now.Date } else { $mins -ge 30 -or ($mins -ge 0 -and -not $it.IsData) }

        $card = New-Object Windows.Controls.Border
        $card.Margin = '6,0,0,6'; $card.Padding = '10,7,12,8'; $card.CornerRadius = '8'
        $card.Background = Brush $(if ($justOut) { $T.CardNew } else { $T.Card })
        $card.BorderThickness = '3,0,0,0'
        $card.BorderBrush = Brush $(if ($justOut) { '#FFB020' } elseif ($it.Imp -ge 4) { '#FF4D4F' } elseif ($it.Imp -ge 3) { '#C99A06' } else { '#00000000' })
        if ($isPast) { $card.Opacity = 0.62 }

        $g = New-Object Windows.Controls.Grid
        $c0 = New-Object Windows.Controls.ColumnDefinition; $c0.Width = [Windows.GridLength]::new($tw)
        $c1 = New-Object Windows.Controls.ColumnDefinition
        [void]$g.ColumnDefinitions.Add($c0); [void]$g.ColumnDefinitions.Add($c1)

        $left = New-Object Windows.Controls.StackPanel
        $tm = New-Object Windows.Controls.TextBlock
        $tm.Text = if ($it.AllDay) { '全天' } else { $it.Time.ToString('HH:mm') }
        $tm.FontWeight = 'SemiBold'; $tm.FontSize = $fs; $tm.Foreground = Brush $T.Text
        $st = New-Object Windows.Controls.TextBlock
        $st.Text = '★' * [Math]::Min(4, [Math]::Max(1, $it.Imp))
        $st.FontSize = [Math]::Round($fsS * 0.85, 1)
        $st.Foreground = Brush $(if ($it.Imp -ge 4) { '#FF4D4F' } elseif ($it.Imp -ge 3) { '#FFB020' } else { $T.Dim })
        [void]$left.Children.Add($tm); [void]$left.Children.Add($st)
        [Windows.Controls.Grid]::SetColumn($left, 0)

        $right = New-Object Windows.Controls.StackPanel
        $head = New-Object Windows.Controls.WrapPanel
        if ($justOut) { [void]$head.Children.Add((New-Tag '剛公布' '#FFB020' '#1A1400')) }
        elseif (-not $it.IsData) { [void]$head.Children.Add((New-Tag '事件' $T.TransBg $T.TransFg)) }
        if ($head.Children.Count) { $head.Margin = '0,0,0,3'; [void]$right.Children.Add($head) }
        $ti = New-Object Windows.Controls.TextBlock
        $ti.Text = $it.Title; $ti.TextWrapping = 'Wrap'; $ti.Foreground = Brush $T.Text; $ti.FontSize = $fs
        $ti.LineHeight = [Math]::Round($fs * 1.4)
        [void]$right.Children.Add($ti)

        if ($it.IsData) {
            # 「實際 / 預期 / 前值 / 高於預期」各自一塊，視窗窄的時候整塊換行，不會從字中間斷開
            $vals = New-Object Windows.Controls.WrapPanel
            $vals.Margin = '0,3,0,0'
            $cmp = Get-CalCmp $it
            $imp = Get-DataImpact $it.Title $it.Actual $it.Forecast
            $chunk = {
                param([string]$label, [string]$value, $valueBrush, [bool]$big)
                $tb = New-Object Windows.Controls.TextBlock
                $tb.FontSize = $fsS; $tb.Foreground = Brush $T.Muted; $tb.Margin = '0,0,16,0'; $tb.VerticalAlignment = 'Bottom'
                if ($label) { $tb.Inlines.Add((New-Object Windows.Documents.Run ($label + ' '))) }
                $r = New-Object Windows.Documents.Run $value
                if ($valueBrush) { $r.Foreground = $valueBrush }
                if ($big) { $r.FontWeight = 'Bold'; $r.FontSize = $fs }
                $tb.Inlines.Add($r)
                [void]$vals.Children.Add($tb)
            }
            if ($it.Actual) {
                # 顏色看「對價格的影響」而不是數字大小：例如 CPI 高於預期 = 偏利空 → 紅色
                & $chunk '實際' (Format-CalVal $it.Actual $it.Unit) (Brush $(if ($imp -and $imp.Dir -gt 0) { $T.Up } elseif ($imp -and $imp.Dir -lt 0) { $T.Down } else { $T.Title })) $true
            } else {
                $txt = if ($it.AllDay -or $mins -lt 0) { '—' } elseif ($mins -gt 180) { '未提供' } else { '待公布' }
                & $chunk '實際' $txt (Brush $T.Dim) $false
            }
            & $chunk '預期' (Format-CalVal $it.Forecast $it.Unit) $null $false
            $prevTxt = Format-CalVal $it.Previous $it.Unit
            if ($it.Revised) { $prevTxt += '（修正 ' + (Format-CalVal $it.Revised $it.Unit) + '）' }
            & $chunk '前值' $prevTxt $null $false
            if ($cmp) { & $chunk '' $cmp.Text (Brush $T.Muted) $false }
            if ($imp) {
                $itag = if ($imp.Dir -gt 0) { New-Tag '▲ 偏利多' $T.Up '#FFFFFF' } else { New-Tag '▼ 偏利空' $T.Down '#FFFFFF' }
                $itag.ToolTip = $imp.Why + "`n（依指標種類自動判斷，僅供參考，不構成投資建議）"
                $itag.VerticalAlignment = 'Center'
                [void]$vals.Children.Add($itag)
            }
            [void]$right.Children.Add($vals)
        }
        [Windows.Controls.Grid]::SetColumn($right, 1)
        [void]$g.Children.Add($left); [void]$g.Children.Add($right)
        $card.Child = $g

        $et = [TimeZoneInfo]::ConvertTime($it.Time, [TimeZoneInfo]::FindSystemTimeZoneById('Eastern Standard Time'))
        $tip = $it.Title
        if (-not $it.AllDay) { $tip += "`n" + $it.Time.ToString('yyyy/MM/dd HH:mm') + '（美東 ' + $et.ToString('MM/dd HH:mm') + '）' }
        if ($it.Note) { $tip += "`n`n" + $it.Note }
        if ($it.Url) { $tip += "`n`n點擊開啟華爾街見聞的歷史數據頁"; $card.Cursor = 'Hand'; $card.Tag = $it.Url }
        $tipBlock = New-Object Windows.Controls.TextBlock
        $tipBlock.Text = $tip; $tipBlock.TextWrapping = 'Wrap'; $tipBlock.MaxWidth = 420
        $card.ToolTip = $tipBlock
        $card.Add_MouseLeftButtonUp({ param($s, $e) if ($s.Tag) { Start-Process $s.Tag } })
        [void]$c.CalList.Children.Add($card)
        if (-not $nowRow -and -not $it.AllDay -and $mins -lt 30 -and $it.Time.Date -eq $now.Date) { $nowRow = $card }
        if (-not $nowRow -and $it.Time.Date -gt $now.Date) { $nowRow = $card }
    }
    if (-not $items.Count) {
        $empty = New-Object Windows.Controls.TextBlock
        $empty.Text = if ($script:CalFirst) { '載入中…' } elseif ($script:CalErr) { $script:CalErr } else { '這段期間沒有符合條件的美國數據' }
        $empty.Foreground = Brush $T.Dim; $empty.Margin = '12'; $empty.TextWrapping = 'Wrap'
        [void]$c.CalList.Children.Add($empty)
    }

    # 第一次打開時捲到「現在」附近；之後保持使用者捲動的位置
    if (-not $script:CalScrolled -and $nowRow -and $items.Count) {
        $script:CalScrolled = $true
        $script:CalNowRow = $nowRow
        $script:CalWin.Dispatcher.BeginInvoke([Action]{
            try {
                $p = $script:CalNowRow.TransformToAncestor($script:CalUi.CalList).Transform([Windows.Point]::new(0, 0))
                $script:CalUi.CalScroller.ScrollToVerticalOffset([Math]::Max(0, $p.Y - 40))
            } catch {}
        }, [Windows.Threading.DispatcherPriority]::Loaded) | Out-Null
    } else {
        $c.CalScroller.UpdateLayout()
        $c.CalScroller.ScrollToVerticalOffset($offset)
    }

    $tzName = if ([TimeZoneInfo]::Local.BaseUtcOffset.TotalHours -eq 8) { '台灣時間' } else { '本機時間' }
    $c.CalStatus.Text = if ($script:CalErr -and $items.Count) { $script:CalErr } elseif ($script:CalOk) { '更新於 ' + $script:CalOk.ToString('HH:mm:ss') + ' · 時間為' + $tzName + ' · 來源：華爾街見聞' } else { '' }
    Update-CalNext
}

function Show-CalWindow {
    if ($script:CalWin) { $script:CalWin.Show(); $script:CalWin.WindowState = 'Normal'; $script:CalWin.Activate() | Out-Null; return }
    $T = $script:T
    [xml]$cx = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="美國數據公布" Width="470" Height="640" MinWidth="340" MinHeight="300"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent" ResizeMode="CanResizeWithGrip" ShowInTaskbar="True"
        FontFamily="Microsoft JhengHei UI, Segoe UI" FontSize="$fs" Foreground="$($T.Text)">
  <!-- 無邊框視窗也能從四個邊和四個角拖曳調整大小 -->
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="0" ResizeBorderThickness="7" GlassFrameThickness="0" CornerRadius="0" UseAeroCaptionButtons="False"/>
  </WindowChrome.WindowChrome>
  <Window.Resources>
    <Style x:Key="IconBtn" TargetType="Button">
      <Setter Property="Foreground" Value="$($T.Muted)"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Width" Value="32"/>
      <Setter Property="Height" Value="30"/>
      <Setter Property="FontSize" Value="$fs"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="6">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="b" Property="Background" Value="$($T.Hover)"/>
                <Setter Property="Foreground" Value="$($T.Title)"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="TabBtn" TargetType="Button" BasedOn="{StaticResource IconBtn}">
      <Setter Property="Width" Value="Auto"/>
      <Setter Property="Padding" Value="14,3"/>
      <Setter Property="Margin" Value="0,0,6,6"/>
      <Setter Property="MinHeight" Value="30"/>
      <Setter Property="FontSize" Value="$fsS"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="15" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.8"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>
  <Border CornerRadius="12" Background="$($T.WinBg)" BorderBrush="$($T.WinBorder)" BorderThickness="1">
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
      </Grid.RowDefinitions>
      <Grid x:Name="CalHeader" Background="Transparent" Margin="12,8,8,2">
        <TextBlock Text="📅 美國數據公布" Foreground="$($T.Title)" FontWeight="SemiBold" FontSize="$fsH" VerticalAlignment="Center"/>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="CalPin"     Style="{StaticResource IconBtn}" Content="📌" ToolTip="置頂 開/關"/>
          <Button x:Name="CalRefresh" Style="{StaticResource IconBtn}" Content="⟳" ToolTip="立即更新"/>
          <Button x:Name="CalClose"   Style="{StaticResource IconBtn}" Content="✕" ToolTip="關閉（主視窗的 📅 可以再打開）"/>
        </StackPanel>
      </Grid>
      <WrapPanel Grid.Row="1" Margin="12,6,12,0">
        <Button x:Name="CalImp" Style="{StaticResource TabBtn}" ToolTip="只看 ★★★ 以上（CPI、非農、FOMC、PPI、零售銷售、初領失業金…）"/>
        <Button x:Name="CalEvt" Style="{StaticResource TabBtn}" ToolTip="是否顯示聯準會官員談話、會議等沒有數字的事件"/>
      </WrapPanel>
      <Border x:Name="NextBox" Grid.Row="2" Margin="12,2,12,8" Padding="12,8" CornerRadius="8" Background="$($T.CardNew)" BorderBrush="#FFB020" BorderThickness="3,0,0,0">
        <StackPanel>
          <DockPanel>
            <TextBlock x:Name="NextLeft" DockPanel.Dock="Right" Foreground="#FFB020" FontWeight="Bold" FontSize="$fs"/>
            <TextBlock x:Name="NextLabel" Foreground="$($T.Muted)" FontSize="$fsS" VerticalAlignment="Center"/>
          </DockPanel>
          <TextBlock x:Name="NextTitle" Foreground="$($T.Title)" FontWeight="SemiBold" TextWrapping="Wrap" Margin="0,2,0,0"/>
        </StackPanel>
      </Border>
      <ScrollViewer x:Name="CalScroller" Grid.Row="3" VerticalScrollBarVisibility="Auto" Margin="6,0,4,0">
        <StackPanel x:Name="CalList" Margin="0,0,4,0"/>
      </ScrollViewer>
      <TextBlock x:Name="CalStatus" Grid.Row="4" Foreground="$($T.Dim)" FontSize="$fsS" Margin="12,6,24,8" TextTrimming="CharacterEllipsis"/>
    </Grid>
  </Border>
</Window>
"@
    $cw = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $cx))
    if (Test-Path $IconPath) { try { $cw.Icon = [Windows.Media.Imaging.BitmapFrame]::Create([Uri]$IconPath) } catch {} }
    $c = @{}
    foreach ($n in 'CalHeader','CalPin','CalRefresh','CalClose','CalImp','CalEvt','NextBox','NextLeft','NextLabel','NextTitle','CalScroller','CalList','CalStatus') { $c[$n] = $cw.FindName($n) }
    $script:CalWin = $cw
    $script:CalUi = $c
    $script:CalScrolled = $false
    $cw.Topmost = $script:CalTopmost

    # 位置：上次的位置（還在螢幕內才用），不然放在主視窗左邊
    $cw.WindowStartupLocation = 'Manual'
    $vs = [System.Windows.SystemParameters]
    $p = $script:CalPos
    if ($p -and $null -ne $p.Left -and $p.Left -ge $vs::VirtualScreenLeft -and $p.Left -lt ($vs::VirtualScreenLeft + $vs::VirtualScreenWidth - 50) -and
        $p.Top -ge $vs::VirtualScreenTop -and $p.Top -lt ($vs::VirtualScreenTop + $vs::VirtualScreenHeight - 50)) {
        $cw.Left = $p.Left; $cw.Top = $p.Top
        if ($p.Width -ge 340) { $cw.Width = $p.Width; $cw.Height = $p.Height }
    } else {
        $cw.Height = [Math]::Max(300, $window.ActualHeight)
        $cw.Top = $window.Top
        $cw.Left = $window.Left - $cw.Width - 10
        if ($cw.Left -lt $vs::VirtualScreenLeft) { $cw.Left = $window.Left + $window.ActualWidth + 10 }
    }

    $c.CalHeader.Add_MouseLeftButtonDown({ $script:CalWin.DragMove() })
    $c.CalClose.Add_Click({ $script:CalWin.Close() })
    $c.CalRefresh.Add_Click({ Start-CalFetch })
    $c.CalPin.Add_Click({ $script:CalWin.Topmost = -not $script:CalWin.Topmost; $script:CalTopmost = $script:CalWin.Topmost; Render-Cal; Save-Settings })
    $c.CalImp.Add_Click({ $script:CalOnlyImp = -not $script:CalOnlyImp; Render-Cal; Save-Settings })
    $c.CalEvt.Add_Click({ $script:CalEvents  = -not $script:CalEvents;  Render-Cal; Save-Settings })
    $cw.Add_Closed({
        $w = $script:CalWin
        $script:CalPos = @{ Left = $w.Left; Top = $w.Top; Width = $w.ActualWidth; Height = $w.ActualHeight }
        $script:CalWin = $null; $script:CalUi = $null
        if (-not $script:ShuttingDown) { $script:CalOpen = $false; Save-Settings }
    })
    $script:CalOpen = $true
    Save-Settings
    $cw.Show()
    Render-Cal
    if (-not $script:CalJob -and ($script:CalFirst -or $script:CalErr)) { Start-CalFetch }
}

# ------------------------- 自動更新（GitHub Releases）-------------------------
$script:UpdJob   = $null
$script:UpdInfo  = $null          # @{ Version; Url; Notes }
$script:UpdNext  = 20             # 啟動 20 秒後檢查一次，之後每 6 小時
$script:UpdShown = $null          # 已經跳過通知的版本（同一版只通知一次）
$UpdCheckScript = {
    param([string]$Repo, [string]$Asset)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $wc = New-Object Net.WebClient
    $wc.Encoding = [Text.Encoding]::UTF8
    $wc.Headers['User-Agent'] = 'CryptoNewsWidget-Updater'
    $wc.Headers['Accept'] = 'application/vnd.github+json'
    try { $r = $wc.DownloadString("https://api.github.com/repos/$Repo/releases/latest") | ConvertFrom-Json } finally { $wc.Dispose() }
    $a = @($r.assets | ForEach-Object { $_ } | Where-Object { $_.name -eq $Asset }) | Select-Object -First 1
    if (-not $a) { $a = @($r.assets | ForEach-Object { $_ } | Where-Object { $_.name -like '*.exe' }) | Select-Object -First 1 }
    [pscustomobject]@{ Tag = [string]$r.tag_name; Url = [string]$a.browser_download_url; Notes = [string]$r.body; Page = [string]$r.html_url }
}
function Convert-Ver([string]$s) {
    $s = ($s -replace '^[vV]', '').Trim()
    $v = $null
    if ([version]::TryParse($s, [ref]$v)) { return $v }
    return $null
}
function Start-UpdateCheck {
    if ($script:UpdJob -or $UpdateRepo -like '__*') { return }
    $ps = [PowerShell]::Create()
    [void]$ps.AddScript($UpdCheckScript.ToString()).AddArgument($UpdateRepo).AddArgument($UpdateAsset)
    $script:UpdJob = @{ PS = $ps; Handle = $ps.BeginInvoke() }
}
function Complete-UpdateCheck {
    $job = $script:UpdJob; $script:UpdJob = $null
    $res = $null
    try { $res = $job.PS.EndInvoke($job.Handle) | Select-Object -Last 1 } catch {}
    $job.PS.Dispose()
    $script:UpdNext = 6 * 3600
    if (-not $res -or -not $res.Url) { return }
    $latest = Convert-Ver $res.Tag; $mine = Convert-Ver $AppVersion
    if (-not $latest -or -not $mine -or $latest -le $mine) { $ui.UpdateBar.Visibility = 'Collapsed'; return }
    $script:UpdInfo = @{ Version = $latest.ToString(); Url = $res.Url; Notes = $res.Notes; Page = $res.Page }
    $ui.UpdateText.Text = "⬆ 有新版本 v$($latest)（目前 v$AppVersion），點這裡自動更新"
    $notes = ($res.Notes -replace '\r', '').Trim()
    $ui.UpdateBar.ToolTip = if ($notes) { "更新內容：`n" + $(if ($notes.Length -gt 600) { $notes.Substring(0, 600) + '…' } else { $notes }) } else { $null }
    $ui.UpdateBar.Visibility = 'Visible'
    if ($script:UpdShown -ne $script:UpdInfo.Version) {
        $script:UpdShown = $script:UpdInfo.Version
        $tray.ShowBalloonTip(8000, '幣圈美股快訊 有新版本', "v$($latest) 已發布，點小工具下方的藍色提示即可更新。", [System.Windows.Forms.ToolTipIcon]::Info)
    }
}
function Install-Update {
    $u = $script:UpdInfo
    if (-not $u) { return }
    $ok = [System.Windows.MessageBox]::Show("要更新到 v$($u.Version) 嗎？`n`n會下載新版安裝檔並自動安裝，小工具會先關閉、裝好後自動重新開啟。你的設定（幣種、字體、視窗位置…）都會保留。", '幣圈美股快訊 更新', 'YesNo', 'Question')
    if ($ok -ne 'Yes') { return }
    $ui.UpdateText.Text = '下載新版中…'
    $window.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Render)
    $dest = Join-Path $env:TEMP ('CryptoNewsWidget-Setup-' + $u.Version + '.exe')
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $wc = New-Object Net.WebClient
        $wc.Headers['User-Agent'] = 'CryptoNewsWidget-Updater'
        try { $wc.DownloadFile($u.Url, $dest) } finally { $wc.Dispose() }
        if ((Get-Item $dest).Length -lt 50KB) { throw '下載的檔案不完整' }
    } catch {
        $ui.UpdateText.Text = "⬆ 有新版本 v$($u.Version)，點這裡重試"
        [System.Windows.MessageBox]::Show("下載失敗：$($_.Exception.Message)`n`n也可以到 GitHub 手動下載：`n$($u.Page)", '幣圈美股快訊 更新', 'OK', 'Warning') | Out-Null
        return
    }
    Start-Process $dest
    $window.Close()   # 安裝程式會覆蓋檔案並重新開啟小工具
}
$ui.UpdateBar.Add_MouseLeftButtonUp({ Install-Update })

# ------------------------- 事件 -------------------------
$ui.Header.Add_MouseLeftButtonDown({ $window.DragMove() })
$ui.BtnClose.Add_Click({ $window.Close() })
$ui.BtnMin.Add_Click({ $window.Hide() })
$ui.BtnRefresh.Add_Click({ Start-Fetch })
$ui.BtnSettings.Add_Click({ Show-SymbolDialog })
$ui.HeaderTitle.ToolTip = "幣圈美股快訊 v$AppVersion"
$ui.BtnCal.Add_Click({ Show-CalWindow })
$ui.Ticker.Background = Brush '#00000000'
$ui.Ticker.Cursor = 'Hand'
$ui.Ticker.ToolTip = '點一下自訂要顯示的幣與美股'
$ui.Ticker.Add_MouseLeftButtonUp({ Show-SymbolDialog })
$ui.BtnPin.Add_Click({ $window.Topmost = -not $window.Topmost; Render-Buttons; Save-Settings })
$ui.BtnVoice.Add_Click({
    $script:AlertOn = -not $script:AlertOn
    if (-not $script:AlertOn) { $synth.SpeakAsyncCancelAll() }
    Render-Buttons; Save-Settings
})
$ui.TabAll.Add_Click({      $script:Filter = 'all';      Render-Buttons; Render-List; $ui.Scroller.ScrollToTop(); Save-Settings })
$ui.TabCrypto.Add_Click({   $script:Filter = 'crypto';   Render-Buttons; Render-List; $ui.Scroller.ScrollToTop(); Save-Settings })
$ui.TabStock.Add_Click({    $script:Filter = 'stock';    Render-Buttons; Render-List; $ui.Scroller.ScrollToTop(); Save-Settings })
$ui.TabBreaking.Add_Click({ $script:Filter = 'breaking'; Render-Buttons; Render-List; $ui.Scroller.ScrollToTop(); Save-Settings })
$ui.TabWatch.Add_Click({    $script:Filter = 'watch';    Render-Buttons; Render-List; $ui.Scroller.ScrollToTop(); Save-Settings })
$ui.TabImportant.Add_Click({ $script:OnlyImportant = -not $script:OnlyImportant; Render-Buttons; Render-List; $ui.Scroller.ScrollToTop(); Save-Settings })

# 每 0.3 秒檢查背景工作是否完成
$pollTimer = New-Object Windows.Threading.DispatcherTimer
$pollTimer.Interval = [TimeSpan]::FromMilliseconds(300)
$pollTimer.Add_Tick({
    if ($script:Job -and $script:Job.Handle.IsCompleted) { Complete-Fetch }
    if ($script:CalJob -and $script:CalJob.Handle.IsCompleted) { Complete-CalFetch }
    if ($script:UpdJob -and $script:UpdJob.Handle.IsCompleted) { Complete-UpdateCheck }
})

# 每秒倒數
$secTimer = New-Object Windows.Threading.DispatcherTimer
$secTimer.Interval = [TimeSpan]::FromSeconds(1)
$secTimer.Add_Tick({
    if (-not $script:Job) {
        $script:Countdown--
        if ($script:Countdown -le 0) { Start-Fetch }
        elseif ($script:Countdown % 30 -eq 0) { Render-List }   # 刷新「幾分鐘前」
    }
    Render-Status
    # 自動更新檢查
    if (-not $script:UpdJob) { $script:UpdNext--; if ($script:UpdNext -le 0) { $script:UpdNext = 6 * 3600; Start-UpdateCheck } }
    # 美國數據：視窗關著也會在背景更新，重要數據一公布就跳通知
    if (-not $script:CalJob) {
        $script:CalCountdown--
        if ($script:CalCountdown -le 0) { Start-CalFetch }
    }
    if ($script:CalUi) {
        if ((Get-Date).Second % 30 -eq 0) { Render-Cal } else { Update-CalNext }
    }
})

$window.Add_Loaded({
    Update-WatchRx
    Apply-Appearance
    $pollTimer.Start(); $secTimer.Start()
    Start-Fetch
    Start-CalFetch
    if ($script:CalOpen) { Show-CalWindow }
})
$window.Add_Closing({
    $script:ShuttingDown = $true
    if ($script:CalWin) { $script:CalOpen = $true }
    Save-Settings
    if ($script:CalWin) { $script:CalWin.Close() }
    $pollTimer.Stop(); $secTimer.Stop()
    try { $synth.SpeakAsyncCancelAll(); $synth.Dispose() } catch {}
    try { $tray.Visible = $false; $tray.Dispose() } catch {}
})

$app = New-Object Windows.Application
$app.ShutdownMode = 'OnMainWindowClose'
[void]$app.Run($window)
$mutex.ReleaseMutex()

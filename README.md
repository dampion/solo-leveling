# Solo Leveling

個人使用的 iPhone side project 入口。SwiftUI、iOS 17 以上，無第三方套件、無 App 後端。

## 開始使用

1. 使用 Xcode 開啟 `SoloLeveling.xcodeproj`，選取 `SoloLeveling` scheme。
2. 選取 App target → **Signing & Capabilities** → 開啟 **Automatically manage signing**。
3. 在 Xcode → Settings → Accounts 登入 Apple 帳號，選取自己的 **Personal Team**。若 Bundle Identifier 已被使用，將 `dev.evanchen79.SoloLeveling` 改成自己的唯一識別碼，之後維持相同識別碼以保留資料。
4. 連接並信任 iPhone；在手機 **設定 → 隱私權與安全性 → 開發者模式** 啟用 Developer Mode，依提示重新啟動。選取手機為執行裝置並按 Run。必要時在 **設定 → 一般 → VPN 與裝置管理** 信任開發者。
5. 首次輸入 `0304`。右上角設定可修改四位數密碼、啟用 Face ID；右下角選單開啟網站。

免費 Apple 帳號的佈建效期為 7 天，到期後以相同 Team 與 Bundle Identifier 重新 Run。直接覆蓋安裝，避免刪除 App 而遺失網站資料。簽署與實機配對需在你的 Xcode 中完成；本專案不包含簽署憑證。

## 功能與資料

- Face ID 預設關閉，設定頁驗證成功後才啟用。之後開啟 App 自動驗證；取消、失敗或不可用時輸入 **App 密碼**，不改用手機解鎖碼。
- 進入背景即上鎖，回到前景重新驗證。Face ID 系統提示造成的 inactive 狀態不會重複上鎖。網站畫面離開背景後需從入口重開，但網站儲存資料仍保留。
- 首次登入算第 1 天；距最後成功登入超過 24 小時，重置為第 1 天。若未中斷且距最後累加至少 24 小時，增加 1 天。每次成功登入更新最後登入時間；停留在 App 不會自動登入。時間倒退時保留天數並重設計時基準。
- 首頁「上次登入」顯示此次解鎖之前的成功登入時間。紀錄與 Face ID 偏好存於 UserDefaults；密碼的隨機鹽與雜湊存於僅限本機、裝置解鎖後可讀取的 Keychain。
- WebView 使用 `WKWebsiteDataStore.default()`，保留各網站的 localStorage、Cookie 等資料；不與 Safari 共用，不自動匯入 Safari 的舊進度。刪除 App 或網站自行清除資料可能導致進度遺失。App 不提供雲端同步；嵌入網站自身的網路與資料行為由各網站決定。
- 日本語學習使用 HTTPS。王品品牌島目前保留需求提供的 HTTP 網址，ATS 只允許該完整網域的 HTTP，不允許所有網站；待確認該站 HTTPS 正常後，可修改 `SideProject.url` 並移除對應例外。
- Keychain 資料可能在重新安裝後保留，因此重新安裝不保證將已修改的密碼重設成 `0304`。本版沒有忘記密碼或復原流程。

## 開發與驗證

```sh
# 建置 iPhone App，不簽署（不能直接安裝）
xcodebuild -project SoloLeveling.xcodeproj -scheme SoloLeveling \
  -configuration Debug -destination 'generic/platform=iOS' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build

# 在 macOS 執行核心邏輯的 XCTest，不需啟動 iOS 模擬器
swift test
```

Swift Package 僅包含平台無關的核心邏輯；App 本體由 Xcode 專案建置。測試涵蓋 24 小時邊界、連續登入、重啟讀取、時間倒退、重複解鎖與過期回呼、四位數密碼格式。Xcode App scheme 本身未配置測試 target，請使用 `swift test` 執行核心測試。

本次環境驗證：13 個 XCTest 全部通過；所有 App Swift 原始碼通過 iOS SDK 型別檢查（啟用完整併發檢查，將警告視為錯誤）。專案與 plist 格式檢查通過。完整 `xcodebuild` 在資產編譯階段因無法連線 CoreSimulator／取得 simulator runtimes 而失敗，尚未產出經完整驗證的可安裝 App。兩個網站在此環境無法解析 DNS；Face ID、畫面與 localStorage 保存仍需依下列清單在實機驗證。

受限環境可將 Swift 的快取改至可寫目錄：

```sh
CLANG_MODULE_CACHE_PATH=/private/tmp/solo-leveling-clang-cache \
swift test --scratch-path .build \
  --cache-path /private/tmp/solo-leveling-spm-cache --disable-sandbox
```

### 實機驗收

以下涉及 iOS 系統與外部網站，必須實際操作，核心單元測試不代表這些項目已通過：

1. 首次以 `0304` 解鎖；錯誤密碼留在鎖定畫面。修改密碼時驗證舊密碼、新密碼格式與兩次一致；重開後新密碼有效、舊密碼無效。
2. 啟用 Face ID，確認重開會自動提示；取消、辨識失敗、權限拒絕均可改輸入 App 密碼；關閉設定後不再自動提示。
3. 從首頁、設定及網站退到背景，再回來均需解鎖。Face ID 提示不造成驗證迴圈；App 切換器不應顯示網站或設定內容。
4. 連續多次解鎖不增加天數。中間登入可維持連續性；完整時間邊界由單元測試驗證。
5. 兩個網站能載入；上一頁、重新整理、關閉與另開視窗連結正常；斷網後有錯誤與重試入口。
6. 在日本語學習建立進度，關閉網站再開、將 App 結束再開，確認進度保留。Safari 既有進度不會自動出現在 App。

## 專案結構

- `SoloLeveling/App/`：SwiftUI 畫面、Face ID、Keychain、WebView。
- `SoloLeveling/Core/`：登入計算、持久化與解鎖事件防重。
- `SoloLeveling/Resources/`：Info.plist、隱私權資訊與圖示。
- `Tests/SoloLevelingCoreTests/`：XCTest 核心測試。

使用四個空白縮排、Swift 標準命名；核心邏輯保持可獨立測試。既有 `AGENTS.md` 保留不變。

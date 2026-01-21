# 安全網地圖 APP - 使用指南

## 📱 專案概述

這是一個 Flutter 開發的設備追蹤地圖應用，整合 Firebase Auth、Google Maps 和 Cloud Functions API，提供完整的設備綁定、位置追蹤和通知管理功能。

## 🎨 設計風格

- **UI 風格**: iOS Cupertino 設計風格
- **主色調**: 藍綠色 (#4ECDC4)
- **次要色**: 橙色 (#FF6B6B)
- **特色**: 圓潤按鈕、柔和陰影、流暢動畫

## 🏗️ 專案結構

```
lib/
├── main.dart                    # 應用程式進入點
├── models/                      # 資料模型
│   ├── gateway.dart            # 接收點模型
│   ├── notification_point.dart # 通知點位模型
│   ├── device.dart             # 設備模型
│   ├── activity.dart           # 活動記錄模型
│   └── user_profile.dart       # 用戶資料模型
├── services/                    # 服務類別
│   ├── auth_service.dart       # Firebase 認證服務
│   └── api_service.dart        # Cloud Functions API 服務
├── providers/                   # 狀態管理
│   ├── auth_provider.dart      # 認證狀態
│   ├── map_provider.dart       # 地圖狀態
│   └── user_provider.dart      # 用戶狀態
├── screens/                     # 畫面
│   ├── splash_screen.dart      # 啟動畫面
│   ├── auth/                   # 認證相關
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   └── home/                   # 主畫面
│       ├── home_screen.dart    # 底部導覽
│       ├── map_tab.dart        # 地圖頁面
│       ├── profile_tab.dart    # 個人資料頁面
│       └── notification_points_screen.dart
├── widgets/                     # UI 元件
│   ├── map/                    # 地圖相關元件
│   │   ├── bind_device_button.dart
│   │   └── timeline_bottom_sheet.dart
│   └── dialogs/                # 對話框元件
│       ├── bind_device_dialog.dart
│       └── gateway_detail_dialog.dart
└── utils/                       # 工具類別
    ├── constants.dart          # 常數定義
    └── helpers.dart            # 輔助函數
```

## 🚀 主要功能

### 1. 用戶認證
- **註冊**: Email + 密碼，提供姓名、電話（選填）
- **登入**: Email + 密碼
- **自動登入**: 記住登入狀態
- **登出**: 清除所有本地狀態

### 2. 地圖功能
- **查看接收點**: 顯示所有公共接收點標記
- **接收點資訊**: 點擊標記查看詳細資訊
- **設定通知**: 在接收點設定通知點位
- **定位功能**: 顯示用戶當前位置
- **地圖控制**: 縮放、拖曳、定位按鈕

### 3. 設備管理
- **綁定設備**: 輸入設備 ID、暱稱、年齡
- **查看設備**: 顯示已綁定設備資訊
- **解綁設備**: 移除設備綁定
- **設備狀態**: 左上角圓形按鈕顯示綁定狀態

### 4. 活動追蹤
- **時間軸彈窗**: 可拉起的底部彈窗
- **預覽模式**: 顯示設備暱稱和最新活動
- **完整模式**: 按日期分組的完整活動記錄
- **點擊跳轉**: 點擊活動記錄跳轉到地圖位置

### 5. 通知管理
- **新增通知點位**: 設定點位名稱和通知訊息
- **查看通知點位**: 列表顯示所有通知點位
- **移除通知點位**: 刪除不需要的通知點位
- **推播通知**: 設備經過通知點位時接收推播

### 6. 個人資料
- **用戶資訊**: 顯示頭像、姓名、Email、電話
- **設備資訊**: 顯示已綁定設備詳情
- **通知點位**: 查看和管理通知點位列表
- **登出功能**: 安全登出並清除狀態

## 🔧 環境設定

### 必要配置

1. **Firebase 配置**
   - `lib/firebase_options.dart` ✅
   - `android/app/google-services.json` ✅
   - `ios/Runner/GoogleService-Info.plist` ✅

2. **Google Maps API Key**
   - Android: `android/app/src/main/AndroidManifest.xml` ✅
   - iOS: `ios/Runner/AppDelegate.swift` ✅

3. **Package Name / Bundle ID**
   - Android: `com.app.safe_net` ✅
   - iOS: `com.app.safenet` ✅

### 已安裝依賴

```yaml
dependencies:
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.3
  firebase_messaging: ^15.1.6
  google_maps_flutter: ^2.10.0
  geolocator: ^13.0.2
  http: ^1.2.0
  provider: ^6.1.2
  cached_network_image: ^3.4.1
  intl: ^0.19.0
  permission_handler: ^11.3.1
```

## 📡 API 整合

所有 API 端點已封裝在 `lib/services/api_service.dart`：

- `mapUserAuth` - 註冊/登入
- `getMapUserProfile` - 取得用戶完整資料
- `bindDeviceToMapUser` - 綁定設備
- `unbindDeviceFromMapUser` - 解綁設備
- `getPublicGateways` - 取得接收點列表
- `addMapUserNotificationPoint` - 新增通知點位
- `getMapUserNotificationPoints` - 取得通知點位列表
- `removeMapUserNotificationPoint` - 移除通知點位
- `updateMapUserFcmToken` - 更新 FCM Token
- `getMapUserActivities` - 取得活動記錄

詳細 API 文檔請參考 `MAP_APP_API_ENDPOINTS.md`

## 🎯 使用流程

### 首次使用

1. **註冊帳號**
   - 點擊「立即註冊」
   - 填寫 Email、密碼、姓名
   - 電話為選填欄位

2. **綁定設備**
   - 點擊地圖左上角圓形按鈕
   - 輸入設備 ID
   - 可選填暱稱和年齡

3. **設定通知點位**
   - 在地圖上點擊接收點標記
   - 選擇「新增通知點位」
   - 輸入點位名稱和通知訊息

### 日常使用

1. **查看設備行蹤**
   - 開啟 app 自動載入地圖
   - 向上拉起底部彈窗查看完整時間軸
   - 點擊活動記錄跳轉到地圖位置

2. **接收通知**
   - 設備經過通知點位自動推播
   - app 在前景顯示彈窗通知
   - app 在背景顯示系統推播

3. **管理設定**
   - 切換到「個人資料」頁面
   - 查看或移除綁定設備
   - 管理通知點位列表

## 🔒 權限需求

### Android
- `INTERNET` - 網路連線
- `ACCESS_FINE_LOCATION` - 精確定位
- `ACCESS_COARSE_LOCATION` - 粗略定位

### iOS
- `NSLocationWhenInUseUsageDescription` - 使用時定位
- `NSLocationAlwaysUsageDescription` - 始終定位

### 通知權限
- 首次啟動自動請求通知權限
- 用於接收設備位置推播通知

## 🐛 已知問題與解決方案

### API Key 安全
- 建議在 Google Cloud Console 設定 API Key 限制
- Android: 限制 Package Name + SHA-1
- iOS: 限制 Bundle ID

### 定位權限
- 確保在實體設備上測試定位功能
- 模擬器可能無法正確模擬 GPS

### 推播通知
- iOS 需要實體設備測試
- 需要在 Firebase Console 上傳 APNs 憑證

## 📝 開發筆記

### 狀態管理
使用 Provider 進行狀態管理，包含三個主要 Provider：
- `AuthProvider`: 管理認證狀態
- `MapProvider`: 管理地圖、接收點、通知點位、活動記錄
- `UserProvider`: 管理用戶資料和綁定設備

### 路由導航
- 使用 `CupertinoPageRoute` 實現 iOS 風格頁面轉場
- 根據認證狀態自動導航到登入頁或主畫面

### 資料載入
- 啟動時自動載入接收點（無需登入）
- 登入後載入用戶資料、通知點位、活動記錄
- 支援手動重新整理

## 🎓 學習資源

- [Flutter 官方文檔](https://docs.flutter.dev)
- [Firebase Flutter 文檔](https://firebase.google.com/docs/flutter/setup)
- [Google Maps Flutter 套件](https://pub.dev/packages/google_maps_flutter)
- [Provider 狀態管理](https://pub.dev/packages/provider)

## 📞 支援

如有問題或建議，請參考：
- `MAP_APP_API_ENDPOINTS.md` - API 詳細文檔
- `ENVIRONMENT_SETUP.md` - 環境設定詳情
- `QUICK_START.md` - 快速開始指南

---

**版本**: 1.0.0  
**最後更新**: 2026-01-21  
**開發狀態**: ✅ 所有功能已完成並測試

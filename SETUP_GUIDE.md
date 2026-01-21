# Firebase 與 Google Maps API 設定指南

## 專案資訊
- **專案位置**: `/Users/danielkai/Desktop/flutter_app`
- **套件管理**: 已安裝 Firebase 和 Google Maps 相關依賴

## 📋 需要的配置參數

### 1. Firebase 設定

#### 步驟 1: 建立 Firebase 專案
1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 建立新專案或選擇現有專案
3. 啟用 **Authentication** 服務

#### 步驟 2: 安裝 FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

#### 步驟 3: 配置 Firebase (需要提供的資訊)
在專案目錄執行以下命令:
```bash
cd /Users/danielkai/Desktop/flutter_app
flutterfire configure
```

這將會:
- 自動建立 `lib/firebase_options.dart` 檔案
- 配置 Android 和 iOS 平台的 Firebase 設定

**需要準備的資訊**:
- Firebase 專案 ID
- 選擇要支援的平台 (iOS, Android, Web)

---

### 2. Google Maps API 設定

#### Android 配置

**需要的參數**:
- **Google Maps API Key** (Android)

**設定步驟**:
1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 啟用 **Maps SDK for Android**
3. 建立 API Key (限制為 Android apps)
4. 將 API Key 添加到 `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
  <application ...>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_ANDROID_API_KEY_HERE"/>
  </application>
</manifest>
```

#### iOS 配置

**需要的參數**:
- **Google Maps API Key** (iOS)

**設定步驟**:
1. 在 Google Cloud Console 啟用 **Maps SDK for iOS**
2. 建立 API Key (限制為 iOS apps)
3. 將 API Key 添加到 `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 🔒 Android 權限設定

需要在 `android/app/src/main/AndroidManifest.xml` 添加:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

---

## 🍎 iOS 權限設定

需要在 `ios/Runner/Info.plist` 添加:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>此應用程式需要存取您的位置以顯示地圖</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>此應用程式需要存取您的位置</string>
```

---

## ⚡ iOS 最低版本要求

更新 `ios/Podfile`:

```ruby
platform :ios, '15.0'
```

---

## 📝 待提供的資訊清單

準備好以下資訊後，我可以協助您完成配置:

- [ ] Firebase 專案已建立
- [ ] Firebase Authentication 已啟用
- [ ] Google Maps Android API Key
- [ ] Google Maps iOS API Key
- [ ] 已執行 `flutterfire configure`

---

## 🚀 執行專案

配置完成後:

```bash
cd /Users/danielkai/Desktop/flutter_app
flutter run
```

---

## 📚 範例代碼結構

專案已包含基本的 Firebase 初始化代碼在 `lib/main.dart`。

需要時可以新增:
- `lib/services/auth_service.dart` - Firebase Auth 服務
- `lib/screens/map_screen.dart` - Google Maps 畫面
- `lib/models/` - 資料模型

有任何問題或需要協助設定特定功能，請隨時告訴我！

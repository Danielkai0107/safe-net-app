# Flutter 專案說明

## 專案位置
`/Users/danielkai/Desktop/flutter_app`

## 已完成設定

### ✅ 已安裝的套件
- Firebase Core
- Firebase Auth
- Google Maps Flutter

### ✅ 檔案與配置
- `lib/main.dart` - Firebase 初始化
- `lib/services/auth_service.dart` - 認證服務
- `lib/screens/map_screen.dart` - 地圖畫面
- Android 權限與 API 金鑰設定
- iOS 權限與 API 金鑰設定

## 🔧 下一步：需要您提供的設定

### 1. Firebase 配置
執行以下指令完成 Firebase 設定：
```bash
cd /Users/danielkai/Desktop/flutter_app
flutterfire configure
```

### 2. Google Maps API Keys
需要在以下檔案中替換 API 金鑰：

**Android**: `android/app/src/main/AndroidManifest.xml`
- 尋找: `YOUR_ANDROID_GOOGLE_MAPS_API_KEY_HERE`
- 替換成您的 Android API Key

**iOS**: `ios/Runner/AppDelegate.swift`
- 尋找: `YOUR_IOS_GOOGLE_MAPS_API_KEY_HERE`
- 替換成您的 iOS API Key

## 📖 完整設定說明
請參考 `SETUP_GUIDE.md` 獲取詳細的配置步驟。

## 🚀 執行專案
配置完成後執行：
```bash
flutter run
```

## 💡 建議工作區設定
建議將此目錄設為工作區：
```
/Users/danielkai/Desktop/flutter_app
```
# safe-net-app

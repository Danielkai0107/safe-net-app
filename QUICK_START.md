# 快速開始指南 🚀

## 環境已設定完成！

所有必要的配置都已完成，你可以立即開始開發。

## 📦 已設定內容

### 1. Firebase (safe-net-tw)
- ✅ Android App: `com.app.safe_net`
- ✅ iOS App: `com.app.safenet`
- ✅ 配置檔案已生成並放置在正確位置

### 2. Google Maps
- ✅ API Key: `AIzaSyCdFLTXzYPQlYeBxZWaboqWYTJRDNsKydo`
- ✅ Android 和 iOS 都已配置

### 3. 依賴套件
- ✅ Firebase Auth
- ✅ Firebase Messaging
- ✅ Google Maps
- ✅ Geolocator
- ✅ HTTP Client

## 🎯 立即開始

### 執行應用程式

```bash
# 確保在專案目錄
cd /Users/danielkai/Desktop/flutter_app

# 執行應用程式
flutter run
```

### 測試 API 功能

1. **開啟範例頁面**：
   - 在 `main.dart` 中導入並使用 `ApiUsageExample`
   
2. **或直接使用服務類別**：

```dart
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/services/api_service.dart';

final authService = AuthService();
final apiService = ApiService();

// 登入
await authService.signInWithEmailAndPassword(
  email: 'your@email.com',
  password: 'password',
);

// 呼叫 API
final gateways = await apiService.getPublicGateways();
print('接收點數量: ${gateways['count']}');
```

## 📚 重要檔案位置

### 服務類別
- `lib/services/auth_service.dart` - Firebase 認證
- `lib/services/api_service.dart` - Cloud Functions API

### 畫面
- `lib/screens/map_screen.dart` - Google Maps 畫面

### 範例
- `lib/examples/api_usage_example.dart` - 完整的 API 使用範例

### 文檔
- `MAP_APP_API_ENDPOINTS.md` - API 端點完整文檔
- `ENVIRONMENT_SETUP.md` - 環境設定詳情
- `SETUP_CHECKLIST.md` - 設定檢查清單

## 🔧 常用指令

```bash
# 安裝依賴
flutter pub get

# 執行應用程式
flutter run

# 建立 APK (Debug)
flutter build apk --debug

# 建立 APK (Release)
flutter build apk --release

# 清理建置
flutter clean

# 檢查依賴更新
flutter pub outdated
```

## 📱 支援的平台

- ✅ Android (Package: `com.app.safe_net`)
- ✅ iOS (Bundle ID: `com.app.safenet`)

## 🌐 API 端點

基礎 URL: `https://us-central1-safe-net-tw.cloudfunctions.net`

### 主要 API
1. `mapUserAuth` - 註冊/登入
2. `getPublicGateways` - 取得接收點
3. `bindDeviceToMapUser` - 綁定設備
4. `addMapUserNotificationPoint` - 新增通知點位
5. `getMapUserActivities` - 取得活動記錄

詳細說明請參考 `MAP_APP_API_ENDPOINTS.md`

## 💡 使用範例

### 1. 用戶註冊流程

```dart
// Step 1: Firebase Auth 註冊
final userCredential = await authService.registerWithEmailAndPassword(
  email: 'user@example.com',
  password: 'password123',
);

// Step 2: 註冊到地圖系統
final result = await apiService.mapUserAuth(
  action: 'register',
  email: 'user@example.com',
  name: '張三',
  phone: '0912345678',
);
```

### 2. 取得並顯示接收點

```dart
// 取得所有接收點
final result = await apiService.getPublicGateways();
final gateways = result['gateways'] as List;

// 在地圖上顯示
for (var gateway in gateways) {
  markers.add(Marker(
    markerId: MarkerId(gateway['id']),
    position: LatLng(
      gateway['latitude'],
      gateway['longitude'],
    ),
    infoWindow: InfoWindow(
      title: gateway['name'],
      snippet: gateway['location'],
    ),
  ));
}
```

### 3. 綁定設備並設定通知

```dart
final user = FirebaseAuth.instance.currentUser!;

// 綁定設備
await apiService.bindDeviceToMapUser(
  userId: user.uid,
  deviceId: 'device_abc123',
);

// 新增通知點位
await apiService.addMapUserNotificationPoint(
  userId: user.uid,
  gatewayId: 'gateway_001',
  name: '我的家',
  notificationMessage: '已到達家門口',
);
```

## ⚠️ 注意事項

### Google Maps API Key
目前使用的 API Key 沒有設定限制。**強烈建議**在 Google Cloud Console 設定限制：
- Android: 限制為 Package Name `com.app.safe_net`
- iOS: 限制為 Bundle ID `com.app.safenet`

### Firebase 安全規則
確認 Firestore 安全規則已正確設定，保護用戶資料。

### 推播通知
如需使用推播通知，還需要：
- iOS: 上傳 APNs 認證金鑰到 Firebase
- 應用程式: 請求通知權限並取得 FCM Token

詳細步驟請參考 `SETUP_CHECKLIST.md`

## 🐛 常見問題

### Q: 地圖無法顯示？
A: 檢查 API Key 是否正確設定，並確認網路連線正常。

### Q: Firebase 認證失敗？
A: 確認 `firebase_options.dart` 已正確生成，並檢查 Firebase Console 的認證設定。

### Q: API 呼叫回傳 401 錯誤？
A: 確認已登入並取得有效的 ID Token。

### Q: iOS 編譯錯誤？
A: 執行 `cd ios && pod install` 安裝 CocoaPods 依賴。

## 📞 需要協助？

遇到問題時，請檢查：
1. `ENVIRONMENT_SETUP.md` - 環境設定詳情
2. `SETUP_CHECKLIST.md` - 完整檢查清單
3. `MAP_APP_API_ENDPOINTS.md` - API 文檔
4. `lib/examples/api_usage_example.dart` - 程式碼範例

---

**準備好了！開始開發吧！** 🎉

**最後更新**: 2026-01-21

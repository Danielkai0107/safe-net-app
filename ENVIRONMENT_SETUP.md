# 環境設定完成摘要

## ✅ 已完成的設定

### 1. Package Name / Bundle ID

- **Android Package Name**: `com.app.safe_net`
- **iOS Bundle ID**: `com.app.safenet` (iOS 不允許底線)

### 2. Google Maps API

- **API Key**: `AIzaSyCdFLTXzYPQlYeBxZWaboqWYTJRDNsKydo`
- **Android**: 已設定在 `android/app/src/main/AndroidManifest.xml`
- **iOS**: 已設定在 `ios/Runner/AppDelegate.swift`

### 3. Firebase 配置

- **專案**: safe-net-tw
- **Region**: us-central1
- **配置檔案**:
  - ✅ `lib/firebase_options.dart`
  - ✅ `android/app/google-services.json`
  - ✅ `ios/Runner/GoogleService-Info.plist`

**Firebase App IDs**:
- Android: `1:290555063879:android:5fd7823bbdd780f6bd4b62`
- iOS: `1:290555063879:ios:7c622b03c8651664bd4b62`

### 4. 已安裝的依賴套件

```yaml
dependencies:
  firebase_core: ^3.8.1          # Firebase 核心
  firebase_auth: ^5.3.3          # Firebase 認證
  firebase_messaging: ^15.1.6    # FCM 推播通知
  google_maps_flutter: ^2.10.0   # Google Maps
  geolocator: ^13.0.2            # 定位服務
  http: ^1.2.0                   # HTTP 客戶端
```

### 5. API 服務類別

已建立 `lib/services/api_service.dart`，包含所有 Cloud Functions API 的封裝方法：

- ✅ mapUserAuth (註冊/登入)
- ✅ updateMapUserFcmToken
- ✅ bindDeviceToMapUser
- ✅ unbindDeviceFromMapUser
- ✅ getPublicGateways
- ✅ addMapUserNotificationPoint
- ✅ getMapUserNotificationPoints
- ✅ updateMapUserNotificationPoint
- ✅ removeMapUserNotificationPoint
- ✅ getMapUserActivities

## 📋 需要補充的設定

### Android 構建配置

需要在 `android/build.gradle.kts` 添加 Google Services plugin：

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

然後在 `android/app/build.gradle.kts` 添加：

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // 添加這行
}
```

### iOS 權限設定

已設定在 `ios/Runner/Info.plist`：
- ✅ NSLocationWhenInUseUsageDescription
- ✅ NSLocationAlwaysUsageDescription

### Android 權限設定

已設定在 `android/app/src/main/AndroidManifest.xml`：
- ✅ INTERNET
- ✅ ACCESS_FINE_LOCATION
- ✅ ACCESS_COARSE_LOCATION

## 🚀 使用範例

### 1. 初始化 Firebase (已在 main.dart)

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

### 2. 使用 AuthService 登入

```dart
import 'package:flutter_app/services/auth_service.dart';

final authService = AuthService();

// 註冊
await authService.registerWithEmailAndPassword(
  email: 'user@example.com',
  password: 'password123',
);

// 登入
await authService.signInWithEmailAndPassword(
  email: 'user@example.com',
  password: 'password123',
);
```

### 3. 使用 ApiService 呼叫 Cloud Functions

```dart
import 'package:flutter_app/services/api_service.dart';

final apiService = ApiService();

// 註冊到地圖 APP 系統
final result = await apiService.mapUserAuth(
  action: 'register',
  email: 'user@example.com',
  name: '張三',
  phone: '0912345678',
);

// 取得公共接收點
final gateways = await apiService.getPublicGateways();

// 新增通知點位
await apiService.addMapUserNotificationPoint(
  userId: 'firebase_uid_123',
  gatewayId: 'gateway_001',
  name: '我的家',
  notificationMessage: '已到達家門口',
);
```

### 4. 使用 Google Maps

```dart
import 'package:flutter_app/screens/map_screen.dart';

// 已建立基本的 MapScreen，可以直接使用
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const MapScreen()),
);
```

## 🧪 測試步驟

1. **測試編譯**:
   ```bash
   flutter run
   ```

2. **測試 Firebase Auth**:
   - 使用 AuthService 進行註冊/登入
   - 確認可以取得 ID Token

3. **測試 Google Maps**:
   - 開啟 MapScreen
   - 確認地圖正常顯示
   - 確認定位功能正常

4. **測試 API 呼叫**:
   - 呼叫 getPublicGateways (不需認證)
   - 登入後呼叫其他 API

## ⚠️ 注意事項

### Google Maps API Key 限制

建議在 Google Cloud Console 設定 API Key 限制：

**Android API Key**:
- 應用程式限制: Android apps
- 限制為 Package Name: `com.app.safe_net`
- SHA-1 指紋: (需要從開發/發布金鑰取得)

**iOS API Key**:
- 應用程式限制: iOS apps
- 限制為 Bundle ID: `com.app.safenet`

### Firebase 安全規則

確認 Firestore 和 Storage 的安全規則已正確設定，允許地圖 APP 用戶存取相關資料。

### FCM 推播通知

如需使用推播通知，還需要：
1. 在 Firebase Console 上傳 APNs 認證金鑰 (iOS)
2. 在應用程式中請求通知權限
3. 取得並更新 FCM Token

## 📚 相關文件

- [MAP_APP_API_ENDPOINTS.md](MAP_APP_API_ENDPOINTS.md) - API 端點完整文檔
- [Firebase 文檔](https://firebase.google.com/docs/flutter/setup)
- [Google Maps Flutter 文檔](https://pub.dev/packages/google_maps_flutter)

---

**設定完成日期**: 2026-01-21  
**Firebase 專案**: safe-net-tw  
**狀態**: ✅ 環境設定完成，可以開始開發

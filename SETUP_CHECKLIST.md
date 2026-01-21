# 環境設定檢查清單

## ✅ 已完成項目

### 1. 專案識別碼
- [x] Android Package Name: `com.app.safe_net`
- [x] iOS Bundle ID: `com.app.safenet`
- [x] MainActivity 已移動到正確的 package 資料夾

### 2. Firebase 配置
- [x] Firebase 專案: `safe-net-tw`
- [x] 已生成 `lib/firebase_options.dart`
- [x] 已下載 `android/app/google-services.json`
- [x] 已下載 `ios/Runner/GoogleService-Info.plist`
- [x] Android 已添加 Google Services plugin
- [x] Firebase App IDs:
  - Android: `1:290555063879:android:5fd7823bbdd780f6bd4b62`
  - iOS: `1:290555063879:ios:7c622b03c8651664bd4b62`

### 3. Google Maps API
- [x] API Key: `AIzaSyCdFLTXzYPQlYeBxZWaboqWYTJRDNsKydo`
- [x] Android AndroidManifest.xml 已設定
- [x] iOS AppDelegate.swift 已設定
- [x] Android 權限已設定 (INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION)
- [x] iOS 權限已設定 (NSLocationWhenInUseUsageDescription, NSLocationAlwaysUsageDescription)

### 4. 依賴套件
- [x] firebase_core: ^3.8.1
- [x] firebase_auth: ^5.3.3
- [x] firebase_messaging: ^15.1.6
- [x] google_maps_flutter: ^2.10.0
- [x] geolocator: ^13.0.2
- [x] http: ^1.2.0
- [x] 已執行 `flutter pub get`

### 5. 服務類別
- [x] `lib/services/auth_service.dart` - Firebase 認證服務
- [x] `lib/services/api_service.dart` - Cloud Functions API 服務
- [x] `lib/screens/map_screen.dart` - Google Maps 畫面
- [x] `lib/examples/api_usage_example.dart` - API 使用範例

### 6. 文檔
- [x] `MAP_APP_API_ENDPOINTS.md` - API 端點文檔
- [x] `ENVIRONMENT_SETUP.md` - 環境設定摘要
- [x] `SETUP_CHECKLIST.md` - 本檢查清單

## ⚠️ 建議補充項目

### Google Maps API Key 安全設定

建議在 [Google Cloud Console](https://console.cloud.google.com) 設定 API Key 限制：

#### Android API Key 限制
1. 前往 Google Cloud Console
2. 選擇「憑證」→ 找到你的 API Key
3. 設定「應用程式限制」為「Android apps」
4. 新增「套件名稱和指紋」:
   - 套件名稱: `com.app.safe_net`
   - SHA-1 指紋: (需要從你的金鑰庫取得)

取得 SHA-1 指紋：
```bash
# Debug 金鑰
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release 金鑰 (發布時)
keytool -list -v -keystore your-release-key.jks -alias your-key-alias
```

#### iOS API Key 限制
1. 設定「應用程式限制」為「iOS apps」
2. 新增「iOS 套件 ID」: `com.app.safenet`

### Firebase 推播通知設定

如需使用 FCM 推播通知：

#### iOS (APNs)
1. 前往 [Apple Developer](https://developer.apple.com)
2. 建立 APNs 認證金鑰或憑證
3. 在 Firebase Console → 專案設定 → Cloud Messaging
4. 上傳 APNs 認證金鑰

#### Android
- Google Services 已自動配置，無需額外設定

#### 應用程式內設定
在 `main.dart` 添加 FCM 初始化：

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('處理背景訊息: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 設定背景訊息處理器
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const MyApp());
}
```

請求通知權限：

```dart
final messaging = FirebaseMessaging.instance;
final settings = await messaging.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);

if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  // 取得 FCM Token
  final fcmToken = await messaging.getToken();
  
  // 更新到後端
  final apiService = ApiService();
  await apiService.updateMapUserFcmToken(
    userId: FirebaseAuth.instance.currentUser!.uid,
    fcmToken: fcmToken!,
  );
}
```

### 定位服務設定

使用 `geolocator` 套件取得用戶位置：

```dart
import 'package:geolocator/geolocator.dart';

// 檢查權限
LocationPermission permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();
}

// 取得當前位置
Position position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);

print('緯度: ${position.latitude}, 經度: ${position.longitude}');
```

### Firebase 安全規則

確認 Firestore 安全規則允許地圖 APP 用戶存取：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 地圖用戶只能讀寫自己的資料
    match /mapAppUsers/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 地圖用戶只能讀寫自己的通知點位
    match /mapUserNotificationPoints/{pointId} {
      allow read, write: if request.auth != null && 
        resource.data.mapAppUserId == request.auth.uid;
    }
    
    // 地圖用戶只能讀取自己的活動記錄
    match /mapUserActivities/{activityId} {
      allow read: if request.auth != null;
      allow write: if false; // 只能由後端寫入
    }
  }
}
```

## 🧪 測試步驟

### 1. 基本編譯測試
```bash
# Android
flutter build apk --debug

# iOS (需要 macOS)
flutter build ios --debug --no-codesign
```

### 2. 執行應用程式
```bash
flutter run
```

### 3. 測試 Firebase Auth
- 開啟 API 使用範例頁面
- 點擊「註冊並登入」
- 確認可以成功註冊並取得用戶資訊

### 4. 測試 Google Maps
- 開啟 MapScreen
- 確認地圖正常顯示
- 確認可以看到台北 101 標記
- 測試定位功能（需要實體設備或模擬器支援）

### 5. 測試 API 呼叫
- 點擊「取得公共接收點」
- 確認可以取得接收點列表
- 登入後測試其他 API 功能

## 📱 發布準備

### Android
1. 建立 release keystore
2. 設定 `android/key.properties`
3. 更新 `android/app/build.gradle.kts` 的 signing config
4. 取得 release SHA-1 並更新 Google Maps API Key 限制
5. 執行 `flutter build appbundle --release`

### iOS
1. 在 Xcode 中設定 Signing & Capabilities
2. 設定 Bundle ID: `com.app.safenet`
3. 上傳 APNs 認證金鑰到 Firebase
4. 執行 `flutter build ipa --release`

## 🔗 相關連結

- [Firebase Console](https://console.firebase.google.com/project/safe-net-tw)
- [Google Cloud Console](https://console.cloud.google.com)
- [Apple Developer](https://developer.apple.com)
- [Flutter 文檔](https://docs.flutter.dev)
- [Firebase Flutter 文檔](https://firebase.google.com/docs/flutter/setup)

## 📞 需要協助？

如有任何問題，請參考：
- `MAP_APP_API_ENDPOINTS.md` - API 使用說明
- `ENVIRONMENT_SETUP.md` - 環境設定詳情
- `lib/examples/api_usage_example.dart` - 程式碼範例

---

**最後更新**: 2026-01-21  
**狀態**: ✅ 基本環境已完成，可以開始開發

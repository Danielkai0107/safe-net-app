# API 使用範例

## checkMapUserStatus API 使用方法

### 基本用法

```dart
import 'package:your_app/services/api_service.dart';
import 'package:your_app/constants/error_codes.dart';

final apiService = ApiService();

// 檢查用戶狀態
final response = await apiService.checkMapUserStatus(
  userId: 'user-id-here',
);

if (response['success'] == true) {
  final exists = response['exists'] as bool;
  final statusString = response['status'] as String;
  final status = UserStatus.fromString(statusString);
  
  switch (status) {
    case UserStatus.active:
      print('用戶狀態正常');
      break;
    case UserStatus.deleted:
      print('用戶已被刪除');
      // 執行登出流程
      break;
    case UserStatus.suspended:
      print('用戶已被暫停');
      // 顯示暫停訊息
      break;
    case UserStatus.notFound:
      print('用戶不存在');
      break;
  }
}
```

### 在 AuthenticationWrapper 中使用

可以考慮在 `_checkUserData()` 中使用這個輕量級 API 來快速驗證用戶狀態：

```dart
Future<bool> _checkUserData() async {
  final authProvider = context.read<AuthProvider>();
  final userProvider = context.read<UserProvider>();

  // ... 其他檢查邏輯 ...

  final userId = authProvider.user!.uid;
  
  // 可選：快速檢查用戶狀態（輕量級）
  try {
    final statusResponse = await _apiService.checkMapUserStatus(userId: userId);
    
    if (statusResponse['success'] == true) {
      final status = UserStatus.fromString(statusResponse['status']);
      
      if (status == UserStatus.deleted || status == UserStatus.notFound) {
        debugPrint('AuthWrapper: 用戶已被刪除，登出');
        await authProvider.signOut();
        return false;
      }
      
      if (status == UserStatus.suspended) {
        debugPrint('AuthWrapper: 用戶已被暫停');
        // 顯示暫停訊息
        return false;
      }
    }
  } catch (e) {
    debugPrint('AuthWrapper: 檢查用戶狀態失敗 - $e');
    // 錯誤時繼續執行，不影響正常流程
  }

  // 繼續載入完整用戶資料
  await userProvider.loadUserProfile(userId);
  // ...
}
```

### 使用場景

1. **App 啟動時快速驗證**
   - 在載入完整用戶資料前，先用輕量級 API 檢查用戶是否還存在
   - 如果用戶已被刪除，可以直接登出，避免載入大量無用資料

2. **定期健康檢查**
   - 可以設置定時器，每隔一段時間檢查用戶狀態
   - 及早發現帳號被刪除或暫停的情況

3. **操作前預檢查**
   - 在執行重要操作（如綁定設備、更新資料）前
   - 先快速檢查用戶狀態是否正常

### API 回應格式

#### 成功回應（用戶存在且正常）
```json
{
  "success": true,
  "exists": true,
  "status": "ACTIVE",
  "userId": "abc123"
}
```

#### 成功回應（用戶不存在）
```json
{
  "success": true,
  "exists": false,
  "status": "NOT_FOUND"
}
```

#### 成功回應（用戶已被刪除）
```json
{
  "success": true,
  "exists": false,
  "status": "DELETED"
}
```

#### 成功回應（用戶已被暫停）
```json
{
  "success": true,
  "exists": true,
  "status": "SUSPENDED",
  "userId": "abc123"
}
```

### 錯誤處理

```dart
try {
  final response = await apiService.checkMapUserStatus(userId: userId);
  
  if (response['success'] == true) {
    // 處理成功情況
    final status = UserStatus.fromString(response['status']);
    // ...
  } else {
    // 處理失敗情況
    final error = response['error'];
    final errorCode = response['errorCode'];
    print('檢查失敗: $error (code: $errorCode)');
  }
} catch (e) {
  // 處理網路錯誤等異常
  print('發生錯誤: $e');
}
```

### 性能優勢

相比 `getMapUserProfile` API：
- ✅ 更快：不需要查詢和返回完整的用戶資料、設備資料、通知點位等
- ✅ 更輕量：只返回必要的狀態資訊
- ✅ 更省資源：減少資料庫查詢和網路傳輸

建議在只需要驗證用戶狀態的場景下使用 `checkMapUserStatus`，
在需要完整用戶資料時才使用 `getMapUserProfile`。

---

## 其他 API 使用範例

### 使用 ApiResponse 類別

```dart
import 'package:your_app/services/api_service.dart';

final apiService = ApiService();

// 範例：綁定設備
final response = await apiService.bindDeviceToMapUser(
  userId: 'user-id',
  deviceName: 'DEVICE-123',
  nickname: '我的設備',
  age: 25,
  gender: 'MALE',
  avatar: '01.png',
);

if (response['success'] == true) {
  print('綁定成功');
} else {
  // 使用 errorCode 判斷錯誤類型
  final errorCode = response['errorCode'];
  
  if (errorCode == ApiErrorCodes.deviceNotFound) {
    print('設備不存在，請檢查產品序號');
  } else if (errorCode == ApiErrorCodes.deviceAlreadyBound) {
    print('此設備已被其他用戶綁定');
  } else if (errorCode == ApiErrorCodes.userNotFound) {
    print('用戶不存在');
    // 觸發登出流程
  } else {
    print('綁定失敗: ${response['error']}');
  }
}
```

### 檢查帳號刪除

所有 API 都會自動檢查帳號是否被刪除：

```dart
// 不需要手動檢查，ApiService 會自動處理
final response = await apiService.getMapUserProfile(userId: userId);

// 如果帳號被刪除，AccountDeletedHandler 會自動觸發
// 訂閱 onAccountDeleted 事件即可處理
```

在 main.dart 的 AuthenticationWrapper 中已經設置了監聽：

```dart
void _setupAccountDeletedListener() {
  final handler = AccountDeletedHandler();
  _accountDeletedSubscription = handler.onAccountDeleted.listen((reason) {
    _handleAccountDeletedFromApi(reason);
  });
}
```

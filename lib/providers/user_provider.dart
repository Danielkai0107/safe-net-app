import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/device.dart';
import '../services/api_service.dart';

/// 用戶資料狀態管理
class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasDevice => _userProfile?.hasDevice ?? false;
  Device? get boundDevice => _userProfile?.boundDevice;

  /// 載入用戶完整資料
  Future<void> loadUserProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('載入用戶資料: $userId');
      final result = await _apiService.getMapUserProfile(userId: userId);
      debugPrint('API 回應: $result');

      if (result['success'] == true) {
        final userData = result['user'];
        if (userData == null) {
          throw Exception('用戶資料為空');
        }

        _userProfile = UserProfile.fromJson({
          'id': userData['id'] ?? userId,
          'email': userData['email'] ?? '',
          'name': userData['name'] ?? '',
          'phone': userData['phone'],
          'avatar': userData['avatar'],
          'notificationEnabled': userData['notificationEnabled'] ?? true,
          'boundDevice': result['boundDevice'],
          'notificationPoints': result['notificationPoints'] ?? [],
        });
        debugPrint('用戶資料載入成功: ${_userProfile?.name}');
      } else {
        throw Exception(result['error'] ?? '載入用戶資料失敗');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('載入用戶資料失敗: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 綁定設備
  ///
  /// [userId] - 用戶 ID（必需）
  /// [deviceId] - 設備 ID（與 deviceName 二選一）
  /// [deviceName] - 產品序號（與 deviceId 二選一）
  /// [nickname] - 設備暱稱（選填）
  /// [age] - 使用者年齡（選填）
  Future<bool> bindDevice({
    required String userId,
    String? deviceId,
    String? deviceName,
    String? nickname,
    int? age,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('UserProvider: 開始綁定設備');
      debugPrint('  userId: $userId');
      debugPrint('  deviceId: $deviceId');
      debugPrint('  deviceName: $deviceName');
      debugPrint('  nickname: $nickname');
      debugPrint('  age: $age');
      
      final result = await _apiService.bindDeviceToMapUser(
        userId: userId,
        deviceId: deviceId,
        deviceName: deviceName,
        nickname: nickname,
        age: age,
      );

      debugPrint('UserProvider: API 回應: $result');

      if (result['success'] == true) {
        debugPrint('UserProvider: 綁定成功，重新載入用戶資料');
        // 重新載入用戶資料
        await loadUserProfile(userId);
        return true;
      } else {
        _error = result['error'] ?? '綁定設備失敗';
        debugPrint('UserProvider: 綁定失敗 - $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('UserProvider: 綁定錯誤 - $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 解綁設備
  Future<bool> unbindDevice({required String userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.unbindDeviceFromMapUser(userId: userId);

      if (result['success'] == true) {
        // 重新載入用戶資料
        await loadUserProfile(userId);
        return true;
      } else {
        _error = result['error'] ?? '解綁設備失敗';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 更新 FCM Token
  Future<void> updateFcmToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      await _apiService.updateMapUserFcmToken(
        userId: userId,
        fcmToken: fcmToken,
      );
    } catch (e) {
      debugPrint('更新 FCM Token 失敗: $e');
    }
  }

  /// 清除錯誤
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 重置狀態
  void reset() {
    _userProfile = null;
    _error = null;
    notifyListeners();
  }
}

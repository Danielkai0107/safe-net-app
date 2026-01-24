import 'dart:async';
import 'package:flutter/foundation.dart';
import '../constants/error_codes.dart';

/// 帳號刪除處理服務
/// 
/// 當檢測到帳號被刪除時（API 回傳用戶不存在或帳號已刪除錯誤碼），
/// 通知訂閱者執行登出流程。
class AccountDeletedHandler {
  // 單例模式
  static final AccountDeletedHandler _instance =
      AccountDeletedHandler._internal();
  factory AccountDeletedHandler() => _instance;
  AccountDeletedHandler._internal();

  // 使用 StreamController 發送帳號刪除事件
  final _accountDeletedController = StreamController<String>.broadcast();

  /// 帳號刪除事件流
  Stream<String> get onAccountDeleted => _accountDeletedController.stream;

  /// 檢查 API 回應是否表示帳號已被刪除
  /// 
  /// 使用標準化的 errorCode 判斷，不再依賴字串比對
  bool isAccountDeletedError(Map<String, dynamic> response) {
    if (response['success'] == true) return false;

    final errorCode = response['errorCode']?.toString();

    // 檢查標準錯誤碼
    if (errorCode == ApiErrorCodes.userNotFound ||
        errorCode == ApiErrorCodes.accountDeleted) {
      debugPrint('AccountDeletedHandler: 檢測到帳號被刪除 - errorCode: $errorCode');
      return true;
    }

    // 向後相容：如果後端尚未實作 errorCode，回退到字串比對
    // 這段代碼可在後端完全更新後移除
    if (errorCode == null || errorCode.isEmpty) {
      debugPrint(
          'AccountDeletedHandler: errorCode 為空，使用字串比對（向後相容模式）');
      return _legacyStringCheck(response);
    }

    return false;
  }

  /// 向後相容的字串比對檢查（過渡期使用）
  /// 
  /// 當後端尚未實作標準 errorCode 時的備用方案
  bool _legacyStringCheck(Map<String, dynamic> response) {
    final error = response['error']?.toString().toLowerCase() ?? '';

    final accountDeletedPatterns = [
      'user not found',
      '用戶不存在',
      '找不到用戶',
      '找不到使用者',
      'map_user_not_found',
      'user_not_found',
      'account not found',
      'account deleted',
      '帳號不存在',
      '帳號已刪除',
    ];

    for (final pattern in accountDeletedPatterns) {
      if (error.contains(pattern)) {
        debugPrint(
            'AccountDeletedHandler: 字串比對檢測到帳號被刪除 - error: $error');
        return true;
      }
    }

    return false;
  }

  /// 通知帳號已被刪除
  void notifyAccountDeleted({String reason = '您的帳號已被刪除'}) {
    debugPrint('AccountDeletedHandler: 發送帳號刪除通知 - $reason');
    _accountDeletedController.add(reason);
  }

  /// 檢查 API 回應，如果帳號被刪除則自動通知
  /// 
  /// 回傳 true 表示帳號已被刪除
  bool checkAndNotify(Map<String, dynamic> response) {
    if (isAccountDeletedError(response)) {
      notifyAccountDeleted(
          reason: response['error']?.toString() ?? '您的帳號已被刪除');
      return true;
    }
    return false;
  }

  /// 釋放資源
  void dispose() {
    _accountDeletedController.close();
  }
}

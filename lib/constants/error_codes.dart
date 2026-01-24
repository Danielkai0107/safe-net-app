/// API 標準錯誤碼定義
///
/// 對應後端 API 返回的 errorCode 欄位
/// 詳見：docs/BACKEND_API_SPEC.md
class ApiErrorCodes {
  /// 用戶不存在（後端資料庫）
  static const String userNotFound = 'USER_NOT_FOUND';

  /// 用戶已存在（註冊時 email 已被使用）
  static const String userAlreadyExists = 'USER_ALREADY_EXISTS';

  /// 認證資訊無效
  static const String invalidCredentials = 'INVALID_CREDENTIALS';

  /// 設備不存在
  static const String deviceNotFound = 'DEVICE_NOT_FOUND';

  /// 設備已被其他用戶綁定
  static const String deviceAlreadyBound = 'DEVICE_ALREADY_BOUND';

  /// 用戶未綁定設備
  static const String noBoundDevice = 'NO_BOUND_DEVICE';

  /// 帳號已被刪除
  static const String accountDeleted = 'ACCOUNT_DELETED';

  /// 未授權（Token 無效或過期）
  static const String unauthorized = 'UNAUTHORIZED';

  /// 參數驗證失敗
  static const String validationError = 'VALIDATION_ERROR';

  /// 伺服器內部錯誤
  static const String internalError = 'INTERNAL_ERROR';
}

/// 用戶狀態定義
enum UserStatus {
  /// 正常活躍用戶
  active,

  /// 已被刪除
  deleted,

  /// 已被暫停
  suspended,

  /// 不存在
  notFound;

  /// 從字串轉換為 UserStatus
  static UserStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return UserStatus.active;
      case 'DELETED':
        return UserStatus.deleted;
      case 'SUSPENDED':
        return UserStatus.suspended;
      case 'NOT_FOUND':
        return UserStatus.notFound;
      default:
        return UserStatus.notFound;
    }
  }

  /// 轉換為字串
  String toApiString() {
    switch (this) {
      case UserStatus.active:
        return 'ACTIVE';
      case UserStatus.deleted:
        return 'DELETED';
      case UserStatus.suspended:
        return 'SUSPENDED';
      case UserStatus.notFound:
        return 'NOT_FOUND';
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'account_deleted_handler.dart';
import '../constants/error_codes.dart';

/// API 回應封裝類別
///
/// 統一處理所有 API 回應，包含成功、失敗和錯誤碼
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? errorCode;
  final Map<String, dynamic>? errorDetails;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.errorCode,
    this.errorDetails,
  });

  /// 從原始 Map 創建 ApiResponse
  factory ApiResponse.fromMap(Map<String, dynamic> map, {T? data}) {
    return ApiResponse<T>(
      success: map['success'] == true,
      data: data,
      error: map['error']?.toString(),
      errorCode: map['errorCode']?.toString(),
      errorDetails: map['errorDetails'] as Map<String, dynamic>?,
    );
  }

  /// 檢查是否為用戶不存在錯誤
  bool get isUserNotFound =>
      errorCode == ApiErrorCodes.userNotFound ||
      errorCode == ApiErrorCodes.accountDeleted;

  /// 檢查是否為帳號已刪除錯誤
  bool get isAccountDeleted => errorCode == ApiErrorCodes.accountDeleted;

  /// 檢查是否為用戶已存在錯誤
  bool get isUserAlreadyExists => errorCode == ApiErrorCodes.userAlreadyExists;

  /// 檢查是否為設備相關錯誤
  bool get isDeviceError =>
      errorCode == ApiErrorCodes.deviceNotFound ||
      errorCode == ApiErrorCodes.deviceAlreadyBound ||
      errorCode == ApiErrorCodes.noBoundDevice;

  /// 檢查是否為認證錯誤
  bool get isAuthError =>
      errorCode == ApiErrorCodes.unauthorized ||
      errorCode == ApiErrorCodes.invalidCredentials;

  /// 轉換為舊格式（向後相容）
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'success': success};
    if (error != null) map['error'] = error;
    if (errorCode != null) map['errorCode'] = errorCode;
    if (errorDetails != null) map['errorDetails'] = errorDetails;
    if (data != null && data is Map) {
      map.addAll(data as Map<String, dynamic>);
    }
    return map;
  }
}

/// 地圖 APP API 服務
///
/// 用於呼叫 safe-net-tw Firebase Cloud Functions (2nd Gen)
class ApiService {
  final AccountDeletedHandler _accountDeletedHandler = AccountDeletedHandler();
  // 2nd Gen Cloud Functions URLs
  static const String _mapUserAuthUrl =
      'https://mapuserauth-kmzfyt3t5a-uc.a.run.app';
  static const String _updateMapUserFcmTokenUrl =
      'https://updatemapuserfcmtoken-kmzfyt3t5a-uc.a.run.app';
  static const String _bindDeviceToMapUserUrl =
      'https://binddevicetomapuser-kmzfyt3t5a-uc.a.run.app';
  static const String _unbindDeviceFromMapUserUrl =
      'https://unbinddevicefrommapuser-kmzfyt3t5a-uc.a.run.app';
  static const String _getPublicGatewaysUrl =
      'https://getpublicgateways-kmzfyt3t5a-uc.a.run.app';
  static const String _addMapUserNotificationPointUrl =
      'https://addmapusernotificationpoint-kmzfyt3t5a-uc.a.run.app';
  static const String _getMapUserNotificationPointsUrl =
      'https://getmapusernotificationpoints-kmzfyt3t5a-uc.a.run.app';
  static const String _updateMapUserNotificationPointUrl =
      'https://updatemapusernotificationpoint-kmzfyt3t5a-uc.a.run.app';
  static const String _removeMapUserNotificationPointUrl =
      'https://removemapusernotificationpoint-kmzfyt3t5a-uc.a.run.app';
  static const String _getMapUserActivitiesUrl =
      'https://getmapuseractivities-kmzfyt3t5a-uc.a.run.app';
  static const String _getMapUserProfileUrl =
      'https://getmapuserprofile-kmzfyt3t5a-uc.a.run.app';
  static const String _updateMapUserDeviceUrl =
      'https://updatemapuserdevice-kmzfyt3t5a-uc.a.run.app';
  static const String _updateMapUserAvatarUrl =
      'https://updatemapuseravatar-kmzfyt3t5a-uc.a.run.app';
  static const String _deleteMapAppUserUrl =
      'https://deletemapappuser-kmzfyt3t5a-uc.a.run.app';
  static const String _checkMapUserStatusUrl =
      'https://us-central1-safe-net-tw.cloudfunctions.net/checkMapUserStatus';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 取得當前用戶的 ID Token
  Future<String?> _getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  /// 取得認證 Headers
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};

    if (requireAuth) {
      final token = await _getIdToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// 統一處理 API 回應
  ///
  /// 自動檢查帳號刪除狀態並觸發通知
  Map<String, dynamic> _processResponse(Map<String, dynamic> responseBody) {
    // 檢查帳號是否被刪除
    _accountDeletedHandler.checkAndNotify(responseBody);

    return responseBody;
  }

  /// 統一的 POST 請求處理
  Future<Map<String, dynamic>> _post({
    required String url,
    required Map<String, dynamic> body,
    bool requireAuth = true,
  }) async {
    try {
      print('ApiService: POST 請求 - $url');
      print('  Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(requireAuth: requireAuth),
        body: jsonEncode(body),
      );

      print('ApiService: 回應狀態 - ${response.statusCode}');
      print('  Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        return _processResponse(responseBody);
      } else {
        // 處理 HTTP 錯誤
        try {
          final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
          return _processResponse({
            'success': false,
            'error': errorBody['error'] ??
                'HTTP ${response.statusCode}: ${response.reasonPhrase}',
            'errorCode':
                errorBody['errorCode'] ?? ApiErrorCodes.internalError,
          });
        } catch (e) {
          return {
            'success': false,
            'error': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
            'errorCode': ApiErrorCodes.internalError,
          };
        }
      }
    } catch (e) {
      print('ApiService: 請求錯誤 - $e');
      return {
        'success': false,
        'error': '網路錯誤: $e',
        'errorCode': ApiErrorCodes.internalError,
      };
    }
  }

  /// 統一的 GET 請求處理
  Future<Map<String, dynamic>> _get({
    required String url,
    bool requireAuth = true,
  }) async {
    try {
      print('ApiService: GET 請求 - $url');

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(requireAuth: requireAuth),
      );

      print('ApiService: 回應狀態 - ${response.statusCode}');
      print('  Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        return _processResponse(responseBody);
      } else {
        // 處理 HTTP 錯誤
        try {
          final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
          return _processResponse({
            'success': false,
            'error': errorBody['error'] ??
                'HTTP ${response.statusCode}: ${response.reasonPhrase}',
            'errorCode':
                errorBody['errorCode'] ?? ApiErrorCodes.internalError,
          });
        } catch (e) {
          return {
            'success': false,
            'error': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
            'errorCode': ApiErrorCodes.internalError,
          };
        }
      }
    } catch (e) {
      print('ApiService: 請求錯誤 - $e');
      return {
        'success': false,
        'error': '網路錯誤: $e',
        'errorCode': ApiErrorCodes.internalError,
      };
    }
  }

  /// 統一的 PUT 請求處理
  Future<Map<String, dynamic>> _put({
    required String url,
    required Map<String, dynamic> body,
    bool requireAuth = true,
  }) async {
    try {
      print('ApiService: PUT 請求 - $url');
      print('  Body: ${jsonEncode(body)}');

      final response = await http.put(
        Uri.parse(url),
        headers: await _getHeaders(requireAuth: requireAuth),
        body: jsonEncode(body),
      );

      print('ApiService: 回應狀態 - ${response.statusCode}');
      print('  Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        return _processResponse(responseBody);
      } else {
        // 處理 HTTP 錯誤
        try {
          final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
          return _processResponse({
            'success': false,
            'error': errorBody['error'] ??
                'HTTP ${response.statusCode}: ${response.reasonPhrase}',
            'errorCode':
                errorBody['errorCode'] ?? ApiErrorCodes.internalError,
          });
        } catch (e) {
          return {
            'success': false,
            'error': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
            'errorCode': ApiErrorCodes.internalError,
          };
        }
      }
    } catch (e) {
      print('ApiService: 請求錯誤 - $e');
      return {
        'success': false,
        'error': '網路錯誤: $e',
        'errorCode': ApiErrorCodes.internalError,
      };
    }
  }

  /// 用戶認證 API (註冊/登入)
  ///
  /// [action] - "register" 或 "login"
  /// [email] - 用戶電子郵件
  /// [name] - 用戶姓名 (註冊時必填)
  /// [phone] - 用戶電話 (選填)
  Future<Map<String, dynamic>> mapUserAuth({
    required String action,
    required String email,
    String? name,
    String? phone,
  }) async {
    print('ApiService: 用戶認證請求 - Action: $action, Email: $email');

    return await _post(
      url: _mapUserAuthUrl,
      body: {
        'action': action,
        'email': email,
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
      },
    );
  }

  /// 更新 FCM Token
  Future<Map<String, dynamic>> updateMapUserFcmToken({
    required String userId,
    required String fcmToken,
  }) async {
    return await _post(
      url: _updateMapUserFcmTokenUrl,
      body: {'userId': userId, 'fcmToken': fcmToken},
    );
  }

  /// 綁定設備
  ///
  /// [userId] - 用戶 ID（必需）
  /// [deviceId] - 設備 ID（與 deviceName 二選一）
  /// [deviceName] - 產品序號（與 deviceId 二選一）
  /// [nickname] - 設備暱稱（選填）
  /// [age] - 使用者年齡（選填）
  /// [gender] - 性別（選填，MALE | FEMALE | OTHER）
  /// [avatar] - 頭像檔名（選填，例如：01.png）
  Future<Map<String, dynamic>> bindDeviceToMapUser({
    required String userId,
    String? deviceId,
    String? deviceName,
    String? nickname,
    int? age,
    String? gender,
    String? avatar,
  }) async {
    final body = <String, dynamic>{'userId': userId};

    // deviceId 和 deviceName 二選一
    if (deviceId != null) {
      body['deviceId'] = deviceId;
    } else if (deviceName != null) {
      body['deviceName'] = deviceName;
    }

    // 選填參數
    if (nickname != null && nickname.isNotEmpty) {
      body['nickname'] = nickname;
    }
    if (age != null) {
      body['age'] = age;
    }
    if (gender != null && gender.isNotEmpty) {
      body['gender'] = gender;
    }
    if (avatar != null && avatar.isNotEmpty) {
      body['avatar'] = avatar;
    }

    print('ApiService: 綁定設備請求 - userId: $userId');

    return await _post(
      url: _bindDeviceToMapUserUrl,
      body: body,
    );
  }

  /// 解綁設備
  Future<Map<String, dynamic>> unbindDeviceFromMapUser({
    required String userId,
  }) async {
    print('ApiService: 解綁設備請求 - userId: $userId');

    return await _post(
      url: _unbindDeviceFromMapUserUrl,
      body: {'userId': userId},
    );
  }

  /// 更新設備資訊
  ///
  /// [userId] - 用戶 ID（必需）
  /// [avatar] - 頭像檔名（選填）
  /// [nickname] - 設備暱稱（選填，傳入空字串可清空）
  /// [age] - 使用者年齡（選填）
  /// [gender] - 性別（選填，MALE | FEMALE | OTHER）
  /// 
  /// 根據 API 文檔：
  /// - avatar 儲存在 mapAppUsers collection
  /// - nickname, age, gender 儲存在 devices collection（欄位名：mapUserNickname, mapUserAge, mapUserGender）
  /// - 如果用戶未綁定設備，只會更新 avatar
  Future<Map<String, dynamic>> updateMapUserDevice({
    required String userId,
    String? avatar,
    String? nickname,
    int? age,
    String? gender,
  }) async {
    final body = <String, dynamic>{'userId': userId};

    // 只有明確提供值時才加入 body
    if (avatar != null) {
      body['avatar'] = avatar;
    }
    if (nickname != null) {
      body['nickname'] = nickname; // 允許空字串來清空暱稱
    }
    if (age != null) {
      body['age'] = age;
    }
    if (gender != null) {
      body['gender'] = gender;
    }

    print('ApiService: 更新設備資訊請求 - userId: $userId');

    return await _post(
      url: _updateMapUserDeviceUrl,
      body: body,
    );
  }

  /// 更新用戶頭像
  ///
  /// [userId] - 用戶 ID（必需）
  /// [avatar] - 頭像（必需，可以是檔名如 01.png 或完整 URL）
  Future<Map<String, dynamic>> updateMapUserAvatar({
    required String userId,
    required String avatar,
  }) async {
    print('ApiService: 更新用戶頭像請求 - userId: $userId, avatar: $avatar');

    return await _post(
      url: _updateMapUserAvatarUrl,
      body: {'userId': userId, 'avatar': avatar},
    );
  }

  /// 取得所有公共接收點
  Future<Map<String, dynamic>> getPublicGateways() async {
    return await _get(
      url: _getPublicGatewaysUrl,
      requireAuth: false,
    );
  }

  /// 新增通知點位
  Future<Map<String, dynamic>> addMapUserNotificationPoint({
    required String userId,
    required String gatewayId,
    required String name,
    required String notificationMessage,
  }) async {
    return await _post(
      url: _addMapUserNotificationPointUrl,
      body: {
        'userId': userId,
        'gatewayId': gatewayId,
        'name': name,
        'notificationMessage': notificationMessage,
      },
    );
  }

  /// 取得通知點位列表
  Future<Map<String, dynamic>> getMapUserNotificationPoints({
    required String userId,
  }) async {
    return await _get(
      url: '$_getMapUserNotificationPointsUrl?userId=$userId',
    );
  }

  /// 更新通知點位
  Future<Map<String, dynamic>> updateMapUserNotificationPoint({
    required String pointId,
    String? name,
    String? notificationMessage,
    bool? isActive,
  }) async {
    return await _put(
      url: _updateMapUserNotificationPointUrl,
      body: {
        'pointId': pointId,
        if (name != null) 'name': name,
        if (notificationMessage != null)
          'notificationMessage': notificationMessage,
        if (isActive != null) 'isActive': isActive,
      },
    );
  }

  /// 刪除通知點位
  Future<Map<String, dynamic>> removeMapUserNotificationPoint({
    required String pointId,
  }) async {
    return await _post(
      url: _removeMapUserNotificationPointUrl,
      body: {'pointId': pointId},
    );
  }

  /// 取得設備活動記錄
  ///
  /// [userId] - 用戶 ID
  /// [startTime] - 開始時間 (milliseconds since epoch)
  /// [endTime] - 結束時間 (milliseconds since epoch)
  /// [limit] - 最多回傳筆數 (預設 100, 最大 1000)
  Future<Map<String, dynamic>> getMapUserActivities({
    required String userId,
    int? startTime,
    int? endTime,
    int? limit,
  }) async {
    final queryParams = <String, String>{
      'userId': userId,
      if (startTime != null) 'startTime': startTime.toString(),
      if (endTime != null) 'endTime': endTime.toString(),
      if (limit != null) 'limit': limit.toString(),
    };

    final url = Uri.parse(_getMapUserActivitiesUrl)
        .replace(queryParameters: queryParams)
        .toString();

    return await _get(url: url);
  }

  /// 取得用戶完整資料
  ///
  /// 包含基本資訊、綁定設備、通知點位列表
  /// [userId] - 用戶 ID
  Future<Map<String, dynamic>> getMapUserProfile({
    required String userId,
  }) async {
    print('ApiService: 取得用戶資料請求 - userId: $userId');

    return await _get(
      url: '$_getMapUserProfileUrl?userId=$userId',
    );
  }

  /// 註銷帳號
  ///
  /// [userId] - 用戶 ID（必需）
  /// 
  /// 此操作將刪除用戶的所有資料，包括：
  /// - 用戶基本資料
  /// - 綁定的設備資料
  /// - 通知點位設定
  Future<Map<String, dynamic>> deleteMapAppUser({
    required String userId,
  }) async {
    print('ApiService: 註銷帳號請求 - userId: $userId');

    return await _post(
      url: _deleteMapAppUserUrl,
      body: {'userId': userId},
    );
  }

  /// 檢查用戶狀態
  ///
  /// [userId] - 用戶 ID（必需）
  /// 
  /// 輕量級 API，用於快速檢查用戶狀態，不返回完整用戶資料
  /// 
  /// 回傳格式：
  /// ```json
  /// {
  ///   "success": true,
  ///   "exists": true,
  ///   "status": "ACTIVE" | "DELETED" | "SUSPENDED" | "NOT_FOUND",
  ///   "userId": "string"
  /// }
  /// ```
  Future<Map<String, dynamic>> checkMapUserStatus({
    required String userId,
  }) async {
    print('ApiService: 檢查用戶狀態 - userId: $userId');

    return await _get(
      url: '$_checkMapUserStatusUrl?userId=$userId',
    );
  }
}

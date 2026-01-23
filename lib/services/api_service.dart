import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// 地圖 APP API 服務
///
/// 用於呼叫 safe-net-tw Firebase Cloud Functions (2nd Gen)
class ApiService {
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
      'https://us-central1-safe-net-tw.cloudfunctions.net/updateMapUserAvatar';

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
    final response = await http.post(
      Uri.parse(_mapUserAuthUrl),
      headers: await _getHeaders(),
      body: jsonEncode({
        'action': action,
        'email': email,
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
      }),
    );

    return jsonDecode(response.body);
  }

  /// 更新 FCM Token
  Future<Map<String, dynamic>> updateMapUserFcmToken({
    required String userId,
    required String fcmToken,
  }) async {
    final response = await http.post(
      Uri.parse(_updateMapUserFcmTokenUrl),
      headers: await _getHeaders(),
      body: jsonEncode({'userId': userId, 'fcmToken': fcmToken}),
    );

    return jsonDecode(response.body);
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

    print('ApiService: 綁定設備請求');
    print('  URL: $_bindDeviceToMapUserUrl');
    print('  Body: ${jsonEncode(body)}');

    try {
      final response = await http.post(
        Uri.parse(_bindDeviceToMapUserUrl),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      print('ApiService: 綁定設備回應');
      print('  Status Code: ${response.statusCode}');
      print('  Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // 處理 HTTP 錯誤
        try {
          final errorBody = jsonDecode(response.body);
          return {
            'success': false,
            'error': errorBody['error'] ?? 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        }
      }
    } catch (e) {
      print('ApiService: 綁定設備錯誤 - $e');
      return {
        'success': false,
        'error': '網路錯誤: $e',
      };
    }
  }

  /// 解綁設備
  Future<Map<String, dynamic>> unbindDeviceFromMapUser({
    required String userId,
  }) async {
    print('ApiService: 解綁設備請求');
    print('  URL: $_unbindDeviceFromMapUserUrl');
    print('  Body: ${jsonEncode({'userId': userId})}');

    try {
      final response = await http.post(
        Uri.parse(_unbindDeviceFromMapUserUrl),
        headers: await _getHeaders(),
        body: jsonEncode({'userId': userId}),
      );

      print('ApiService: 解綁設備回應');
      print('  Status Code: ${response.statusCode}');
      print('  Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // 處理 HTTP 錯誤
        try {
          final errorBody = jsonDecode(response.body);
          return {
            'success': false,
            'error': errorBody['error'] ?? 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        }
      }
    } catch (e) {
      print('ApiService: 解綁設備錯誤 - $e');
      return {
        'success': false,
        'error': '網路錯誤: $e',
      };
    }
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

    print('ApiService: 更新設備資訊請求');
    print('  URL: $_updateMapUserDeviceUrl');
    print('  Body: ${jsonEncode(body)}');

    try {
      final response = await http.post(
        Uri.parse(_updateMapUserDeviceUrl),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      print('ApiService: 更新設備資訊回應');
      print('  Status Code: ${response.statusCode}');
      print('  Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          return {
            'success': false,
            'error': errorBody['error'] ?? 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        }
      }
    } catch (e) {
      print('ApiService: 更新設備資訊錯誤 - $e');
      return {
        'success': false,
        'error': '網路錯誤: $e',
      };
    }
  }

  /// 更新用戶頭像
  ///
  /// [userId] - 用戶 ID（必需）
  /// [avatar] - 頭像（必需，可以是檔名如 01.png 或完整 URL）
  Future<Map<String, dynamic>> updateMapUserAvatar({
    required String userId,
    required String avatar,
  }) async {
    final body = <String, dynamic>{
      'userId': userId,
      'avatar': avatar,
    };

    print('ApiService: 更新用戶頭像請求');
    print('  URL: $_updateMapUserAvatarUrl');
    print('  Body: ${jsonEncode(body)}');

    try {
      final response = await http.post(
        Uri.parse(_updateMapUserAvatarUrl),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      print('ApiService: 更新用戶頭像回應');
      print('  Status Code: ${response.statusCode}');
      print('  Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          return {
            'success': false,
            'error': errorBody['error'] ?? 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          };
        }
      }
    } catch (e) {
      print('ApiService: 更新用戶頭像錯誤 - $e');
      return {
        'success': false,
        'error': '網路錯誤: $e',
      };
    }
  }

  /// 取得所有公共接收點
  Future<Map<String, dynamic>> getPublicGateways() async {
    final response = await http.get(
      Uri.parse(_getPublicGatewaysUrl),
      headers: await _getHeaders(requireAuth: false),
    );

    return jsonDecode(response.body);
  }

  /// 新增通知點位
  Future<Map<String, dynamic>> addMapUserNotificationPoint({
    required String userId,
    required String gatewayId,
    required String name,
    required String notificationMessage,
  }) async {
    final response = await http.post(
      Uri.parse(_addMapUserNotificationPointUrl),
      headers: await _getHeaders(),
      body: jsonEncode({
        'userId': userId,
        'gatewayId': gatewayId,
        'name': name,
        'notificationMessage': notificationMessage,
      }),
    );

    return jsonDecode(response.body);
  }

  /// 取得通知點位列表
  Future<Map<String, dynamic>> getMapUserNotificationPoints({
    required String userId,
  }) async {
    final response = await http.get(
      Uri.parse('$_getMapUserNotificationPointsUrl?userId=$userId'),
      headers: await _getHeaders(),
    );

    return jsonDecode(response.body);
  }

  /// 更新通知點位
  Future<Map<String, dynamic>> updateMapUserNotificationPoint({
    required String pointId,
    String? name,
    String? notificationMessage,
    bool? isActive,
  }) async {
    final response = await http.put(
      Uri.parse(_updateMapUserNotificationPointUrl),
      headers: await _getHeaders(),
      body: jsonEncode({
        'pointId': pointId,
        if (name != null) 'name': name,
        if (notificationMessage != null)
          'notificationMessage': notificationMessage,
        if (isActive != null) 'isActive': isActive,
      }),
    );

    return jsonDecode(response.body);
  }

  /// 刪除通知點位
  Future<Map<String, dynamic>> removeMapUserNotificationPoint({
    required String pointId,
  }) async {
    final response = await http.post(
      Uri.parse(_removeMapUserNotificationPointUrl),
      headers: await _getHeaders(),
      body: jsonEncode({'pointId': pointId}),
    );

    return jsonDecode(response.body);
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

    final uri = Uri.parse(
      _getMapUserActivitiesUrl,
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: await _getHeaders());

    return jsonDecode(response.body);
  }

  /// 取得用戶完整資料
  ///
  /// 包含基本資訊、綁定設備、通知點位列表
  /// [userId] - 用戶 ID
  Future<Map<String, dynamic>> getMapUserProfile({
    required String userId,
  }) async {
    final response = await http.get(
      Uri.parse('$_getMapUserProfileUrl?userId=$userId'),
      headers: await _getHeaders(),
    );

    return jsonDecode(response.body);
  }
}

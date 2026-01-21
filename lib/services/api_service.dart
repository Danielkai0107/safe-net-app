import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// 地圖 APP API 服務
/// 
/// 用於呼叫 safe-net-tw Firebase Cloud Functions
class ApiService {
  static const String baseUrl = 'https://us-central1-safe-net-tw.cloudfunctions.net';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 取得當前用戶的 ID Token
  Future<String?> _getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  /// 取得認證 Headers
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

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
      Uri.parse('$baseUrl/mapUserAuth'),
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
      Uri.parse('$baseUrl/updateMapUserFcmToken'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'userId': userId,
        'fcmToken': fcmToken,
      }),
    );

    return jsonDecode(response.body);
  }

  /// 綁定設備
  Future<Map<String, dynamic>> bindDeviceToMapUser({
    required String userId,
    required String deviceId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bindDeviceToMapUser'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'userId': userId,
        'deviceId': deviceId,
      }),
    );

    return jsonDecode(response.body);
  }

  /// 解綁設備
  Future<Map<String, dynamic>> unbindDeviceFromMapUser({
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/unbindDeviceFromMapUser'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'userId': userId,
      }),
    );

    return jsonDecode(response.body);
  }

  /// 取得所有公共接收點
  Future<Map<String, dynamic>> getPublicGateways() async {
    final response = await http.get(
      Uri.parse('$baseUrl/getPublicGateways'),
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
      Uri.parse('$baseUrl/addMapUserNotificationPoint'),
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
      Uri.parse('$baseUrl/getMapUserNotificationPoints?userId=$userId'),
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
      Uri.parse('$baseUrl/updateMapUserNotificationPoint'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'pointId': pointId,
        if (name != null) 'name': name,
        if (notificationMessage != null) 'notificationMessage': notificationMessage,
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
      Uri.parse('$baseUrl/removeMapUserNotificationPoint'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'pointId': pointId,
      }),
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

    final uri = Uri.parse('$baseUrl/getMapUserActivities')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

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
      Uri.parse('$baseUrl/getMapUserProfile?userId=$userId'),
      headers: await _getHeaders(),
    );

    return jsonDecode(response.body);
  }
}

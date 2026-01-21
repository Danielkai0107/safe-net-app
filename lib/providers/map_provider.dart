import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/gateway.dart';
import '../models/notification_point.dart';
import '../models/activity.dart';
import '../services/api_service.dart';

/// 地圖狀態管理
class MapProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 地圖狀態
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(25.0330, 121.5654); // 預設台北 101
  double _zoom = 15.0;

  // 接收點
  List<Gateway> _gateways = [];
  bool _isLoadingGateways = false;

  // 通知點位
  List<NotificationPoint> _notificationPoints = [];
  bool _isLoadingNotificationPoints = false;

  // 活動記錄
  List<Activity> _activities = [];
  bool _isLoadingActivities = false;
  StreamSubscription<QuerySnapshot>? _activitiesSubscription;
  String? _currentUserId;

  String? _error;

  // Getters
  GoogleMapController? get mapController => _mapController;
  LatLng get center => _center;
  double get zoom => _zoom;
  List<Gateway> get gateways => _gateways;
  List<NotificationPoint> get notificationPoints => _notificationPoints;
  List<Activity> get activities => _activities;
  bool get isLoadingGateways => _isLoadingGateways;
  bool get isLoadingNotificationPoints => _isLoadingNotificationPoints;
  bool get isLoadingActivities => _isLoadingActivities;
  String? get error => _error;

  /// 設定地圖控制器
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    notifyListeners();
  }

  /// 更新地圖中心點
  void updateCenter(LatLng newCenter, {double? newZoom}) {
    _center = newCenter;
    if (newZoom != null) _zoom = newZoom;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: newCenter,
          zoom: _zoom,
          tilt: 0, // 鎖定平面視角
        ),
      ),
    );
    notifyListeners();
  }

  /// 載入所有接收點
  Future<void> loadGateways() async {
    _isLoadingGateways = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('開始載入接收點...');
      final result = await _apiService.getPublicGateways();
      debugPrint('API 回應: $result');

      if (result['success'] == true) {
        final gatewaysList = result['gateways'] as List;
        debugPrint('API 回應包含 ${gatewaysList.length} 個接收點');

        _gateways = [];
        for (var json in gatewaysList) {
          try {
            final gateway = Gateway.fromJson(json as Map<String, dynamic>);
            _gateways.add(gateway);
            debugPrint(
              '  ✓ ${gateway.name} at (${gateway.latitude}, ${gateway.longitude})',
            );
          } catch (e) {
            debugPrint('  ✗ 解析接收點失敗: $e');
            debugPrint('    原始資料: $json');
          }
        }

        debugPrint('成功載入 ${_gateways.length} 個接收點');
      } else {
        throw Exception(result['error'] ?? '載入接收點失敗');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('載入接收點失敗: $_error');
    } finally {
      _isLoadingGateways = false;
      notifyListeners();
    }
  }

  /// 載入通知點位列表
  Future<void> loadNotificationPoints(String userId) async {
    _isLoadingNotificationPoints = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('MapProvider: 開始載入通知點位 userId=$userId');
      final result = await _apiService.getMapUserNotificationPoints(
        userId: userId,
      );

      debugPrint('MapProvider: API 回應 = $result');

      if (result['success'] == true) {
        final points = result['notificationPoints'] as List? ?? [];
        debugPrint('MapProvider: 收到 ${points.length} 個通知點位');

        _notificationPoints = points
            .map(
              (json) =>
                  NotificationPoint.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        debugPrint('MapProvider: 成功解析 ${_notificationPoints.length} 個通知點位');
        for (var point in _notificationPoints) {
          debugPrint(
            '  - ${point.name} (gatewayId=${point.gatewayId}, isActive=${point.isActive})',
          );
        }
      } else {
        throw Exception(result['error'] ?? '載入通知點位失敗');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('MapProvider: 載入通知點位失敗 = $_error');
    } finally {
      _isLoadingNotificationPoints = false;
      notifyListeners();
    }
  }

  /// 新增通知點位
  Future<bool> addNotificationPoint({
    required String userId,
    required String gatewayId,
    required String name,
    required String notificationMessage,
  }) async {
    try {
      final result = await _apiService.addMapUserNotificationPoint(
        userId: userId,
        gatewayId: gatewayId,
        name: name,
        notificationMessage: notificationMessage,
      );

      if (result['success'] == true) {
        // 重新載入通知點位列表
        await loadNotificationPoints(userId);
        return true;
      } else {
        _error = result['error'] ?? '新增通知點位失敗';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 移除通知點位
  Future<bool> removeNotificationPoint({
    required String pointId,
    required String userId,
  }) async {
    try {
      final result = await _apiService.removeMapUserNotificationPoint(
        pointId: pointId,
      );

      if (result['success'] == true) {
        // 重新載入通知點位列表
        await loadNotificationPoints(userId);
        return true;
      } else {
        _error = result['error'] ?? '移除通知點位失敗';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 檢查 Gateway 是否已設定通知點位
  bool isGatewayNotified(String gatewayId) {
    return _notificationPoints.any(
      (point) => point.gatewayId == gatewayId && point.isActive,
    );
  }

  /// 取得 Gateway 的通知點位
  NotificationPoint? getNotificationPoint(String gatewayId) {
    try {
      return _notificationPoints.firstWhere(
        (point) => point.gatewayId == gatewayId && point.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  /// 載入活動記錄
  Future<void> loadActivities({
    required String userId,
    int? startTime,
    int? endTime,
    int? limit,
  }) async {
    _isLoadingActivities = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.getMapUserActivities(
        userId: userId,
        startTime: startTime,
        endTime: endTime,
        limit: limit,
      );

      if (result['success'] == true) {
        _activities = (result['activities'] as List)
            .map((json) => Activity.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(result['error'] ?? '載入活動記錄失敗');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingActivities = false;
      notifyListeners();
    }
  }

  /// 開始監聽活動記錄（Firestore 即時更新）
  void startListeningToActivities({required String userId, String? deviceId}) {
    // 如果沒有 deviceId，無法監聽
    if (deviceId == null) {
      debugPrint('MapProvider: 無法監聽活動記錄，deviceId 為 null');
      return;
    }

    // 如果已經在監聽同一個用戶，不需要重複訂閱
    if (_currentUserId == userId && _activitiesSubscription != null) {
      debugPrint('MapProvider: 已在監聽活動記錄 userId=$userId');
      return;
    }

    // 停止舊的監聽
    stopListeningToActivities();

    _currentUserId = userId;
    debugPrint('MapProvider: 開始監聽活動記錄 userId=$userId, deviceId=$deviceId');

    // 監聽 devices/{deviceId}/activities 子集合
    // 查詢最近 100 筆記錄，按時間戳降序排列
    final query = _firestore
        .collection('devices')
        .doc(deviceId)
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(100);

    _activitiesSubscription = query.snapshots().listen(
      (snapshot) {
        debugPrint('MapProvider: 收到活動記錄更新，共 ${snapshot.docs.length} 筆');

        final activities = <Activity>[];
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            // 設定 document ID
            data['id'] = doc.id;
            // 將 Firestore Timestamp 轉換為 ISO 8601 字串
            if (data['timestamp'] is Timestamp) {
              final timestamp = data['timestamp'] as Timestamp;
              data['timestamp'] = timestamp.toDate().toIso8601String();
            }
            activities.add(Activity.fromJson(data));
          } catch (e) {
            debugPrint('MapProvider: 解析活動記錄失敗 - $e');
          }
        }

        _activities = activities;
        _isLoadingActivities = false;
        notifyListeners();

        debugPrint('MapProvider: 活動記錄已更新，共 ${_activities.length} 筆');
      },
      onError: (error) {
        debugPrint('MapProvider: 監聽活動記錄錯誤 - $error');
        _error = error.toString();
        _isLoadingActivities = false;
        notifyListeners();
      },
    );
  }

  /// 停止監聽活動記錄
  void stopListeningToActivities() {
    if (_activitiesSubscription != null) {
      debugPrint('MapProvider: 停止監聽活動記錄');
      _activitiesSubscription?.cancel();
      _activitiesSubscription = null;
      _currentUserId = null;
    }
  }

  /// 清除活動記錄
  void clearActivities() {
    stopListeningToActivities();
    _activities = [];
    notifyListeners();
  }

  /// 清除錯誤
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 重置狀態
  void reset() {
    stopListeningToActivities();
    _gateways = [];
    _notificationPoints = [];
    _activities = [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListeningToActivities();
    super.dispose();
  }
}

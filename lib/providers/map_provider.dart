import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/gateway.dart';
import '../models/notification_point.dart';
import '../models/activity.dart';
import '../services/api_service.dart';

/// 地圖狀態管理
class MapProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

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
        CameraPosition(target: newCenter, zoom: _zoom),
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
      final result = await _apiService.getPublicGateways();
      
      if (result['success'] == true) {
        _gateways = (result['gateways'] as List)
            .map((json) => Gateway.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(result['error'] ?? '載入接收點失敗');
      }
    } catch (e) {
      _error = e.toString();
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
      final result = await _apiService.getMapUserNotificationPoints(
        userId: userId,
      );
      
      if (result['success'] == true) {
        _notificationPoints = (result['notificationPoints'] as List)
            .map((json) => NotificationPoint.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(result['error'] ?? '載入通知點位失敗');
      }
    } catch (e) {
      _error = e.toString();
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
    return _notificationPoints.any((point) => 
      point.gatewayId == gatewayId && point.isActive
    );
  }

  /// 取得 Gateway 的通知點位
  NotificationPoint? getNotificationPoint(String gatewayId) {
    try {
      return _notificationPoints.firstWhere(
        (point) => point.gatewayId == gatewayId && point.isActive
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

  /// 清除錯誤
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 重置狀態
  void reset() {
    _gateways = [];
    _notificationPoints = [];
    _activities = [];
    _error = null;
    notifyListeners();
  }
}

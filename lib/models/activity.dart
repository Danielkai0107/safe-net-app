/// 活動記錄模型
class Activity {
  final String id;
  final String deviceId;
  final String gatewayId;
  final String gatewayName;
  final String? gatewayType; // "GENERAL", "BOUNDARY", "MOBILE"
  final String gatewayLocation;
  final DateTime timestamp;
  final int rssi;
  final double latitude;
  final double longitude;
  final String? bindingType; // "ELDER", "MAP_USER", "UNBOUND"
  final String? boundTo; // 綁定對象 ID
  final bool triggeredNotification;
  final String? notificationType; // "LINE", "FCM", null
  final Map<String, dynamic>? notificationDetails; // 通知詳細資訊

  Activity({
    required this.id,
    required this.deviceId,
    required this.gatewayId,
    required this.gatewayName,
    this.gatewayType,
    required this.gatewayLocation,
    required this.timestamp,
    required this.rssi,
    required this.latitude,
    required this.longitude,
    this.bindingType,
    this.boundTo,
    required this.triggeredNotification,
    this.notificationType,
    this.notificationDetails,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: (json['id'] ?? '') as String,
      deviceId: (json['deviceId'] ?? '') as String,
      gatewayId: (json['gatewayId'] ?? '') as String,
      gatewayName: (json['gatewayName'] ?? 'Unknown') as String,
      gatewayType: json['gatewayType'] as String?,
      gatewayLocation: (json['gatewayLocation'] ?? '') as String,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      rssi: (json['rssi'] ?? 0) as int,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : 0.0,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : 0.0,
      bindingType: json['bindingType'] as String?,
      boundTo: json['boundTo'] as String?,
      triggeredNotification: json['triggeredNotification'] as bool? ?? false,
      notificationType: json['notificationType'] as String?,
      notificationDetails: json['notificationDetails'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'gatewayId': gatewayId,
      'gatewayName': gatewayName,
      if (gatewayType != null) 'gatewayType': gatewayType,
      'gatewayLocation': gatewayLocation,
      'timestamp': timestamp.toIso8601String(),
      'rssi': rssi,
      'latitude': latitude,
      'longitude': longitude,
      if (bindingType != null) 'bindingType': bindingType,
      if (boundTo != null) 'boundTo': boundTo,
      'triggeredNotification': triggeredNotification,
      if (notificationType != null) 'notificationType': notificationType,
      if (notificationDetails != null) 'notificationDetails': notificationDetails,
    };
  }

  /// 取得通知點位 ID (從 notificationDetails 中取得)
  String? get notificationPointId {
    if (notificationDetails == null) return null;
    return notificationDetails!['pointId'] as String?;
  }

  /// 取得通知點位名稱 (從 notificationDetails 中取得)
  String? get notificationPointName {
    if (notificationDetails == null) return null;
    return notificationDetails!['pointName'] as String?;
  }

  @override
  String toString() {
    return 'Activity(id: $id, gatewayName: $gatewayName, timestamp: $timestamp)';
  }
}

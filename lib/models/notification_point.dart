import 'gateway.dart';

/// 通知點位模型
class NotificationPoint {
  final String id;
  final String mapAppUserId;
  final String gatewayId;
  final String name;
  final String notificationMessage;
  final bool isActive;
  final DateTime createdAt;
  final Gateway? gateway; // 關聯的 Gateway 資訊

  NotificationPoint({
    required this.id,
    required this.mapAppUserId,
    required this.gatewayId,
    required this.name,
    required this.notificationMessage,
    required this.isActive,
    required this.createdAt,
    this.gateway,
  });

  factory NotificationPoint.fromJson(Map<String, dynamic> json) {
    return NotificationPoint(
      id: (json['id'] ?? '') as String,
      mapAppUserId: (json['mapAppUserId'] ?? '') as String,
      gatewayId: (json['gatewayId'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      notificationMessage: (json['notificationMessage'] ?? '') as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      gateway: json['gateway'] != null
          ? Gateway.fromJson(json['gateway'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mapAppUserId': mapAppUserId,
      'gatewayId': gatewayId,
      'name': name,
      'notificationMessage': notificationMessage,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      if (gateway != null) 'gateway': gateway!.toJson(),
    };
  }

  @override
  String toString() {
    return 'NotificationPoint(id: $id, name: $name, gatewayId: $gatewayId)';
  }
}

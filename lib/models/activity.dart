/// 活動記錄模型
class Activity {
  final String id;
  final String deviceId;
  final String gatewayId;
  final String gatewayName;
  final String gatewayLocation;
  final DateTime timestamp;
  final int rssi;
  final double latitude;
  final double longitude;
  final bool triggeredNotification;
  final String? notificationPointId;

  Activity({
    required this.id,
    required this.deviceId,
    required this.gatewayId,
    required this.gatewayName,
    required this.gatewayLocation,
    required this.timestamp,
    required this.rssi,
    required this.latitude,
    required this.longitude,
    required this.triggeredNotification,
    this.notificationPointId,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      gatewayId: json['gatewayId'] as String,
      gatewayName: json['gatewayName'] as String,
      gatewayLocation: json['gatewayLocation'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      rssi: json['rssi'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      triggeredNotification: json['triggeredNotification'] as bool? ?? false,
      notificationPointId: json['notificationPointId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'gatewayId': gatewayId,
      'gatewayName': gatewayName,
      'gatewayLocation': gatewayLocation,
      'timestamp': timestamp.toIso8601String(),
      'rssi': rssi,
      'latitude': latitude,
      'longitude': longitude,
      'triggeredNotification': triggeredNotification,
      if (notificationPointId != null) 'notificationPointId': notificationPointId,
    };
  }

  @override
  String toString() {
    return 'Activity(id: $id, gatewayName: $gatewayName, timestamp: $timestamp)';
  }
}

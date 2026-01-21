import 'device.dart';
import 'notification_point.dart';

/// 用戶資料模型
class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatar;
  final bool notificationEnabled;
  final Device? boundDevice;
  final List<NotificationPoint> notificationPoints;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatar,
    required this.notificationEnabled,
    this.boundDevice,
    this.notificationPoints = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      name: (json['name'] ?? 'Unknown') as String,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      boundDevice: json['boundDevice'] != null
          ? Device.fromJson(json['boundDevice'] as Map<String, dynamic>)
          : null,
      notificationPoints: json['notificationPoints'] != null
          ? (json['notificationPoints'] as List)
              .map((item) => NotificationPoint.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (phone != null) 'phone': phone,
      if (avatar != null) 'avatar': avatar,
      'notificationEnabled': notificationEnabled,
      if (boundDevice != null) 'boundDevice': boundDevice!.toJson(),
      'notificationPoints': notificationPoints.map((e) => e.toJson()).toList(),
    };
  }

  /// 是否已綁定設備
  bool get hasDevice => boundDevice != null;

  /// 取得通知點位數量
  int get notificationPointCount => notificationPoints.length;

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, email: $email, hasDevice: $hasDevice)';
  }
}

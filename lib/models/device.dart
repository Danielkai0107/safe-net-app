/// 設備模型
class Device {
  final String id;
  final String uuid;
  final int major;
  final int minor;
  final String deviceName;
  final String? nickname; // 設備暱稱（用戶自訂）
  final int? age; // 使用者年齡（用戶自訂）
  final String? gender; // 性別（MALE | FEMALE | OTHER）
  final DateTime? boundAt; // 綁定時間
  final int? batteryLevel; // 電池電量 (0-100)
  final String? avatar; // 頭像檔名（預設：01.png）

  Device({
    required this.id,
    required this.uuid,
    required this.major,
    required this.minor,
    required this.deviceName,
    this.nickname,
    this.age,
    this.gender,
    this.boundAt,
    this.batteryLevel,
    this.avatar,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: (json['id'] ?? '') as String,
      uuid: (json['uuid'] ?? '') as String,
      major: (json['major'] ?? 0) as int,
      minor: (json['minor'] ?? 0) as int,
      deviceName: (json['deviceName'] ?? 'Unknown Device') as String,
      nickname: json['nickname'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      boundAt: json['boundAt'] != null
          ? DateTime.parse(json['boundAt'] as String)
          : null,
      batteryLevel: json['batteryLevel'] as int?,
      avatar: json['avatar'] as String? ?? '01.png',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'major': major,
      'minor': minor,
      'deviceName': deviceName,
      if (nickname != null) 'nickname': nickname,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (boundAt != null) 'boundAt': boundAt!.toIso8601String(),
      if (batteryLevel != null) 'batteryLevel': batteryLevel,
      if (avatar != null) 'avatar': avatar,
    };
  }

  /// 取得顯示名稱（優先使用暱稱，否則使用設備名稱）
  String get displayName => nickname ?? deviceName;

  @override
  String toString() {
    return 'Device(id: $id, displayName: $displayName, deviceName: $deviceName)';
  }
}

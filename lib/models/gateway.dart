/// 守望點類型
class GatewayType {
  static const String schoolZone = 'SCHOOL_ZONE'; // 學校守望點 - 可新增通知點位
  static const String safeZone = 'SAFE_ZONE'; // 可通知守望點 - 可新增通知點位
  static const String observeZone = 'OBSERVE_ZONE'; // 僅紀錄守望點 - 不可新增通知點位
  static const String inactive = 'INACTIVE'; // 準備中 - 不可新增通知點位

  /// 檢查是否可新增通知點位
  static bool canAddNotification(String type) {
    return type == schoolZone || type == safeZone;
  }

  /// 取得標籤文字
  static String getLabel(String type) {
    switch (type) {
      case schoolZone:
        return '學校守望點';
      case safeZone:
        return '可通知守望點';
      case observeZone:
        return '僅紀錄守望點';
      case inactive:
        return '準備中';
      default:
        return '守望點';
    }
  }

  /// 取得描述文字
  static String getDescription(String type) {
    switch (type) {
      case schoolZone:
        return '位置記錄和通知';
      case safeZone:
        return '位置記錄和通知';
      case observeZone:
        return '僅記錄位置';
      case inactive:
        return '準備中';
      default:
        return '';
    }
  }
}

/// 守望點模型
class Gateway {
  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final String type; // "SCHOOL_ZONE", "SAFE_ZONE", "OBSERVE_ZONE", or "INACTIVE"
  final String serialNumber;
  final String? tenantId;

  /// 是否可新增通知點位
  bool get canAddNotification => GatewayType.canAddNotification(type);

  /// 取得類型標籤
  String get typeLabel => GatewayType.getLabel(type);

  /// 取得類型描述
  String get typeDescription => GatewayType.getDescription(type);

  Gateway({
    required this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.serialNumber,
    this.tenantId,
  });

  factory Gateway.fromJson(Map<String, dynamic> json) {
    // 處理座標可能是字串或數字的情況
    double parseCoordinate(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value) ?? 0.0;
      } else {
        return 0.0;
      }
    }

    return Gateway(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? 'Unknown Gateway') as String,
      location: (json['location'] ?? '') as String,
      latitude: parseCoordinate(json['latitude']),
      longitude: parseCoordinate(json['longitude']),
      type: (json['type'] ?? GatewayType.safeZone) as String,
      serialNumber: (json['serialNumber'] ?? '') as String,
      tenantId: json['tenantId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'serialNumber': serialNumber,
      if (tenantId != null) 'tenantId': tenantId,
    };
  }

  @override
  String toString() {
    return 'Gateway(id: $id, name: $name, location: $location)';
  }
}

/// 接收點模型
class Gateway {
  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final String type; // "GENERAL", "BOUNDARY", or "MOBILE"
  final String serialNumber;
  final String? tenantId;

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
      type: (json['type'] ?? 'GENERAL') as String,
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

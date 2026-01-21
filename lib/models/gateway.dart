/// 接收點模型
class Gateway {
  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final String type; // "GENERAL" or "BOUNDARY"
  final String serialNumber;
  final String? tenantId;
  final String poolType; // "PUBLIC" or "TENANT"

  Gateway({
    required this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.serialNumber,
    this.tenantId,
    required this.poolType,
  });

  factory Gateway.fromJson(Map<String, dynamic> json) {
    return Gateway(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      type: json['type'] as String,
      serialNumber: json['serialNumber'] as String,
      tenantId: json['tenantId'] as String?,
      poolType: json['poolType'] as String,
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
      'tenantId': tenantId,
      'poolType': poolType,
    };
  }

  @override
  String toString() {
    return 'Gateway(id: $id, name: $name, location: $location)';
  }
}

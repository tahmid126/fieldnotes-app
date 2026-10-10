class SiteModel {
  final String id;
  final String name;
  final String address;
  final String customerId;
  final String? customerName;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  SiteModel({
    required this.id,
    required this.name,
    required this.address,
    required this.customerId,
    this.customerName,
    this.deleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  factory SiteModel.fromMap(Map<String, dynamic> map) {
    return SiteModel(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      customerId: map['customer_id'] as String,
      customerName: map['customer_name'] as String?,
      deleted: (map['deleted'] == 1 || map['deleted'] == true),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] == 1 || map['is_synced'] == true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'customer_id': customerId,
      'customer_name': customerName,
      'deleted': deleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String?,
      deleted: json['deleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSynced: true,
    );
  }

  Map<String, dynamic> toSyncJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'customerId': customerId,
      'deleted': deleted,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SiteModel copyWith({
    String? id,
    String? name,
    String? address,
    String? customerId,
    String? customerName,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return SiteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

class CustomerModel {
  final String id;
  final String name;
  final String? contactInformation;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  CustomerModel({
    required this.id,
    required this.name,
    this.contactInformation,
    this.deleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      contactInformation: map['contact_information'] as String?,
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
      'contact_information': contactInformation,
      'deleted': deleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      contactInformation: json['contactInformation'] as String?,
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
      'contactInformation': contactInformation,
      'deleted': deleted,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? contactInformation,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contactInformation: contactInformation ?? this.contactInformation,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

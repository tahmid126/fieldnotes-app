class FieldNoteModel {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime noteDateTime;
  final String status;
  final String? photoUrl;
  final String siteId;
  final String? siteName;
  final String? customerId;
  final String? customerName;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  FieldNoteModel({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.latitude,
    this.longitude,
    required this.noteDateTime,
    required this.status,
    this.photoUrl,
    required this.siteId,
    this.siteName,
    this.customerId,
    this.customerName,
    this.deleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  factory FieldNoteModel.fromMap(Map<String, dynamic> map) {
    return FieldNoteModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      location: map['location'] as String?,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      noteDateTime: DateTime.parse(map['note_date_time'] as String),
      status: map['status'] as String,
      photoUrl: map['photo_url'] as String?,
      siteId: map['site_id'] as String,
      siteName: map['site_name'] as String?,
      customerId: map['customer_id'] as String?,
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
      'title': title,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'note_date_time': noteDateTime.toIso8601String(),
      'status': status,
      'photo_url': photoUrl,
      'site_id': siteId,
      'site_name': siteName,
      'customer_id': customerId,
      'customer_name': customerName,
      'deleted': deleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory FieldNoteModel.fromJson(Map<String, dynamic> json) {
    return FieldNoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      noteDateTime: DateTime.parse(json['noteDateTime'] as String),
      status: json['status'] as String,
      photoUrl: json['photoUrl'] as String?,
      siteId: json['siteId'] as String,
      siteName: json['siteName'] as String?,
      customerId: json['customerId'] as String?,
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
      'title': title,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'noteDateTime': noteDateTime.toIso8601String(),
      'status': status,
      'photoUrl': photoUrl,
      'siteId': siteId,
      'deleted': deleted,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FieldNoteModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? noteDateTime,
    String? status,
    String? photoUrl,
    String? siteId,
    String? siteName,
    String? customerId,
    String? customerName,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return FieldNoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      noteDateTime: noteDateTime ?? this.noteDateTime,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

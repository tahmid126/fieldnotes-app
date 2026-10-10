import 'package:flutter/material.dart';

class AppConstants {
  // 192.168.10.99 is the computer's LAN IP for physical Android device connectivity
  static const String defaultBaseUrl = 'http://192.168.10.99:8080/api';
  static const String localhostBaseUrl = 'http://localhost:8080/api';
  static const String windowsBaseUrl = 'http://localhost:8080/api';

  static const List<String> noteStatuses = [
    'DRAFT',
    'IN_PROGRESS',
    'COMPLETED',
  ];

  static const String defaultNoteStatusKey = 'default_note_status';
  static const String authTokenKey = 'auth_token';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';
  static const String userIdKey = 'user_id';
  static const String lastSyncKey = 'last_sync_timestamp';

  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'DRAFT':
      default:
        return Colors.blueGrey;
    }
  }
}

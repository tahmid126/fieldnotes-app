import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/customer_model.dart';
import '../models/field_note_model.dart';
import '../models/site_model.dart';
import 'api_service.dart';
import 'database_service.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  final DatabaseService _db = DatabaseService.instance;
  final ApiService _api = ApiService.instance;

  String? lastSyncError;
  bool isLastSyncOffline = false;

  bool isOfflineException(dynamic e) {
    final msg = e.toString().toLowerCase();
    return e is SocketException ||
        e is http.ClientException ||
        e is TimeoutException ||
        msg.contains('connection refused') ||
        msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection timed out') ||
        msg.contains('errno = 111') ||
        msg.contains('clientexception') ||
        msg.contains('handshakeexception');
  }

  Future<bool> performSync() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.authTokenKey);
    if (token == null || token.isEmpty) {
      lastSyncError = 'Not logged in. Please log in first.';
      isLastSyncOffline = false;
      return false;
    }

    try {
      final lastSyncStr = prefs.getString(AppConstants.lastSyncKey);
      final lastSyncTimestamp = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;

      final unsyncedCustomers = await _db.getUnsyncedCustomers();
      final unsyncedSites = await _db.getUnsyncedSites();
      final unsyncedNotes = await _db.getUnsyncedNotes();

      final response = await _api.syncWithServer(
        token: token,
        lastSyncTimestamp: lastSyncTimestamp,
        unsyncedCustomers: unsyncedCustomers,
        unsyncedSites: unsyncedSites,
        unsyncedNotes: unsyncedNotes,
      );

      final serverTimestampStr = response['serverTimestamp'] as String;
      final serverCustomers = (response['customers'] as List? ?? [])
          .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final serverSites = (response['sites'] as List? ?? [])
          .map((e) => SiteModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final serverNotes = (response['notes'] as List? ?? [])
          .map((e) => FieldNoteModel.fromJson(e as Map<String, dynamic>))
          .toList();

      await _db.batchSaveServerData(
        customers: serverCustomers,
        sites: serverSites,
        notes: serverNotes,
      );

      await prefs.setString(AppConstants.lastSyncKey, serverTimestampStr);
      lastSyncError = null;
      isLastSyncOffline = false;
      return true;
    } catch (e) {
      if (isOfflineException(e)) {
        isLastSyncOffline = true;
        lastSyncError = 'Offline mode: Changes saved locally. Will sync automatically when connected.';
      } else {
        isLastSyncOffline = false;
        lastSyncError = e.toString().replaceAll('Exception: ', '');
      }
      return false;
    }
  }

  Future<bool> restoreAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.authTokenKey);
    if (token == null || token.isEmpty) return false;

    try {
      final response = await _api.restoreAllData(token);
      final serverTimestampStr = response['serverTimestamp'] as String;

      final serverCustomers = (response['customers'] as List? ?? [])
          .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final serverSites = (response['sites'] as List? ?? [])
          .map((e) => SiteModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final serverNotes = (response['notes'] as List? ?? [])
          .map((e) => FieldNoteModel.fromJson(e as Map<String, dynamic>))
          .toList();

      await _db.clearAll();
      await _db.batchSaveServerData(
        customers: serverCustomers,
        sites: serverSites,
        notes: serverNotes,
      );

      await prefs.setString(AppConstants.lastSyncKey, serverTimestampStr);
      lastSyncError = null;
      isLastSyncOffline = false;
      return true;
    } catch (e) {
      if (isOfflineException(e)) {
        isLastSyncOffline = true;
        lastSyncError = 'Offline mode: Server unreachable. Connect online to restore data.';
      } else {
        isLastSyncOffline = false;
        lastSyncError = e.toString().replaceAll('Exception: ', '');
      }
      return false;
    }
  }
}

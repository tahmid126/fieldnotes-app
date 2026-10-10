import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/customer_model.dart';
import '../models/field_note_model.dart';
import '../models/site_model.dart';
import '../models/user_model.dart';

class ApiService {
  static final ApiService instance = ApiService._init();
  ApiService._init();

  String? _cachedWorkingBaseUrl;

  Future<String> getBaseUrl({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString('custom_server_url')?.trim();

    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      if (customUrl != null && customUrl.isNotEmpty) return customUrl;
      return AppConstants.localhostBaseUrl;
    }

    // If user explicitly configured a custom non-localhost IP/domain, use it directly
    if (customUrl != null &&
        customUrl.isNotEmpty &&
        !customUrl.contains('localhost') &&
        !customUrl.contains('127.0.0.1')) {
      return customUrl;
    }

    if (!forceRefresh && _cachedWorkingBaseUrl != null) {
      return _cachedWorkingBaseUrl!;
    }

    // On Android/iOS: Dynamically probe whether USB or Wi-Fi is reachable right now
    // 1. Probe USB (localhost via adb reverse) with a fast 400ms timeout
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.localhostBaseUrl}/auth/ping'))
          .timeout(const Duration(milliseconds: 400));
      if (res.statusCode == 200 || res.statusCode == 401 || res.statusCode == 404) {
        _cachedWorkingBaseUrl = AppConstants.localhostBaseUrl;
        return AppConstants.localhostBaseUrl;
      }
    } catch (_) {}

    // 2. Probe Wi-Fi LAN IP (192.168.10.99:8080) with a fast 700ms timeout
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.defaultBaseUrl}/auth/ping'))
          .timeout(const Duration(milliseconds: 700));
      if (res.statusCode == 200 || res.statusCode == 401 || res.statusCode == 404) {
        _cachedWorkingBaseUrl = AppConstants.defaultBaseUrl;
        return AppConstants.defaultBaseUrl;
      }
    } catch (_) {}

    // 3. Fallback: if user specified localhost, return it; otherwise return default LAN URL
    if (customUrl != null && customUrl.isNotEmpty) {
      return customUrl;
    }
    return AppConstants.defaultBaseUrl;
  }

  void resetCachedBaseUrl() {
    _cachedWorkingBaseUrl = null;
  }

  Map<String, dynamic> _safeJsonDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {'message': body.isNotEmpty ? body : 'Server returned empty response'};
    }
  }

  Future<UserModel> register(String name, String email, String password) async {
    final baseUrl = await getBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 12));

      final data = _safeJsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to register (${response.statusCode})');
      }
    } catch (e) {
      resetCachedBaseUrl();
      rethrow;
    }
  }

  Future<UserModel> login(String email, String password) async {
    final baseUrl = await getBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 12));

      final data = _safeJsonDecode(response.body);
      if (response.statusCode == 200) {
        return UserModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to login (${response.statusCode})');
      }
    } catch (e) {
      resetCachedBaseUrl();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> testConnection() async {
    final baseUrl = await getBaseUrl(forceRefresh: true);
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/auth/ping'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final mode = baseUrl.contains('localhost') ? 'USB (localhost)' : 'Wi-Fi LAN';
        return {'success': true, 'url': baseUrl, 'message': 'Online ($mode)'};
      }
      return {'success': false, 'url': baseUrl, 'message': 'HTTP ${res.statusCode}'};
    } catch (e) {
      resetCachedBaseUrl();
      return {'success': false, 'url': baseUrl, 'message': 'Offline: Server unreachable'};
    }
  }

  Future<Map<String, dynamic>> syncWithServer({
    required String token,
    required DateTime? lastSyncTimestamp,
    required List<CustomerModel> unsyncedCustomers,
    required List<SiteModel> unsyncedSites,
    required List<FieldNoteModel> unsyncedNotes,
  }) async {
    String baseUrl = await getBaseUrl();
    final body = {
      'lastSyncTimestamp': lastSyncTimestamp?.toIso8601String(),
      'customers': unsyncedCustomers.map((c) => c.toSyncJson()).toList(),
      'sites': unsyncedSites.map((s) => s.toSyncJson()).toList(),
      'notes': unsyncedNotes.map((n) => n.toSyncJson()).toList(),
    };

    try {
      return await _executeSyncRequest(baseUrl, token, body);
    } catch (e) {
      resetCachedBaseUrl();
      // If localhost failed (e.g. USB cable disconnected), transparently try Wi-Fi fallback
      if (baseUrl.contains('localhost') && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          final fallbackUrl = AppConstants.defaultBaseUrl;
          final result = await _executeSyncRequest(fallbackUrl, token, body);
          _cachedWorkingBaseUrl = fallbackUrl;
          return result;
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _executeSyncRequest(
    String baseUrl,
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/sync'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    final data = _safeJsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      _cachedWorkingBaseUrl = baseUrl;
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Failed to sync with backend');
    }
  }

  Future<Map<String, dynamic>> restoreAllData(String token) async {
    String baseUrl = await getBaseUrl();
    try {
      return await _executeRestoreRequest(baseUrl, token);
    } catch (e) {
      resetCachedBaseUrl();
      if (baseUrl.contains('localhost') && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          final fallbackUrl = AppConstants.defaultBaseUrl;
          final result = await _executeRestoreRequest(fallbackUrl, token);
          _cachedWorkingBaseUrl = fallbackUrl;
          return result;
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _executeRestoreRequest(String baseUrl, String token) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/sync/restore'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    final data = _safeJsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      _cachedWorkingBaseUrl = baseUrl;
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Failed to restore data from server');
    }
  }

  Future<String> uploadPhoto(File file, String token) async {
    final baseUrl = await getBaseUrl();
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final data = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data']['url'] as String;
      } else {
        throw Exception(data['message'] ?? 'Failed to upload photo');
      }
    } catch (e) {
      resetCachedBaseUrl();
      rethrow;
    }
  }
}

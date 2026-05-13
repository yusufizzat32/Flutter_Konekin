// lib/services/auth_service.dart
// =============================================================================
// AUTH SERVICE - Single Source of Truth untuk autentikasi
// =============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Sesuaikan dengan IP/Localhost Anda
  // Emulator Android: 10.0.2.2
  // Real device: IP komputer di jaringan yang sama
  // Chrome web: localhost
  static const String baseUrl = 'http://localhost:8000/api';
  
  // Keys SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _userTypeKey = 'user_type';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';
  
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  // ───────────────────────────────────────────────────────────────────────────
  // TOKEN MANAGEMENT
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    // Pastikan formatnya konsisten: selalu dengan 'Bearer '
    String finalToken = token.trim();
    if (!finalToken.startsWith('Bearer ')) {
      finalToken = 'Bearer $finalToken';
    }
    await prefs.setString(_tokenKey, finalToken);
  }
  
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
  
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty && token != 'Bearer ';
  }
  
  // ───────────────────────────────────────────────────────────────────────────
  // TOKEN VALIDATION & REFRESH (FIX REFRESH ISSUE)
  // ───────────────────────────────────────────────────────────────────────────
  
  /// Cek validitas token ke server
  Future<bool> validateToken() async {
    final token = await getToken();
    if (token == null) return false;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'), // Endpoint yang butuh auth
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
      
      // 200 = token masih valid, 401 = token expired
      return response.statusCode == 200;
    } catch (e) {
      // Jika gagal konek, asumsikan token masih valid? Tidak, lebih aman false
      // Tapi kita coba refresh dulu
      final refreshResult = await refreshToken();
      return refreshResult['success'] == true;
    }
  }
  
  /// Refresh token ke server
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final oldToken = await getToken();
      if (oldToken == null) {
        return {'success': false, 'message': 'No token to refresh'};
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/refresh-token'),
        headers: {
          'Authorization': oldToken,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        final newToken = data['data']['token'];
        await setToken(newToken);
        return {'success': true, 'token': newToken};
      }
      return {'success': false, 'message': data['message'] ?? 'Refresh failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // ───────────────────────────────────────────────────────────────────────────
  // USER DATA MANAGEMENT
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
    await prefs.setString(_userTypeKey, userData['type'] ?? '');
    await prefs.setString(_userNameKey, userData['name'] ?? '');
    await prefs.setString(_userEmailKey, userData['email'] ?? '');
    await prefs.setString(_userIdKey, (userData['id'] ?? '').toString());
  }
  
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }
  
  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }
  
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }
  
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }
  
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
  
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userIdKey);
  }
  
  // ───────────────────────────────────────────────────────────────────────────
  // LOGIN / REGISTER / LOGOUT
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      
      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        final token = data['data']['token'];
        final userData = data['data']['user'];
        await setToken(token);
        await saveUserData(userData);
        return {
          'success': true,
          'message': data['message'] ?? 'Login berhasil',
          'userType': userData['type'],
          'userData': userData,
        };
      }
      
      String errorMessage = data['message'] ?? 'Login gagal';
      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstError = errors[errors.keys.first];
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first;
          }
        }
      }
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': _handleErrorMessage(e)};
    }
  }
  
  Future<Map<String, dynamic>> register({
    required String type,
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String city,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'type': type,
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'phone': phone,
          'city': city,
        }),
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      
      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        final token = data['data']['token'];
        final userData = data['data']['user'];
        await setToken(token);
        await saveUserData(userData);
        return {
          'success': true,
          'message': data['message'] ?? 'Registrasi berhasil',
          'userType': userData['type'],
          'userData': userData,
        };
      }
      
      String errorMessage = data['message'] ?? 'Registrasi gagal';
      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstError = errors[errors.keys.first];
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first;
          }
        }
      }
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': _handleErrorMessage(e)};
    }
  }
  
  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {'Authorization': token, 'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 30));
      }
    } catch (e) {
      // ignore error
    } finally {
      await clearToken();
      await clearUserData();
    }
    return {'success': true, 'message': 'Logout berhasil'};
  }
  
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not logged in'};
      
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {'Authorization': token, 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final userData = data['data']['user'] ?? data['data'];
        await saveUserData(userData);
        return {'success': true, 'data': userData};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to get profile'};
    } catch (e) {
      return {'success': false, 'message': _handleErrorMessage(e)};
    }
  }
  
  String _handleErrorMessage(dynamic e) {
    if (e.toString().contains('SocketException')) {
      return 'Tidak ada koneksi internet. Periksa koneksi Anda.';
    } else if (e.toString().contains('TimeoutException')) {
      return 'Koneksi timeout. Silakan coba lagi.';
    } else if (e.toString().contains('Connection refused')) {
      return 'Tidak dapat terhubung ke server. Periksa URL API.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
// lib/services/auth_service.dart
// =============================================================================
// AUTH SERVICE - Reusable authentication logic untuk seluruh aplikasi
// =============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000/api'; // Ganti dengan URL API Anda
  
  // Keys untuk SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _userTypeKey = 'user_type';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  // ───────────────────────────────────────────────────────────────────────────
  // TOKEN MANAGEMENT
  // ───────────────────────────────────────────────────────────────────────────
  
  /// Mendapatkan token yang tersimpan
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  /// Menyimpan token setelah login/register
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  /// Menghapus token (logout)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
  
  /// Mengecek apakah user sudah login (token ada)
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  // ───────────────────────────────────────────────────────────────────────────
  // USER DATA MANAGEMENT
  // ───────────────────────────────────────────────────────────────────────────
  
  /// Menyimpan data user setelah login/register
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
    await prefs.setString(_userTypeKey, userData['type'] ?? '');
    await prefs.setString(_userNameKey, userData['name'] ?? '');
    await prefs.setString(_userEmailKey, userData['email'] ?? '');
    await prefs.setString(_userIdKey, userData['id'] ?? '');
  }
  
  /// Mendapatkan seluruh data user
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }
  
  /// Mendapatkan tipe user (umkm / creative_worker / admin)
  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }
  
  /// Mendapatkan nama user
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }
  
  /// Mendapatkan email user
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }
  
  /// Mendapatkan ID user
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
  
  /// Menghapus semua data user (logout)
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userIdKey);
  }
  
  // ───────────────────────────────────────────────────────────────────────────
  // API CALLS
  // ───────────────────────────────────────────────────────────────────────────
  
  /// Headers untuk request yang memerlukan autentikasi
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': token ?? '', // Format: "bearer eyJ0eXAiOi..."
    };
  }
  
  /// Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true && responseData['data'] != null) {
          final userData = responseData['data']['user'];
          final token = responseData['data']['token'];
          final tokenType = responseData['data']['token_type']; // "bearer"
          
          // Simpan token dan data user
          await setToken('$tokenType $token');
          await saveUserData(userData);
          
          return {
            'success': true,
            'message': responseData['message'] ?? 'Login berhasil',
            'userType': userData['type'],
            'userData': userData,
          };
        }
      }
      
      String errorMessage = responseData['message'] ?? 'Login gagal';
      if (responseData['errors'] != null && responseData['errors'] is Map) {
        final errors = responseData['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstErrorValue = errors[errors.keys.first];
          if (firstErrorValue is List && firstErrorValue.isNotEmpty) {
            errorMessage = firstErrorValue.first;
          }
        }
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': _handleErrorMessage(e),
      };
    }
  }
  
  /// Register user
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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true && responseData['data'] != null) {
          final userData = responseData['data']['user'];
          final token = responseData['data']['token'];
          final tokenType = responseData['data']['token_type'];
          
          // Simpan token dan data user (langsung login setelah register)
          await setToken('$tokenType $token');
          await saveUserData(userData);
          
          return {
            'success': true,
            'message': responseData['message'] ?? 'Registrasi berhasil',
            'userType': userData['type'],
            'userData': userData,
          };
        }
      }
      
      String errorMessage = responseData['message'] ?? 'Registrasi gagal';
      if (responseData['errors'] != null && responseData['errors'] is Map) {
        final errors = responseData['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstErrorValue = errors[errors.keys.first];
          if (firstErrorValue is List && firstErrorValue.isNotEmpty) {
            errorMessage = firstErrorValue.first;
          }
        }
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': _handleErrorMessage(e),
      };
    }
  }
  
  /// Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      final headers = await getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      // Tetap hapus data lokal meskipun API error
      await clearToken();
      await clearUserData();
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Logout berhasil',
        };
      }
      
      return {
        'success': true,
        'message': 'Logout berhasil',
      };
    } catch (e) {
      // Tetap hapus data lokal meskipun API error
      await clearToken();
      await clearUserData();
      
      return {
        'success': true,
        'message': 'Logout berhasil',
      };
    }
  }
  
  /// Get user profile dari API (untuk refresh data)
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (responseData['success'] == true && responseData['data'] != null) {
          final userData = responseData['data']['user'];
          await saveUserData(userData);
          
          return {
            'success': true,
            'data': userData,
          };
        }
      }
      
      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal mengambil profil',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _handleErrorMessage(e),
      };
    }
  }
  
  // ───────────────────────────────────────────────────────────────────────────
  // HELPER
  // ───────────────────────────────────────────────────────────────────────────
  
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
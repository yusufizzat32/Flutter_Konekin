
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  static const String _tokenKey = 'auth_token';
  
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ───────────────────────────────────────────────────────────────────────────
  // TOKEN MANAGEMENT
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
  
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': token ?? '',
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // AUTH ENDPOINTS
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['token'];
        await setToken(token);
        return {'success': true, 'data': data['data'], 'message': data['message']};
      }
      
      return {'success': false, 'message': data['message'] ?? 'Login gagal'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }
  
  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      
      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        final token = data['data']['token'];
        await setToken(token);
        return {'success': true, 'data': data['data'], 'message': data['message']};
      }
      
      String errorMsg = data['message'] ?? 'Registrasi gagal';
      if (data['errors'] != null) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          errorMsg = errors.values.first.first;
        }
      }
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }
  
  Future<Map<String, dynamic>> logout() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      await clearToken();
      final data = jsonDecode(response.body);
      return {'success': true, 'message': data['message'] ?? 'Logout berhasil'};
    } catch (e) {
      await clearToken();
      return {'success': true, 'message': 'Logout berhasil'};
    }
  }
  
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal mengambil profile'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }
  
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> payload) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/profile/update'),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data'], 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal update profile'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DASHBOARD ENDPOINTS
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<Map<String, dynamic>> getCreativeDashboard() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/creative/dashboard'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal mengambil data dashboard'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }
  
  Future<Map<String, dynamic>> getUMKMDashboard() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/umkm/dashboard'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal mengambil data dashboard'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PROJECTS ENDPOINTS
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<Map<String, dynamic>> getProjects({String? category, String? search}) async {
    try {
      final headers = await getAuthHeaders();
      String url = '$baseUrl/projects';
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      
      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal mengambil proyek'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }
  
  Future<Map<String, dynamic>> getProjectDetail(int projectId) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/projects/$projectId'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal mengambil detail proyek'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }
  
  Future<Map<String, dynamic>> applyToProject(int projectId, {String? coverLetter}) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/apply'),
        headers: headers,
        body: jsonEncode({'cover_letter': coverLetter ?? ''}),
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Berhasil melamar'};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal melamar'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }
  
  Future<Map<String, dynamic>> getCreativeProjects() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/creative/projects'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal mengambil proyek'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }
  
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> payload) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/umkm/projects'),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data'], 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal membuat proyek'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PORTFOLIO ENDPOINTS
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<Map<String, dynamic>> getPortfolios() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/portfolios'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal mengambil portfolio'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }
  
  Future<Map<String, dynamic>> createPortfolio(Map<String, dynamic> payload) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/portfolios'),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data'], 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal menambah portfolio'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }
  
  Future<Map<String, dynamic>> deletePortfolio(int portfolioId) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/portfolios/$portfolioId'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Berhasil menghapus'};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal menghapus'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ONBOARDING
  // ───────────────────────────────────────────────────────────────────────────
  
  Future<Map<String, dynamic>> creativeOnboarding(Map<String, dynamic> payload) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/creative/onboarding'),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal menyimpan onboarding'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HELPER
  // ───────────────────────────────────────────────────────────────────────────
  
  String _handleError(dynamic e) {
    if (e.toString().contains('SocketException')) {
      return 'Tidak ada koneksi internet';
    } else if (e.toString().contains('TimeoutException')) {
      return 'Koneksi timeout. Silakan coba lagi';
    } else if (e.toString().contains('Connection refused')) {
      return 'Tidak dapat terhubung ke server';
    }
    return 'Terjadi kesalahan. Silakan coba lagi';
  }
}
// lib/services/profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ProfileService {
  final AuthService _authService = AuthService();
  
  // Base headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': token ?? '',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }
  
  // Get profile data
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        final userData = data['data']['user'] ?? data['data'];
        await _authService.saveUserData(userData);
        return {
          'success': true,
          'data': userData,
        };
      }
      
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mengambil profil',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _handleErrorMessage(e),
      };
    }
  }
  
  // Update profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? city,
    String? bio,
    String? creativeCategory,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final Map<String, dynamic> body = {};
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (address != null && address.isNotEmpty) body['address'] = address;
      if (city != null && city.isNotEmpty) body['city'] = city;
      if (bio != null && bio.isNotEmpty) body['bio'] = bio;
      if (creativeCategory != null && creativeCategory.isNotEmpty) {
        body['creative_category'] = creativeCategory;
      }
      if (bankName != null && bankName.isNotEmpty) body['bank_name'] = bankName;
      if (bankAccountNumber != null && bankAccountNumber.isNotEmpty) {
        body['bank_account_number'] = bankAccountNumber;
      }
      if (bankAccountName != null && bankAccountName.isNotEmpty) {
        body['bank_account_name'] = bankAccountName;
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileUpdate}'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        // Refresh user data after update
        final userData = data['data']['user'] ?? data['data'];
        await _authService.saveUserData(userData);
        
        return {
          'success': true,
          'message': data['message'] ?? 'Profil berhasil diperbarui',
          'data': userData,
        };
      }
      
      String errorMessage = data['message'] ?? 'Gagal memperbarui profil';
      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstError = errors[errors.keys.first];
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first;
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
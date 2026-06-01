// lib/services/project_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/projectcr_model.dart';
import 'auth_service.dart'; // ← IMPORT AuthService

class ProjectService {
  final AuthService _auth = AuthService(); // ← Gunakan instance yang benar

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Authorization': token,
      };

  // ── GET /api/projects ──────────────────────────
  Future<Map<String, dynamic>> getProjects({
    String? category,
    String? search,
    int page = 1,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Tidak terautentikasi'};
      }

      final params = <String, String>{'page': page.toString()};
      if (category != null && category.isNotEmpty && category != 'Semua') {
        params['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.projects}')
          .replace(queryParameters: params);
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        List<Project> projects = [];
        if (json['data'] is List) {
          projects = (json['data'] as List)
              .map((e) => Project.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        return {
          'success': true,
          'projects': projects,
          'current_page': json['current_page'] ?? 1,
          'last_page': json['last_page'] ?? 1,
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Sesi habis, silakan login ulang'};
      } else {
        final json = jsonDecode(response.body);
        return {
          'success': false,
          'message': json['message'] ?? 'Gagal memuat proyek',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi gagal: ${e.toString()}',
      };
    }
  }

  // ── GET /api/projects/{id} ─────────────────────
  Future<Map<String, dynamic>> getProjectDetail(String id) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Tidak terautentikasi'};
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.projectDetail(id)}');
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final projectJson = json['data'] as Map<String, dynamic>;
        return {
          'success': true,
          'project': Project.fromJson(projectJson),
        };
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Proyek tidak ditemukan'};
      } else {
        final json = jsonDecode(response.body);
        return {
          'success': false,
          'message': json['message'] ?? 'Gagal memuat detail proyek',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi gagal: ${e.toString()}',
      };
    }
  }

  // ── POST /api/projects/{id}/apply ──────────────
  Future<Map<String, dynamic>> applyToProject(
    String projectId, {
    required String message,
    required File proposalFile,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Tidak terautentikasi'};
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.applyToProject(projectId)}');
      
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_headers(token));
      request.fields['message'] = message;
      request.files.add(
        await http.MultipartFile.fromPath('proposal_file', proposalFile.path),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': json['message'] ?? 'Berhasil melamar proyek',
        };
      } else if (response.statusCode == 422) {
        return {
          'success': false,
          'message': json['message'] ?? 'Data tidak valid. Pastikan pesan minimal 20 karakter dan file proposal sesuai format.',
          'errors': json['errors'],
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': json['message'] ?? 'Gagal melamar. Mungkin proyek sudah memiliki creative worker terpilih.',
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': json['message'] ?? 'Hanya creative worker yang dapat melamar.',
        };
      } else {
        return {
          'success': false,
          'message': json['message'] ?? 'Gagal melamar proyek',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi gagal: ${e.toString()}',
      };
    }
  }
}
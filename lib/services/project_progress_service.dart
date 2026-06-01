// lib/services/project_progress_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/project_progress_model.dart';
import '../services/auth_service.dart';

class ProjectProgressService {
  final AuthService _auth = AuthService();
  
  Future<Map<String, dynamic>> getCreativeProjects() async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.creativeProjects}'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> projectsData = data['data'];
        final projects = projectsData.map((json) => ProjectProgressModel.fromJson(json)).toList();
        return {
          'success': true,
          'projects': projects,
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to load projects'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  Future<Map<String, dynamic>> updateProgress({
    required String projectId,
    required int progressPercentage,
    required String note,
    File? mediaFile,
  }) async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.creativeProjectProgress(projectId)}');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = token;
      request.fields['progress_percentage'] = progressPercentage.toString();
      request.fields['note'] = note;

      if (mediaFile != null) {
        final fileStream = http.MultipartFile.fromPath('progress_media', mediaFile.path);
        request.files.add(await fileStream);
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Progress updated'};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to update progress'};
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  String _handleError(dynamic e) {
    if (e.toString().contains('SocketException')) {
      return 'Tidak ada koneksi internet';
    } else if (e.toString().contains('TimeoutException')) {
      return 'Koneksi timeout';
    }
    return e.toString();
  }
}
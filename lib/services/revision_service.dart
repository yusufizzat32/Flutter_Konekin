// lib/services/revision_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class RevisionService {
  final AuthService _auth = AuthService();

  Future<Map<String, dynamic>> requestRevision({
    required String projectId,
    required String reason,
    String? feedback,
    DateTime? deadline,
  }) async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final body = {
        'reason': reason,
        if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
        if (deadline != null) 'deadline': deadline.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/umkm/projects/$projectId/request-revision'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Revision requested successfully',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to request revision',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
      };
    }
  }

  Future<Map<String, dynamic>> getRevisions(String projectId) async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/creative/projects/$projectId/revisions'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get revisions',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
      };
    }
  }

  Future<Map<String, dynamic>> submitRevision({
    required String projectId,
    required String note,
    File? mediaFile,
    int? progressPercentage,
  }) async {
    try {
      final token = await _auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/creative/projects/$projectId/submit-revision');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = token;
      request.fields['note'] = note;

      if (progressPercentage != null) {
        request.fields['progress_percentage'] = progressPercentage.toString();
      }

      if (mediaFile != null) {
        final fileStream = http.MultipartFile.fromPath('media', mediaFile.path);
        request.files.add(await fileStream);
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Revision submitted successfully',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to submit revision',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _handleError(e),
      };
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
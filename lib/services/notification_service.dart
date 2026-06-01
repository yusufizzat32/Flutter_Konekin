// lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class NotificationService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse(ApiConfig.getFullUrl(ApiConfig.notifications)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
         
    print('📡 Response status: ${response.statusCode}');
    print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'notifications': (data['data'] as List)
              .map((n) => NotificationModel.fromJson(n))
              .toList(),
          'unreadCount': data['unread_count'],
        };
      }
      return {'success': false, 'message': 'Gagal mengambil notifikasi'};
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get unread count only (lebih ringan)
  Future<int> getUnreadCount() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse(ApiConfig.getFullUrl(ApiConfig.notificationsUnreadCount)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse(ApiConfig.getFullUrl(ApiConfig.notificationRead(notificationId))),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse(ApiConfig.getFullUrl(ApiConfig.notificationsReadAll)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse(ApiConfig.getFullUrl(ApiConfig.notificationDelete(notificationId))),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Delete all read notifications
  Future<int> deleteAllReadNotifications() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return 0;

      final response = await http.delete(
        Uri.parse(ApiConfig.getFullUrl(ApiConfig.notificationsReadAllRead)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);
      return data['deleted_count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
// lib/providers/notification_provider.dart
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isInitialized = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasUnread => _unreadCount > 0;

  Future<void> loadNotifications({bool forceRefresh = false}) async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    final result = await _service.getNotifications();
    
    if (result['success']) {
      _notifications = result['notifications'];
      _unreadCount = result['unreadCount'];
      _isInitialized = true;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Load hanya unread count (lebih ringan untuk periodic refresh)
  Future<void> refreshUnreadCount() async {
    final count = await _service.getUnreadCount();
    if (_unreadCount != count) {
      _unreadCount = count;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final success = await _service.markAsRead(id);
    
    if (success) {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          data: _notifications[index].data,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    final success = await _service.markAllAsRead();
    
    if (success) {
      _notifications = _notifications.map((n) => 
        NotificationModel(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
        )
      ).toList();
      _unreadCount = 0;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    final success = await _service.deleteNotification(id);
    
    if (success) {
      final wasUnread = _notifications.firstWhere((n) => n.id == id).isRead == false;
      _notifications.removeWhere((n) => n.id == id);
      if (wasUnread && _unreadCount > 0) {
        _unreadCount--;
      }
      notifyListeners();
    }
  }

  // Delete all read notifications
  Future<void> deleteAllRead() async {
    final deletedCount = await _service.deleteAllReadNotifications();
    if (deletedCount > 0) {
      _notifications.removeWhere((n) => n.isRead);
      notifyListeners();
    }
  }

  // Periodic refresh every 30 seconds (hanya update count, tidak full load)
  void startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (_isInitialized) {
        refreshUnreadCount();
        startPeriodicRefresh();
      }
    });
  }
}
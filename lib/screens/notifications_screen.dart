// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B1B1F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1B1F),
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.notifications.isNotEmpty && !provider.isLoading) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
                  onSelected: (value) async {
                    if (value == 'mark_all_read') {
                      await provider.markAllAsRead();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Semua notifikasi ditandai sudah dibaca'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else if (value == 'delete_all_read') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Hapus Notifikasi'),
                          content: const Text('Hapus semua notifikasi yang sudah dibaca?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await provider.deleteAllRead();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifikasi yang sudah dibaca dihapus'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    if (provider.unreadCount > 0)
                      const PopupMenuItem<String>(
                        value: 'mark_all_read',
                        child: Row(
                          children: [
                            Icon(Icons.done_all_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Tandai semua sudah dibaca'),
                          ],
                        ),
                      ),
                    const PopupMenuItem<String>(
                      value: 'delete_all_read',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Hapus notifikasi yang sudah dibaca'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.notifications.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            color: const Color(0xFF003466),
            onRefresh: () => provider.loadNotifications(),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _buildNotificationItem(context, notification, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF0),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada notifikasi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi akan muncul disini saat ada aktivitas',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, 
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (direction) {
        provider.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifikasi dihapus')),
        );
      },
      child: GestureDetector(
        onTap: () => _onNotificationTap(context, notification, provider),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : const Color(0xFFE8F4FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead ? const Color(0xFFE8ECF0) : const Color(0xFF7AB3E8),
              width: notification.isRead ? 1 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getIconColor(notification.type).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getIcon(notification.type),
                  color: _getIconColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: const Color(0xFF1B1B1F),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      // Creative Worker notifications
      case 'project_application_approved':
        return Icons.check_circle_rounded;
      case 'escrow_payment_received':
        return Icons.payment_rounded;
      case 'payment_approved_to_creative':
        return Icons.verified_rounded;
      case 'payment_rejected_to_creative':
        return Icons.cancel_rounded;
      case 'escrow_funds_released':
        return Icons.account_balance_wallet_rounded;
      
      // UMKM notifications
      case 'payment_invoice_created':
        return Icons.receipt_rounded;
      case 'payment_approved':
        return Icons.verified_rounded;
      case 'payment_rejected':
        return Icons.cancel_rounded;
      case 'payment_verified':
        return Icons.check_circle_outline_rounded;
      case 'escrow_payment_successful':
        return Icons.verified_rounded;
      
      // Admin notifications
      case 'payment_proof_submitted':
        return Icons.upload_file_rounded;
      
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'project_application_approved':
      case 'escrow_payment_successful':
      case 'payment_verified':
      case 'payment_approved':
      case 'payment_approved_to_creative':
        return const Color(0xFF20C997);
      case 'escrow_payment_received':
        return const Color(0xFF3B82F6);
      case 'payment_rejected':
      case 'payment_rejected_to_creative':
        return const Color(0xFFEF4444);
      case 'escrow_funds_released':
        return const Color(0xFFF59E0B);
      case 'payment_invoice_created':
        return const Color(0xFF8B5CF6);
      case 'payment_proof_submitted':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF003466);
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  void _onNotificationTap(
    BuildContext context, 
    NotificationModel notification,
    NotificationProvider provider,
  ) async {
    if (!notification.isRead) {
      await provider.markAsRead(notification.id);
    }
    
    // Navigasi berdasarkan tipe notifikasi
    final projectId = notification.data['project_id'];
    final projectTitle = notification.data['project_title'];
    
    switch (notification.type) {
      // Creative Worker
      case 'project_application_approved':
        if (projectId != null) {
          Navigator.pushNamed(context, '/project-detail', arguments: projectId);
        }
        break;
      case 'escrow_payment_received':
      case 'payment_approved_to_creative':
        Navigator.pushNamed(context, '/creative/my-projects');
        break;
      case 'escrow_funds_released':
        Navigator.pushNamed(context, '/creative/earnings');
        break;
      case 'payment_rejected_to_creative':
        Navigator.pushNamed(context, '/creative/my-projects');
        break;
      
      // UMKM
      case 'payment_invoice_created':
        Navigator.pushNamed(context, '/umkm/my-projects');
        break;
      case 'payment_approved':
      case 'escrow_payment_successful':
        Navigator.pushNamed(context, '/umkm/my-projects');
        break;
      case 'payment_rejected':
        Navigator.pushNamed(context, '/umkm/my-projects');
        break;
      case 'payment_verified':
        Navigator.pushNamed(context, '/umkm/my-projects');
        break;
      
      default:
        // Default action
        if (projectId != null) {
          Navigator.pushNamed(context, '/project-detail', arguments: projectId);
        }
    }
  }
}
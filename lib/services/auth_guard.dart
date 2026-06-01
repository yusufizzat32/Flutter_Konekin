// lib/services/auth_guard.dart
// =============================================================================
// AUTH GUARD - Untuk melindungi route yang memerlukan login
// =============================================================================

import 'package:flutter/material.dart';
import 'auth_service.dart';

class AuthGuard {
  final AuthService _auth = AuthService();
  
  /// Cek apakah user sudah login, jika belum redirect ke login
  Future<bool> isAuthenticated(BuildContext context) async {
    final isLoggedIn = await _auth.isLoggedIn();
    
    if (!isLoggedIn) {
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return false;
    }
    return true;
  }
  
  /// Cek apakah user memiliki role yang diizinkan
  Future<bool> hasRole(BuildContext context, List<String> allowedRoles) async {
    final isLoggedIn = await isAuthenticated(context);
    if (!isLoggedIn) return false;
    
    final userType = await _auth.getUserType();
    
    if (userType == null || !allowedRoles.contains(userType)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda tidak memiliki akses ke halaman ini'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
      return false;
    }
    return true;
  }
}
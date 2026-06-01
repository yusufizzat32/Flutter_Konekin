// lib/config/api_config.dart
// ============================================================================
// API CONFIGURATION - Centralized API URLs and endpoints
// ============================================================================

import 'dart:io';

class ApiConfig {
  // Private constructor to prevent instantiation
  ApiConfig._();
  
  // --------------------------------------------------------------------------
  // BASE URL CONFIGURATION
  // --------------------------------------------------------------------------
  
  /// Base URL untuk Laravel API (Backend utama)
  static String get baseUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api'; // Android Emulator
      }
    } catch (_) {}
    return 'http://localhost:8000/api'; // Web / Desktop / Real Device
  }
  
  /// Base URL untuk Flask ML Service (AI Recommendation)
  static String get flaskBaseUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000'; // Android Emulator
      }
    } catch (_) {}
    return 'http://localhost:5000'; // Web / Desktop / Real Device
  }
  
  // --------------------------------------------------------------------------
  // AUTH ENDPOINTS
  // --------------------------------------------------------------------------
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String refreshToken = '/refresh-token';
  static const String user = '/user';
  static const String profile = '/profile';
  static const String profileUpdate = '/profile/update';
  
  // --------------------------------------------------------------------------
  // DASHBOARD ENDPOINTS
  // --------------------------------------------------------------------------
  static const String umkmDashboard = '/umkm/dashboard';
  static const String creativeDashboard = '/creative/dashboard';
  
  // --------------------------------------------------------------------------
  // PROJECTS ENDPOINTS (UMKM)
  // --------------------------------------------------------------------------
  static const String umkmProjects = '/umkm/projects';
  static const String umkmProjectsProgress = '/umkm/projects/progress';
  
  /// Get project applications: /umkm/projects/{projectId}/applications
  static String umkmProjectApplications(String projectId) => 
      '/umkm/projects/$projectId/applications';
  
  /// Approve application: /umkm/projects/{projectId}/approve/{applicationId}
  static String umkmApproveApplication(String projectId, String applicationId) => 
      '/umkm/projects/$projectId/approve/$applicationId';
  
  /// Create payment invoice: /umkm/projects/{projectId}/create-payment
  static String createPaymentInvoice(String projectId) => 
      '/umkm/projects/$projectId/create-payment';
  
  /// Upload payment proof: /umkm/projects/{projectId}/upload-payment-proof
  static String uploadPaymentProof(String projectId) => 
      '/umkm/projects/$projectId/upload-payment-proof';
  
  /// Check payment status: /umkm/projects/{projectId}/check-payment-status
  static String checkPaymentStatus(String projectId) => 
      '/umkm/projects/$projectId/check-payment-status';
  
  /// Get payment detail: /umkm/payments/{paymentId}
  static String paymentDetail(String paymentId) => 
      '/umkm/payments/$paymentId';
  
  /// Approve completion: /umkm/projects/{projectId}/approve-completion
  static String umkmApproveCompletion(String projectId) => 
      '/umkm/projects/$projectId/approve-completion';
  
  /// Complete project (fallback): /umkm/projects/{projectId}/complete
  static String umkmCompleteProject(String projectId) => 
      '/umkm/projects/$projectId/complete';
  
  /// Delete project: /umkm/projects/{projectId}
  static String umkmDeleteProject(String projectId) => 
      '/umkm/projects/$projectId';
  
  // --------------------------------------------------------------------------
  // PROJECTS ENDPOINTS (CREATIVE)
  // --------------------------------------------------------------------------
  static const String projects = '/projects';
  
  /// Project detail: /projects/{projectId}
  static String projectDetail(String projectId) => '/projects/$projectId';
  
  /// Apply to project: /projects/{projectId}/apply
  static String applyToProject(String projectId) => '/projects/$projectId/apply';
  
  static const String creativeProjects = '/creative/projects';
  
  /// Update project progress: /creative/projects/{projectId}/progress
  static String creativeProjectProgress(String projectId) => 
      '/creative/projects/$projectId/progress';
  
  // --------------------------------------------------------------------------
  // CREATIVES / PORTFOLIO ENDPOINTS
  // --------------------------------------------------------------------------
  static const String creatives = '/creatives';
  
  /// Creative detail: /creatives/{creativeId}
  static String creativeDetail(String creativeId) => '/creatives/$creativeId';
  
  static const String portfolios = '/portfolios';
  
  /// Delete portfolio: /portfolios/{portfolioId}
  static String deletePortfolio(int portfolioId) => '/portfolios/$portfolioId';
  
  // --------------------------------------------------------------------------
  // RATINGS ENDPOINTS
  // --------------------------------------------------------------------------
  static const String umkmRatings = '/umkm/ratings';
  
  // --------------------------------------------------------------------------
  // NOTIFICATIONS ENDPOINTS
  // --------------------------------------------------------------------------
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread/count';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String notificationsReadAllRead = '/notifications/read/all';
  
  /// Get notifications by type: /notifications/type/{type}
  static String notificationsByType(String type) => '/notifications/type/$type';
  
  /// Mark notification as read: /notifications/{id}/read
  static String notificationRead(String notificationId) => 
      '/notifications/$notificationId/read';
  
  /// Delete notification: /notifications/{id}
  static String notificationDelete(String notificationId) => 
      '/notifications/$notificationId';
  
  // --------------------------------------------------------------------------
  // ESCROW ENDPOINTS
  // --------------------------------------------------------------------------
  static const String creativeEscrow = '/creative/escrow';
  static const String creativeEarnings = '/creative/earnings';
  
  /// Release funds: /admin/escrow/{escrowId}/release
  static String releaseFunds(String escrowId) => '/admin/escrow/$escrowId/release';
  
  // --------------------------------------------------------------------------
  // AI RECOMMENDATION ENDPOINTS
  // --------------------------------------------------------------------------
  static const String recommendations = '/v1/recommendations';
  static const String rekomendasiAi = '/rekomendasi-ai';
  
  // --------------------------------------------------------------------------
  // FLASK ML SERVICE ENDPOINTS
  // --------------------------------------------------------------------------
  static const String flaskHealth = '/health';
  static const String flaskStatus = '/status';
  static const String flaskRoot = '/';
  
  // --------------------------------------------------------------------------
  // HELPER METHODS
  // --------------------------------------------------------------------------
  
  /// Get full API URL for a specific endpoint
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  /// Get full Flask URL for a specific endpoint
  static String getFlaskFullUrl(String endpoint) {
    return '$flaskBaseUrl$endpoint';
  }
  
  /// List of Flask endpoints to check for health status
  static List<String> get flaskHealthEndpoints => [
    flaskHealth,
    flaskStatus,
    flaskRoot,
  ];
  
  // --------------------------------------------------------------------------
  // GEOCODING (External API)
  // --------------------------------------------------------------------------
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String nominatimSearch = '/search';
  
  static String getNominatimFullUrl(String endpoint) {
    return '$nominatimBaseUrl$endpoint';
  }
}
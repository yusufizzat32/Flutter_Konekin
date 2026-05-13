// lib/models/dashboard_model.dart
class CreativeDashboardData {
  final int totalEarnings;
  final int ongoingProjects;
  final int completedProjects;
  final int canceledProjects;
  final int profileViews;
  final int newConnections;
  final double rating;
  final Map<String, double> topCategories;

  CreativeDashboardData({
    this.totalEarnings = 0,
    this.ongoingProjects = 0,
    this.completedProjects = 0,
    this.canceledProjects = 0,
    this.profileViews = 0,
    this.newConnections = 0,
    this.rating = 0.0,
    this.topCategories = const {},
  });

  factory CreativeDashboardData.fromJson(Map<String, dynamic> json) {
    // api_service sudah unwrap data['data'], jadi json bisa berisi:
    // { user, stats, latest_projects } atau langsung stats di root json
    final stats = json['stats'] ?? json['statistics'] ?? json;

    return CreativeDashboardData(
      totalEarnings: _parseInt(stats['total_earnings']),
      ongoingProjects: _parseInt(stats['active_projects'] ?? stats['ongoing_projects']),
      completedProjects: _parseInt(stats['completed_projects']),
      canceledProjects: _parseInt(stats['canceled_projects']),
      profileViews: _parseInt(stats['profile_views']),
      newConnections: _parseInt(stats['new_connections']),
      rating: _parseDouble(stats['average_rating'] ?? stats['rating']),
      topCategories: Map<String, double>.from(stats['top_categories'] ?? {}),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class UMKMKDashboardData {
  final int totalProjects;
  final int activeProjects;
  final int totalSpend;
  final int totalApplicants;
  final double rating;

  UMKMKDashboardData({
    this.totalProjects = 0,
    this.activeProjects = 0,
    this.totalSpend = 0,
    this.totalApplicants = 0,
    this.rating = 0.0,
  });

  // Getter kompatibilitas
  int get completedProjects => totalProjects;

  factory UMKMKDashboardData.fromJson(Map<String, dynamic> json) {
    // api_service sudah unwrap data['data'], jadi json bisa berupa:
    // { user, stats, ... } atau { total_projects, ... } langsung (fallback)
    final stats = json['stats'] ?? json['statistics'] ?? json;

    return UMKMKDashboardData(
      totalProjects: _parseInt(stats['total_projects']),
      activeProjects: _parseInt(stats['projects_in_progress'] ?? stats['active_projects']),
      totalSpend: _parseInt(stats['total_spend']),
      totalApplicants: _parseInt(stats['total_applications'] ?? stats['total_applicants']),
      rating: _parseDouble(stats['rating'] ?? stats['average_rating']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
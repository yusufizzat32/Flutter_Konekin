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
    final data = json['data'] ?? json;
    final stats = data['statistics'] ?? data;
    
    return CreativeDashboardData(
      totalEarnings: stats['total_earnings'] ?? 0,
      ongoingProjects: stats['ongoing_projects'] ?? 0,
      completedProjects: stats['completed_projects'] ?? 0,
      canceledProjects: stats['canceled_projects'] ?? 0,
      profileViews: stats['profile_views'] ?? 0,
      newConnections: stats['new_connections'] ?? 0,
      rating: (stats['rating'] ?? 0).toDouble(),
      topCategories: Map<String, double>.from(stats['top_categories'] ?? {}),
    );
  }
}

class UMKMKDashboardData {
  final int activeProjects;
  final int totalSpend;
  final int totalApplicants;
  final int completedProjects;
  final double rating;

  UMKMKDashboardData({
    this.activeProjects = 0,
    this.totalSpend = 0,
    this.totalApplicants = 0,
    this.completedProjects = 0,
    this.rating = 0.0,
  });

  factory UMKMKDashboardData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final stats = data['statistics'] ?? data;
    
    return UMKMKDashboardData(
      activeProjects: stats['active_projects'] ?? 0,
      totalSpend: stats['total_spend'] ?? 0,
      totalApplicants: stats['total_applicants'] ?? 0,
      completedProjects: stats['completed_projects'] ?? 0,
      rating: (stats['rating'] ?? 0).toDouble(),
    );
  }
}
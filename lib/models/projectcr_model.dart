// lib/models/projectcr_model.dart

class Project {
  final String id;
  final String title;
  final String description;
  final String category;
  final String budget;
  final String deadline;
  final String clientId;
  final String clientName;
  final String clientAvatar;
  final String status;
  final String? requirements;
  final String? thumbnail;
  final String? mediaUrl;
  final String? mediaType;
  final int progressPercentage;
  final int applicationsCount;
  final String? statusLabel;
  final String? progressSummary;
  final DateTime? createdAt;
  final String? selectedCreativeId;

  const Project({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    required this.deadline,
    required this.clientId,
    required this.clientName,
    required this.clientAvatar,
    required this.status,
    this.requirements,
    this.thumbnail,
    this.mediaUrl,
    this.mediaType,
    this.progressPercentage = 0,
    this.applicationsCount = 0,
    this.statusLabel,
    this.progressSummary,
    this.createdAt,
    this.selectedCreativeId,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      budget: json['budget']?.toString() ?? '0',
      deadline: json['deadline']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      clientName: json['client_name'] ?? '',
      clientAvatar: json['client_avatar'] ?? '',
      status: json['status'] ?? '',
      requirements: json['requirements'],
      thumbnail: json['thumbnail'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      progressPercentage: json['progress_percentage'] ?? 0,
      applicationsCount: json['applications_count'] ?? 0,
      statusLabel: json['status_label'],
      progressSummary: json['progress_summary'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      selectedCreativeId: json['selected_creative_id']?.toString(),
    );
  }

  // ─────────────────────────────────────────────
  // COMPUTED PROPERTIES (GETTERS)
  // ─────────────────────────────────────────────

  /// Format budget ke Rupiah, misal "3500000" → "Rp 3.5JT"
  String get formattedBudget {
    final amount = double.tryParse(budget) ?? 0;
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      final formatted = millions == millions.truncateToDouble()
          ? millions.toInt().toString()
          : millions.toStringAsFixed(1);
      return 'Rp $formatted JT';
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      final formatted = thousands == thousands.truncateToDouble()
          ? thousands.toInt().toString()
          : thousands.toStringAsFixed(0);
      return 'Rp $formatted RB';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  /// Format deadline ke "X hari lagi" atau "Lewat deadline"
  String get deadlineLabel {
    if (deadline.isEmpty) return '';
    final date = DateTime.tryParse(deadline);
    if (date == null) return '';
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff < 0) return 'Lewat deadline';
    if (diff == 0) return 'Hari ini';
    return '$diff hari lagi';
  }

  /// Apakah user sudah apply ke proyek ini?
  /// NOTE: Ini hanya perkiraan. Sebaiknya cek dari response terpisah.
  bool get isApplied => status == 'applied';

  /// Apakah proyek masih open (belum dipilih creative worker)?
  bool get isOpen => status == 'open' && selectedCreativeId == null;
}

// ─────────────────────────────────────────────
// RESPONSE WRAPPER UNTUK PAGINATION
// ─────────────────────────────────────────────
class ProjectListResponse {
  final List<Project> projects;
  final int? total;
  final int? currentPage;
  final int? lastPage;

  const ProjectListResponse({
    required this.projects,
    this.total,
    this.currentPage,
    this.lastPage,
  });

  factory ProjectListResponse.fromJson(Map<String, dynamic> json) {
    List<Project> projects = [];

    if (json['data'] is List) {
      projects = (json['data'] as List)
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json is Map && json.containsKey('id')) {
      projects = [Project.fromJson(json)];
    }

    return ProjectListResponse(
      projects: projects,
      total: json['total'],
      currentPage: json['current_page'],
      lastPage: json['last_page'],
    );
  }
}

// ─────────────────────────────────────────────
// APPLY RESULT MODEL
// ─────────────────────────────────────────────
class ApplyResult {
  final bool success;
  final String message;

  const ApplyResult({required this.success, required this.message});

  factory ApplyResult.fromJson(Map<String, dynamic> json) {
    return ApplyResult(
      success: json['success'] == true || json['status'] == 'success',
      message: json['message'] ?? '',
    );
  }
}
// lib/models/project_model.dart
class Project {
  final int id;
  final String title;
  final String description;
  final String budget;
  final String duration;
  final String status;
  final String category;
  final List<String> skills;
  final String? thumbnail;
  final int? umkmId;
  final String? umkmName;
  final String? umkmCity;
  final DateTime createdAt;
  final DateTime? deadline;
  final int? applicantCount;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    required this.duration,
    required this.status,
    required this.category,
    required this.skills,
    this.thumbnail,
    this.umkmId,
    this.umkmName,
    this.umkmCity,
    required this.createdAt,
    this.deadline,
    this.applicantCount,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Handle various response structures
    final data = json['data'] ?? json;
    final project = data['project'] ?? data;
    
    return Project(
      id: project['id'] ?? 0,
      title: project['title'] ?? '',
      description: project['description'] ?? '',
      budget: project['budget']?.toString() ?? '0',
      duration: project['duration'] ?? '',
      status: project['status'] ?? 'open',
      category: project['category'] ?? 'General',
      skills: (project['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      thumbnail: project['thumbnail'],
      umkmId: project['umkm_id'],
      umkmName: project['umkm_name'],
      umkmCity: project['umkm_city'],
      createdAt: DateTime.tryParse(project['created_at'] ?? '') ?? DateTime.now(),
      deadline: project['deadline'] != null ? DateTime.tryParse(project['deadline']) : null,
      applicantCount: project['applicant_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'budget': budget,
      'duration': duration,
      'status': status,
      'category': category,
      'skills': skills,
      'thumbnail': thumbnail,
      'umkm_id': umkmId,
      'umkm_name': umkmName,
      'umkm_city': umkmCity,
      'created_at': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'applicant_count': applicantCount,
    };
  }
}

class MyProjectProgress {
  final int id;
  final String title;
  final String status;
  final int progress;
  final String? umkmName;
  final String? creativeName;
  final DateTime? startedAt;
  final DateTime? deadline;

  MyProjectProgress({
    required this.id,
    required this.title,
    required this.status,
    required this.progress,
    this.umkmName,
    this.creativeName,
    this.startedAt,
    this.deadline,
  });

  factory MyProjectProgress.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return MyProjectProgress(
      id: data['id'] ?? 0,
      title: data['title'] ?? '',
      status: data['status'] ?? 'pending',
      progress: data['progress'] ?? 0,
      umkmName: data['umkm_name'],
      creativeName: data['creative_name'],
      startedAt: data['started_at'] != null ? DateTime.tryParse(data['started_at']) : null,
      deadline: data['deadline'] != null ? DateTime.tryParse(data['deadline']) : null,
    );
  }
}
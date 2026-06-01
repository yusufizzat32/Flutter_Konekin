// lib/models/project_progress_model.dart
class ProjectProgressModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String budget;
  final DateTime deadline;
  final String clientId;
  final String clientName;
  final String clientAvatar;
  final String status;
  final String? requirements;
  final String? thumbnail;
  final int progressPercentage;
  final int applicationsCount;
  final String statusLabel;
  final String progressSummary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProgressUpdate>? progressUpdates;
  
  // Revision fields
  final int? revisionCount;
  final DateTime? revisionDeadline;
  final String? revisionReason;
  final String? revisionFeedback;
  final DateTime? revisionRequestedAt;
  final DateTime? revisionSubmittedAt;
  final bool isRevisionOverdue;

  ProjectProgressModel.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        description = json['description'] ?? '',
        category = json['category'],
        budget = json['budget'],
        deadline = DateTime.parse(json['deadline']),
        clientId = json['client_id'],
        clientName = json['client_name'],
        clientAvatar = json['client_avatar'] ?? '',
        status = json['status'],
        requirements = json['requirements'],
        thumbnail = json['thumbnail'],
        progressPercentage = json['progress_percentage'] ?? 0,
        applicationsCount = json['applications_count'] ?? 0,
        statusLabel = json['status_label'] ?? '',
        progressSummary = json['progress_summary'] ?? '',
        createdAt = DateTime.parse(json['created_at']),
        updatedAt = DateTime.parse(json['updated_at']),
        progressUpdates = json['progress_updates'] != null
            ? (json['progress_updates'] as List)
                .map((e) => ProgressUpdate.fromJson(e))
                .toList()
            : null,
        revisionCount = json['revision_count'],
        revisionDeadline = json['revision_deadline'] != null 
            ? DateTime.tryParse(json['revision_deadline']) 
            : null,
        revisionReason = json['revision_reason'],
        revisionFeedback = json['revision_feedback'],
        revisionRequestedAt = json['revision_requested_at'] != null 
            ? DateTime.tryParse(json['revision_requested_at']) 
            : null,
        revisionSubmittedAt = json['revision_submitted_at'] != null 
            ? DateTime.tryParse(json['revision_submitted_at']) 
            : null,
        isRevisionOverdue = json['revision_deadline'] != null && 
            DateTime.parse(json['revision_deadline']).isBefore(DateTime.now());

  bool get isActive => status == 'in_progress' || status == 'hired';
  bool get isCompleted => status == 'completed';
  bool get isWaitingPayment => status == 'awaiting_payment' || status == 'ready_for_review';
  String get formattedBudget => 'Rp ${int.tryParse(budget.replaceAll(RegExp(r'[^0-9]'), ''))?.toString() ?? budget}';
  String get deadlineLabel {
    final now = DateTime.now();
    final diff = deadline.difference(now).inDays;
    if (diff < 0) return 'Lewat deadline';
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Besok';
    return '$diff hari lagi';
  }
}

class ProgressUpdate {
  final String id;
  final String note;
  final int percentage;
  final String? mediaUrl;
  final String? mediaType;
  final DateTime createdAt;
  final String creativeName;

  ProgressUpdate.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        note = json['note'],
        percentage = json['percentage'] ?? json['progress_percentage'] ?? 0,
        mediaUrl = json['media_url'],
        mediaType = json['media_type'],
        createdAt = DateTime.parse(json['created_at']),
        creativeName = json['creative_name'] ?? '';
}
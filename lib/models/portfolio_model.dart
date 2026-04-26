// lib/models/portfolio_model.dart
class Portfolio {
  final int id;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime createdAt;

  Portfolio({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final portfolio = data['portfolio'] ?? data;
    
    return Portfolio(
      id: portfolio['id'] ?? 0,
      title: portfolio['title'] ?? '',
      description: portfolio['description'] ?? '',
      category: portfolio['category'] ?? 'General',
      imageUrl: portfolio['image_url'] ?? portfolio['thumbnail'],
      videoUrl: portfolio['video_url'],
      createdAt: DateTime.tryParse(portfolio['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'image_url': imageUrl,
      'video_url': videoUrl,
    };
  }
}
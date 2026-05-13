import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class CreativeDetailPage extends StatefulWidget {
  final String creativeId;
  
  const CreativeDetailPage({super.key, required this.creativeId});

  @override
  State<CreativeDetailPage> createState() => _CreativeDetailPageState();
}

class _CreativeDetailPageState extends State<CreativeDetailPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _creativeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCreativeDetail();
  }

  Future<void> _loadCreativeDetail() async {
    setState(() => _isLoading = true);
    
    final result = await _api.getCreativeDetail(int.tryParse(widget.creativeId) ?? 0);
    
    if (mounted && result['success']) {
      setState(() {
        _creativeData = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          _creativeData?['name'] ?? 'Detail Creative Worker',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A4B84)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _creativeData == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      
                      // Skills
                      _buildSkillsSection(),
                      const SizedBox(height: 24),
                      
                      // Portfolio
                      _buildPortfolioSection(),
                      const SizedBox(height: 24),
                      
                      // Ratings
                      _buildRatingsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    final photo = _creativeData?['profile_photo'] ?? '';
    final name = _creativeData?['name'] ?? '';
    final role = _creativeData?['role'] ?? '';
    final city = _creativeData?['city'] ?? '';
    final rating = _creativeData?['rating'] ?? 0.0;
    final completedProjects = _creativeData?['completed_projects'] ?? 0;
    final bio = _creativeData?['bio'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003466), Color(0xFF1A4B84)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              image: photo.isNotEmpty
                  ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover)
                  : null,
            ),
            child: photo.isEmpty
                ? Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          
          Text(
            role,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.white60),
              const SizedBox(width: 4),
              Text(city, style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
              const SizedBox(width: 16),
              Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Icon(Icons.work, size: 14, color: Colors.white60),
              const SizedBox(width: 4),
              Text(
                '$completedProjects proyek',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
          
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              bio,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    final skills = (_creativeData?['skills'] as List<dynamic>?) ?? [];
    if (skills.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFF1B1B1F),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A4B84).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1A4B84).withOpacity(0.2)),
              ),
              child: Text(
                skill.toString(),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A4B84),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPortfolioSection() {
    final portfolios = (_creativeData?['portfolios'] as List<dynamic>?) ?? [];
    if (portfolios.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portfolio',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFF1B1B1F),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: portfolios.length,
            itemBuilder: (context, index) {
              final portfolio = portfolios[index] as Map<String, dynamic>;
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Container(
                        height: 100,
                        color: const Color(0xFFEAE7ED),
                        child: portfolio['image_url'] != null
                            ? Image.network(portfolio['image_url'], fit: BoxFit.cover, width: double.infinity)
                            : const Center(child: Icon(Icons.image_outlined, color: Color(0xFF424750))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        portfolio['title'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingsSection() {
    final ratings = (_creativeData?['recent_ratings'] as List<dynamic>?) ?? [];
    if (ratings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating & Review',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFF1B1B1F),
          ),
        ),
        const SizedBox(height: 12),
        ...ratings.map((rating) {
          final r = rating as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(5, (i) => Icon(
                      i < (r['rating'] ?? 0) ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    )),
                    const Spacer(),
                    Text(
                      r['from_user_name'] ?? '',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF424750)),
                    ),
                  ],
                ),
                if (r['comment'] != null && r['comment'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    r['comment'],
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF424750)),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
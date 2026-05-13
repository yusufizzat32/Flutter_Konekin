// lib/screens/explore_creatives.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'creative_detail_page.dart';

class ExploreCreativesPage extends StatefulWidget {
  const ExploreCreativesPage({super.key});

  @override
  State<ExploreCreativesPage> createState() => _ExploreCreativesPageState();
}

class _ExploreCreativesPageState extends State<ExploreCreativesPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedCategory = 'Semua';
  List<Map<String, dynamic>> _creatives = [];
  List<Map<String, dynamic>> _recommendedCreatives = [];
  bool _isLoading = true;
  bool _isSearching = false;
  
  final List<String> _categories = [
    'Semua', 'Graphic Designer', 'Content Creator', 
    'Web Developer', 'Photographer', 'UI/UX Designer',
    'Illustrator', 'Video Editor', 'Social Media Manager'
  ];

  @override
  void initState() {
    super.initState();
    _loadRecommendedCreatives();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendedCreatives() async {
  setState(() => _isLoading = true);
  
  try {
    final result = await _api.getRecommendedCreatives();
    
    if (mounted) {
      setState(() {
        if (result['success'] == true && result['data'] != null) {
          final raw = result['data'];
          List<dynamic> list = [];
          if (raw is List) {
            list = raw;
          } else if (raw is Map) {
            // Handle semua kemungkinan key dari backend Laravel
            list = (raw['creatives'] ??
                    raw['data'] ??
                    raw['users'] ??
                    raw['creative_workers'] ??
                    []) as List<dynamic>;
          }
          _recommendedCreatives = list.map((e) => Map<String, dynamic>.from(e)).toList();
          _creatives = _recommendedCreatives;
        }
        _isLoading = false; // ← selalu set false, baik sukses maupun gagal
      });
    }
  } catch (e) {
    debugPrint('Error loading creatives: $e');
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _onSearch() async {
    setState(() => _isSearching = true);
    
    final query = _searchController.text.trim();
    final category = _selectedCategory == 'Semua' ? null : _selectedCategory;
    
    final result = await _api.searchCreatives(
      query: query.isNotEmpty ? query : null,
      category: category,
    );
    
    if (mounted) {
      setState(() {
        if (result['success']) {
          final raw = result['data'];
          List<dynamic> list = [];
          if (raw is List) {
            list = raw;
          } else if (raw is Map) {
            list = (raw['creatives'] ?? raw['data'] ?? raw['users'] ?? raw['creative_workers'] ?? []) as List<dynamic>;
          }
          _creatives = list.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        _isSearching = false;
      });
    }
  }

  void _onCategoryChanged(String category) {
    setState(() => _selectedCategory = category);
    _onSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          'Explore Creative Worker',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          
          // Sub Judul Baru
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A4B84).withOpacity(0.04),
                  const Color(0xFF006D77).withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: const Color(0xFF1A4B84).withOpacity(0.08)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temukan Talenta Kreatif Terbaik',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A4B84),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ribuan profesional kreatif siap membantu bisnismu naik kelas. Pilih yang paling sesuai dengan visi bisnismu.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF424750),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadRecommendedCreatives,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (_recommendedCreatives.isNotEmpty && _searchController.text.isEmpty)
                          _buildRecommendedSection(),
                        
                        _buildCreativesList(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEAE7ED)),
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _onSearch(),
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari creative worker berdasarkan skill, nama...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF424750).withOpacity(0.5),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF424750)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 8,
                    right: index == _categories.length - 1 ? 0 : 0,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => _onCategoryChanged(category),
                    backgroundColor: const Color(0xFFF5F3F7),
                    selectedColor: const Color(0xFF1A4B84),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF424750),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF1A4B84) : const Color(0xFFEAE7ED),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    elevation: 0,
                    pressElevation: 0,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: const Color(0xFFE29578)),
                const SizedBox(width: 6),
                Text(
                  'Rekomendasi untukmu',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: const Color(0xFF1B1B1F),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_recommendedCreatives.length} kreator',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF424750),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreativesList() {
    if (_isSearching) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_creatives.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64, 
                   color: const Color(0xFF424750).withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                'Belum ada creative worker',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF424750),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final creative = _creatives[index];
          return _CreativeCard(
            creative: creative, 
            isRecommended: _recommendedCreatives.contains(creative),
          );
        },
        childCount: _creatives.length,
      ),
    );
  }
}

class _CreativeCard extends StatelessWidget {
  final Map<String, dynamic> creative;
  final bool isRecommended;
  
  const _CreativeCard({
    required this.creative, 
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = creative['name'] ?? creative['creative_name'] ?? '';
    final role = creative['role'] ?? creative['creative_category'] ?? '';
    final city = creative['city'] ?? creative['creative_city'] ?? '';
    final rating = creative['rating'] ?? creative['average_rating'] ?? 0.0;
    final skills = (creative['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final avatar = creative['profile_photo'] ?? creative['avatar'] ?? '';
    final portfolioCount = creative['portfolio_count'] ?? 0;
    final completedProjects = creative['completed_projects'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreativeDetailPage(creativeId: creative['id'].toString()),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A4B84), Color(0xFF006D77)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            image: avatar.isNotEmpty
                                ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover)
                                : null,
                          ),
                          child: avatar.isEmpty
                              ? Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        if (isRecommended)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: Color(0xFFE29578),
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: const Color(0xFF1B1B1F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF424750),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: const Color(0xFF424750).withOpacity(0.6)),
                              const SizedBox(width: 2),
                              Text(
                                city,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF424750).withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1B1B1F),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    Icon(Icons.chevron_right, color: const Color(0xFF424750).withOpacity(0.4)),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                if (skills.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: skills.take(3).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3F7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          skill,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1A4B84),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                
                if (portfolioCount > 0 || completedProjects > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _infoChip(Icons.work_history, '$completedProjects proyek'),
                      const SizedBox(width: 12),
                      _infoChip(Icons.photo_library_outlined, '$portfolioCount portfolio'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF424750).withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF424750).withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
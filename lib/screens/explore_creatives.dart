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
    'Semua',
    'Graphic Designer',
    'Content Creator',
    'Web Developer',
    'Photographer',
    'UI/UX Designer',
    'Illustrator',
    'Video Editor',
    'Social Media Manager',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllCreatives();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Load: coba recommended dulu, fallback ke search all ────────────────────
  Future<void> _loadAllCreatives() async {
    setState(() => _isLoading = true);

    try {
      // 1) Coba endpoint recommended
      final recResult = await _api.getRecommendedCreatives();
      List<Map<String, dynamic>> recList = [];

      if (recResult['success'] == true && recResult['data'] != null) {
        recList = _parseCreativeList(recResult['data']);
      }

      // 2) Selalu ambil semua kreator via search (query kosong = ambil semua)
      final allResult = await _api.searchCreatives();
      List<Map<String, dynamic>> allList = [];

      if (allResult['success'] == true && allResult['data'] != null) {
        allList = _parseCreativeList(allResult['data']);
      }

      // 3) Kalau search all gagal/kosong, pakai recommended sebagai fallback
      final displayList = allList.isNotEmpty ? allList : recList;

      if (mounted) {
        setState(() {
          _recommendedCreatives = recList;
          _creatives = displayList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading creatives: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Search / filter ────────────────────────────────────────────────────────
  Future<void> _onSearch() async {
    setState(() => _isSearching = true);

    try {
      final query = _searchController.text.trim();
      final category =
          _selectedCategory == 'Semua' ? null : _selectedCategory;

      final result = await _api.searchCreatives(
        query: query.isNotEmpty ? query : null,
        category: category,
      );

      if (mounted) {
        setState(() {
          if (result['success'] == true && result['data'] != null) {
            _creatives = _parseCreativeList(result['data']);
          } else {
            _creatives = [];
          }
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching creatives: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onCategoryChanged(String category) {
    setState(() => _selectedCategory = category);
    _onSearch();
  }

  // ─── Helper: parse berbagai bentuk response backend ─────────────────────────
  List<Map<String, dynamic>> _parseCreativeList(dynamic raw) {
    List<dynamic> list = [];
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      list = (raw['creatives'] ??
              raw['data'] ??
              raw['users'] ??
              raw['creative_workers'] ??
              []) as List<dynamic>;
    }
    return list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          // Subtitle banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A4B84).withOpacity(0.05),
                  const Color(0xFF006D77).withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(
                    color: const Color(0xFF1A4B84).withOpacity(0.08)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temukan Talenta Kreatif Terbaik',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A4B84),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Profesional kreatif siap membantu bisnismu naik kelas.',
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
                    onRefresh: _loadAllCreatives,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (_recommendedCreatives.isNotEmpty &&
                            _searchController.text.isEmpty)
                          _buildRecommendedHeader(),
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
                hintText: 'Cari creative worker berdasarkan nama, skill...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF424750).withOpacity(0.5),
                  fontSize: 13,
                ),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Color(0xFF424750)),
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
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => _onCategoryChanged(cat),
                    backgroundColor: const Color(0xFFF5F3F7),
                    selectedColor: const Color(0xFF1A4B84),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF424750),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF1A4B84)
                            : const Color(0xFFEAE7ED),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
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

  Widget _buildRecommendedHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome,
                size: 16, color: Color(0xFFE29578)),
            const SizedBox(width: 6),
            Text(
              'Rekomendasi untukmu',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: const Color(0xFF1B1B1F),
              ),
            ),
            const Spacer(),
            Text(
              '${_creatives.length} kreator',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF424750),
              ),
            ),
          ],
        ),
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
              Icon(Icons.search_off_rounded,
                  size: 56,
                  color: const Color(0xFF424750).withOpacity(0.25)),
              const SizedBox(height: 14),
              Text(
                'Belum ada creative worker',
                style: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFF424750)),
              ),
              const SizedBox(height: 6),
              Text(
                'Coba kata kunci atau kategori lain',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF424750).withOpacity(0.6)),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _CreativeCard(
            creative: _creatives[index],
            isRecommended:
                _recommendedCreatives.contains(_creatives[index]),
          ),
          childCount: _creatives.length,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// CREATIVE CARD
// ════════════════════════════════════════════════════════════

class _CreativeCard extends StatelessWidget {
  final Map<String, dynamic> creative;
  final bool isRecommended;

  const _CreativeCard({required this.creative, this.isRecommended = false});

  @override
  Widget build(BuildContext context) {
    final name =
        creative['name'] ?? creative['creative_name'] ?? '';
    final role = creative['role'] ??
        creative['creative_category'] ??
        creative['category'] ??
        '';
    final city =
        creative['city'] ?? creative['creative_city'] ?? '';
    final rating =
        (creative['rating'] ?? creative['average_rating'] ?? 0.0) is int
            ? (creative['rating'] ?? 0).toDouble()
            : (creative['rating'] ?? creative['average_rating'] ?? 0.0)
                as double;
    final skills =
        (creative['skills'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
            [];
    final avatar =
        creative['profile_photo'] ?? creative['avatar'] ?? '';
    final portfolioCount = creative['portfolio_count'] ?? 0;
    final completedProjects = creative['completed_projects'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B84).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreativeDetailPage(
                  creativeId: creative['id'].toString()),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1A4B84),
                                Color(0xFF006D77)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            image: (avatar as String).isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(avatar),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: avatar.isEmpty
                              ? Center(
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                        color: Colors.white),
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
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.auto_awesome,
                                  size: 13, color: Color(0xFFE29578)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: const Color(0xFF1B1B1F),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isRecommended)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE29578)
                                        .withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Rekomendasi',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFE29578),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            role,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF1A4B84),
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 12,
                                  color: const Color(0xFF424750)
                                      .withOpacity(0.6)),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  city,
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF424750)
                                          .withOpacity(0.7)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.star_rounded,
                                  size: 13, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1B1B1F)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: const Color(0xFF424750).withOpacity(0.35)),
                  ],
                ),
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: skills.take(3).map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A4B84)
                                .withOpacity(0.07),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            s,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1A4B84)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (portfolioCount > 0 || completedProjects > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _chip(Icons.work_history_outlined,
                          '$completedProjects proyek'),
                      const SizedBox(width: 14),
                      _chip(Icons.photo_library_outlined,
                          '$portfolioCount portfolio'),
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

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 12,
            color: const Color(0xFF424750).withOpacity(0.55)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF424750).withOpacity(0.7)),
        ),
      ],
    );
  }
}
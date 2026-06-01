// lib/screens/explore_screen.dart
//
// Halaman Explore untuk Creative Worker — daftar proyek tersedia
// beserta Project Detail Screen dengan form apply (message + proposal file).
// Desain mengikuti creative_dashboard.dart (warna, tipografi, radius, shadow).

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../models/projectcr_model.dart';
import '../services/project_service.dart';

// ─────────────────────────────────────────────
//  EXPLORE SCREEN
// ─────────────────────────────────────────────
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ProjectService _service = ProjectService();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<Project> _projects = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _errorMsg = '';
  String _selectedCategory = 'Semua';
  int _currentPage = 1;
  int _lastPage = 1;

  static const List<String> _categories = [
    'Semua',
    'Desain',
    'Branding',
    'Foto',
    'Video',
    'Copywriting',
    'Ilustrasi',
    'UI/UX',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProjects(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Infinite scroll ──────────────────────────
  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _lastPage) {
      _fetchProjects(page: _currentPage + 1);
    }
  }

  // ── Fetch data ───────────────────────────────
  Future<void> _fetchProjects({bool reset = false, int page = 1}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _currentPage = 1;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    final result = await _service.getProjects(
      category: _selectedCategory,
      search: _searchCtrl.text,
      page: page,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final newProjects = result['projects'] as List<Project>;
      setState(() {
        if (reset || page == 1) {
          _projects = newProjects;
        } else {
          _projects = [..._projects, ...newProjects];
        }
        _currentPage = result['current_page'] ?? page;
        _lastPage = result['last_page'] ?? 1;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _hasError = true;
        _errorMsg = result['message'] ?? 'Terjadi kesalahan';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onCategoryTap(String cat) {
    if (_selectedCategory == cat) return;
    setState(() => _selectedCategory = cat);
    _fetchProjects(reset: true);
  }

  void _onSearch(String _) => _fetchProjects(reset: true);

  // Tinggi sticky header: searchbar (52) + gap (10) + chips (40) + gap bawah (8)
  static const double _stickyHeight = 52 + 10 + 40 + 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF003466),
          onRefresh: () => _fetchProjects(reset: true),
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Header ikut scroll ─────────────
              SliverToBoxAdapter(child: _buildHeader()),

              // ── Sticky: searchbar + category chips ─
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchDelegate(
                  height: _stickyHeight,
                  child: _buildStickyBar(),
                ),
              ),

              // ── Konten list / state ────────────
              if (_isLoading)
                _buildSkeletonSliver()
              else if (_hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildError(),
                )
              else if (_projects.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmpty(),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ExploreProjectCard(
                          project: _projects[i],
                          onTap: () => _openDetail(_projects[i]),
                        ),
                      ),
                      childCount: _projects.length,
                    ),
                  ),
                ),
                if (_isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(Color(0xFF003466)),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Header (ikut scroll) ──────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B1B1F),
                height: 1.25,
              ),
              children: [
                const TextSpan(text: 'Temukan '),
                TextSpan(
                  text: 'kanvas kreatif ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF20C997),
                    fontStyle: FontStyle.italic,
                    height: 1.25,
                  ),
                ),
                const TextSpan(text: 'Anda berikutnya.'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kesempatan yang dipilih secara cermat untuk\ntalenta-talenta terbaik.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky bar: searchbar + chips ────────────
  Widget _buildStickyBar() {
    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8ECF0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: _onSearch,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF1B1B1F),
                ),
                decoration: InputDecoration(
                  hintText: 'Search project names or skills...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 22,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            _fetchProjects(reset: true);
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF9CA3AF),
                            size: 18,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Category chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => _onCategoryTap(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF003466)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF003466)
                            : const Color(0xFFE8ECF0),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Skeleton sebagai Sliver ──────────────────
  SliverPadding _buildSkeletonSliver() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: _SkeletonCard(),
          ),
          childCount: 4,
        ),
      ),
    );
  }

  void _openDetail(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(project: project),
      ),
    ).then((_) {
      _fetchProjects(reset: true);
    });
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Terjadi Kesalahan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMsg,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _fetchProjects(reset: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Coba Lagi',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003466),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Color(0xFF003466),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Proyek',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coba kategori atau kata kunci lain.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STICKY SEARCH DELEGATE
// ─────────────────────────────────────────────
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const _StickySearchDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickySearchDelegate old) =>
      old.height != height || old.child != child;
}

// ─────────────────────────────────────────────
//  EXPLORE PROJECT CARD
// ─────────────────────────────────────────────
class _ExploreProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ExploreProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8ECF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    project.thumbnail != null
                        ? Image.network(
                            project.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _PlaceholderThumbnail(category: project.category),
                          )
                        : _PlaceholderThumbnail(category: project.category),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _StatusBadge(status: project.status),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.category.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF20C997),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1F),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    project.formattedBudget,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF003466),
                    ),
                  ),
                  Text(
                    'SINGLE PROJECT',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9CA3AF),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF003466),
                        backgroundImage: project.clientAvatar.isNotEmpty
                            ? NetworkImage(project.clientAvatar)
                            : null,
                        child: project.clientAvatar.isEmpty
                            ? Text(
                                project.clientName.isNotEmpty
                                    ? project.clientName[0].toUpperCase()
                                    : 'U',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        project.clientName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('•', style: TextStyle(color: Color(0xFF9CA3AF))),
                      const SizedBox(width: 4),
                      const Icon(Icons.business_rounded,
                          size: 12, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 2),
                      Text(
                        'SME',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      const Spacer(),
                      if (project.deadlineLabel.isNotEmpty) ...[
                        const Icon(Icons.access_time_rounded,
                            size: 12, color: Color(0xFFEF4444)),
                        const SizedBox(width: 3),
                        Text(
                          'Due in ${project.deadlineLabel}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: project.isApplied
                        ? _AppliedButton()
                        : _ApplyButton(onTap: onTap),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ApplyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF003466),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Apply to Project',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_rounded, size: 16),
        ],
      ),
    );
  }
}

class _AppliedButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF20C997).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF20C997)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 16, color: Color(0xFF20C997)),
          const SizedBox(width: 6),
          Text(
            'Sudah Di-apply',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF20C997),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STATUS BADGE
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color dot;
    String label;
    Color bg;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'open':
        dot = const Color(0xFF20C997);
        label = 'OPEN';
        bg = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        break;
      case 'applied':
        dot = const Color(0xFF3B82F6);
        label = 'APPLIED';
        bg = const Color(0xFFDCEFFD);
        textColor = const Color(0xFF1E40AF);
        break;
      case 'ongoing':
        dot = const Color(0xFFF59E0B);
        label = 'ONGOING';
        bg = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      default:
        dot = const Color(0xFF9CA3AF);
        label = status.toUpperCase();
        bg = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PLACEHOLDER THUMBNAIL
// ─────────────────────────────────────────────
class _PlaceholderThumbnail extends StatelessWidget {
  final String category;
  const _PlaceholderThumbnail({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003466), Color(0xFF0056A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work_outline_rounded,
                size: 36, color: Colors.white54),
            const SizedBox(height: 6),
            Text(
              category.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SKELETON CARD
// ─────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: Container(color: const Color(0xFFE8ECF0)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bone(60, 10),
                const SizedBox(height: 8),
                _bone(double.infinity, 14),
                const SizedBox(height: 4),
                _bone(180, 14),
                const SizedBox(height: 10),
                _bone(100, 18),
                const SizedBox(height: 12),
                _bone(double.infinity, 44, radius: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bone(double w, double h, {double radius = 6}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECF0),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// ─────────────────────────────────────────────
//  PROJECT DETAIL SCREEN (DENGAN FORM APPLY)
// ─────────────────────────────────────────────
class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectService _service = ProjectService();

  late Project _project;
  bool _isLoadingDetail = false;
  bool _isApplying = false;
  bool _showFullDesc = false;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _refreshDetail();
  }

  Future<void> _refreshDetail() async {
    setState(() => _isLoadingDetail = true);
    final result = await _service.getProjectDetail(_project.id);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _project = result['project'] as Project;
        _isLoadingDetail = false;
      });
    } else {
      setState(() => _isLoadingDetail = false);
    }
  }

  // ── PROSES APPLY DENGAN MESSAGE + FILE ────────
  Future<void> _apply(String message, File proposalFile) async {
    if (_isApplying) return;

    setState(() => _isApplying = true);

    final result = await _service.applyToProject(
      _project.id,
      message: message,
      proposalFile: proposalFile,
    );

    if (!mounted) return;
    setState(() => _isApplying = false);

    if (result['success'] == true) {
      _showSnackBar(result['message'] ?? 'Berhasil melamar!', isSuccess: true);
      await _refreshDetail();
    } else {
      _showSnackBar(result['message'] ?? 'Gagal melamar.', isSuccess: false);
    }
  }

  // ── BOTTOM SHEET UNTUK INPUT MESSAGE + FILE ───
  Future<void> _showApplySheet() async {
    final TextEditingController messageController = TextEditingController();
    File? selectedFile;
    bool isUploading = false;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECF0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.send_rounded,
                      size: 32, color: Color(0xFF003466)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lamar Proyek',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B1B1F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _project.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1B1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_project.clientName} • ${_project.formattedBudget}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF003466),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                // ── MESSAGE FIELD ──────────────────
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: 'Pesan Lamaran *',
                    hintText: 'Jelaskan mengapa Anda cocok untuk proyek ini... (minimal 20 karakter)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '${messageController.text.length}/1000',
                  ),
                  onChanged: (value) => setSheetState(() {}),
                ),

                const SizedBox(height: 16),

                // ── FILE PICKER ────────────────────
                GestureDetector(
                  onTap: isUploading
                      ? null
                      : () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'zip'],
                          );
                          if (result != null) {
                            setSheetState(() {
                              selectedFile = File(result.files.single.path!);
                            });
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE8ECF0)),
                      borderRadius: BorderRadius.circular(12),
                      color: selectedFile != null
                          ? const Color(0xFFF0FDF4)
                          : Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selectedFile == null
                              ? Icons.attach_file
                              : Icons.check_circle,
                          color: selectedFile == null
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF20C997),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedFile == null
                                ? 'Upload Proposal (PDF/DOC/PPT/ZIP) *'
                                : selectedFile!.path.split('/').last,
                            style: GoogleFonts.inter(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── VALIDATION MESSAGE ─────────────
                if (messageController.text.length < 20 && messageController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '⚠️ Pesan minimal 20 karakter (saat ini: ${messageController.text.length})',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // ── BUTTONS ────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          side: const BorderSide(color: Color(0xFFE8ECF0)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isUploading ||
                                messageController.text.length < 20 ||
                                selectedFile == null
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _apply(messageController.text, selectedFile!);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003466),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Kirim Lamaran',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSnackBar(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF20C997) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildContent()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCTA(),
          ),
          if (_isLoadingDetail)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF003466)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: const Color(0xFF003466),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.bookmark_border_rounded,
                  color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _project.thumbnail != null
                ? Image.network(
                    _project.thumbnail!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _PlaceholderThumbnail(category: _project.category),
                  )
                : _PlaceholderThumbnail(category: _project.category),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: _StatusBadge(status: _project.status),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline_rounded,
                        size: 13, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${_project.applicationsCount} pelamar',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleSection(),
          const SizedBox(height: 20),
          _buildInfoCards(),
          const SizedBox(height: 20),
          _buildClientSection(),
          const SizedBox(height: 20),
          _buildDescriptionSection(),
          if (_project.requirements != null && _project.requirements!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildRequirementsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _project.category.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF20C997),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _project.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1B1B1F),
            height: 1.25,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.attach_money_rounded,
            label: 'Budget',
            value: _project.formattedBudget,
            iconColor: const Color(0xFF003466),
            bgColor: const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.calendar_today_rounded,
            label: 'Deadline',
            value: _project.deadlineLabel.isNotEmpty
                ? _project.deadlineLabel
                : 'Tidak ditentukan',
            iconColor: _project.deadlineLabel.contains('Lewat')
                ? const Color(0xFFEF4444)
                : const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
          ),
        ),
      ],
    );
  }

  Widget _buildClientSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF003466),
            backgroundImage: _project.clientAvatar.isNotEmpty
                ? NetworkImage(_project.clientAvatar)
                : null,
            child: _project.clientAvatar.isEmpty
                ? Text(
                    _project.clientName.isNotEmpty
                        ? _project.clientName[0].toUpperCase()
                        : 'U',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _project.clientName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1B1F),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.business_rounded,
                        size: 13, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(
                      'Small & Medium Enterprise',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'SME',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF003466),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final desc = _project.description;
    final isLong = desc.length > 200;
    final displayText = isLong && !_showFullDesc ? '${desc.substring(0, 200)}...' : desc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deskripsi Proyek',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1B1F),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8ECF0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayText,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF374151),
                  height: 1.6,
                ),
              ),
              if (isLong) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _showFullDesc = !_showFullDesc),
                  child: Text(
                    _showFullDesc ? 'Tampilkan lebih sedikit ↑' : 'Baca selengkapnya ↓',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF003466),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requirements',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1B1F),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.checklist_rounded,
                  size: 18, color: Color(0xFF003466)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _project.requirements!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF1E40AF),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: _project.isApplied
          ? _AppliedButton()
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isApplying ? null : _showApplySheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003466),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF003466).withValues(alpha: 0.6),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isApplying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Apply to Project',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────
//  INFO CARD
// ─────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color bgColor;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9CA3AF),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1B1F),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
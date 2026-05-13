// lib/screens/umkm_dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/dashboard_model.dart';
import '../models/project_model.dart';
import 'create_project.dart';
import 'my_projects_umkm.dart';
import 'explore_creatives.dart';
import 'profile_umkm.dart';
import 'project_applicants.dart';
import 'project_progress_detail.dart';
import 'creative_detail_page.dart';
import 'ai_recommendation_page.dart';

class UmkmDashboard extends StatefulWidget {
  const UmkmDashboard({super.key});

  @override
  State<UmkmDashboard> createState() => _UmkmDashboardState();
}

class _UmkmDashboardState extends State<UmkmDashboard> {
  final AuthService _auth = AuthService();
  final ApiService _api = ApiService();

  int _currentIndex = 0;

  Map<String, dynamic> _userData = {};
  String _userName = '';
  String _userCity = '';
  UMKMKDashboardData? _dashboardStats;
  List<Project> _recentProjects = [];
  List<Map<String, dynamic>> _recommendedCreatives = [];
  bool _isLoading = true;
  bool _isLoadingCreatives = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _loadUserAndDashboard(),
      _loadProjects(),
      _loadCreativeRecommendations(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserAndDashboard() async {
    final cachedName = await _auth.getUserName();
    final cachedData = await _auth.getUserData();

    if (mounted) {
      setState(() {
        _userData = cachedData ?? {};
        _userName = cachedName ?? '';
        _userCity = _userData['city'] ?? '';
      });
    }

    final result = await _api.getUMKMDashboard();

    if (mounted && result['success'] == true && result['data'] != null) {
      final data = Map<String, dynamic>.from(result['data']);
      final apiUser = data['user'] as Map<String, dynamic>?;

      if (apiUser != null) {
        setState(() {
          _userName = apiUser['name']?.toString() ?? _userName;
          _userCity = apiUser['city']?.toString() ??
              apiUser['address']?.toString() ??
              _userCity;
        });
      }

      try {
        setState(() {
          _dashboardStats = UMKMKDashboardData.fromJson(data);
        });
      } catch (e) {
        debugPrint('Error parsing dashboard stats: $e');
      }
    }
  }

  Future<void> _loadProjects() async {
    final result = await _api.getUmkmProjects();

    if (mounted && result['success'] == true && result['data'] != null) {
      try {
        final raw = result['data'];
        List<dynamic> projectsList = [];

        if (raw is List) {
          projectsList = raw;
        } else if (raw is Map) {
          projectsList = raw['projects'] as List? ?? raw['data'] as List? ?? [];
        }

        final parsed = <Project>[];
        for (var e in projectsList) {
          try {
            parsed.add(Project.fromJson(Map<String, dynamic>.from(e)));
          } catch (err) {
            debugPrint('Error parsing project item: $err');
          }
        }

        if (mounted) {
          setState(() {
            _recentProjects = parsed;
          });
        }
      } catch (e) {
        debugPrint('Error loading projects: $e');
      }
    }
  }

  Future<void> _loadCreativeRecommendations() async {
    setState(() => _isLoadingCreatives = true);

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
              list = raw['creatives'] ?? raw['data'] ?? raw['users'] ?? [];
            }

            _recommendedCreatives = list.map((item) {
              final creative = Map<String, dynamic>.from(item);
              return {
                'id': creative['id']?.toString() ?? '',
                'name': creative['name']?.toString() ?? 'Creative Worker',
                'role': creative['role']?.toString() ?? creative['category']?.toString() ?? '',
                'rating': double.tryParse(creative['rating']?.toString() ?? '0') ?? 0.0,
                'skills': creative['skills'] is List
                    ? List<String>.from(creative['skills'])
                    : <String>[],
                'city': creative['city']?.toString() ?? '',
                'profile_photo': creative['profile_photo']?.toString(),
                'completed_projects': creative['completed_projects'] ?? 0,
                'portfolio_count': creative['portfolio_count'] ?? 0,
                'relevance_score': double.tryParse(creative['relevance_score']?.toString() ?? '0') ?? 0.0,
              };
            }).toList();
          }
          _isLoadingCreatives = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading creative recommendations: $e');
      if (mounted) setState(() {
        _recommendedCreatives = [];
        _isLoadingCreatives = false;
      });
    }
  }

  void _navigateToCreateProject() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateProjectPage()),
    ).then((_) => _loadAllData());
  }

  void _navigateToAiRecommendation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiRecommendationPage()),
    ).then((_) => _loadAllData());
  }

  void _navigateToProjectStatus(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectProgressDetailPage(project: project),
      ),
    ).then((_) => _loadAllData());
  }

  // ==================== DASHBOARD CONTENT ====================

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildStatsGrid(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildRecommendedCreatives(),
            const SizedBox(height: 20),
            _buildCollaborationStatusSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ==================== PROFILE HEADER ====================

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003466), Color(0xFF1A4B84)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.store, size: 26, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang,',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 2),
                Text(
                  _userName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (_userCity.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 11, color: Colors.white60),
                      const SizedBox(width: 3),
                      Text(
                        _userCity,
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.white60),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => setState(() => _currentIndex = 4),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, size: 12, color: Colors.white),
                  const SizedBox(width: 3),
                  Text(
                    'Edit',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STATS GRID ====================

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: [
        _statCardCompact(
          title: 'Total Proyek',
          value: (_dashboardStats?.totalProjects ?? 0).toString(),
          icon: Icons.folder_outlined,
          color: const Color(0xFF1A4B84),
        ),
        _statCardCompact(
          title: 'Proyek Berjalan',
          value: (_dashboardStats?.activeProjects ?? 0).toString(),
          icon: Icons.work_outline,
          color: const Color(0xFF006D77),
        ),
        _statCardCompact(
          title: 'Apply Masuk',
          value: (_dashboardStats?.totalApplicants ?? 0).toString(),
          icon: Icons.people_outline,
          color: const Color(0xFFE29578),
        ),
        _statCardCompact(
          title: 'Status Akun',
          value: 'Aktif',
          icon: Icons.check_circle_outline,
          color: const Color(0xFF68FADD),
          isStatus: true,
        ),
      ],
    );
  }

  Widget _statCardCompact({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isStatus = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF424750),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                isStatus
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          value,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B1B1F),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== QUICK ACTIONS ====================

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1B1F),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                icon: Icons.add_circle_outline,
                title: 'Upload\nProyek Baru',
                color: const Color(0xFF1A4B84),
                onTap: _navigateToCreateProject,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quickActionCard(
                icon: Icons.timeline,
                title: 'Progress\nProyek',
                color: const Color(0xFF006D77),
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== RECOMMENDED CREATIVES ====================

  Widget _buildRecommendedCreatives() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: const Color(0xFFE29578)),
                const SizedBox(width: 6),
                Text(
                  'Rekomendasi Kreator',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1B1F),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A4B84),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            const SizedBox(width: 22),
            Expanded(
              child: Text(
                'Disesuaikan dengan kategori proyek Anda',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF424750).withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_isLoadingCreatives)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_recommendedCreatives.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAE7ED)),
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 36, color: const Color(0xFF424750).withOpacity(0.3)),
                const SizedBox(height: 6),
                Text(
                  'Belum ada rekomendasi',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF424750)),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 2),
              itemCount: _recommendedCreatives.length,
              itemBuilder: (context, index) {
                final creative = _recommendedCreatives[index];
                return _creativeCardCompact(creative);
              },
            ),
          ),
      ],
    );
  }

  Widget _creativeCardCompact(Map<String, dynamic> creative) {
    final name = creative['name'] ?? '';
    final role = creative['role'] ?? '';
    final rating = creative['rating'] ?? 0.0;
    final city = creative['city'] ?? '';
    final photo = creative['profile_photo'] ?? '';
    final relevanceScore = creative['relevance_score'] ?? 0.0;

    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B84).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFEAE7ED).withOpacity(0.6)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreativeDetailPage(creativeId: creative['id'] ?? ''),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A4B84), Color(0xFF006D77)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: const Color(0xFF1B1B1F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            role,
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF424750)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 11, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B1B1F),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.location_on_outlined, size: 9, color: const Color(0xFF424750).withOpacity(0.5)),
                    const SizedBox(width: 1),
                    Expanded(
                      child: Text(
                        city,
                        style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF424750).withOpacity(0.6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (relevanceScore > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006D77).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, size: 9, color: const Color(0xFF006D77)),
                        const SizedBox(width: 3),
                        Text(
                          '${(relevanceScore * 10).toStringAsFixed(0)}% Cocok',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF006D77),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== COLLABORATION STATUS SECTION (BARU) ====================

  Widget _buildCollaborationStatusSection() {
    // Hanya proyek dengan status hiring/ongoing (sudah ada kreator terpilih)
    final collaborationProjects = _recentProjects.where((p) {
      return p.status == 'hired' || p.status == 'in_progress' || p.status == 'ongoing';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Status Kerja Sama',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1B1F),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 3),
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A4B84),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (collaborationProjects.isEmpty)
          _buildEmptyCollaborationState()
        else
          ...collaborationProjects.map((project) => _collaborationCard(project)),
      ],
    );
  }

  Widget _buildEmptyCollaborationState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Icon(Icons.handshake_outlined, size: 48, color: const Color(0xFF424750).withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            'Belum ada kerja sama aktif',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF424750)),
          ),
          const SizedBox(height: 6),
          Text(
            'Setelah kreator dipilih, status proyek akan muncul di sini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF424750)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _navigateToCreateProject,
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text('Buat Proyek Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A4B84),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _collaborationCard(Project project) {
    final progress = (project.status == 'in_progress' || project.status == 'ongoing')
        ? 65
        : (project.status == 'hired' ? 10 : 0);
    final creativeName = project.umkmName ?? 'Creative Worker'; // sesuaikan dengan field yang ada

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: InkWell(
        onTap: () => _navigateToProjectStatus(project),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A4B84).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.work_outline, color: Color(0xFF1A4B84), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kreator: $creativeName',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF424750)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006D77).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$progress%',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF006D77)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: const Color(0xFFEAE7ED),
                color: const Color(0xFF006D77),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Lihat Detail →',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1A4B84)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== BOTTOM NAVIGATION ====================

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboardContent(),
      const ExploreCreativesPage(),
      const AiRecommendationPage(),
      const MyProjectsUmkmPage(),
      const ProfileUmkmPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF1B1B1F),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentIndex == 0
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A4B84), size: 18),
                onPressed: () => setState(() => _currentIndex = 0),
              ),
        actions: const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1A4B84),
        unselectedItemColor: const Color(0xFF424750),
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Eksplor'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: 'Rekomen AI'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), activeIcon: Icon(Icons.work), label: 'Proyek'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Eksplor Kreator';
      case 2:
        return 'Rekomendasi AI';
      case 3:
        return 'Proyek Saya';
      case 4:
        return 'Profil';
      default:
        return 'Konekin';
    }
  }
}
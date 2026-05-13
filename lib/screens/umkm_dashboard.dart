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
import 'project_detail.dart';
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
  String _userPhotoUrl = '';
  UMKMKDashboardData? _dashboardStats;
  List<Project> _recentProjects = [];
  List<Map<String, dynamic>> _recommendedCreatives = [];
  List<Map<String, dynamic>> _notifications = [];
  int _unreadNotifCount = 0;
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
      _loadRecentProjects(),
      _loadCreativeRecommendations(),
      _loadNotifications(),
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
        _userPhotoUrl = _userData['profile_photo'] ?? '';
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
          _userPhotoUrl = apiUser['profile_photo']?.toString() ??
              apiUser['photo']?.toString() ??
              _userPhotoUrl;
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

  Future<void> _loadRecentProjects() async {
    final result = await _api.getUmkmProjects();

    if (mounted && result['success'] == true && result['data'] != null) {
      try {
        final raw = result['data'];
        List<dynamic> projectsList = [];

        if (raw is List) {
          projectsList = raw;
        } else if (raw is Map) {
          projectsList =
              raw['projects'] as List? ?? raw['data'] as List? ?? [];
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
            _recentProjects = parsed.take(3).toList();
          });
        }
      } catch (e) {
        debugPrint('Error loading recent projects: $e');
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
                'role': creative['role']?.toString() ??
                    creative['category']?.toString() ??
                    '',
                'rating':
                    double.tryParse(creative['rating']?.toString() ?? '0') ??
                        0.0,
                'skills': creative['skills'] is List
                    ? List<String>.from(creative['skills'])
                    : <String>[],
                'city': creative['city']?.toString() ?? '',
                'profile_photo': creative['profile_photo']?.toString(),
                'completed_projects': creative['completed_projects'] ?? 0,
                'portfolio_count': creative['portfolio_count'] ?? 0,
                'relevance_score':
                    double.tryParse(
                          creative['relevance_score']?.toString() ?? '0',
                        ) ??
                        0.0,
              };
            }).toList();
          }
          _isLoadingCreatives = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading creative recommendations: $e');
      if (mounted) {
        setState(() {
          _recommendedCreatives = [];
          _isLoadingCreatives = false;
        });
      }
    }
  }

  /// Load notifications from backend: GET /api/notifications
  Future<void> _loadNotifications() async {
    try {
      final result = await _api.getNotifications();
      if (mounted && result['success'] == true && result['data'] != null) {
        final raw = result['data'];
        List<dynamic> list = [];
        if (raw is List) {
          list = raw;
        } else if (raw is Map) {
          list = raw['notifications'] ?? raw['data'] ?? [];
        }
        final notifs = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final unread =
            notifs.where((n) => n['read_at'] == null).length;
        if (mounted) {
          setState(() {
            _notifications = notifs;
            _unreadNotifCount = unread;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
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

  void _navigateToProjectDetail(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailPage(projectId: project.id),
      ),
    ).then((_) => _loadAllData());
  }

  void _navigateToApplicants(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectApplicantsPage(project: project),
      ),
    ).then((_) => _loadAllData());
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationsSheet(
        notifications: _notifications,
        onMarkAllRead: () async {
          await _api.markAllNotificationsRead();
          Navigator.pop(ctx);
          _loadNotifications();
        },
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Keluar',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah kamu yakin ingin keluar dari akun ini?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: const Color(0xFF424750)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A4B84),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _api.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar() {
    if (_currentIndex != 0) {
      return AppBar(
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1A4B84), size: 18),
          onPressed: () => setState(() => _currentIndex = 0),
        ),
        actions: const [],
      );
    }

    // Dashboard AppBar
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Profile photo
            _buildAvatarSmall(),
            const SizedBox(width: 10),
            // Name & role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _userName.isNotEmpty ? _userName : 'UMKM',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF1B1B1F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'UMKM',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF1A4B84),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Notification bell
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Color(0xFF1A4B84), size: 22),
                  onPressed: _showNotificationsSheet,
                  tooltip: 'Notifikasi',
                ),
                if (_unreadNotifCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _unreadNotifCount > 9
                              ? '9+'
                              : _unreadNotifCount.toString(),
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Logout
            IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: Color(0xFFE53935), size: 20),
              onPressed: _logout,
              tooltip: 'Keluar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSmall() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF1A4B84), Color(0xFF006D77)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: _userPhotoUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(_userPhotoUrl), fit: BoxFit.cover)
            : null,
      ),
      child: _userPhotoUrl.isEmpty
          ? Center(
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white),
              ),
            )
          : null,
    );
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
            _buildWelcomeBanner(),
            const SizedBox(height: 16),
            _buildStatsGrid(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildRecommendedCreatives(),
            const SizedBox(height: 20),
            _buildRecentProjectsSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ==================== WELCOME BANNER (menggantikan profile header) ====================

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003466), Color(0xFF1A4B84), Color(0xFF006D77)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B84).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikon toko kecil
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Halo, ',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: '${_userName.isNotEmpty ? _userName : 'UMKM'}! 🏢',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Selamat datang di dashboard UMKM.\nTemukan talenta kreatif terbaik untuk bisnismu.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.82),
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STATS GRID ====================

  Widget _buildStatsGrid() {
    // Hitung proyek berjalan dari data proyek nyata sebagai fallback
    final activeFromProjects = _recentProjects
        .where((p) =>
            p.status == 'hired' ||
            p.status == 'in_progress' ||
            p.status == 'ongoing')
        .length;

    final activeCount = (_dashboardStats?.activeProjects ?? 0) > 0
        ? _dashboardStats!.activeProjects
        : activeFromProjects;

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
          value: activeCount.toString(),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
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

  // ==================== QUICK ACTIONS (vertical list, sesuai desain) ====================

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
        _quickActionTile(
          icon: Icons.add_circle_rounded,
          iconBg: const Color(0xFF1A4B84),
          title: 'Upload Proyek Baru',
          subtitle: 'Mulai cari talenta hari ini',
          isHighlighted: true,
          onTap: _navigateToCreateProject,
        ),
        const SizedBox(height: 8),
        _quickActionTile(
          icon: Icons.person_outline_rounded,
          iconBg: const Color(0xFF5C6BC0),
          title: 'Lengkapi Profil Usaha',
          subtitle: 'Tingkatkan kepercayaan kreator',
          onTap: () => setState(() => _currentIndex = 4),
        ),
        const SizedBox(height: 8),
        _quickActionTile(
          icon: Icons.bar_chart_rounded,
          iconBg: const Color(0xFF006D77),
          title: 'Progress Proyek',
          subtitle: 'Pantau apply dan update progress',
          onTap: () => setState(() => _currentIndex = 3),
        ),
        const SizedBox(height: 8),
        _quickActionTile(
          icon: Icons.access_time_rounded,
          iconBg: const Color(0xFFE29578),
          title: 'Rekomendasi Kreator AI',
          subtitle: 'Cocokkan UMKM dengan kreator terbaik',
          onTap: _navigateToAiRecommendation,
        ),
      ],
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Material(
      color: isHighlighted ? const Color(0xFF1A4B84) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isHighlighted
                ? null
                : Border.all(color: const Color(0xFFEAE7ED), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.white.withOpacity(0.18)
                      : iconBg.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isHighlighted ? Colors.white : iconBg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isHighlighted
                            ? Colors.white
                            : const Color(0xFF1B1B1F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isHighlighted
                            ? Colors.white70
                            : const Color(0xFF424750),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isHighlighted
                    ? Colors.white60
                    : const Color(0xFF424750).withOpacity(0.4),
              ),
            ],
          ),
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
                Icon(Icons.auto_awesome,
                    size: 16, color: const Color(0xFFE29578)),
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
                Icon(Icons.people_outline,
                    size: 36,
                    color: const Color(0xFF424750).withOpacity(0.3)),
                const SizedBox(height: 6),
                Text(
                  'Belum ada rekomendasi',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: const Color(0xFF424750)),
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
        border:
            Border.all(color: const Color(0xFFEAE7ED).withOpacity(0.6)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CreativeDetailPage(creativeId: creative['id'] ?? ''),
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
                        image: (photo as String).isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(photo),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: photo.isEmpty
                          ? Center(
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
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
                            style: GoogleFonts.inter(
                                fontSize: 10, color: const Color(0xFF424750)),
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
                    Icon(Icons.star_rounded,
                        size: 11, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      (rating as double).toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B1B1F),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.location_on_outlined,
                        size: 9,
                        color:
                            const Color(0xFF424750).withOpacity(0.5)),
                    const SizedBox(width: 1),
                    Expanded(
                      child: Text(
                        city,
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            color: const Color(0xFF424750)
                                .withOpacity(0.6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if ((relevanceScore as double) > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF006D77).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up,
                            size: 9, color: const Color(0xFF006D77)),
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

  // ==================== RECENT PROJECTS ====================

  Widget _buildRecentProjectsSection() {
    final activeProjects = _recentProjects
        .where((p) =>
            p.status == 'hired' ||
            p.status == 'in_progress' ||
            p.status == 'ongoing')
        .toList();

    if (activeProjects.isEmpty) return const SizedBox.shrink();

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
        ...activeProjects.map((project) => _statusKerjasamaCard(project)),
      ],
    );
  }

  Widget _statusKerjasamaCard(Project project) {
    String statusLabel;
    Color statusColor;
    IconData statusIcon;

    switch (project.status) {
      case 'hired':
        statusLabel = 'UNDANGAN DITERIMA';
        statusColor = const Color(0xFF006D77);
        statusIcon = Icons.handshake_outlined;
        break;
      case 'in_progress':
      case 'ongoing':
        statusLabel = 'SEDANG BERJALAN';
        statusColor = const Color(0xFFE29578);
        statusIcon = Icons.trending_up;
        break;
      default:
        statusLabel = project.status.toUpperCase();
        statusColor = const Color(0xFF424750);
        statusIcon = Icons.work_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.08), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _navigateToProjectDetail(project),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon,
                              size: 10, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (project.applicantCount != null &&
                        project.applicantCount! > 0)
                      Row(
                        children: [
                          Icon(Icons.people_outline,
                              size: 12,
                              color: const Color(0xFF424750)),
                          const SizedBox(width: 3),
                          Text(
                            '${project.applicantCount} apply',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF424750)),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  project.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF1B1B1F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.attach_money,
                        size: 13, color: const Color(0xFF006D77)),
                    Text(
                      project.budget,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF006D77),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        project.status == 'hired'
                            ? 'Bayar Sekarang'
                            : 'Lihat Detail',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyProjectState() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Icon(Icons.folder_open_outlined,
              size: 40,
              color: const Color(0xFF424750).withOpacity(0.4)),
          const SizedBox(height: 10),
          Text(
            'Belum ada proyek',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: const Color(0xFF424750),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Unggah proyek pertamamu untuk\nmenemukan talenta terbaik.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF424750),
                height: 1.4),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _navigateToCreateProject,
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text('Buat Proyek'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A4B84),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

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
      appBar: _buildAppBar(),
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
        selectedLabelStyle:
            GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Eksplor'),
          BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Rekomen AI'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Status Proyek'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil'),
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
        return 'Status Proyek';
      case 4:
        return 'Profil';
      default:
        return 'Konekin';
    }
  }
}

// ==================== NOTIFICATIONS BOTTOM SHEET ====================

class _NotificationsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final VoidCallback onMarkAllRead;

  const _NotificationsSheet({
    required this.notifications,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifikasi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1B1F),
                  ),
                ),
                if (notifications.any((n) => n['read_at'] == null))
                  TextButton(
                    onPressed: onMarkAllRead,
                    child: Text(
                      'Tandai semua dibaca',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF1A4B84),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none_outlined,
                            size: 40,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada notifikasi',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, indent: 58),
                    itemBuilder: (ctx, i) {
                      final notif = notifications[i];
                      final isUnread = notif['read_at'] == null;
                      final title =
                          notif['data']?['title']?.toString() ??
                              notif['title']?.toString() ??
                              'Notifikasi';
                      final body =
                          notif['data']?['body']?.toString() ??
                              notif['body']?.toString() ??
                              '';
                      return Container(
                        color: isUnread
                            ? const Color(0xFF1A4B84).withOpacity(0.04)
                            : Colors.transparent,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isUnread
                                  ? const Color(0xFF1A4B84)
                                      .withOpacity(0.1)
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_outlined,
                              size: 18,
                              color: isUnread
                                  ? const Color(0xFF1A4B84)
                                  : Colors.grey,
                            ),
                          ),
                          title: Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: const Color(0xFF1B1B1F),
                            ),
                          ),
                          subtitle: body.isNotEmpty
                              ? Text(
                                  body,
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF424750)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: isUnread
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1A4B84),
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
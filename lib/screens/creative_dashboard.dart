import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/dashboard_model.dart';
import '../models/project_model.dart';
import 'explore_projects.dart';
import 'my_projects.dart';
import 'portfolio_page.dart';
import 'edit_profile.dart';

class CreativeDashboard extends StatefulWidget {
  const CreativeDashboard({super.key});

  @override
  State<CreativeDashboard> createState() => _CreativeDashboardState();
}

class _CreativeDashboardState extends State<CreativeDashboard> {
  final AuthService _auth = AuthService();
  final ApiService _api = ApiService();
  
  // User Data
  Map<String, dynamic> _userData = {};
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userCity = '';
  String _userType = '';
  String _userBio = '';
  
  // Dashboard Stats
  CreativeDashboardData? _dashboardStats;
  
  // Recommended Projects
  List<Project> _recommendedProjects = [];
  
  // Loading States
  bool _isLoading = true;
  bool _isLoggingOut = false;
  
  // Dummy recommended projects untuk sementara jika API belum siap
  final List<Map<String, dynamic>> _dummyProjects = [
    {
      'id': 1,
      'title': 'Desain Logo untuk Cafe',
      'description': 'Mencari desainer logo untuk cafe modern dengan konsep minimalis.',
      'budget': 'Rp 1.000.000 - 2.000.000',
      'duration': '1 minggu',
      'status': 'open',
      'skills': ['Logo Design', 'Illustrator'],
    },
    {
      'id': 2,
      'title': 'Social Media Content Creator',
      'description': 'Membuat konten Instagram untuk produk fashion.',
      'budget': 'Rp 500.000 - 1.000.000',
      'duration': '2 minggu',
      'status': 'open',
      'skills': ['Content Creation', 'Canva', 'Copywriting'],
    },
    {
      'id': 3,
      'title': 'Website UMKM',
      'description': 'Membangun website sederhana untuk UMKM makanan.',
      'budget': 'Rp 3.000.000 - 5.000.000',
      'duration': '1 bulan',
      'status': 'open',
      'skills': ['Web Development', 'HTML/CSS', 'JavaScript'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUserData(),
      _loadDashboardStats(),
      _loadRecommendedProjects(),
    ]);
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    final userData = await _auth.getUserData();
    final name = await _auth.getUserName();
    final email = await _auth.getUserEmail();
    final userType = await _auth.getUserType();
    
    setState(() {
      _userData = userData ?? {};
      _userName = name ?? 'Creative Worker';
      _userEmail = email ?? '-';
      _userPhone = _userData['phone'] ?? '-';
      _userCity = _userData['city'] ?? '-';
      _userType = userType ?? 'creative_worker';
      _userBio = _userData['bio'] ?? '';
    });
  }

  Future<void> _loadDashboardStats() async {
    final result = await _api.getCreativeDashboard();
    
    if (mounted && result['success'] && result['data'] != null) {
      setState(() {
        _dashboardStats = CreativeDashboardData.fromJson(result['data']);
      });
    }
  }

  Future<void> _loadRecommendedProjects() async {
    try {
      final result = await _api.getProjects();
      
      if (mounted && result['success'] == true && result['data'] != null) {
        dynamic data = result['data'];
        List<dynamic> projectsArray = [];
        
        if (data is Map) {
          if (data.containsKey('projects')) {
            if (data['projects'] is List) {
              projectsArray = data['projects'] as List;
            }
          } else if (data.containsKey('data')) {
            if (data['data'] is List) {
              projectsArray = data['data'] as List;
            }
          }
        } else if (data is List) {
          projectsArray = data;
        }
        
        if (projectsArray.isNotEmpty) {
          final List<Project> tempProjects = [];
          for (var item in projectsArray) {
            if (item is Map) {
              try {
                final safeItem = Map<String, dynamic>.from(item);
                if (safeItem['id'] is String) {
                  safeItem['id'] = int.tryParse(safeItem['id']) ?? 0;
                }
                tempProjects.add(Project.fromJson(safeItem));
              } catch (e) {
                print('Error parsing item: $e');
              }
            }
          }
          setState(() {
            _recommendedProjects = tempProjects.take(3).toList();
          });
        } else {
          // Gunakan dummy data jika API tidak mengembalikan data
          _loadDummyProjects();
        }
      } else {
        _loadDummyProjects();
      }
    } catch (e) {
      print('Error in _loadRecommendedProjects: $e');
      _loadDummyProjects();
    }
  }
  
  void _loadDummyProjects() {
    final List<Project> tempProjects = [];
    for (var item in _dummyProjects) {
      tempProjects.add(Project(
        id: item['id'],
        title: item['title'],
        description: item['description'],
        budget: item['budget'],
        duration: item['duration'],
        status: item['status'],
        category: 'General',
        skills: List<String>.from(item['skills']),
        createdAt: DateTime.now(),
      ));
    }
    setState(() {
      _recommendedProjects = tempProjects;
    });
  }

  Future<void> _showLogoutConfirmation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red.shade400, size: 28),
              const SizedBox(width: 12),
              Text(
                'Konfirmasi Logout',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: const Color(0xFF1B1B1F),
                ),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF424750),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF424750),
              ),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    final result = await _auth.logout();
    
    if (mounted) {
      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      
      if (result['success']) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  void _navigateTo(String route, {Object? arguments}) {
  Navigator.push(context, MaterialPageRoute(
    builder: (context) {
      switch (route) {
        case '/explore-projects':
          return const ExploreProjectsPage();
        case '/my-projects':
          return MyProjectsPage(userType: 'creative');
        case '/portfolio':
          return const PortfolioPage();
        case '/edit-profile':
          // PERBAIKAN: Hapus const
          return EditProfilePage();
        default:
          return const SizedBox.shrink();
      }
    },
  )).then((_) => _refreshData());
}

  Future<void> _refreshData() async {
    await _loadDashboardStats();
    await _loadRecommendedProjects();
  }

  void _showDevelopmentMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur dalam pengembangan'),
        backgroundColor: Color(0xFF424750),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          'Creative Dashboard',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B1B1F),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF424750)),
            onPressed: _showDevelopmentMessage,
          ),
          _isLoggingOut
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF006D77),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFF424750)),
                  onPressed: _showLogoutConfirmation,
                  tooltip: 'Logout',
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header dengan gradient hijau tosca
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF006D77), Color(0xFF83C5BE)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Bekerja,',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Creative Worker',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_userBio.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    _userBio,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Statistik
                    Text(
                      'Statistik',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1B1F),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            title: 'Proyek Selesai',
                            value: _dashboardStats?.completedProjects.toString() ?? '0',
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF006D77),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            title: 'Proyek Aktif',
                            value: _dashboardStats?.ongoingProjects.toString() ?? '0',
                            icon: Icons.hourglass_empty,
                            color: const Color(0xFF83C5BE),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            title: 'Rating',
                            value: _dashboardStats?.rating.toString() ?? '0.0',
                            icon: Icons.star_outline,
                            color: const Color(0xFFE29578),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            title: 'Total Earnings',
                            value: 'Rp ${((_dashboardStats?.totalEarnings ?? 0) / 1000).toStringAsFixed(0)}k',
                            icon: Icons.monetization_on_outlined,
                            color: const Color(0xFF006D77),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Profile Performance (if available)
                    if (_dashboardStats != null && (_dashboardStats!.profileViews > 0 || _dashboardStats!.newConnections > 0))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Performa Profile',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B1B1F),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _infoCard(
                                  title: 'Profile Views',
                                  value: _dashboardStats!.profileViews.toString(),
                                  icon: Icons.visibility_outlined,
                                  color: const Color(0xFF006D77),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _infoCard(
                                  title: 'New Connections',
                                  value: _dashboardStats!.newConnections.toString(),
                                  icon: Icons.people_outline,
                                  color: const Color(0xFF83C5BE),
                                  suffix: _dashboardStats!.newConnections > 0
                                      ? '+${((_dashboardStats!.newConnections / 10).ceil())}%'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),

                    // Info Akun
                    Text(
                      'Informasi Akun',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1B1F),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _infoRow(Icons.email_outlined, 'Email', _userEmail),
                            const Divider(),
                            _infoRow(Icons.phone_outlined, 'Telepon', _userPhone),
                            const Divider(),
                            _infoRow(Icons.location_on_outlined, 'Kota', _userCity),
                            const Divider(),
                            _infoRow(Icons.brush_outlined, 'Tipe', 'Creative Worker'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recommended Projects
                    if (_recommendedProjects.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rekomendasi Proyek',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B1B1F),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _navigateTo('/explore-projects'),
                            child: Text(
                              'Lihat semua',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF006D77),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._recommendedProjects.map((project) => _recommendedProjectCard(project)),
                    ],

                    const SizedBox(height: 24),

                    // Menu Cepat
                    Text(
                      'Menu Cepat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1B1F),
                      ),
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _menuCard(
                          icon: Icons.search_outlined,
                          title: 'Cari Proyek',
                          color: const Color(0xFF006D77),
                          onTap: () => _navigateTo('/explore-projects'),
                        ),
                        _menuCard(
                          icon: Icons.work_outline,
                          title: 'Proyek Saya',
                          color: const Color(0xFF83C5BE),
                          onTap: () => _navigateTo('/my-projects'),
                        ),
                        _menuCard(
                          icon: Icons.photo_library_outlined,
                          title: 'Portfolio',
                          color: const Color(0xFFE29578),
                          onTap: () => _navigateTo('/portfolio'),
                        ),
                        _menuCard(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          color: const Color(0xFF006D77),
                          onTap: () => _navigateTo('/edit-profile'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _recommendedProjectCard(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC3C6D1).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF006D77).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  project.status == 'open' ? 'OPEN' : project.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF006D77),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project.description.length > 80
                ? '${project.description.substring(0, 80)}...'
                : project.description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF424750),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.attach_money, size: 14, color: const Color(0xFF006D77)),
              const SizedBox(width: 4),
              Text(
                project.budget,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF006D77),
                ),
              ),
              const Spacer(),
              Text(
                project.duration,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF424750),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.access_time, size: 12, color: const Color(0xFF424750)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Text(
                  suffix,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF424750)),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF424750),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1B1B1F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
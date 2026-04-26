import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/dashboard_model.dart';
import '../models/project_model.dart';
import 'explore_projects.dart';
import 'my_projects.dart';
import 'edit_profile.dart';
import 'create_project.dart';

class UmkmDashboard extends StatefulWidget {
  const UmkmDashboard({super.key});

  @override
  State<UmkmDashboard> createState() => _UmkmDashboardState();
}

class _UmkmDashboardState extends State<UmkmDashboard> {
  final AuthService _auth = AuthService();
  final ApiService _api = ApiService();
  
  // User Data
  Map<String, dynamic> _userData = {};
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userCity = '';
  String _userType = '';
  
  // Dashboard Stats
  UMKMKDashboardData? _dashboardStats;
  
  // Recent Projects
  List<Project> _recentProjects = [];
  
  // Loading States
  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUserData(),
      _loadDashboardStats(),
      _loadRecentProjects(),
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
      _userName = name ?? 'Pengguna UMKM';
      _userEmail = email ?? '-';
      _userPhone = _userData['phone'] ?? '-';
      _userCity = _userData['city'] ?? '-';
      _userType = userType ?? 'umkm';
    });
  }

  Future<void> _loadDashboardStats() async {
    final result = await _api.getUMKMDashboard();
    
    if (mounted && result['success'] && result['data'] != null) {
      setState(() {
        _dashboardStats = UMKMKDashboardData.fromJson(result['data']);
      });
    }
  }

  Future<void> _loadRecentProjects() async {
    final result = await _api.getProjects();
    
    if (mounted && result['success'] && result['data'] != null) {
      final projectsData = result['data']['projects'] ?? result['data'];
      if (projectsData is List) {
        setState(() {
          _recentProjects = projectsData.take(3).map((e) => Project.fromJson(e)).toList();
        });
      }
    }
  }

  // ── Logout dengan Konfirmasi ───────────────────────────────────────────────

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
          case '/create-project':
            return const CreateProjectPage();
          case '/my-projects':
            return MyProjectsPage(userType: 'umkm');
          case '/edit-profile':
            return EditProfilePage(userData: _userData);
          case '/explore-talents':
            // TODO: Implement talent search page
            _showDevelopmentMessage();
            return const SizedBox.shrink();
          default:
            return const SizedBox.shrink();
        }
      },
    )).then((_) => _refreshData());
  }

  Future<void> _refreshData() async {
    await _loadDashboardStats();
    await _loadRecentProjects();
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
          'Dashboard UMKM',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B1B1F),
        elevation: 0,
        actions: [
          // Notification Icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF424750)),
            onPressed: _showDevelopmentMessage,
          ),
          // Logout button dengan loading indicator
          _isLoggingOut
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1A4B84),
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
                    // Header dengan gradient
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF003466), Color(0xFF1A4B84)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang,',
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
                              'UMKM Account',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Statistik Section
                    Text(
                      'Ringkasan',
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
                            title: 'Proyek Aktif',
                            value: _dashboardStats?.activeProjects.toString() ?? '0',
                            icon: Icons.work_outline,
                            color: const Color(0xFF003466),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            title: 'Total Spend',
                            value: 'Rp ${((_dashboardStats?.totalSpend ?? 0) / 1000).toStringAsFixed(0)}k',
                            icon: Icons.attach_money,
                            color: const Color(0xFF1A4B84),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            title: 'Total Pelamar',
                            value: _dashboardStats?.totalApplicants.toString() ?? '0',
                            icon: Icons.people_outline,
                            color: const Color(0xFF68FADD),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            title: 'Rating',
                            value: _dashboardStats?.rating.toString() ?? '0.0',
                            icon: Icons.star_outline,
                            color: const Color(0xFFE29578),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

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
                            _infoRow(Icons.badge_outlined, 'Tipe', _userType),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recent Projects
                    if (_recentProjects.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Proyek Terbaru',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B1B1F),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _navigateTo('/my-projects'),
                            child: Text(
                              'Lihat semua',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1A4B84),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._recentProjects.map((project) => _recentProjectCard(project)),
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
                          icon: Icons.add_circle_outline,
                          title: 'Buat Proyek',
                          color: const Color(0xFF003466),
                          onTap: () => _navigateTo('/create-project'),
                        ),
                        _menuCard(
                          icon: Icons.work_outline,
                          title: 'Proyek Saya',
                          color: const Color(0xFF1A4B84),
                          onTap: () => _navigateTo('/my-projects'),
                        ),
                        _menuCard(
                          icon: Icons.people_outline,
                          title: 'Cari Talent',
                          color: const Color(0xFF68FADD),
                          onTap: () => _navigateTo('/explore-talents'),
                        ),
                        _menuCard(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          color: const Color(0xFFE29578),
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

  Widget _recentProjectCard(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC3C6D1).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFEAE7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.work, color: Color(0xFF1A4B84)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Budget: ${project.budget}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF006D77),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: project.status == 'open'
                  ? const Color(0xFF006D77).withOpacity(0.1)
                  : const Color(0xFFE29578).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              project.status == 'open' ? 'OPEN' : project.status.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: project.status == 'open' ? const Color(0xFF006D77) : const Color(0xFFE29578),
              ),
            ),
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
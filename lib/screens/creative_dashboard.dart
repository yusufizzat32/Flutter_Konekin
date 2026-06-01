// lib/screens/creative_dashboard.dart
// ============================================================================
// CREATIVE DASHBOARD - Halaman Utama untuk Creative Worker
// Dengan navigasi lengkap ke Explore, Projects, Portofolio, dan Profile
// DILENGKAPI DENGAN NOTIFIKASI
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widget/bottom_nav_bar.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/project_progress_service.dart';
import '../services/escrow_service.dart';
import '../providers/notification_provider.dart';
import '../screens/notifications_screen.dart';
import 'explore_screen.dart';
import 'creative_profile_screen.dart';
import 'creative_projects_screen.dart';
import 'creative_portfolio_screen.dart';
import '../models/project_progress_model.dart';
import '../models/escrow_model.dart';
import '../models/projectcr_model.dart';
import '../services/project_service.dart';

class CreativeDashboard extends StatefulWidget {
  const CreativeDashboard({super.key});

  @override
  State<CreativeDashboard> createState() => _CreativeDashboardState();
}

class _CreativeDashboardState extends State<CreativeDashboard> {
  int _currentNavIndex = 0;
  String _userName = '';
  bool _isLoading = true;
  bool _isLoggingOut = false;
  bool _isLoadingDashboardData = false;
  late final PageController _pageController;
  
  // Dashboard data dari API
  EarningsSummary? _earnings;
  List<ProjectProgressModel> _recentProjects = [];
  int _activeProjectsCount = 0;
  List<Project> _recommendedProjects = [];
  bool _isLoadingRecommended = false;

  List<Widget> get _pages => [
    _buildDashboardContent(),
    const ExploreScreen(),
    const CreativePortfolioScreen(),
    const CreativeProjectsScreen(),
    const CreativeProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadUserData();
    _loadDashboardData();
    
    // Load notifikasi dan start periodic refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      provider.loadNotifications();
      provider.startPeriodicRefresh();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // DATA LOADING
  // ==========================================================================

  Future<void> _loadUserData() async {
    debugPrint('🟡 Loading user data...');
    
    try {
      final authService = AuthService();
      
      String? userName = await authService.getUserName();
      debugPrint('🟡 User name from SharedPreferences: $userName');
      
      if (userName == null || userName.isEmpty) {
        debugPrint('🟡 Fetching from API...');
        final profileResult = await authService.getProfile();
        if (profileResult['success'] == true) {
          final userData = profileResult['data'];
          userName = userData['name'] ?? 'Creative Worker';
          debugPrint('🟡 Got user name from API: $userName');
        } else {
          userName = 'Creative Worker';
          debugPrint('🟡 Using default name');
        }
      }
      
      if (mounted) {
        setState(() {
          _userName = userName ?? 'Creative Worker';
          _isLoading = false;
        });
        debugPrint('✅ User loaded: $_userName');
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      if (mounted) {
        setState(() {
          _userName = 'Creative Worker';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDashboardData() async {
    if (_isLoadingDashboardData) return;
    
    setState(() {
      _isLoadingDashboardData = true;
      _isLoadingRecommended = true;
    });
    
    try {
      final escrowService = EscrowService();
      final projectProgressService = ProjectProgressService();
      final projectService = ProjectService();
      
      // Load earnings
      final earningsResult = await escrowService.getEarnings();
      if (earningsResult['success'] == true && mounted) {
        setState(() {
          _earnings = earningsResult['earnings'];
        });
      }
      
      // Load recent projects (my projects)
      final projectsResult = await projectProgressService.getCreativeProjects();
      if (projectsResult['success'] == true && mounted) {
        final List<ProjectProgressModel> allProjects = projectsResult['projects'];
        setState(() {
          _recentProjects = allProjects.take(3).toList();
          _activeProjectsCount = allProjects.where((p) => p.isActive).length;
        });
      }

      // Load recommended projects (open projects from API)
      final recommendedResult = await projectService.getProjects(page: 1);
      if (recommendedResult['success'] == true && mounted) {
        final List<Project> allOpen = recommendedResult['projects'] as List<Project>;
        setState(() {
          _recommendedProjects = allOpen.take(6).toList();
        });
      }
      
    } catch (e) {
      debugPrint('❌ Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDashboardData = false;
          _isLoadingRecommended = false;
        });
      }
    }
  }

  // ==========================================================================
  // LOGOUT HANDLER
  // ==========================================================================

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red[400],
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Konfirmasi Logout',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) Navigator.of(context).pop(false);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
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
                if (mounted) Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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

    if (shouldLogout == true && mounted) {
      setState(() => _isLoggingOut = true);

      try {
        final apiService = ApiService();
        await apiService.logout();
        
        final authService = AuthService();
        await authService.clearToken();
        await authService.clearUserData();
        
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Berhasil logout')),
              ],
            ),
            backgroundColor: Color(0xFF20C997),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/get-started',
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Logout error: $e');
        final authService = AuthService();
        await authService.clearToken();
        await authService.clearUserData();
        
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/get-started',
            (route) => false,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoggingOut = false);
        }
      }
    }
  }

  void _showLogoutMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(30, 80, 20, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      items: [
        PopupMenuItem(
          value: 'logout',
          onTap: _logout,
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red[400],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[400],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getInitials() {
    if (_userName.isEmpty || _userName == 'Creative Worker') return 'CW';
    
    final List<String> nameParts = _userName.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'CW';
  }

  // ==========================================================================
  // DASHBOARD CONTENT
  // ==========================================================================

  Widget _buildDashboardContent() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF003466),
          onRefresh: () async {
            await _loadUserData();
            await _loadDashboardData();
            if (!mounted) return;
            // ignore: use_build_context_synchronously
            Provider.of<NotificationProvider>(context, listen: false)
                .loadNotifications();
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildWalletCard(),
                const SizedBox(height: 28),
                _buildRecommendedSection(),
                const SizedBox(height: 28),
                _buildRecentProjects(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // HEADER SECTION WITH NOTIFICATION
  // ==========================================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF003466),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _getInitials(),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                if (_isLoading)
                  Container(
                    width: 120,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                else
                  Text(
                    _userName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1F),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // ✅ NOTIFICATION ICON WITH UNREAD BADGE
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      ).then((_) {
                        // Refresh notifications when returning
                        provider.loadNotifications();
                      });
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8ECF0)),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFF6B7280),
                        size: 22,
                      ),
                    ),
                  ),
                  if (provider.hasUnread)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _isLoggingOut ? null : _showLogoutMenu,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8ECF0)),
              ),
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                      ),
                    )
                  : Icon(
                      Icons.logout_rounded,
                      color: Colors.red[400],
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // WALLET CARD
  // ==========================================================================

  Widget _buildWalletCard() {
    final String balanceDisplay = _earnings != null 
        ? _earnings!.formattedTotalEarned 
        : 'Rp 0';
    
    final String earnedDisplay = _earnings != null
        ? 'Rp ${(_earnings!.totalEarned / 1000).toStringAsFixed(0)}rb'
        : 'Rp 0';
    
    final int activeProjects = _activeProjectsCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF003466), Color(0xFF0056A8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF003466).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Total Pendapatan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              balanceDisplay,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROJECT AKTIF',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$activeProjects',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL EARNED',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        earnedDisplay,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF20C997),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentNavIndex = 3;
                      _pageController.jumpToPage(3);
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF20C997),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // RECOMMENDED PROJECTS SECTION
  // ==========================================================================

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                '✨ Rekomendasi Project',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B1B1F),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentNavIndex = 1;
                    _pageController.jumpToPage(1);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF20C997).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Lihat Semua',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF20C997),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF20C997),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 210,
          child: _isLoadingRecommended
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 20, right: 12),
                  itemCount: 3,
                  itemBuilder: (_, __) => _SkeletonProjectCard(),
                )
              : _recommendedProjects.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Text(
                          'Belum ada proyek tersedia',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 20, right: 12),
                      itemCount: _recommendedProjects.length,
                      itemBuilder: (context, index) {
                        final project = _recommendedProjects[index];
                        // deadline sudah berupa getter String dari projectcr_model
                        final deadlineLabel = project.deadlineLabel;
                        // budget sudah ada getter formattedBudget dari projectcr_model
                        final budgetLabel = project.formattedBudget;
                        // business dari clientName (projectcr_model)
                        final businessLabel = project.clientName.isNotEmpty
                            ? project.clientName
                            : 'UMKM';
                        return _ProjectCard(
                          category: project.category.toUpperCase(),
                          title: project.title,
                          business: businessLabel,
                          budget: budgetLabel,
                          deadline: deadlineLabel,
                          onTap: () {
                            setState(() {
                              _currentNavIndex = 1;
                              _pageController.jumpToPage(1);
                            });
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ==========================================================================
  // RECENT PROJECTS SECTION
  // ==========================================================================

  Widget _buildRecentProjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                '📋 Proyek Terbaru Saya',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B1B1F),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentNavIndex = 3;
                    _pageController.jumpToPage(3);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003466).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Lihat Semua',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF003466),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF003466),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingDashboardData)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _SkeletonActivityCard(),
                const SizedBox(height: 12),
                _SkeletonActivityCard(),
              ],
            ),
          )
        else if (_recentProjects.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECF0)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.work_outline_rounded,
                    size: 48,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada proyek',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ayo cari dan lamar proyek pertama Anda!',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentNavIndex = 1;
                        _pageController.jumpToPage(1);
                      });
                    },
                    icon: const Icon(Icons.explore_rounded, size: 18),
                    label: Text(
                      'Cari Proyek',
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
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: _recentProjects.map((project) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecentProjectCard(
                    project: project,
                    onTap: () {
                      setState(() {
                        _currentNavIndex = 3;
                        _pageController.jumpToPage(3);
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ==========================================================================
  // MAIN BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
              },
              physics: const NeverScrollableScrollPhysics(),
              children: _pages,
            ),
          ),
          BottomNavBar(
            currentIndex: _currentNavIndex,
            onTap: (index) {
              setState(() {
                _currentNavIndex = index;
                _pageController.jumpToPage(index);
              });
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// PROJECT CARD COMPONENT
// ==========================================================================

class _ProjectCard extends StatelessWidget {
  final String category;
  final String title;
  final String business;
  final String budget;
  final String deadline;
  final VoidCallback? onTap;

  const _ProjectCard({
    required this.category,
    required this.title,
    required this.business,
    required this.budget,
    required this.deadline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8ECF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF003466),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.bookmark_border_rounded,
                  size: 20,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B1B1F),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              business,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF6B7280),
              ),
            ),
            const Spacer(),
            const SizedBox(height: 12),
            const Divider(
              color: Color(0xFFE8ECF0),
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    budget,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF003466),
                    ),
                  ),
                ),
                if (deadline.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      deadline,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFFD97706),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// RECENT PROJECT CARD COMPONENT
// ==========================================================================

class _RecentProjectCard extends StatelessWidget {
  final ProjectProgressModel project;
  final VoidCallback onTap;

  const _RecentProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    
    if (project.isActive) {
      statusColor = const Color(0xFF3B82F6);
      statusText = 'ONGOING';
    } else if (project.isWaitingPayment) {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'PENDING';
    } else {
      statusColor = const Color(0xFF20C997);
      statusText = 'COMPLETED';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                project.isActive ? Icons.edit_document : 
                (project.isWaitingPayment ? Icons.hourglass_empty : Icons.check_circle_outline),
                color: statusColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.attach_money_rounded, size: 14, color: const Color(0xFF20C997)),
                      const SizedBox(width: 4),
                      Text(
                        project.formattedBudget,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF003466),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.percent_rounded, size: 12, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        '${project.progressPercentage}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// SKELETON PROJECT CARD (for recommended section)
// ==========================================================================

class _SkeletonProjectCard extends StatelessWidget {
  const _SkeletonProjectCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF0),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 160,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Container(
            width: 100,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE8ECF0), thickness: 1, height: 1),
          const SizedBox(height: 10),
          Container(
            width: 120,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// SKELETON LOADER
// ==========================================================================

class _SkeletonActivityCard extends StatelessWidget {
  const _SkeletonActivityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF0),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECF0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECF0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF0),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}
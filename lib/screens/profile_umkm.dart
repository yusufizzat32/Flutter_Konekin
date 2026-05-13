// lib/screens/profile_umkm.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/dashboard_model.dart';
import 'edit_profile.dart';

class ProfileUmkmPage extends StatefulWidget {
  const ProfileUmkmPage({super.key});

  @override
  State<ProfileUmkmPage> createState() => _ProfileUmkmPageState();
}

class _ProfileUmkmPageState extends State<ProfileUmkmPage> {
  final AuthService _auth = AuthService();
  final ApiService _api = ApiService();
  
  Map<String, dynamic> _userData = {};
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userCity = '';
  String _userType = '';
  String _userAvatar = '';
  String _userBio = '';
  String _userBusinessName = '';
  String _userBusinessAddress = '';
  
  UMKMKDashboardData? _dashboardStats;
  
  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    await Future.wait([
      _loadUserData(),
      _loadDashboardStats(),
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
      _userName = name ?? 'Nama UMKM';
      _userEmail = email ?? '-';
      _userPhone = _userData['phone'] ?? '-';
      _userCity = _userData['city'] ?? '-';
      _userType = userType ?? 'umkm';
      _userAvatar = _userData['profile_photo'] ?? _userData['avatar'] ?? '';
      _userBio = _userData['bio'] ?? '';
      _userBusinessName = _userData['business_name'] ?? _userData['name'] ?? '';
      _userBusinessAddress = _userData['address'] ?? _userData['city'] ?? '';
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

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          userData: {
            'name': _userName,
            'phone': _userPhone,
            'city': _userCity,
            'bio': _userBio,
            'profile_photo': _userAvatar,
            'business_name': _userBusinessName,
            'address': _userBusinessAddress,
          },
        ),
      ),
    ).then((_) => _loadProfileData());
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
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF424750)),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    final result = await _auth.logout();
    
    if (mounted) {
      setState(() => _isLoggingOut = false);
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Header
                    _buildProfileHeader(),
                    
                    const SizedBox(height: 20),
                    
                    // Stats
                    _buildStatsRow(),
                    
                    const SizedBox(height: 24),
                    
                    // Informasi Usaha
                    _buildBusinessInfo(),
                    
                    const SizedBox(height: 24),
                    
                    // Tombol Edit Profil
                    _buildEditProfileButton(),
                    
                    const SizedBox(height: 20),
                    
                    // Tombol Logout di Paling Bawah
                    _buildLogoutButton(),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003466), Color(0xFF1A4B84)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4B84).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
                  image: _userAvatar.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(_userAvatar),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _userAvatar.isEmpty
                    ? Center(
                        child: Text(
                          _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _navigateToEditProfile,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Color(0xFF1A4B84),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            _userName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Pemilik UMKM',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  _dashboardStats?.completedProjects.toString() ?? '0',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A4B84),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Proyek',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF424750),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: const Color(0xFFEAE7ED)),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, size: 28, color: Colors.amber.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _dashboardStats?.rating.toString() ?? '0.0',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A4B84),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Rating',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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

  Widget _buildBusinessInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Usaha',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.store, 'Nama Usaha', _userBusinessName.isNotEmpty ? _userBusinessName : _userName),
          const Divider(height: 20),
          _buildInfoRow(Icons.email_outlined, 'Email', _userEmail),
          const Divider(height: 20),
          _buildInfoRow(Icons.phone_outlined, 'Telepon', _userPhone),
          const Divider(height: 20),
          _buildInfoRow(Icons.location_on_outlined, 'Lokasi Usaha', _userBusinessAddress.isNotEmpty ? _userBusinessAddress : _userCity),
          if (_userBio.isNotEmpty) ...[
            const Divider(height: 20),
            _buildInfoRow(Icons.description_outlined, 'Bio / Deskripsi', _userBio),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1A4B84).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1A4B84)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF424750),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1B1B1F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _navigateToEditProfile,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(
          'Edit Profil',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A4B84),
          side: const BorderSide(color: Color(0xFF1A4B84)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoggingOut ? null : _showLogoutConfirmation,
        icon: _isLoggingOut
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
              )
            : const Icon(Icons.logout_rounded, size: 18),
        label: Text(
          _isLoggingOut ? 'Keluar...' : 'Keluar',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
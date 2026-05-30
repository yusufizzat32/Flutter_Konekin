import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  final ImagePicker _picker = ImagePicker();
  final MapController _mapController = MapController();

  // ── User data ──────────────────────────────────────────────────────────────
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
  String _businessDescription = '';
  double? _latitude;
  double? _longitude;

  UMKMKDashboardData? _dashboardStats;

  // ── State flags ────────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isLoggingOut = false;
  bool _isUploadingPhoto = false;
  bool _isEditingDescription = false;
  bool _isSavingDescription = false;
  // ── FIX: flag untuk loading lokasi ─────────────────────────────────────────
  bool _isSearchingLocation = false;
  bool _isSavingLocation = false;

  // ── Controllers ────────────────────────────────────────────────────────────
  late TextEditingController _descController;
  late TextEditingController _locationSearchController;

  // ── Constants ──────────────────────────────────────────────────────────────
  static const _primaryBlue = Color(0xFF1A4B84);
  static const _darkBlue = Color(0xFF003466);
  static const _textDark = Color(0xFF1B1B1F);
  static const _textMid = Color(0xFF424750);
  static const _bgPage = Color(0xFFFBF8FE);

  static const LatLng _defaultCenter = LatLng(-2.5489, 118.0149);

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
    _locationSearchController = TextEditingController();
    _loadProfileData();
  }

  @override
  void dispose() {
    _descController.dispose();
    _locationSearchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Data loaders ───────────────────────────────────────────────────────────
  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadUserData(), _loadDashboardStats()]);
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Helper build URL foto absolute ────────────────────────────────────────
  String _buildPhotoUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    final base = AuthService().baseUrl.replaceFirst('/api', '');
    final clean = rawUrl.startsWith('/') ? rawUrl : '/storage/$rawUrl';
    return '$base$clean'.replaceAll('/storage/storage/', '/storage/');
  }

  Future<void> _loadUserData() async {
    final profileResult = await _auth.getProfile();
    if (profileResult['success'] == true && profileResult['data'] != null) {
      await _auth.saveUserData(profileResult['data'] as Map<String, dynamic>);
    }

    final userData = await _auth.getUserData();
    final name = await _auth.getUserName();
    final email = await _auth.getUserEmail();
    final userType = await _auth.getUserType();

    if (!mounted) return;
    setState(() {
      _userData = userData ?? {};
      _userName = name ?? 'Nama UMKM';
      _userEmail = email ?? '-';
      _userPhone = _userData['phone'] ?? '-';
      _userCity = _userData['city'] ?? '-';
      _userType = userType ?? 'umkm';

      final rawPhoto = _userData['profile_photo'] ?? _userData['avatar'] ?? '';
      _userAvatar = _buildPhotoUrl(rawPhoto.toString());

      _userBio = _userData['bio'] ?? '';
      _userBusinessName =
          _userData['business_name'] ?? _userData['name'] ?? '';
      _userBusinessAddress = _userData['address'] ?? _userData['city'] ?? '';

      // ── FIX: baca deskripsi dari semua kemungkinan key ────────────────────
      _businessDescription = _userData['description'] ??
          _userData['business_description'] ??
          _userData['bio'] ??
          '';

      // Koordinat
      final lat = _userData['latitude'];
      final lng = _userData['longitude'];
      if (lat != null && lng != null) {
        _latitude = double.tryParse(lat.toString());
        _longitude = double.tryParse(lng.toString());
      }

      _descController.text = _businessDescription;
      _locationSearchController.text = _userBusinessAddress;
    });
  }

  Future<void> _loadDashboardStats() async {
    final result = await _api.getUMKMDashboard();
    if (mounted && result['success'] == true && result['data'] != null) {
      setState(() {
        _dashboardStats = UMKMKDashboardData.fromJson(result['data']);
      });
    }
  }

  // ── Photo upload ───────────────────────────────────────────────────────────
  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() => _isUploadingPhoto = true);

      final result = await _api.updateProfileWithPhoto(
        {
          'name': _userName,
          'phone': _userPhone,
          'city': _userCity,
          'description': _businessDescription,
          'business_description': _businessDescription,
          'bio': _businessDescription,
          'latitude': _latitude?.toString() ?? '',
          'longitude': _longitude?.toString() ?? '',
          'address': _userBusinessAddress,
        },
        photoBytes: bytes,
      );

      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);

      if (result['success'] == true) {
        final updated = result['data'];
        if (updated is Map<String, dynamic>) {
          await _auth.saveUserData(updated);
        } else {
          await _auth.getProfile();
        }
        await _loadUserData();
        _showSnack('Foto profil berhasil diperbarui', isError: false);
      } else {
        _showSnack(result['message'] ?? 'Gagal upload foto', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        _showSnack('Gagal memilih gambar: $e', isError: true);
      }
    }
  }

  // ── Description save ───────────────────────────────────────────────────────
  Future<void> _saveDescription() async {
    setState(() => _isSavingDescription = true);
    final newDesc = _descController.text.trim();

    // ── FIX: kirim semua key agar backend bisa baca field apapun ─────────────
    final result = await _api.updateProfileWithPhoto(
      {
        'name': _userName,
        'phone': _userPhone,
        'city': _userCity,
        'bio': newDesc,
        'description': newDesc,
        'business_description': newDesc,
        'latitude': _latitude?.toString() ?? '',
        'longitude': _longitude?.toString() ?? '',
        'address': _userBusinessAddress,
      },
    );

    if (!mounted) return;
    setState(() => _isSavingDescription = false);

    if (result['success'] == true) {
      setState(() {
        _businessDescription = newDesc;
        _isEditingDescription = false;
      });
      final updated = result['data'];
      if (updated is Map<String, dynamic>) {
        // ── FIX: update cache lokal ──────────────────────────────────────────
        final merged = Map<String, dynamic>.from(_userData)
          ..addAll({
            'description': newDesc,
            'business_description': newDesc,
            'bio': newDesc,
          })
          ..addAll(updated);
        await _auth.saveUserData(merged);
      }
      _showSnack('Deskripsi bisnis disimpan', isError: false);
    } else {
      _showSnack(result['message'] ?? 'Gagal menyimpan deskripsi', isError: true);
    }
  }

  // ── Location search (Nominatim OSM) ────────────────────────────────────────
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    // ── FIX: set loading state & cegah double-tap ────────────────────────────
    if (_isSearchingLocation) return;
    setState(() => _isSearchingLocation = true);

    try {
      final result = await _api.geocodeAddress(query.trim());

      if (!mounted) return;
      setState(() => _isSearchingLocation = false);

      if (result['success'] == true && result['lat'] != null) {
        final lat = double.parse(result['lat'].toString());
        final lng = double.parse(result['lng'].toString());
        final displayName = result['display_name']?.toString() ?? query;

        setState(() {
          _latitude = lat;
          _longitude = lng;
          _userBusinessAddress = displayName;
          _locationSearchController.text = displayName;
        });

        // ── FIX: pindahkan peta ke lokasi baru ────────────────────────────────
        try {
          _mapController.move(LatLng(lat, lng), 15);
        } catch (_) {
          // MapController belum ready, tidak apa-apa
        }

        // Simpan ke server
        await _saveLocationToServer(lat, lng, displayName);
      } else {
        _showSnack('Lokasi tidak ditemukan, coba nama lain', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearchingLocation = false);
        _showSnack('Gagal mencari lokasi', isError: true);
      }
    }
  }

  Future<void> _saveLocationToServer(
      double lat, double lng, String address) async {
    if (_isSavingLocation) return;
    setState(() => _isSavingLocation = true);

    try {
      final result = await _api.updateProfileWithPhoto({
        'name': _userName,
        'phone': _userPhone,
        'city': _userCity,
        'description': _businessDescription,
        'business_description': _businessDescription,
        'bio': _businessDescription,
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'address': address,
      });

      if (result['success'] == true) {
        final updated = result['data'];
        if (updated is Map<String, dynamic>) {
          final merged = Map<String, dynamic>.from(_userData)
            ..addAll({
              'latitude': lat.toString(),
              'longitude': lng.toString(),
              'address': address,
            })
            ..addAll(updated);
          await _auth.saveUserData(merged);
        }
      }
    } finally {
      if (mounted) setState(() => _isSavingLocation = false);
    }
  }

  void _onMapTap(TapPosition _, LatLng point) {
    setState(() {
      _latitude = point.latitude;
      _longitude = point.longitude;
      _locationSearchController.text =
          '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      _userBusinessAddress = _locationSearchController.text;
    });
    _saveLocationToServer(
        point.latitude, point.longitude, _locationSearchController.text);
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          userData: {
            'name': _userName,
            'phone': _userPhone,
            'city': _userCity,
            'bio': _businessDescription,
            'description': _businessDescription,
            'business_description': _businessDescription,
            'profile_photo': _userAvatar,
            'business_name': _userBusinessName,
            'address': _userBusinessAddress,
          },
        ),
      ),
    ).then((_) => _loadProfileData());
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> _showLogoutConfirmation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red.shade400, size: 28),
            const SizedBox(width: 12),
            Text(
              'Konfirmasi Logout',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: _textDark,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          style: GoogleFonts.inter(fontSize: 14, color: _textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: _textMid),
            child: Text('Batal',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Logout',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    final result = await _auth.logout();
    if (!mounted) return;
    setState(() => _isLoggingOut = false);
    _showSnack(result['message'], isError: result['success'] != true);
    if (result['success'] == true) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _buildBusinessInfo(),
                    const SizedBox(height: 20),
                    _buildDescriptionCard(),
                    const SizedBox(height: 20),
                    _buildLocationCard(),
                    const SizedBox(height: 24),
                    _buildEditProfileButton(),
                    const SizedBox(height: 12),
                    _buildLogoutButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Profile Header ─────────────────────────────────────────────────────────
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkBlue, _primaryBlue],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with upload
          GestureDetector(
            onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
            child: Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: ClipOval(
                    child: _isUploadingPhoto
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : _userAvatar.isNotEmpty
                            ? Image.network(
                                _userAvatar,
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                                headers: const {'Accept': 'image/*'},
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    _userName.isNotEmpty
                                        ? _userName[0].toUpperCase()
                                        : 'U',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  _userName.isNotEmpty
                                      ? _userName[0].toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: _primaryBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _userName,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'UMKM',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final totalProyek = _dashboardStats?.totalProjects ?? 0;
    final proyekBerjalan = _dashboardStats?.activeProjects ?? 0;
    final totalApply = _dashboardStats?.totalApplicants ?? 0;

    return Row(
      children: [
        Expanded(
            child: _statItem('Total Proyek', totalProyek.toString(),
                Icons.folder_open_rounded, _primaryBlue)),
        Container(width: 1, height: 40, color: const Color(0xFFEAE7ED)),
        Expanded(
            child: _statItem('Berjalan', proyekBerjalan.toString(),
                Icons.work_rounded, const Color(0xFF006D77))),
        Container(width: 1, height: 40, color: const Color(0xFFEAE7ED)),
        Expanded(
            child: _statItem('Total Apply', totalApply.toString(),
                Icons.people_rounded, const Color(0xFFE29578))),
      ],
    );
  }

  Widget _statItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: _textMid),
          ),
        ],
      ),
    );
  }

  // ── Business Info ──────────────────────────────────────────────────────────
  Widget _buildBusinessInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Informasi Bisnis'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.store_rounded, 'Nama Bisnis', _userBusinessName),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email_outlined, 'Email', _userEmail),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone_outlined, 'Telepon', _userPhone),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_city_outlined, 'Kota', _userCity),
        ],
      ),
    );
  }

  // ── Description Card ───────────────────────────────────────────────────────
  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Deskripsi Bisnis'),
              if (!_isEditingDescription)
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _isEditingDescription = true),
                  icon: const Icon(Icons.edit_outlined,
                      size: 14, color: _primaryBlue),
                  label: Text(
                    'Edit',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _primaryBlue,
                        fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditingDescription) ...[
            TextField(
              controller: _descController,
              maxLines: 5,
              style: GoogleFonts.inter(fontSize: 13, color: _textDark),
              decoration: InputDecoration(
                hintText:
                    'Ceritakan tentang bisnis Anda, produk/jasa yang ditawarkan, dan keunggulan Anda...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 12, color: _textMid.withOpacity(0.6)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSavingDescription
                      ? null
                      : () {
                          setState(() {
                            _isEditingDescription = false;
                            _descController.text = _businessDescription;
                          });
                        },
                  child: Text('Batal',
                      style: GoogleFonts.inter(
                          color: _textMid, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSavingDescription ? null : _saveDescription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSavingDescription
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Simpan',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ] else ...[
            _businessDescription.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _primaryBlue.withOpacity(0.2),
                          style: BorderStyle.solid),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: _primaryBlue.withOpacity(0.6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tambahkan deskripsi bisnis untuk menarik lebih banyak kreator',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _textMid.withOpacity(0.8),
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    _businessDescription,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: _textDark, height: 1.6),
                  ),
          ],
        ],
      ),
    );
  }

  // ── Location Card ──────────────────────────────────────────────────────────
  Widget _buildLocationCard() {
    final center = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : _defaultCenter;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Lokasi Usaha'),
          const SizedBox(height: 8),
          Text(
            'Geser marker atau klik pada peta untuk menentukan lokasi usaha Anda.',
            style: GoogleFonts.inter(fontSize: 12, color: _textMid),
          ),
          const SizedBox(height: 12),

          // ── Search bar ──
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationSearchController,
                  style:
                      GoogleFonts.inter(fontSize: 13, color: _textDark),
                  decoration: InputDecoration(
                    hintText: 'Cari alamat atau nama tempat...',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: _textMid.withOpacity(0.6)),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: _primaryBlue),
                    ),
                    prefixIcon: const Icon(Icons.search,
                        color: _primaryBlue, size: 18),
                    // ── FIX: indikator loading saat mencari ─────────────────
                    suffixIcon: _isSearchingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _primaryBlue),
                            ),
                          )
                        : null,
                  ),
                  onSubmitted: _searchLocation,
                  textInputAction: TextInputAction.search,
                  enabled: !_isSearchingLocation,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSearchingLocation
                    ? null
                    : () =>
                        _searchLocation(_locationSearchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(60, 44),
                ),
                child: _isSearchingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Cari',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── FIX: Map dengan CancellableTileProvider ─────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _latitude != null ? 15 : 5,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // ── FIX: gunakan CancellableTileProvider ─────────────────
                    tileProvider: NetworkTileProvider(),
                    userAgentPackageName: 'com.konekin.app',
                  ),
                  if (_latitude != null && _longitude != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_latitude!, _longitude!),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Koordinat & status simpan ──────────────────────────────────────
          if (_latitude != null && _longitude != null)
            Row(
              children: [
                const Icon(Icons.gps_fixed,
                    size: 13, color: _primaryBlue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                    style:
                        GoogleFonts.inter(fontSize: 11, color: _textMid),
                  ),
                ),
                if (_isSavingLocation)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: _primaryBlue),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Menyimpan...',
                        style: GoogleFonts.inter(
                            fontSize: 10, color: _textMid),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Edit / Logout buttons ─────────────────────────────────────────────────
  Widget _buildEditProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _navigateToEditProfile,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text('Edit Profil',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryBlue,
          side: const BorderSide(color: _primaryBlue),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
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
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.red))
            : const Icon(Icons.logout_rounded, size: 18),
        label: Text(
          _isLoggingOut ? 'Keluar...' : 'Keluar',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: _textDark,
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
            color: _primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: _primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      GoogleFonts.inter(fontSize: 11, color: _textMid)),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : '-',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
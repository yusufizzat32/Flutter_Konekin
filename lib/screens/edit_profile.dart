// lib/screens/edit_profile.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';


class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfilePage({super.key, this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final AuthService _auth = AuthService();
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  // ── FIX: Rename bio → description agar konsisten dengan backend & profile page ──
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _businessNameCtrl = TextEditingController();
  final TextEditingController _businessAddressCtrl = TextEditingController();

  Uint8List? _selectedPhotoBytes;
  String? _currentPhotoUrl;
  bool _isUploadingPhoto = false;

  bool _isLoading = false;
  bool _isSaving = false;

  // ── FIX: Helper untuk build URL foto yang benar ────────────────────────────
  String _buildPhotoUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    // URL relatif dari Laravel storage — gabungkan dengan base URL server
    final base = AuthService().baseUrl.replaceFirst('/api', '');
    return '$base/storage/$rawUrl'
        .replaceAll('/storage/storage/', '/storage/');
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    // Prioritas: data dari widget.userData (dioper dari halaman profil)
    if (widget.userData != null) {
      _nameCtrl.text = widget.userData!['name'] ?? '';
      _phoneCtrl.text = widget.userData!['phone'] ?? '';
      _cityCtrl.text = widget.userData!['city'] ?? '';
      // ── FIX: baca description / bio dari semua kemungkinan key ──
      _descriptionCtrl.text = widget.userData!['description'] ??
          widget.userData!['business_description'] ??
          widget.userData!['bio'] ??
          '';
      _currentPhotoUrl =
          _buildPhotoUrl(widget.userData!['profile_photo'] ?? widget.userData!['avatar']);
      _businessNameCtrl.text = widget.userData!['business_name'] ?? '';
      _businessAddressCtrl.text = widget.userData!['address'] ?? '';
    }

    // Fallback: ambil dari SharedPreferences
    final userData = await _auth.getUserData();

    setState(() {
      if (userData != null) {
        if (_nameCtrl.text.isEmpty) _nameCtrl.text = userData['name'] ?? '';
        if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = userData['phone'] ?? '';
        if (_cityCtrl.text.isEmpty) _cityCtrl.text = userData['city'] ?? '';
        if (_descriptionCtrl.text.isEmpty) {
          _descriptionCtrl.text = userData['description'] ??
              userData['business_description'] ??
              userData['bio'] ??
              '';
        }
        if (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty) {
          _currentPhotoUrl =
              _buildPhotoUrl(userData['profile_photo'] ?? userData['avatar']);
        }
        if (_businessNameCtrl.text.isEmpty) {
          _businessNameCtrl.text = userData['business_name'] ?? '';
        }
        if (_businessAddressCtrl.text.isEmpty) {
          _businessAddressCtrl.text = userData['address'] ?? '';
        }
      }
      _isLoading = false;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile != null) {
      setState(() => _isUploadingPhoto = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedPhotoBytes = bytes;
          _isUploadingPhoto = false;
        });
      } catch (e) {
        setState(() => _isUploadingPhoto = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Gagal membaca gambar: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhotoBytes = null;
      _currentPhotoUrl = null;
    });
  }

  void _showPhotoPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC3C6D1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ubah Foto Profil',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _photoOption(
                    Icons.camera_alt_rounded, 'Kamera', const Color(0xFF1A4B84),
                    () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                }),
                _photoOption(
                    Icons.photo_library_rounded, 'Galeri', const Color(0xFF006D77),
                    () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                }),
                if (_selectedPhotoBytes != null ||
                    (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty))
                  _photoOption(Icons.delete_outline, 'Hapus', Colors.red, () {
                    Navigator.pop(context);
                    _removePhoto();
                  }),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _photoOption(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama tidak boleh kosong'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // ── FIX: kirim SEMUA key yang mungkin dipakai backend ─────────────────────
    final String descValue = _descriptionCtrl.text.trim();
    final Map<String, dynamic> payload = {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'bio': descValue,              // untuk backward compat
      'description': descValue,      // field utama profil UMKM
      'business_description': descValue,
      'business_name': _businessNameCtrl.text.trim(),
      'address': _businessAddressCtrl.text.trim(),
    };

    final result = await _api.updateProfileWithPhoto(
      payload,
      photoBytes: _selectedPhotoBytes,
    );

    if (mounted) {
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Profil berhasil disimpan'),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      if (result['success'] == true) {
        // ── FIX: refresh profile dari server agar data terbaru tersimpan lokal ──
        await _auth.getProfile();
        if (mounted) Navigator.pop(context, true);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _descriptionCtrl.dispose();
    _businessNameCtrl.dispose();
    _businessAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          'Edit Profil',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A4B84)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Simpan',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: const Color(0xFF1A4B84),
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Informasi Usaha'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _businessNameCtrl,
                    label: 'Nama Usaha',
                    hint: 'Masukkan nama usaha Anda',
                    icon: Icons.store,
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameCtrl,
                    label: 'Nama Pemilik',
                    hint: 'Masukkan nama lengkap Anda',
                    icon: Icons.person_outline,
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _businessAddressCtrl,
                    label: 'Alamat Usaha',
                    hint: 'Masukkan alamat lengkap usaha',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneCtrl,
                    label: 'Nomor Telepon',
                    hint: 'Contoh: 081234567890',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _cityCtrl,
                    label: 'Kota / Domisili',
                    hint: 'Contoh: Jakarta, Bandung, Surabaya',
                    icon: Icons.location_city_outlined,
                  ),
                  const SizedBox(height: 16),
                  // ── FIX: field deskripsi bisnis ───────────────────────────────
                  _buildTextField(
                    controller: _descriptionCtrl,
                    label: 'Deskripsi Bisnis',
                    hint:
                        'Ceritakan tentang bisnis UMKM Anda, produk/jasa yang ditawarkan, keunggulan, dll...',
                    icon: Icons.description_outlined,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── Photo section ─────────────────────────────────────────────────────────
  Widget _buildPhotoSection() {
    Widget photoWidget;
    if (_isUploadingPhoto) {
      photoWidget = const Center(child: CircularProgressIndicator());
    } else if (_selectedPhotoBytes != null) {
      // ── FIX: tampilkan preview bytes dari galeri ──────────────────────────
      photoWidget = ClipOval(
        child: Image.memory(
          _selectedPhotoBytes!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    } else if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      // ── FIX: tampilkan foto dari network dengan loading & error handler ───
      photoWidget = ClipOval(
        child: Image.network(
          _currentPhotoUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          // Header tambahan untuk menghindari masalah CORS di web
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
          errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
        ),
      );
    } else {
      photoWidget = _buildAvatarPlaceholder();
    }

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showPhotoPickerOptions,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A4B84), Color(0xFF006D77)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A4B84).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: photoWidget,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 34,
                    height: 34,
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
                      size: 18,
                      color: Color(0xFF1A4B84),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ketuk untuk mengubah foto profil',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF424750).withOpacity(0.6),
            ),
          ),
          // ── FIX: tampilkan info jika ada foto baru dipilih ────────────────
          if (_selectedPhotoBytes != null) ...[
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Text(
                'Foto baru siap diunggah',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : '?',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: const Color(0xFF1B1B1F),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: const Color(0xFF1B1B1F),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: maxLines > 1
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Icon(icon, color: const Color(0xFF424750), size: 20),
                  )
                : Icon(icon, color: const Color(0xFF424750), size: 20),
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF424750).withOpacity(0.5),
            ),
            filled: true,
            fillColor: const Color(0xFFF5F3F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF1A4B84), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            alignLabelWithHint: maxLines > 1,
          ),
        ),
      ],
    );
  }
}
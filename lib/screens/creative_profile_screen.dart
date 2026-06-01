// lib/screens/creative_profile_screen.dart
// Perbaikan untuk menampilkan bio dengan debug lengkap

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class CreativeProfileScreen extends StatefulWidget {
  const CreativeProfileScreen({super.key});

  @override
  State<CreativeProfileScreen> createState() => _CreativeProfileScreenState();
}

class _CreativeProfileScreenState extends State<CreativeProfileScreen> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  
  // User data
  Map<String, dynamic> _userData = {};
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAccountNumberController = TextEditingController();
  final TextEditingController _bankAccountNameController = TextEditingController();
  
  // Creative category - menggunakan label langsung (sama dengan registrasi)
  String _selectedCategory = '';
  bool _showBankFields = false;
  
  // Daftar kategori (sama persis dengan registrasi screen)
  static const List<String> _creativeCategoryList = [
    'Full Stack Developer',
    'Web Developer',
    'Frontend Developer',
    'Backend Developer',
    'App Developer',
    'Graphic Designer',
    'Illustrator',
    'UI/UX Designer',
    'Product Designer',
    'Video Editor',
    'Videographer',
    'Motion Graphic',
    'Animator',
    'Content Creator',
    'Photographer',
    'Copywriter',
    'Content Writer',
    'UGC Creator',
    'Social Media Specialist',
    'Social Media Manager',
    'Social Media Marketing',
    'Brand Strategist',
  ];
  
  // List dropdown items
  List<DropdownMenuItem<String>> get _dropdownItems {
    return _creativeCategoryList.map((category) {
      return DropdownMenuItem<String>(
        value: category,
        child: Text(category),
      );
    }).toList();
  }
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankAccountNameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    final result = await _profileService.getProfile();
    
    if (!mounted) return;
    
    // DEBUG: Print full result to see the structure
    debugPrint('🔍 FULL PROFILE RESULT:');
    debugPrint(jsonEncode(result));
    
    if (result['success'] == true) {
      setState(() {
        _userData = result['data'];
        
        // DEBUG: Print userData keys and values
        debugPrint('🔍 USER DATA KEYS: ${_userData.keys}');
        debugPrint('🔍 USER DATA "bio": "${_userData['bio']}"');
        debugPrint('🔍 USER DATA "bio" type: ${_userData['bio'].runtimeType}');
        debugPrint('🔍 FULL USER DATA: ${jsonEncode(_userData)}');
        
        _populateControllers();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar(result['message'], isError: true);
    }
  }
  
  void _populateControllers() {
    _nameController.text = _userData['name'] ?? '';
    _phoneController.text = _userData['phone'] ?? '';
    _addressController.text = _userData['address'] ?? '';
    _cityController.text = _userData['city'] ?? '';
    
    // Cek berbagai kemungkinan key untuk bio
    String bioValue = '';
    
    // Coba dari berbagai kemungkinan key
    if (_userData['bio'] != null && _userData['bio'].toString().isNotEmpty) {
      bioValue = _userData['bio'].toString();
    } else if (_userData['user_bio'] != null && _userData['user_bio'].toString().isNotEmpty) {
      bioValue = _userData['user_bio'].toString();
    } else if (_userData['description'] != null && _userData['description'].toString().isNotEmpty) {
      bioValue = _userData['description'].toString();
    } else if (_userData['about'] != null && _userData['about'].toString().isNotEmpty) {
      bioValue = _userData['about'].toString();
    }
    
    _bioController.text = bioValue;
    
    debugPrint('🟡 Bio value after population: "$bioValue"');
    debugPrint('🟡 Bio controller text: "${_bioController.text}"');
    
    // Ambil kategori langsung dari database
    final rawCategory = _userData['creative_category'] ?? '';
    _selectedCategory = rawCategory;
    
    debugPrint('🟡 Loaded category from API: "$rawCategory"');
    
    final bankName = _userData['bank_name'];
    final bankAccountNumber = _userData['bank_account_number'];
    final bankAccountName = _userData['bank_account_name'];
    
    _bankNameController.text = bankName ?? '';
    _bankAccountNumberController.text = bankAccountNumber?.toString() ?? '';
    _bankAccountNameController.text = bankAccountName ?? '';
    
    _showBankFields = (bankName != null && bankName.isNotEmpty) ||
        (bankAccountNumber != null && bankAccountNumber.toString().isNotEmpty) ||
        (bankAccountName != null && bankAccountName.isNotEmpty);
  }
  
  Future<void> _saveProfile() async {
    if (_selectedCategory.isEmpty) {
      _showSnackBar('Harap pilih kategori kreatif', isError: true);
      return;
    }
    
    setState(() => _isSaving = true);
    
    debugPrint('🟢 Saving category: "$_selectedCategory"');
    debugPrint('🟢 Saving bio: "${_bioController.text.trim()}"');
    
    final result = await _profileService.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      bio: _bioController.text.trim(),
      creativeCategory: _selectedCategory,
      bankName: _showBankFields ? _bankNameController.text.trim() : null,
      bankAccountNumber: _showBankFields ? _bankAccountNumberController.text.trim() : null,
      bankAccountName: _showBankFields ? _bankAccountNameController.text.trim() : null,
    );
    
    if (!mounted) return;
    setState(() => _isSaving = false);
    
    if (result['success'] == true) {
      setState(() {
        _userData = result['data'];
        _bioController.text = _userData['bio'] ?? '';
        _isEditing = false;
      });
      _showSnackBar(result['message'], isError: false);
      _loadProfile();
    } else {
      _showSnackBar(result['message'], isError: true);
    }
  }
  
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: GoogleFonts.inter(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF20C997),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  String _getInitials() {
    final name = _userData['name'] ?? 'Creative Worker';
    if (name.isEmpty || name == 'Creative Worker') return 'CW';
    
    final List<String> nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'CW';
  }
  
  String _getCategoryLabel() {
    if (_selectedCategory.isEmpty) return 'Belum dipilih';
    return _selectedCategory;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF003466),
          onRefresh: _loadProfile,
          child: _isLoading
              ? _buildLoadingSkeleton()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildProfileCard(),
                      const SizedBox(height: 20),
                      if (_isEditing) ...[
                        _buildFormSection(),
                        const SizedBox(height: 20),
                        _buildActionButtons(),
                      ] else ...[
                        _buildInfoSection(),
                        const SizedBox(height: 20),
                        _buildBankSection(),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8ECF0)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFF1B1B1F),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Profil Saya',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B1B1F),
                ),
              ),
              const Spacer(),
              if (!_isEditing)
                GestureDetector(
                  onTap: () => setState(() => _isEditing = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003466),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Edit',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola informasi profil dan data diri Anda',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileCard() {
    // Ambil bio dari userData dengan lebih hati-hati
    String bioValue = '';
    if (_userData['bio'] != null && _userData['bio'].toString().isNotEmpty) {
      bioValue = _userData['bio'].toString();
    } else if (_bioController.text.isNotEmpty) {
      bioValue = _bioController.text;
    }
    
    final hasBio = bioValue.isNotEmpty;
    
    debugPrint('🔵 ProfileCard - bioValue: "$bioValue", hasBio: $hasBio');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003466), Color(0xFF0056A8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  _getInitials(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userData['name'] ?? 'Creative Worker',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B1B1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData['email'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedCategory.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getCategoryLabel(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF003466),
                        ),
                      ),
                    ),
                  if (hasBio)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        bioValue.length > 60 
                            ? '${bioValue.substring(0, 60)}...' 
                            : bioValue,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoSection() {
    // Ambil bio dari userData
    String bioValue = '';
    if (_userData['bio'] != null && _userData['bio'].toString().isNotEmpty) {
      bioValue = _userData['bio'].toString();
    }
    
    final hasBio = bioValue.isNotEmpty;
    
    debugPrint('🔵 InfoSection - bioValue: "$bioValue", hasBio: $hasBio');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Diri',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF0)),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.phone_rounded,
                  label: 'Nomor Telepon',
                  value: _userData['phone'] ?? 'Belum diisi',
                ),
                _Divider(),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Alamat',
                  value: _userData['address'] ?? 'Belum diisi',
                ),
                _Divider(),
                _InfoRow(
                  icon: Icons.location_city_rounded,
                  label: 'Kota',
                  value: _userData['city'] ?? 'Belum diisi',
                ),
                _Divider(),
                _InfoRow(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Kategori Keahlian',
                  value: _selectedCategory.isEmpty ? 'Belum dipilih' : _selectedCategory,
                ),
                _Divider(),
                _InfoRow(
                  icon: Icons.description_rounded,
                  label: 'Bio',
                  value: hasBio ? bioValue : 'Belum diisi',
                  multiline: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBankSection() {
    final bankName = _bankNameController.text;
    final bankAccountNumber = _bankAccountNumberController.text;
    final bankAccountName = _bankAccountNameController.text;
    
    final hasBankInfo = bankName.isNotEmpty || 
        bankAccountNumber.isNotEmpty || 
        bankAccountName.isNotEmpty;
    
    if (!hasBankInfo && !_showBankFields) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Bank',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF0)),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.account_balance_rounded,
                  label: 'Nama Bank',
                  value: bankName.isNotEmpty ? bankName : 'Belum diisi',
                ),
                if (bankName.isNotEmpty) _Divider(),
                if (bankName.isNotEmpty)
                  _InfoRow(
                    icon: Icons.numbers_rounded,
                    label: 'Nomor Rekening',
                    value: bankAccountNumber.isNotEmpty ? bankAccountNumber : 'Belum diisi',
                  ),
                if (bankAccountNumber.isNotEmpty) _Divider(),
                if (bankAccountNumber.isNotEmpty)
                  _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'Nama Pemilik Rekening',
                    value: bankAccountName.isNotEmpty ? bankAccountName : 'Belum diisi',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profil',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: 'Nama Lengkap',
            icon: Icons.person_outline_rounded,
            hint: 'Masukkan nama lengkap',
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _phoneController,
            label: 'Nomor Telepon',
            icon: Icons.phone_outlined,
            hint: '081234567890',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _addressController,
            label: 'Alamat',
            icon: Icons.location_on_outlined,
            hint: 'Jl. Raya No. 1',
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _cityController,
            label: 'Kota',
            icon: Icons.location_city_outlined,
            hint: 'Surabaya',
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _bioController,
            label: 'Bio',
            icon: Icons.description_outlined,
            hint: 'Ceritakan tentang diri Anda...',
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          _buildCategoryDropdown(),
          const SizedBox(height: 14),
          _buildBankToggle(),
          if (_showBankFields) ...[
            const SizedBox(height: 14),
            _buildTextField(
              controller: _bankNameController,
              label: 'Nama Bank',
              icon: Icons.account_balance_outlined,
              hint: 'BCA, Mandiri, BNI, dll',
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _bankAccountNumberController,
              label: 'Nomor Rekening',
              icon: Icons.numbers_outlined,
              hint: '1234567890',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _bankAccountNameController,
              label: 'Nama Pemilik Rekening',
              icon: Icons.person_outline_rounded,
              hint: 'Sesuai nama rekening',
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF1B1B1F),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF9CA3AF),
          ),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
  
  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        value: _dropdownItems.any((item) => item.value == _selectedCategory) 
            ? _selectedCategory 
            : null,
        decoration: InputDecoration(
          labelText: 'Kategori Keahlian *',
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
          prefixIcon: const Icon(
            Icons.workspace_premium_outlined,
            size: 20,
            color: Color(0xFF9CA3AF),
          ),
          border: InputBorder.none,
        ),
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF1B1B1F),
        ),
        hint: Text(
          'Pilih kategori keahlian',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF9CA3AF),
          ),
        ),
        items: _dropdownItems,
        onChanged: (value) {
          setState(() {
            _selectedCategory = value ?? '';
          });
        },
        isExpanded: true,
        dropdownColor: Colors.white,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF9CA3AF)),
      ),
    );
  }
  
  Widget _buildBankToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showBankFields = !_showBankFields),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF0)),
        ),
        child: Row(
          children: [
            Icon(
              _showBankFields ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: _showBankFields ? const Color(0xFF003466) : const Color(0xFF9CA3AF),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tambahkan informasi bank untuk pencairan dana',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF1B1B1F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      _populateControllers();
                      setState(() => _isEditing = false);
                    },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE8ECF0)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003466),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Simpan Perubahan',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingSkeleton() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        _buildSkeletonBox(height: 40, width: 150),
        const SizedBox(height: 20),
        _buildSkeletonBox(height: 120, radius: 20),
        const SizedBox(height: 20),
        _buildSkeletonBox(height: 30, width: 120),
        const SizedBox(height: 12),
        _buildSkeletonBox(height: 200, radius: 16),
        const SizedBox(height: 20),
        _buildSkeletonBox(height: 30, width: 120),
        const SizedBox(height: 12),
        _buildSkeletonBox(height: 150, radius: 16),
      ],
    );
  }
  
  Widget _buildSkeletonBox({required double height, double? width, double radius = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// =============================================================================
// INFO ROW WIDGET
// =============================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;
  
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF003466)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9CA3AF),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: value == 'Belum diisi'
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF1B1B1F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DIVIDER WIDGET
// =============================================================================

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 0,
      thickness: 1,
      color: Color(0xFFE8ECF0),
    );
  }
}
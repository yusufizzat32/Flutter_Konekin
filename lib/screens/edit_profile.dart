// lib/screens/edit_profile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const EditProfilePage({super.key, this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _bioCtrl;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.userData?['name'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.userData?['phone'] ?? '');
    _cityCtrl = TextEditingController(text: widget.userData?['city'] ?? '');
    _bioCtrl = TextEditingController(text: widget.userData?['bio'] ?? '');
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    final result = await _api.getProfile();
    
    if (mounted) {
      setState(() {
        if (result['success'] && result['data'] != null) {
          final user = result['data']['user'] ?? result['data'];
          _nameCtrl.text = user['name'] ?? '';
          _phoneCtrl.text = user['phone'] ?? '';
          _cityCtrl.text = user['city'] ?? '';
          _bioCtrl.text = user['bio'] ?? '';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final result = await _api.updateProfile({
      'name': _nameCtrl.text,
      'phone': _phoneCtrl.text,
      'city': _cityCtrl.text,
      'bio': _bioCtrl.text,
    });
    
    if (mounted) {
      setState(() => _isSaving = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      if (result['success']) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
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
            child: Text(
              'Simpan',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
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
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAE7ED),
                              shape: BoxShape.circle,
                              image: widget.userData?['avatar'] != null
                                  ? DecorationImage(
                                      image: NetworkImage(widget.userData!['avatar']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: widget.userData?['avatar'] == null
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Color(0xFF424750),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A4B84),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Form Fields
                    _buildTextField(
                      controller: _nameCtrl,
                      label: 'Nama Lengkap',
                      icon: Icons.person_outline,
                      validator: (v) => v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _phoneCtrl,
                      label: 'Nomor Telepon',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _cityCtrl,
                      label: 'Kota/Kabupaten',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _bioCtrl,
                      label: 'Bio',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      helperText: 'Ceritakan tentang diri Anda',
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: const Color(0xFF1B1B1F),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF424750), size: 20),
            hintText: helperText,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF424750).withOpacity(0.5),
            ),
            filled: true,
            fillColor: const Color(0xFFEAE7ED),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A4B84), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
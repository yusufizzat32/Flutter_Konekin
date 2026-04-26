// lib/screens/create_project.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _budgetCtrl.dispose();
    _durationCtrl.dispose();
    _categoryCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitProject() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    final skills = _skillsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    
    final result = await _api.createProject({
      'title': _titleCtrl.text,
      'description': _descriptionCtrl.text,
      'budget': _budgetCtrl.text,
      'duration': _durationCtrl.text,
      'category': _categoryCtrl.text,
      'skills': skills,
    });
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      
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
          'Buat Proyek Baru',
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
            onPressed: _isSubmitting ? null : _submitProject,
            child: Text(
              'Posting',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A4B84),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _titleCtrl,
                label: 'Judul Proyek',
                hint: 'Contoh: Desain Logo untuk Cafe',
                icon: Icons.title,
                validator: (v) => v == null || v.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _descriptionCtrl,
                label: 'Deskripsi',
                hint: 'Jelaskan detail proyek yang Anda butuhkan...',
                icon: Icons.description,
                maxLines: 5,
                validator: (v) => v == null || v.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _budgetCtrl,
                      label: 'Budget',
                      hint: 'Rp 1.000.000 - 5.000.000',
                      icon: Icons.attach_money,
                      validator: (v) => v == null || v.isEmpty ? 'Budget tidak boleh kosong' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _durationCtrl,
                      label: 'Durasi',
                      hint: '2 minggu / 1 bulan',
                      icon: Icons.access_time,
                      validator: (v) => v == null || v.isEmpty ? 'Durasi tidak boleh kosong' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _categoryCtrl,
                label: 'Kategori',
                hint: 'Graphic Design, UI/UX, Video, dll',
                icon: Icons.category,
                validator: (v) => v == null || v.isEmpty ? 'Kategori tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _skillsCtrl,
                label: 'Skill yang Dibutuhkan',
                hint: 'Pisahkan dengan koma, contoh: Photoshop, Illustrator, Figma',
                icon: Icons.psychology,
                helperText: 'Masukkan skill yang diperlukan, pisahkan dengan koma',
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
    required String hint,
    required IconData icon,
    int maxLines = 1,
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
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF424750), size: 20),
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF424750).withOpacity(0.5),
            ),
            helperText: helperText,
            helperStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF424750).withOpacity(0.7)),
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
// lib/screens/create_project.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/project_model.dart'; // IMPORT PROJECT MODEL
import 'project_progress_detail.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();

  // Deadline
  DateTime? _selectedDeadline;

  // Kategori
  String _selectedCategory = 'Branding';
  final List<String> _categories = [
    'Branding',
    'Social Media',
    'Web Development',
    'Videography',
    'UI/UX Design',
    'Illustration',
    'Graphic Design',
    'Photography',
    'Copywriting',
  ];

  // Upload Gambar
  Uint8List? _selectedImageBytes;
  bool _isUploadingImage = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _budgetCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _isUploadingImage = false;
        });
      } catch (e) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membaca gambar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A4B84),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1B1B1F),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _submitProject() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih deadline terlebih dahulu')),
      );
      return;
    }

    final token = await AuthService().getToken();
    if (token == null || token.isEmpty || token == 'Bearer ') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi berakhir, silakan login kembali'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    setState(() => _isSubmitting = true);

    final skills = _skillsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final deadlineFormatted =
        '${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')}';

    final payload = {
      'title': _titleCtrl.text,
      'description': _descriptionCtrl.text,
      'budget': _budgetCtrl.text,
      'deadline': deadlineFormatted,
      'category': _selectedCategory,
      'skills': skills,
    };

    final result = await _api.createProject(payload, imageBytes: _selectedImageBytes);

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Proyek berhasil dibuat!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Ambil data proyek yang baru dibuat
        Map<String, dynamic>? createdProject;
        if (result['data'] != null && result['data'] is Map) {
          createdProject = result['data'] as Map<String, dynamic>;
        }

        String newProjectId = '';
        if (createdProject != null && createdProject['id'] != null) {
          newProjectId = createdProject['id'].toString();
        }

        if (newProjectId.isNotEmpty) {
          // Buat objek Project sederhana untuk navigasi
          final newProject = Project(
            id: newProjectId,
            title: _titleCtrl.text,
            description: _descriptionCtrl.text,
            budget: _budgetCtrl.text,
            duration: '',
            status: 'open',
            category: _selectedCategory,
            skills: skills,
            thumbnail: null,
            umkmId: null,
            umkmName: null,
            umkmCity: null,
            createdAt: DateTime.now(),
            deadline: _selectedDeadline,
            applicantCount: 0,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectProgressDetailPage(project: newProject),
            ),
          );
        } else {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal membuat proyek'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
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
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Posting', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1A4B84))),
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
              _buildTextField(
                controller: _budgetCtrl,
                label: 'Budget',
                hint: 'Contoh: 5000000',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Budget tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              _buildDeadlinePicker(),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _skillsCtrl,
                label: 'Skill yang Dibutuhkan',
                hint: 'Pisahkan dengan koma, contoh: Figma, Photoshop, UI/UX',
                icon: Icons.psychology,
                helperText: 'Masukkan skill yang diperlukan, pisahkan dengan koma',
              ),
              const SizedBox(height: 16),
              _buildImageUploadSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeadlinePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deadline Pengerjaan', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDeadline,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAE7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _selectedDeadline != null ? const Color(0xFF1A4B84) : Colors.transparent, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Color(0xFF424750)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDeadline != null
                        ? '${_selectedDeadline!.day} ${_getMonthName(_selectedDeadline!.month)} ${_selectedDeadline!.year}'
                        : 'Pilih tanggal deadline',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _selectedDeadline != null ? const Color(0xFF1B1B1F) : const Color(0xFF424750).withOpacity(0.6),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF424750)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: const Color(0xFFEAE7ED), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF424750)),
              iconSize: 24,
              elevation: 16,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1B1B1F)),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              onChanged: (String? newValue) {
                if (newValue != null) setState(() => _selectedCategory = newValue);
              },
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(value)),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upload Foto / Video (Opsional)', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAE7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC3C6D1).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              if (_isUploadingImage)
                const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
              else if (_selectedImageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_selectedImageBytes!, height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.refresh, size: 18), label: const Text('Ganti')),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ] else ...[
                Icon(Icons.image_outlined, size: 48, color: const Color(0xFF424750).withOpacity(0.5)),
                const SizedBox(height: 12),
                Text('Tambahkan referensi visual', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF424750))),
                const SizedBox(height: 8),
                Text('JPG, PNG maksimal 20MB', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF424750).withOpacity(0.6))),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Pilih File Referensi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4B84),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tips: Berikan deskripsi yang jelas dan anggaran yang realistis untuk mendapatkan tawaran terbaik.',
          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF424750).withOpacity(0.7), fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF424750), size: 20),
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF424750).withOpacity(0.5)),
            helperText: helperText,
            helperStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF424750).withOpacity(0.7)),
            filled: true,
            fillColor: const Color(0xFFEAE7ED),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }
}
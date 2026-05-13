import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';

class CreativeProgressUpdatePage extends StatefulWidget {
  final Project project;
  
  const CreativeProgressUpdatePage({super.key, required this.project});

  @override
  State<CreativeProgressUpdatePage> createState() => _CreativeProgressUpdatePageState();
}

class _CreativeProgressUpdatePageState extends State<CreativeProgressUpdatePage> {
  final ApiService _api = ApiService();
  final TextEditingController _noteController = TextEditingController();
  
  int _progress = 0;
  bool _isSubmitting = false;
  bool _isLoading = true;
  File? _selectedMedia;
  final ImagePicker _picker = ImagePicker();
  
  List<Map<String, dynamic>> _progressHistory = [];

  @override
  void initState() {
    super.initState();
    _loadProgressHistory();
  }

  Future<void> _loadProgressHistory() async {
    setState(() => _isLoading = true);
    
    final result = await _api.getCreativeProjects();
    
    if (mounted && result['success'] && result['data'] != null) {
      final projects = result['data']['projects'] ?? result['data'];
      if (projects is List) {
        final currentProject = projects.firstWhere(
          (p) => p['id'].toString() == widget.project.id.toString(),
          orElse: () => null,
        );
        
        if (currentProject != null) {
          final updates = currentProject['progress_updates'];
          if (updates is List) {
            setState(() {
              _progressHistory = updates.map((u) => Map<String, dynamic>.from(u)).toList();
            });
          }
          setState(() {
            _progress = currentProject['progress_percentage'] ?? 0;
          });
        }
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _pickMedia() async {
    final pickedFile = await _picker.pickMedia();
    
    if (pickedFile != null) {
      setState(() {
        _selectedMedia = File(pickedFile.path);
      });
    }
  }

  void _removeMedia() {
    setState(() {
      _selectedMedia = null;
    });
  }

  Future<void> _submitProgress() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi catatan progress'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (_progress == 0 && _noteController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan progress minimal 10 karakter'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    final result = await _api.updateProjectProgressWithMedia(
      widget.project.id,
      _progress,
      _noteController.text.trim(),
      mediaFile: _selectedMedia,
    );
    
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
        _noteController.clear();
        setState(() => _selectedMedia = null);
        _loadProgressHistory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          'Update Progress',
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Info
                  _buildProjectInfo(),
                  const SizedBox(height: 20),
                  
                  // Progress Slider
                  _buildProgressSlider(),
                  const SizedBox(height: 20),
                  
                  // Note Input
                  _buildNoteInput(),
                  const SizedBox(height: 16),
                  
                  // Media Upload
                  _buildMediaUpload(),
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  _buildSubmitButton(),
                  
                  const SizedBox(height: 24),
                  
                  // Progress History
                  _buildProgressHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildProjectInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003466), Color(0xFF1A4B84)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.project.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Budget: ${widget.project.budget}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.business, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                widget.project.umkmName ?? 'UMKM',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Pengerjaan',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                '$_progress%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF006D77),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: _progress.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: const Color(0xFF006D77),
            inactiveColor: const Color(0xFFEAE7ED),
            onChanged: (value) {
              setState(() {
                _progress = value.round();
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mulai',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF424750),
                ),
              ),
              Text(
                'Progress',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF424750),
                ),
              ),
              Text(
                'Selesai',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF424750),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catatan Progress',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Jelaskan progress yang sudah dikerjakan...',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF424750).withOpacity(0.5),
              ),
              filled: true,
              fillColor: const Color(0xFFFBF8FE),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1A4B84), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaUpload() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dokumentasi (Opsional)',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAE7ED)),
            ),
            child: _selectedMedia != null
                ? Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _selectedMedia!.path.toLowerCase().contains('.mp4') ||
                                _selectedMedia!.path.toLowerCase().contains('.mov')
                            ? Container(
                                height: 150,
                                color: Colors.black,
                                child: const Center(
                                  child: Icon(Icons.play_circle_fill, size: 48, color: Colors.white),
                                ),
                              )
                            : Image.file(
                                _selectedMedia!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: _pickMedia,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Ganti'),
                          ),
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: _removeMedia,
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: const Color(0xFF424750).withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload foto/video progress',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF424750),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'JPG, PNG, MP4 maksimal 20MB',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF424750).withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _pickMedia,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Pilih File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A4B84),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitProgress,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006D77),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                'Kirim Update Progress',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildProgressHistory() {
    if (_progressHistory.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Riwayat Progress',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ..._progressHistory.reversed.map((update) => _buildHistoryItem(update)),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> update) {
    final percentage = update['progress_percentage'] ?? update['percentage'] ?? 0;
    final note = update['note'] ?? '';
    final createdAt = update['created_at'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE7ED)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF006D77).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$percentage%',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: const Color(0xFF006D77),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF1B1B1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 10,
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }
}
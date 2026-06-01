// lib/screens/update_progress_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/project_progress_model.dart';
import '../services/project_progress_service.dart';

class UpdateProgressScreen extends StatefulWidget {
  final ProjectProgressModel project;

  const UpdateProgressScreen({super.key, required this.project});

  @override
  State<UpdateProgressScreen> createState() => _UpdateProgressScreenState();
}

class _UpdateProgressScreenState extends State<UpdateProgressScreen> {
  final ProjectProgressService _service = ProjectProgressService();
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  int _progressPercentage = 0;
  File? _mediaFile;
  bool _isSubmitting = false;
  String? _mediaType;

  @override
  void initState() {
    super.initState();
    _progressPercentage = widget.project.progressPercentage;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera, color: Color(0xFF003466)),
            title: const Text('Ambil Foto/Video'),
            onTap: () async {
              Navigator.pop(context);
              final XFile? media = await _picker.pickImage(source: ImageSource.camera);
              if (media != null) setState(() => _mediaFile = File(media.path));
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Color(0xFF003466)),
            title: const Text('Pilih dari Galeri'),
            onTap: () async {
              Navigator.pop(context);
              final XFile? media = await _picker.pickImage(source: ImageSource.gallery);
              if (media != null) setState(() => _mediaFile = File(media.path));
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _submitProgress() async {
    if (_noteController.text.length < 10) {
      _showSnackBar('Pesan minimal 10 karakter', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _service.updateProgress(
      projectId: widget.project.id,
      progressPercentage: _progressPercentage,
      note: _noteController.text,
      mediaFile: _mediaFile,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      _showSnackBar(result['message'], isError: false);
      Navigator.pop(context, true);
    } else {
      _showSnackBar(result['message'], isError: true);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: GoogleFonts.inter(fontSize: 13))),
        ]),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF20C997),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B1B1F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Update Progress',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B1F)),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectInfo(),
            const SizedBox(height: 24),
            _buildProgressSlider(),
            const SizedBox(height: 24),
            _buildNoteField(),
            const SizedBox(height: 24),
            _buildMediaPicker(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectInfo() {
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: widget.project.thumbnail != null
                  ? DecorationImage(image: NetworkImage(widget.project.thumbnail!), fit: BoxFit.cover)
                  : null,
              color: const Color(0xFFEFF6FF),
            ),
            child: widget.project.thumbnail == null
                ? const Icon(Icons.work_outline_rounded, color: Color(0xFF003466), size: 30)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.project.title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B1F)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Progress saat ini: ${widget.project.progressPercentage}%',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
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
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Pengerjaan',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B1F)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF003466),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_progressPercentage%',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: _progressPercentage.toDouble(),
            min: widget.project.progressPercentage.toDouble(),
            max: 100,
            divisions: (100 - widget.project.progressPercentage) ~/ 5,
            activeColor: const Color(0xFF003466),
            inactiveColor: const Color(0xFFE8ECF0),
            label: '$_progressPercentage%',
            onChanged: (value) => setState(() => _progressPercentage = value.toInt()),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _progressPercentage / 100,
            backgroundColor: const Color(0xFFE8ECF0),
            color: const Color(0xFF20C997),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catatan Progress *',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B1F)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 4,
            maxLength: 1500,
            decoration: InputDecoration(
              hintText: 'Jelaskan progress yang telah dikerjakan... (minimal 10 karakter)',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8ECF0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8ECF0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF003466), width: 2)),
            ),
          ),
          if (_noteController.text.isNotEmpty && _noteController.text.length < 10)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '⚠️ Minimal 10 karakter (saat ini: ${_noteController.text.length})',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFEF4444)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaPicker() {
    return GestureDetector(
      onTap: _pickMedia,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _mediaFile == null ? Colors.white : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _mediaFile == null ? const Color(0xFFE8ECF0) : const Color(0xFF20C997)),
        ),
        child: Row(
          children: [
            Icon(_mediaFile == null ? Icons.attach_file : Icons.check_circle, color: _mediaFile == null ? const Color(0xFF9CA3AF) : const Color(0xFF20C997)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _mediaFile == null ? 'Upload Media (Opsional)' : 'Media Terupload',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _mediaFile == null ? const Color(0xFF6B7280) : const Color(0xFF20C997)),
                  ),
                  if (_mediaFile != null)
                    Text(
                      _mediaFile!.path.split('/').last,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (_mediaFile == null)
                    Text(
                      'Foto atau video progress (max 20MB)',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF)),
                    ),
                ],
              ),
            ),
            if (_mediaFile != null)
              IconButton(
                onPressed: () => setState(() => _mediaFile = null),
                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitProgress,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003466),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSubmitting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
            : Text(
                'Update Progress',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
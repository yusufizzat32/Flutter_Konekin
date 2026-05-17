// lib/screens/creative_progress_update_page.dart
// Creative worker mengirim update progress ke UMKM

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
  State<CreativeProgressUpdatePage> createState() =>
      _CreativeProgressUpdatePageState();
}

class _CreativeProgressUpdatePageState
    extends State<CreativeProgressUpdatePage> {
  final ApiService _api = ApiService();
  final _noteController = TextEditingController();
  int _progressValue = 0;
  File? _selectedMedia;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _progressValue = widget.project.progressPercentage;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pilih Media',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFF1A4B84)),
              title: Text('Galeri', style: GoogleFonts.inter()),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: Color(0xFF1A4B84)),
              title: Text('Kamera', style: GoogleFonts.inter()),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _selectedMedia = File(picked.path));
    }
  }

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    if (note.length < 10) {
      _showSnack('Catatan update minimal 10 karakter', isError: true);
      return;
    }
    if (_progressValue < (widget.project.progressPercentage)) {
      _showSnack('Progress tidak boleh lebih kecil dari sebelumnya', isError: true);
      return;
    }

    setState(() => _isSending = true);

    final result = await _api.storeCreativeProgress(
      projectId: widget.project.id,
      progressPercentage: _progressValue,
      note: note,
      mediaFile: _selectedMedia,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    _showSnack(
      result['message'] ?? (result['success'] ? 'Progress terkirim!' : 'Gagal'),
      isError: result['success'] != true,
    );

    if (result['success'] == true) Navigator.pop(context, true);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF006D77),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Color get _sliderColor {
    if (_progressValue >= 100) return const Color(0xFF006D77);
    if (_progressValue >= 50) return const Color(0xFFE29578);
    return const Color(0xFF1A4B84);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Update Progress',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A4B84)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info Proyek ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF003466), Color(0xFF1A4B84)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.project.title,
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('UMKM: ${widget.project.umkmName ?? "-"}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress saat ini',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.white70)),
                      Text('${widget.project.progressPercentage}%',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF68FADD))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: widget.project.progressPercentage / 100,
                      backgroundColor: Colors.white24,
                      color: const Color(0xFF68FADD),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Progress Slider ────────────────────────────────────────────
            Text('Progress Baru',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF1B1B1F))),
            const SizedBox(height: 4),
            Text('Geser slider untuk menentukan progress saat ini',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF424750))),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_progressValue%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: _sliderColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _sliderColor,
                      inactiveTrackColor: const Color(0xFFEAE7ED),
                      thumbColor: _sliderColor,
                      overlayColor: _sliderColor.withOpacity(0.15),
                      trackHeight: 8,
                    ),
                    child: Slider(
                      value: _progressValue.toDouble(),
                      min: widget.project.progressPercentage.toDouble(),
                      max: 100,
                      divisions: 100 - widget.project.progressPercentage,
                      onChanged: (v) =>
                          setState(() => _progressValue = v.round()),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${widget.project.progressPercentage}%',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color(0xFF424750))),
                      Text('100%',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color(0xFF424750))),
                    ],
                  ),
                  if (_progressValue == 100) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006D77).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: Color(0xFF006D77)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Progress 100%! UMKM akan diminta membayar escrow sebelum kamu bisa menerima dana.',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF006D77),
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Catatan Update ─────────────────────────────────────────────
            Text('Catatan Update *',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF1B1B1F))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 5,
                maxLength: 1500,
                decoration: InputDecoration(
                  hintText:
                      'Jelaskan apa yang sudah dikerjakan, hasil, atau kendala...\n\nMinimal 10 karakter.',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF9E9E9E)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

            // ── Upload Media ───────────────────────────────────────────────
            Text('Bukti Pekerjaan (Opsional)',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF1B1B1F))),
            const SizedBox(height: 4),
            Text('Upload foto atau video sebagai bukti progress',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF424750))),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: _pickMedia,
              child: Container(
                width: double.infinity,
                height: _selectedMedia != null ? null : 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedMedia != null
                        ? const Color(0xFF006D77)
                        : const Color(0xFFCCC9D1),
                    width: 1.5,
                  ),
                ),
                child: _selectedMedia != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedMedia!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedMedia = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              size: 36, color: Color(0xFF9E9E9E)),
                          const SizedBox(height: 8),
                          Text('Tap untuk pilih foto/video',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF9E9E9E))),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Tombol Kirim ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A4B84),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Kirim Update Progress',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
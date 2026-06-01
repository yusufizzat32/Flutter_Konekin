// lib/screens/submit_revision_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/revision_service.dart';
import '../models/project_progress_model.dart';

class SubmitRevisionScreen extends StatefulWidget {
  final ProjectProgressModel project;
  final Map<String, dynamic> revisionData;

  const SubmitRevisionScreen({
    super.key,
    required this.project,
    required this.revisionData,
  });

  @override
  State<SubmitRevisionScreen> createState() => _SubmitRevisionScreenState();
}

class _SubmitRevisionScreenState extends State<SubmitRevisionScreen> {
  final RevisionService _revisionService = RevisionService();
  final _noteController = TextEditingController();
  File? _mediaFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      setState(() => _mediaFile = File(result.path));
    }
  }

  Future<void> _submitRevision() async {
    if (_noteController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan revisi minimal 10 karakter')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _revisionService.submitRevision(
      projectId: widget.project.id,
      note: _noteController.text.trim(),
      mediaFile: _mediaFile,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final revisionReason = widget.revisionData['reason'] ?? 'Tidak ada alasan';
    final revisionFeedback = widget.revisionData['feedback'];
    final deadline = widget.revisionData['deadline'] != null
        ? DateTime.tryParse(widget.revisionData['deadline'])
        : null;
    final isOverdue = deadline != null && deadline.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Submit Revisi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revision Request Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOverdue ? Colors.red.withOpacity(0.05) : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isOverdue ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isOverdue ? Icons.warning_amber_rounded : Icons.edit_note_outlined,
                        size: 20,
                        color: isOverdue ? Colors.red : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Permintaan Revisi #${widget.revisionData['revision_count'] ?? 1}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isOverdue ? Colors.red : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Alasan:',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    revisionReason,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1B1B1F)),
                  ),
                  if (revisionFeedback != null && revisionFeedback.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Catatan:',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      revisionFeedback,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1B1B1F)),
                    ),
                  ],
                  if (deadline != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: isOverdue ? Colors.red : Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'Deadline: ${deadline.day}/${deadline.month}/${deadline.year}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isOverdue ? Colors.red : Colors.orange.shade800,
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'OVERDUE',
                              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Revision Note
            Text(
              'Catatan Revisi *',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: const Color(0xFF1B1B1F),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Jelaskan perubahan yang telah Anda buat...',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1A4B84)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            // Media Attachment
            Text(
              'Lampiran (Opsional)',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: const Color(0xFF1B1B1F),
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickMedia,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0), style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _mediaFile != null
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _mediaFile!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => setState(() => _mediaFile = null),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Hapus'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          const Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF9E9E9E)),
                          const SizedBox(height: 8),
                          Text(
                            'Tap untuk upload file',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E)),
                          ),
                          Text(
                            'JPG, PNG, PDF, MP4 (max 20MB)',
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFBDBDBD)),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRevision,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003466),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Kirim Hasil Revisi',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
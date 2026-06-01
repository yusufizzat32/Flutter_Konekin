// lib/widgets/request_revision_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/revision_service.dart';

class RequestRevisionBottomSheet extends StatefulWidget {
  final String projectId;
  final String projectTitle;
  final VoidCallback onRevisionRequested;

  const RequestRevisionBottomSheet({
    super.key,
    required this.projectId,
    required this.projectTitle,
    required this.onRevisionRequested,
  });

  @override
  State<RequestRevisionBottomSheet> createState() => _RequestRevisionBottomSheetState();
}

class _RequestRevisionBottomSheetState extends State<RequestRevisionBottomSheet> {
  final RevisionService _revisionService = RevisionService();
  final _reasonController = TextEditingController();
  final _feedbackController = TextEditingController();
  DateTime? _deadline;
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _submitRevision() async {
    if (_reasonController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan revisi minimal 10 karakter')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _revisionService.requestRevision(
      projectId: widget.projectId,
      reason: _reasonController.text.trim(),
      feedback: _feedbackController.text.trim().isEmpty ? null : _feedbackController.text.trim(),
      deadline: _deadline,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pop(context);
      widget.onRevisionRequested();
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Request Revisi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.projectTitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Reason Field
          Text(
            'Alasan Revisi *',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Jelaskan apa yang perlu diperbaiki...',
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
          const SizedBox(height: 12),

          // Feedback Field (Optional)
          Text(
            'Catatan Tambahan (Opsional)',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _feedbackController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Berikan detail lebih spesifik...',
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
          const SizedBox(height: 12),

          // Deadline (Optional)
          Text(
            'Deadline Revisi (Opsional)',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _selectDeadline,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF6B7280)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _deadline != null
                          ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                          : 'Pilih tanggal deadline (kosongkan jika tidak ada)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _deadline != null ? const Color(0xFF1B1B1F) : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                  if (_deadline != null)
                    GestureDetector(
                      onTap: () => setState(() => _deadline = null),
                      child: const Icon(Icons.close, size: 16, color: Color(0xFF9E9E9E)),
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
                backgroundColor: const Color(0xFFE29578),
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
                      'Kirim Request Revisi',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
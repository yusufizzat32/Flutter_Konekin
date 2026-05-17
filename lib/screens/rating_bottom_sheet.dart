import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class RatingBottomSheet extends StatefulWidget {
  final String projectId;
  final String projectTitle;
  final VoidCallback onRated;

  const RatingBottomSheet({
    super.key,
    required this.projectId,
    required this.projectTitle,
    required this.onRated,
  });

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  final ApiService _api = ApiService();
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pilih rating terlebih dahulu'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _api.submitRating(
      projectId: widget.projectId,
      rating: _rating,
      comment: _commentController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['message'] ??
          (result['success'] ? 'Rating berhasil dikirim!' : 'Gagal mengirim rating')),
      backgroundColor: result['success'] == true ? const Color(0xFF006D77) : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));

    if (result['success'] == true) widget.onRated();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEAE7ED),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Judul ─────────────────────────────────────────────────────
          Text('Beri Rating',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 4),
          Text(widget.projectTitle,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF424750))),

          const SizedBox(height: 24),

          // ── Bintang ───────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Text(
                  _rating == 0
                      ? 'Pilih rating'
                      : _getRatingLabel(_rating),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _rating == 0
                        ? const Color(0xFF9E9E9E)
                        : const Color(0xFF1A4B84),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = star),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          star <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 44,
                          color: star <= _rating
                              ? const Color(0xFFFFC107)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Komentar ──────────────────────────────────────────────────
          Text('Komentar (Opsional)',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText:
                  'Ceritakan pengalamanmu bekerja sama dengan kreator ini...',
              hintStyle: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF9E9E9E)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEAE7ED)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF1A4B84), width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            style: GoogleFonts.inter(fontSize: 14),
          ),

          const SizedBox(height: 20),

          // ── Tombol ────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCCC9D1)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Lewati',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF424750))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _rating == 0) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4B84),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: const Color(0xFFEAE7ED),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Kirim Rating',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1: return '😞 Mengecewakan';
      case 2: return '😕 Kurang Memuaskan';
      case 3: return '😊 Cukup Baik';
      case 4: return '😄 Memuaskan';
      case 5: return '🤩 Luar Biasa!';
      default: return '';
    }
  }
}
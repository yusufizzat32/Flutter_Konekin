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
  final TextEditingController _commentController = TextEditingController();

  int _selectedRating = 0;
  bool _isSubmitting = false;

  static const List<String> _labels = [
    '',
    'Mengecewakan',
    'Kurang Memuaskan',
    'Cukup Baik',
    'Memuaskan',
    'Luar Biasa!',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pilih rating bintang terlebih dahulu'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _api.rateCreative(
      widget.projectId,
      _selectedRating,
      _commentController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Rating berhasil dikirim!'),
        backgroundColor: const Color(0xFF006D77),
        behavior: SnackBarBehavior.floating,
      ));
      widget.onRated();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(result['message'] ?? 'Gagal mengirim rating'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC3C6D1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.star_rounded,
                  color: Color(0xFFFFB800), size: 32),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Beri Rating',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            widget.projectTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF424750)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    star <= _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 44,
                    color: star <= _selectedRating
                        ? const Color(0xFFFFB800)
                        : const Color(0xFFC3C6D1),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),

          // Label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _selectedRating > 0 ? _labels[_selectedRating] : '',
              key: ValueKey(_selectedRating),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _selectedRating > 0
                    ? const Color(0xFF1A4B84)
                    : Colors.transparent,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Comment field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAE7ED)),
            ),
            child: TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 500,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    'Tulis komentar (opsional) — pengalaman kerja sama, kualitas hasil, dll.',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF424750).withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                counterStyle: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF424750)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A4B84),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor:
                    const Color(0xFF1A4B84).withOpacity(0.5),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Kirim Rating',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Nanti Saja',
              style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF424750)),
            ),
          ),
        ],
      ),
    );
  }
}
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

  static const Map<String, Map<String, dynamic>> _tierInfo = {
    'beginner': {
      'label': 'Beginner',
      'color': Color(0xFF546E7A),
      'gradient': [Color(0xFF546E7A), Color(0xFF78909C)],
      'icon': Icons.emoji_events_outlined,
      'desc': '1–4 rating bintang 5',
    },
    'intermediate': {
      'label': 'Intermediate',
      'color': Color(0xFF1A4B84),
      'gradient': [Color(0xFF0D47A1), Color(0xFF1976D2)],
      'icon': Icons.workspace_premium_outlined,
      'desc': '5–14 rating bintang 5',
    },
    'expert': {
      'label': 'Expert',
      'color': Color(0xFFE65100),
      'gradient': [Color(0xFFBF360C), Color(0xFFFF6D00)],
      'icon': Icons.military_tech_outlined,
      'desc': '15+ rating bintang 5',
    },
  };

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      _showSnack('Pilih rating terlebih dahulu', isError: true);
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

    debugPrint('🔵 Rating result: $result');

    if (result['success'] == true) {
      // Cek apakah ada tier baru
      final tierData = result['data']?['tier_update'];
      final newTier = tierData?['new_tier']?.toString();
      final fiveStarCount = (tierData?['five_star_count'] as num?)?.toInt() ?? 0;

      if (_rating == 5 && newTier != null && _tierInfo.containsKey(newTier)) {
        await _showTierUnlockedDialog(newTier, fiveStarCount);
      } else {
        _showSnack(result['message'] ?? 'Rating berhasil dikirim!');
      }

      widget.onRated();
      if (mounted) Navigator.pop(context);
    } else {
      // Tampilkan pesan error LANGSUNG dari backend tanpa modifikasi
      final errorMsg = result['message'] ?? 'Gagal mengirim rating';
      _showSnack(errorMsg, isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF006D77),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: isError ? 5 : 3),
    ));
  }

  Future<void> _showTierUnlockedDialog(String tier, int count) async {
    final info = _tierInfo[tier]!;
    final gradColors = info['gradient'] as List<Color>;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: gradColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(info['icon'] as IconData, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text('🎉 Gelar Baru Terbuka!',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 4),
              Text(info['label'] as String,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                'Creative worker ini telah mendapatkan $count rating bintang 5!\n'
                'Profil mereka kini memiliki badge ${info['label']}.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.white.withOpacity(0.85), height: 1.5),
              ),
              const SizedBox(height: 24),
              // Preview 3 tier
              Row(
                children: _tierInfo.keys.map((t) {
                  final ti = _tierInfo[t]!;
                  final isActive = t == tier;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withOpacity(0.25)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive ? Colors.white : Colors.white24,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(ti['icon'] as IconData,
                              size: isActive ? 22 : 16, color: Colors.white),
                          const SizedBox(height: 4),
                          Text(ti['label'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                color: Colors.white,
                              )),
                          Text(ti['desc'] as String,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 8, color: Colors.white60)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: gradColors.last,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Keren! 🎊',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEAE7ED),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Judul
          Text('Beri Rating',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 4),
          Text(widget.projectTitle,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF424750))),
          const SizedBox(height: 8),

          // Debug info - project ID (bisa dihapus nanti)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 12, color: Color(0xFF1A4B84)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Rating bintang 5 membantu creative worker naik gelar Beginner → Intermediate → Expert',
                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF424750)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bintang
          Center(
            child: Column(
              children: [
                Text(
                  _rating == 0 ? 'Pilih rating' : _getRatingLabel(_rating),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _rating == 0 ? const Color(0xFF9E9E9E) : const Color(0xFF1A4B84),
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
                        child: AnimatedScale(
                          scale: star <= _rating ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            star <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 44,
                            color: star <= _rating
                                ? const Color(0xFFFFC107)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                if (_rating == 5) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium, size: 13, color: Color(0xFFFFC107)),
                        const SizedBox(width: 5),
                        Text('Berkontribusi ke kenaikan gelar!',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFFE65100),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Komentar
          Text('Komentar (Opsional)',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Ceritakan pengalamanmu bekerja sama dengan kreator ini...',
              hintStyle:
                  GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9E9E9E)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEAE7ED)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1A4B84), width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            style: GoogleFonts.inter(fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Tombol
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
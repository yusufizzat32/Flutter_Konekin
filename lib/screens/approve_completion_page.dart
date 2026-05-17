// lib/screens/approve_completion_page.dart
// UMKM mereview dan menyetujui (atau menolak) hasil kerja creative worker

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';
import 'rating_bottom_sheet.dart';

class ApproveCompletionPage extends StatefulWidget {
  final Project project;
  final List<Map<String, dynamic>> progressUpdates;

  const ApproveCompletionPage({
    super.key,
    required this.project,
    required this.progressUpdates,
  });

  @override
  State<ApproveCompletionPage> createState() => _ApproveCompletionPageState();
}

class _ApproveCompletionPageState extends State<ApproveCompletionPage> {
  final ApiService _api = ApiService();
  bool _isApproving = false;
  bool _isApproved = false;

  String _formatDate(String? raw) {
    if (raw == null) return '-';
    try {
      final d = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _handleApprove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Setujui Penyelesaian',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dengan menyetujui, kamu mengkonfirmasi bahwa hasil kerja sudah sesuai ekspektasimu.',
              style: GoogleFonts.inter(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF006D77).withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Dana escrow akan dikirimkan ke admin untuk diverifikasi, lalu dicairkan ke creative worker.',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF006D77),
                    height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: GoogleFonts.inter(color: const Color(0xFF424750))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D77),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Ya, Setujui',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isApproving = true);
    final result = await _api.approveCompletion(widget.project.id);
    if (!mounted) return;
    setState(() => _isApproving = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['message'] ??
          (result['success'] ? 'Penyelesaian disetujui!' : 'Gagal')),
      backgroundColor:
          result['success'] == true ? const Color(0xFF006D77) : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));

    if (result['success'] == true) {
      setState(() => _isApproved = true);
      // Tampilkan rating bottom sheet
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RatingBottomSheet(
          projectId: widget.project.id,
          projectTitle: widget.project.title,
          onRated: () {
            Navigator.pop(context); // tutup rating
            Navigator.pop(context, true); // kembali ke halaman sebelumnya
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Review Hasil Kerja',
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
            // ── Status Banner ──────────────────────────────────────────────
            if (_isApproved)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF006D77).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF006D77).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF006D77), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Penyelesaian sudah disetujui! Admin sedang memverifikasi dan akan mencairkan dana.',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF006D77),
                            fontWeight: FontWeight.w600,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Info Proyek ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003466), Color(0xFF1A4B84)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.project.title,
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  if (widget.project.selectedCreativeName != null)
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white24,
                            image: widget.project.selectedCreativeAvatar != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                        widget.project.selectedCreativeAvatar!),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: widget.project.selectedCreativeAvatar == null
                              ? Center(
                                  child: Text(
                                    widget.project.selectedCreativeName![0]
                                        .toUpperCase(),
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                            'Dikerjakan oleh ${widget.project.selectedCreativeName}',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _infoChip(Icons.check_circle_outline,
                          'Progress 100%', const Color(0xFF68FADD)),
                      const SizedBox(width: 8),
                      _infoChip(Icons.account_balance_wallet_outlined,
                          widget.project.budget, Colors.white70),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Riwayat Progress ───────────────────────────────────────────
            Text('Riwayat Update Progress',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xFF1B1B1F))),
            const SizedBox(height: 12),

            if (widget.progressUpdates.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text('Belum ada update progress yang tercatat',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFF424750))),
                ),
              )
            else
              ...widget.progressUpdates
                  .asMap()
                  .entries
                  .map((entry) => _buildProgressItem(
                        entry.value,
                        isLast:
                            entry.key == widget.progressUpdates.length - 1,
                      )),

            const SizedBox(height: 24),

            // ── Panduan Review ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yang Perlu Dicek',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF1B1B1F))),
                  const SizedBox(height: 12),
                  _checklistItem('Apakah hasil kerja sudah sesuai brief?'),
                  _checklistItem(
                      'Apakah semua revisi yang diminta sudah dikerjakan?'),
                  _checklistItem(
                      'Apakah kualitas sudah memenuhi ekspektasimu?'),
                  _checklistItem(
                      'Apakah file/deliverable sudah diterima lengkap?'),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Tombol Approve ─────────────────────────────────────────────
            if (!_isApproved)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isApproving ? null : _handleApprove,
                  icon: _isApproving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.verified_outlined, size: 20),
                  label: Text(
                    _isApproving
                        ? 'Memproses...'
                        : 'Setujui Penyelesaian Proyek',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006D77),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

            if (_isApproved)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.arrow_back_outlined, size: 20),
                  label: Text('Kembali ke Proyek',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4B84),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildProgressItem(Map<String, dynamic> update,
      {required bool isLast}) {
    final pct = int.tryParse(
            update['percentage']?.toString() ??
                update['progress_percentage']?.toString() ??
                '0') ??
        0;
    final note = update['note']?.toString() ?? '';
    final mediaUrl = update['media_url']?.toString();
    final createdAt = update['created_at']?.toString();

    final dotColor = pct >= 100
        ? const Color(0xFF006D77)
        : pct >= 50
            ? const Color(0xFFE29578)
            : const Color(0xFF1A4B84);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
                child: Center(
                  child: Text('$pct%',
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFEAE7ED),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.project.selectedCreativeName ?? 'Creative',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B1B1F))),
                      Text(_formatDate(createdAt),
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color(0xFF424750))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(note,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF424750),
                          height: 1.4)),
                  if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        mediaUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 60,
                          color: const Color(0xFFEAE7ED),
                          child: const Center(
                              child: Icon(Icons.broken_image_outlined)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.radio_button_unchecked,
              size: 16, color: Color(0xFF1A4B84)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF424750),
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
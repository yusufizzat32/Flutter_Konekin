// lib/screens/escrow_payment_page.dart
// UMKM melakukan pembayaran escrow untuk proyek yang sudah di-approve creative-nya

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';

class EscrowPaymentPage extends StatefulWidget {
  final Project project;

  const EscrowPaymentPage({super.key, required this.project});

  @override
  State<EscrowPaymentPage> createState() => _EscrowPaymentPageState();
}

class _EscrowPaymentPageState extends State<EscrowPaymentPage> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  bool _isPaid = false;

  String _formatBudget(String budget) {
    try {
      final num = double.parse(budget.replaceAll(RegExp(r'[^0-9.]'), ''));
      final formatted = num.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
      return 'Rp $formatted';
    } catch (_) {
      return 'Rp $budget';
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    final result = await _api.processPayment(widget.project.id);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _isPaid = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pembayaran escrow berhasil! Proyek dimulai.'),
        backgroundColor: Color(0xFF006D77),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Pembayaran gagal'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1B1B1F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pembayaran Escrow',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF1B1B1F),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info Proyek ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                  Text('Detail Proyek',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: const Color(0xFF1B1B1F))),
                  const SizedBox(height: 16),
                  _infoRow('Nama Proyek', project.title),
                  _infoRow('Kategori', project.category),
                  _infoRow('Durasi', project.duration),
                  _infoRow(
                    'Creative',
                    project.selectedCreativeName ?? '-',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Ringkasan Pembayaran ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                  Text('Ringkasan Pembayaran',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: const Color(0xFF1B1B1F))),
                  const SizedBox(height: 16),
                  _payRow('Budget Proyek', _formatBudget(project.budget)),
                  const Divider(height: 24),
                  _payRow(
                    'Total Escrow',
                    _formatBudget(project.budget),
                    isBold: true,
                    color: const Color(0xFF1A4B84),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Info Escrow ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A4B84).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: Color(0xFF1A4B84), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dana Anda akan disimpan secara aman oleh sistem escrow Konekin dan hanya akan diteruskan ke creative setelah Anda menyetujui hasil kerja.',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF1A4B84),
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Tombol Bayar ─────────────────────────────────────────────
            if (_isPaid)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF006D77).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF006D77)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF006D77), size: 22),
                    const SizedBox(width: 8),
                    Text('Pembayaran Berhasil',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: const Color(0xFF006D77))),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4B84),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFFEAE7ED),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          'Bayar ${_formatBudget(project.budget)}',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                ),
              ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF424750),
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF9E9E9E))),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B1B1F))),
          ),
        ],
      ),
    );
  }

  Widget _payRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                color: color ?? const Color(0xFF424750))),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: color ?? const Color(0xFF1B1B1F))),
      ],
    );
  }
}
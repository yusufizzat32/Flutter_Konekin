// lib/screens/escrow_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/escrow_service.dart';
import '../models/escrow_model.dart';

class EscrowDetailScreen extends StatefulWidget {
  const EscrowDetailScreen({super.key});

  @override
  State<EscrowDetailScreen> createState() => _EscrowDetailScreenState();
}

class _EscrowDetailScreenState extends State<EscrowDetailScreen> {
  final EscrowService _service = EscrowService();
  
  List<EscrowTransaction> _escrows = [];
  EarningsSummary? _earnings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadEscrows(),
      _loadEarnings(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadEscrows() async {
    final result = await _service.getEscrowTransactions();
    if (result['success'] == true) {
      setState(() => _escrows = result['escrows']);
    }
  }

  Future<void> _loadEarnings() async {
    final result = await _service.getEarnings();
    if (result['success'] == true) {
      setState(() => _earnings = result['earnings']);
    }
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
          'Detail Escrow',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B1F)),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF003466),
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF003466)))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildHistoryTitle(),
                  const SizedBox(height: 12),
                  ..._escrows.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _EscrowCard(escrow: e),
                  )),
                  if (_escrows.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.account_balance_wallet_rounded, size: 48, color: Color(0xFF003466)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada transaksi escrow',
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B1F)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Proyek yang sudah dipilih UMKM dan pembayaran sudah diverifikasi akan muncul di sini',
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_earnings == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF003466), Color(0xFF0056A8)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF003466).withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Pendapatan', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
              Text('${_earnings!.releasedCount} Proyek', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _earnings!.formattedTotalEarned,
            style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _SummaryStat(label: 'Ditahan', value: _earnings!.formattedPendingRelease, icon: Icons.pending_actions_rounded),
              const SizedBox(width: 12),
              _SummaryStat(label: 'Proses Cair', value: _earnings!.formattedInDisbursement, icon: Icons.sync_rounded),
              const SizedBox(width: 12),
              _SummaryStat(label: 'Selesai', value: '${_earnings!.releasedCount} proyek', icon: Icons.check_circle_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Riwayat Transaksi',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B1F)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Total: ${_escrows.length}',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF003466)),
          ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}

class _EscrowCard extends StatelessWidget {
  final EscrowTransaction escrow;

  const _EscrowCard({required this.escrow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  escrow.projectTitle,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B1F)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: escrow.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  escrow.statusLabel,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: escrow.statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  escrow.payer['name'] ?? 'UMKM',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                escrow.formattedAmount,
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF003466)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Text(
                _formatDate(escrow.createdAt),
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF)),
              ),
              const Spacer(),
              // Tampilkan fee hanya jika ada
              if (escrow.platformFee > 0)
                Text(
                  'Fee: ${escrow.formattedPlatformFee}',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF)),
                )
              else
                Text(
                  escrow.disbursementStatusLabel,
                  style: GoogleFonts.inter(fontSize: 11, color: escrow.statusColor),
                ),
            ],
          ),
          // Tampilkan info verified jika ada
          if (escrow.isVerified) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 12, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 4),
                  Text(
                    'Terverifikasi: ${_formatDate(escrow.verifiedAt!)}',
                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
          ],
          // Tampilkan info rejection jika ada
          if (escrow.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Ditolak: ${escrow.rejectionReason}',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.red),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Tampilkan info virtual account jika ada
          if (escrow.virtualAccountNumber != null && escrow.isPaymentPending) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance, size: 12, color: Color(0xFF1565C0)),
                  const SizedBox(width: 4),
                  Text(
                    'VA ${escrow.virtualAccountBank ?? 'BCA'}: ${escrow.virtualAccountNumber}',
                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF1565C0)),
                  ),
                ],
              ),
            ),
          ],
          // Tampilkan info disbursement jika sedang proses
          if (escrow.disbursementStatus == 'processing' || escrow.disbursementStatus == 'disbursing') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sedang diproses pencairan',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
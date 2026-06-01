import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class CreativeEarningsPage extends StatefulWidget {
  const CreativeEarningsPage({super.key});

  @override
  State<CreativeEarningsPage> createState() => _CreativeEarningsPageState();
}

class _CreativeEarningsPageState extends State<CreativeEarningsPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  Map<String, dynamic>? _earnings;
  List<Map<String, dynamic>> _escrowList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final earningsResult = await _api.getCreativeEarnings();
    final escrowResult = await _api.getCreativeEscrow();

    if (mounted) {
      setState(() {
        if (earningsResult['success'] == true) {
          _earnings = earningsResult['data'] is Map
              ? Map<String, dynamic>.from(earningsResult['data'])
              : earningsResult;
        }
        if (escrowResult['success'] == true && escrowResult['data'] != null) {
          final d = escrowResult['data'];
          if (d is List) {
            _escrowList =
                d.map((e) => Map<String, dynamic>.from(e)).toList();
          }
        }
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'Rp 0';
    final num = int.tryParse(value.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (num >= 1000000) return 'Rp ${(num / 1000000).toStringAsFixed(1)}jt';
    if (num >= 1000) return 'Rp ${(num / 1000).toStringAsFixed(0)}rb';
    return 'Rp $num';
  }

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

  Color _escrowStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'held': return const Color(0xFFE29578);
      case 'released': return const Color(0xFF006D77);
      case 'refunded': return Colors.red;
      default: return const Color(0xFF424750);
    }
  }

  String _escrowStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'held': return 'DITAHAN';
      case 'released': return 'DICAIRKAN';
      case 'refunded': return 'DIKEMBALIKAN';
      case 'unpaid': return 'BELUM BAYAR';
      default: return (status ?? '-').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Pendapatan & Escrow',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A4B84)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13),
          labelColor: const Color(0xFF1A4B84),
          unselectedLabelColor: const Color(0xFF424750),
          indicatorColor: const Color(0xFF1A4B84),
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Riwayat Escrow'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildEscrowTab(),
              ],
            ),
    );
  }

  Widget _buildSummaryTab() {
    final totalEarned = _earnings?['total_earned'] ?? _earnings?['total_released'] ?? 0;
    final totalHeld = _earnings?['total_held'] ?? 0;
    final totalProjects = _earnings?['total_projects'] ?? _escrowList.length;
    final completedProjects = _earnings?['completed_projects'] ??
        _escrowList.where((e) => e['status'] == 'released').length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Total Pendapatan ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF004C3F), Color(0xFF006D77)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Pendapatan',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(_formatCurrency(totalEarned),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _summaryChip(
                          '$totalProjects Proyek Total', Icons.work_outline),
                      const SizedBox(width: 12),
                      _summaryChip(
                          '$completedProjects Selesai', Icons.check_circle_outline),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Dana Ditahan ──────────────────────────────────────────────
            if (int.tryParse(totalHeld.toString().replaceAll(RegExp(r'[^0-9]'), '')) != null &&
                int.parse(totalHeld.toString().replaceAll(RegExp(r'[^0-9]'), '')) > 0)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE29578).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFE29578).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 24, color: Color(0xFFE29578)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dana Sedang Ditahan',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: const Color(0xFFE29578))),
                        Text(
                          _formatCurrency(totalHeld),
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: const Color(0xFFE29578)),
                        ),
                        Text('Menunggu persetujuan UMKM & admin',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: const Color(0xFF424750))),
                      ],
                    ),
                  ],
                ),
              ),

            // ── Statistik Cards ───────────────────────────────────────────
            Text('Statistik',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xFF1B1B1F))),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Proyek Aktif',
                    (_earnings?['active_projects'] ??
                            _escrowList
                                .where((e) => e['status'] == 'held')
                                .length)
                        .toString(),
                    Icons.pending_outlined,
                    const Color(0xFF1A4B84),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Selesai',
                    completedProjects.toString(),
                    Icons.verified_outlined,
                    const Color(0xFF006D77),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Cara Kerja ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alur Pembayaran',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF1B1B1F))),
                  const SizedBox(height: 12),
                  _flowStep('UMKM membayar ke escrow platform',
                      'Setelah progress 100%', const Color(0xFF1A4B84)),
                  _flowStep('Dana ditahan oleh platform',
                      'Selama review berlangsung', const Color(0xFFE29578)),
                  _flowStep('UMKM approve hasil kerja',
                      'Konfirmasi penyelesaian', const Color(0xFF006D77)),
                  _flowStep('Admin mencairkan dana',
                      'Dana masuk ke akunmu', const Color(0xFF68FADD)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800, fontSize: 20, color: color)),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF424750))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flowStep(String title, String sub, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: const Color(0xFF1B1B1F))),
                Text(sub,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF424750))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _escrowList.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: const Color(0xFF424750).withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('Belum ada transaksi escrow',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: const Color(0xFF424750))),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _escrowList.length,
              itemBuilder: (context, index) {
                final escrow = _escrowList[index];
                return _buildEscrowCard(escrow);
              },
            ),
    );
  }

  Widget _buildEscrowCard(Map<String, dynamic> escrow) {
    final status = escrow['status']?.toString() ?? '';
    final statusColor = _escrowStatusColor(status);
    final title = escrow['project_title']?.toString() ??
        escrow['title']?.toString() ??
        'Proyek';
    final amount =
        escrow['amount']?.toString() ?? escrow['budget']?.toString() ?? '0';
    final createdAt = escrow['created_at']?.toString() ??
        escrow['paid_at']?.toString();
    final releasedAt = escrow['released_at']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.2)),
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
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_escrowStatusLabel(status),
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_formatCurrency(amount),
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: const Color(0xFF1B1B1F))),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Color(0xFF424750)),
              const SizedBox(width: 4),
              Text('Dibuat: ${_formatDate(createdAt)}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF424750))),
              if (releasedAt != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.check_circle_outline,
                    size: 12, color: Color(0xFF006D77)),
                const SizedBox(width: 4),
                Text('Cair: ${_formatDate(releasedAt)}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF006D77))),
              ],
            ],
          ),
          if (status == 'held') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE29578).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Dana sedang ditahan platform. Menunggu UMKM menyetujui hasil kerja dan admin mengkonfirmasi.',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFE29578),
                    height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
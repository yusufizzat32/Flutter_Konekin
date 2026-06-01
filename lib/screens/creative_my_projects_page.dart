// lib/screens/creative_my_projects_page.dart
// Halaman proyek yang dikerjakan creative worker —
// menampilkan status lengkap + aksi update progress

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';
import 'creative_progress_update_page.dart';

class CreativeMyProjectsPage extends StatefulWidget {
  const CreativeMyProjectsPage({super.key});

  @override
  State<CreativeMyProjectsPage> createState() =>
      _CreativeMyProjectsPageState();
}

class _CreativeMyProjectsPageState extends State<CreativeMyProjectsPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  List<Map<String, dynamic>> _rawProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _api.getCreativeProjects();
    if (mounted) {
      setState(() {
        if (result['success'] == true && result['data'] != null) {
          final d = result['data'];
          if (d is List) {
            _rawProjects = d.map((e) => Map<String, dynamic>.from(e)).toList();
          } else if (d is Map && d['projects'] is List) {
            _rawProjects = (d['projects'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _byTab(int tab) {
    return _rawProjects.where((p) {
      final s = p['status']?.toString() ?? '';
      if (tab == 0) {
        // Sedang berjalan
        return [
          'hired', 'in_progress', 'ongoing',
          'ready_for_review', 'awaiting_payment', 'payment_pending'
        ].contains(s);
      } else if (tab == 1) {
        // Menunggu review / pending_admin
        return ['pending_admin_approval', 'revision', 'disputed'].contains(s);
      } else {
        // Selesai
        return ['completed', 'done', 'payment_refunded'].contains(s);
      }
    }).toList();
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'hired': return const Color(0xFF1A4B84);
      case 'in_progress':
      case 'ongoing': return const Color(0xFFE29578);
      case 'awaiting_payment': return const Color(0xFFE29578);
      case 'payment_pending': return Colors.orange;
      case 'ready_for_review': return const Color(0xFF006D77);
      case 'pending_admin_approval': return Colors.purple;
      case 'revision': return Colors.deepOrange;
      case 'disputed': return Colors.red;
      case 'completed':
      case 'done': return const Color(0xFF006D77);
      default: return const Color(0xFF424750);
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'hired': return 'WORKER DIPILIH';
      case 'in_progress':
      case 'ongoing': return 'SEDANG DIKERJAKAN';
      case 'awaiting_payment': return 'MENUNGGU PEMBAYARAN';
      case 'payment_pending': return 'VA MENUNGGU TRANSFER';
      case 'ready_for_review': return 'SIAP DIREVIEW';
      case 'pending_admin_approval': return 'MENUNGGU ADMIN';
      case 'revision': return 'REVISI';
      case 'disputed': return 'DISPUTE';
      case 'completed':
      case 'done': return 'SELESAI';
      case 'payment_refunded': return 'DANA DIKEMBALIKAN';
      default: return (s ?? '-').toUpperCase();
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '-';
    try {
      final d = DateTime.parse(raw);
      const months = [
        'Jan','Feb','Mar','Apr','Mei','Jun',
        'Jul','Ags','Sep','Okt','Nov','Des'
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Proyek Saya',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 12),
          labelColor: const Color(0xFF1A4B84),
          unselectedLabelColor: const Color(0xFF424750),
          indicatorColor: const Color(0xFF1A4B84),
          tabs: const [
            Tab(text: 'Berjalan'),
            Tab(text: 'Review'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(0),
                _buildList(1),
                _buildList(2),
              ],
            ),
    );
  }

  Widget _buildList(int tab) {
    final list = _byTab(tab);
    return RefreshIndicator(
      onRefresh: _load,
      child: list.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.folder_open_outlined,
                          size: 64,
                          color: const Color(0xFF424750).withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        tab == 0
                            ? 'Belum ada proyek berjalan'
                            : tab == 1
                                ? 'Tidak ada proyek menunggu review'
                                : 'Belum ada proyek selesai',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: const Color(0xFF424750)),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, i) => _ProjectCard(
                data: list[i],
                statusColor: _statusColor(list[i]['status']?.toString()),
                statusLabel: _statusLabel(list[i]['status']?.toString()),
                formatDate: _formatDate,
                onUpdateProgress: () async {
                  final project = Project.fromJson(list[i]);
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CreativeProgressUpdatePage(project: project),
                    ),
                  );
                  if (updated == true) _load();
                },
              ),
            ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color statusColor;
  final String statusLabel;
  final String Function(String?) formatDate;
  final VoidCallback onUpdateProgress;

  const _ProjectCard({
    required this.data,
    required this.statusColor,
    required this.statusLabel,
    required this.formatDate,
    required this.onUpdateProgress,
  });

  bool get _canUpdate {
    final s = data['status']?.toString() ?? '';
    return ['hired', 'in_progress', 'ongoing'].contains(s);
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'Proyek';
    final umkmName = data['client_name']?.toString() ??
        data['umkm_name']?.toString() ??
        '';
    final budget =
        data['budget']?.toString() ?? '0';
    final progress = int.tryParse(
            data['progress_percentage']?.toString() ?? '0') ??
        0;
    final deadline = data['deadline']?.toString();
    final progressUpdates = data['progress_updates'];
    final lastUpdate = progressUpdates is List && progressUpdates.isNotEmpty
        ? Map<String, dynamic>.from(progressUpdates.first)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
                const Spacer(),
                Text('Rp $budget',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF006D77))),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Judul ───────────────────────────────────────────────
                Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: const Color(0xFF1B1B1F))),
                const SizedBox(height: 4),
                if (umkmName.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.business_outlined,
                          size: 12, color: Color(0xFF424750)),
                      const SizedBox(width: 4),
                      Text(umkmName,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF424750))),
                    ],
                  ),
                const SizedBox(height: 12),

                // ── Progress Bar ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF424750))),
                    Text('$progress%',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: const Color(0xFFEAE7ED),
                    color: statusColor,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Deadline ────────────────────────────────────────────
                if (deadline != null)
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 13, color: Color(0xFF424750)),
                      const SizedBox(width: 5),
                      Text('Deadline: ${formatDate(deadline)}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF424750))),
                    ],
                  ),

                // ── Update terakhir ──────────────────────────────────────
                if (lastUpdate != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.history,
                            size: 14, color: Color(0xFF424750)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            lastUpdate['note']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF424750),
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Status Khusus ────────────────────────────────────────
                if (data['status'] == 'awaiting_payment') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE29578).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 14, color: Color(0xFFE29578)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Progress 100%! Menunggu UMKM melakukan pembayaran escrow.',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFFE29578),
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (data['status'] == 'ready_for_review') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006D77).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_outlined,
                            size: 14, color: Color(0xFF006D77)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dana sudah ditahan platform. Menunggu UMKM mereview dan menyetujui hasilmu.',
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
                if (data['status'] == 'pending_admin_approval') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings_outlined,
                            size: 14, color: Colors.purple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'UMKM sudah menyetujui. Admin sedang memverifikasi sebelum dana dicairkan.',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.purple,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // ── Tombol Aksi ──────────────────────────────────────────
                if (_canUpdate)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onUpdateProgress,
                      icon: const Icon(Icons.upload_outlined, size: 16),
                      label: Text('Kirim Update Progress',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A4B84),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// lib/screens/project_progress_detail.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';
import 'project_applicants.dart';

class ProjectProgressDetailPage extends StatefulWidget {
  final Project project;

  const ProjectProgressDetailPage({super.key, required this.project});

  @override
  State<ProjectProgressDetailPage> createState() => _ProjectProgressDetailPageState();
}

class _ProjectProgressDetailPageState extends State<ProjectProgressDetailPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _projectData;
  List<Map<String, dynamic>> _progressUpdates = [];
  List<Map<String, dynamic>> _applicants = [];
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isApproving = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);

    // Ambil data lengkap proyek + progress updates + applicants
    final projectDetail = await _api.getProjectDetail(widget.project.id);
    final applications = await _api.getProjectApplications(widget.project.id);
    final progressData = await _api.getUMKMProjectProgress(); // endpoint progress

    if (mounted) {
      setState(() {
        if (projectDetail['success'] && projectDetail['data'] != null) {
          _projectData = Map<String, dynamic>.from(projectDetail['data']);
        } else {
          _projectData = widget.project.toJson();
        }

        if (applications['success'] && applications['data'] != null) {
          final data = applications['data'];
          if (data is List) {
            _applicants = data.map((e) => Map<String, dynamic>.from(e)).toList();
          } else if (data is Map && data['applications'] is List) {
            _applicants = (data['applications'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }

        if (progressData['success'] && progressData['data'] != null) {
          final updates = progressData['data']['updates'] ?? progressData['data'];
          if (updates is List) {
            _progressUpdates = updates
                .where((u) => u['project_id'].toString() == widget.project.id.toString())
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
        _isLoading = false;
      });
    }
  }

  int get _currentProgress {
    if (_projectData != null) {
      return int.tryParse(_projectData!['progress_percentage']?.toString() ?? '0') ?? 0;
    }
    if (widget.project.status == 'completed') return 100;
    if (widget.project.status == 'in_progress') return 50;
    return 0;
  }

  String get _currentStatus => _projectData?['status']?.toString() ?? widget.project.status;
  bool get _isOpen => _currentStatus == 'open';
  bool get _isCompleted => _currentStatus == 'completed' || _currentStatus == 'done';
  bool get _hasSelectedCreative => _projectData?['selected_creative_id'] != null;
  int get _applicantCount => _applicants.length;

  String get _selectedCreativeName {
    return _projectData?['selected_creative_name']?.toString() ?? '';
  }

  // Status tiap langkah
  bool get isStep1Done => _hasSelectedCreative;
  bool get isStep2Done => _currentProgress >= 100;
  bool get isStep3Done => _projectData?['payment_status'] == 'paid';
  bool get isStep4Done => _projectData?['review_status'] == 'approved';
  bool get isStep5Done => _projectData?['admin_release'] == true;

  String get nextActionText {
    if (_isCompleted) return 'Proyek telah selesai';
    if (!isStep1Done) return 'Menunggu apply: Belum ada creative worker yang apply ke proyek ini.';
    if (isStep1Done && !isStep2Done) return 'Menunggu creative worker menyelesaikan draft 100%';
    if (isStep2Done && !isStep3Done) return 'Segera lakukan pembayaran escrow';
    if (isStep3Done && !isStep4Done) return 'Review hasil pekerjaan creative worker';
    if (isStep4Done && !isStep5Done) return 'Menunggu admin melepas dana escrow';
    return 'Proyek selesai';
  }

  Future<void> _handleDeleteProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Proyek', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Apakah Anda yakin ingin menghapus proyek "${widget.project.title}"?\n\nProyek yang sudah dihapus tidak dapat dikembalikan.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isDeleting = true);
    final result = await _api.deleteUmkmProject(widget.project.id);
    if (!mounted) return;
    setState(() => _isDeleting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['message'] ?? 'Proyek dihapus'),
      backgroundColor: result['success'] ? const Color(0xFF006D77) : Colors.red,
    ));
    if (result['success']) Navigator.pop(context, true);
  }

  Future<void> _approveApplicant(int applicationId, String creativeName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Konfirmasi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Setujui $creativeName untuk mengerjakan proyek ini?\n\nCreative worker lain akan otomatis ditolak.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006D77), foregroundColor: Colors.white),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _isApproving = true;
    });
    final result = await _api.approveApplication(widget.project.id, applicationId);
    if (mounted) {
      setState(() => _isApproving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Berhasil menyetujui'),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ));
      if (result['success']) _loadDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          'Status Proyek',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A4B84)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Proyek + Ringkasan Dana (seperti desain)
                    _buildHeaderCard(),
                    const SizedBox(height: 16),

                    // Timeline 5 Langkah
                    _buildProgressStepper(),
                    const SizedBox(height: 20),

                    // Progress Bar & Aksi Berikutnya
                    _buildProgressAndNextAction(),
                    const SizedBox(height: 20),

                    // Pelamar (jika masih open)
                    if (_isOpen) _buildApplicantsSection(),
                    if (_isOpen) const SizedBox(height: 20),

                    // Riwayat Update
                    _buildProgressHistory(),
                    const SizedBox(height: 20),

                    // Hapus Proyek (jika belum ada applicant)
                    if (_isOpen && _applicantCount == 0) _buildDeleteButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    final budget = widget.project.budget;
    final escrowStatus = _projectData?['payment_status'] == 'paid' ? 'PAID' : 'UNPAID';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003466), Color(0xFF1A4B84)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kiri: info proyek
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.project.category.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF68FADD)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.project.title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.project.description.length > 80
                      ? '${widget.project.description.substring(0, 80)}...'
                      : widget.project.description,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      'Deadline: ${_formatDate(widget.project.deadline)}',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 14, color: Color(0xFF68FADD)),
                    const SizedBox(width: 4),
                    Text(
                      budget,
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF68FADD)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Kanan: Ringkasan Dana
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RINGKASAN DANA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70)),
                const SizedBox(height: 8),
                _summaryRow('Budget', budget, Colors.white),
                _summaryRow('Escrow', escrowStatus, escrowStatus == 'PAID' ? const Color(0xFF68FADD) : Colors.white70),
                _summaryRow('Pelamar', '$_applicantCount', Colors.white70),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildProgressStepper() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _stepItem(1, 'PILIH WORKER', isStep1Done, 'Review pelamar'),
          _stepConnector(isStep1Done),
          _stepItem(2, 'DRAFT 100%', isStep2Done, 'Tunggu progress'),
          _stepConnector(isStep2Done),
          _stepItem(3, 'BAYAR ESCROW', isStep3Done, 'VA + bukti'),
          _stepConnector(isStep3Done),
          _stepItem(4, 'REVIEW HASIL', isStep4Done, 'Approve/revisi'),
          _stepConnector(isStep4Done),
          _stepItem(5, 'ADMIN RELEASE', isStep5Done, 'Cair/refund'),
        ],
      ),
    );
  }

  Widget _stepItem(int number, String title, bool isDone, String subtitle) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF006D77) : const Color(0xFFEAE7ED),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text('$number', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF424750))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B1F))),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF424750))),
            ],
          ),
        ),
        if (isDone)
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF006D77)),
      ],
    );
  }

  Widget _stepConnector(bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Container(
        height: 24,
        width: 2,
        color: isDone ? const Color(0xFF006D77) : const Color(0xFFEAE7ED),
      ),
    );
  }

  Widget _buildProgressAndNextAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROGRESS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF424750))),
              Text('$_currentProgress%', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF006D77))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _currentProgress / 100,
              backgroundColor: const Color(0xFFEAE7ED),
              color: const Color(0xFF006D77),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentProgress == 0 && _applicantCount == 0
                ? 'Belum ada creative worker yang apply. Progress masih 0%.'
                : '$_currentProgress% sudah dikerjakan oleh creative worker.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF424750)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AKSI BERIKUTNYA', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1A4B84))),
                const SizedBox(height: 6),
                Text(nextActionText, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF424750))),
                if (_isOpen && _applicantCount == 0 && !_isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isDeleting ? null : _handleDeleteProject,
                        icon: _isDeleting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: Text(_isDeleting ? 'Menghapus...' : 'HAPUS PROYEK'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
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

  Widget _buildApplicantsSection() {
    if (_applicantCount == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PELAMAR', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFFF5F3F7), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 40, color: const Color(0xFF424750).withOpacity(0.3)),
                  const SizedBox(height: 8),
                  Text('Belum ada apply masuk',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF424750))),
                  const SizedBox(height: 4),
                  Text('Proposal creative worker akan muncul di sini setelah mereka apply.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF424750))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PELAMAR', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProjectApplicantsPage(project: widget.project)),
                  ).then((_) => _loadDetail());
                },
                child: Text('Lihat Detail', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A4B84))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._applicants.take(2).map((applicant) => _applicantTile(applicant)),
          if (_applicants.length > 2)
            Text('+ ${_applicants.length - 2} pelamar lainnya', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF424750))),
        ],
      ),
    );
  }

  Widget _applicantTile(Map<String, dynamic> applicant) {
    final name = applicant['creative_name']?.toString() ?? 'Tanpa Nama';
    final status = applicant['status']?.toString() ?? 'applied';
    final isApproved = status == 'approved';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF1A4B84).withOpacity(0.2),
            child: Text(name[0], style: const TextStyle(color: Color(0xFF1A4B84))),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
          if (!isApproved && _isOpen)
            ElevatedButton(
              onPressed: _isApproving ? null : () => _approveApplicant(applicant['id'], name),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006D77),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Setujui', style: TextStyle(fontSize: 11)),
            )
          else if (isApproved)
            const Icon(Icons.check_circle, size: 18, color: Color(0xFF006D77)),
        ],
      ),
    );
  }

  Widget _buildProgressHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RIWAYAT', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (_progressUpdates.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFFF5F3F7), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Icon(Icons.timeline, size: 40, color: const Color(0xFF424750).withOpacity(0.3)),
                  const SizedBox(height: 8),
                  Text('Belum ada update progress',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF424750))),
                  const SizedBox(height: 4),
                  Text('Update dari creative worker akan tampil sebagai timeline di sini.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF424750))),
                ],
              ),
            )
          else
            ..._progressUpdates.map((update) => _historyTile(update)),
        ],
      ),
    );
  }

  Widget _historyTile(Map<String, dynamic> update) {
    final pct = update['progress_percentage'] ?? update['percentage'] ?? 0;
    final note = update['note'] ?? '';
    final createdAt = update['created_at'] ?? '';
    final creativeName = update['creative_name'] ?? _selectedCreativeName;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF006D77).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text('$pct%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF006D77)))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(creativeName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(note, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF424750))),
                const SizedBox(height: 4),
                Text(_formatDateTime(createdAt), style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF424750))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Proyek belum punya pelamar', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.red.shade400)),
                Text('Jika belum dibutuhkan, proyek masih bisa dihapus.', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF424750))),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _handleDeleteProject,
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
            label: const Text('HAPUS', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tidak ditentukan';
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _formatDateTime(String raw) {
    try {
      final date = DateTime.parse(raw);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';

/// [isOwner] = true  → tampilkan tab Info + Pelamar (dipakai dari dashboard/proyek UMKM)
/// [isOwner] = false → tampilkan tombol Lamar (default, dipakai dari explore creative)
class ProjectDetailPage extends StatefulWidget {
  final int projectId;
  final bool isOwner;

  const ProjectDetailPage({
    super.key,
    required this.projectId,
    this.isOwner = false,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  Project? _project;
  bool _isLoading = true;
  bool _isApplying = false;

  // Tab controller — hanya aktif kalau isOwner
  late TabController _tabController;

  // Applicants
  List<Map<String, dynamic>> _applicants = [];
  bool _isLoadingApplicants = false;
  bool _isApproving = false;
  int? _approvingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isOwner ? 2 : 1,
      vsync: this,
    );
    _loadProjectDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectDetail() async {
    setState(() => _isLoading = true);
    final result = await _api.getProjectDetail(widget.projectId);
    if (mounted) {
      setState(() {
        if (result['success'] && result['data'] != null) {
          _project = Project.fromJson(result['data']);
        }
        _isLoading = false;
      });
      if (widget.isOwner) _loadApplicants();
    }
  }

  Future<void> _loadApplicants() async {
    setState(() => _isLoadingApplicants = true);
    final result = await _api.getProjectApplications(widget.projectId);
    if (mounted) {
      setState(() {
        if (result['success'] && result['data'] != null) {
          final data = result['data'];
          if (data is List) {
            _applicants = data.map((e) => Map<String, dynamic>.from(e)).toList();
          } else if (data is Map && data['applications'] is List) {
            _applicants = (data['applications'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
        _isLoadingApplicants = false;
      });
    }
  }

  Future<void> _applyToProject() async {
    setState(() => _isApplying = true);
    final result = await _api.applyToProject(widget.projectId);
    if (mounted) {
      setState(() => _isApplying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (result['success']) Navigator.pop(context);
    }
  }

  void _showApplyConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Lamar'),
        content: Text('Apakah Anda yakin ingin melamar proyek "${_project?.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyToProject();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D77),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lamar Sekarang'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveApplicant(int applicationId, String creativeName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Konfirmasi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Setujui $creativeName untuk mengerjakan proyek ini?\n\nCreative worker lain akan otomatis ditolak.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D77),
              foregroundColor: Colors.white,
            ),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isApproving = true;
      _approvingId = applicationId;
    });

    final result = await _api.approveApplication(widget.projectId, applicationId);

    if (mounted) {
      setState(() {
        _isApproving = false;
        _approvingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Berhasil menyetujui'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (result['success']) _loadApplicants();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          'Detail Proyek',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A4B84)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: widget.isOwner
            ? TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1A4B84),
                unselectedLabelColor: const Color(0xFF424750),
                indicatorColor: const Color(0xFF1A4B84),
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13),
                tabs: const [
                  Tab(text: 'Info Proyek'),
                  Tab(text: 'Pelamar'),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _project == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: const Color(0xFF424750).withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('Proyek tidak ditemukan',
                          style: GoogleFonts.inter(color: const Color(0xFF424750))),
                    ],
                  ),
                )
              : widget.isOwner
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInfoTab(),
                        _buildApplicantsTab(),
                      ],
                    )
                  : _buildInfoTab(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1: INFO PROYEK
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildInfoTab() {
    final p = _project!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          if (p.thumbnail != null && p.thumbnail!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                p.thumbnail!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (p.thumbnail != null && p.thumbnail!.isNotEmpty) const SizedBox(height: 16),

          // Header card
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
                Row(
                  children: [
                    _statusBadge(p.status),
                    const Spacer(),
                    if (p.umkmName != null)
                      Text(p.umkmName!,
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  p.title,
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800, fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 4),
                if (p.applicantCount != null)
                  Text(
                    '${p.applicantCount} creative sudah apply',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _headerStat('Budget', p.budget, highlight: true),
                    ),
                    if (p.deadline != null)
                      Expanded(
                        child: _headerStat(
                          'Deadline',
                          _formatDate(p.deadline!),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Deskripsi
          _sectionTitle('Deskripsi Proyek'),
          const SizedBox(height: 12),
          _card(
            child: Text(
              p.description,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF424750), height: 1.5),
            ),
          ),

          const SizedBox(height: 20),

          // Kebutuhan / Spesifikasi
          _sectionTitle('Kebutuhan / Spesifikasi'),
          const SizedBox(height: 12),
          _card(
            child: p.skills.isNotEmpty
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.skills
                        .map((s) => _skillChip(s))
                        .toList(),
                  )
                : Text(
                    'Belum ada spesifikasi tambahan dari UMKM.',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF424750).withOpacity(0.5),
                        fontStyle: FontStyle.italic),
                  ),
          ),

          const SizedBox(height: 20),

          // Deadline
          _sectionTitle('Deadline Pengerjaan'),
          const SizedBox(height: 12),
          _card(
            child: Text(
              p.deadline != null ? _formatDateLong(p.deadline!) : 'Tidak ditentukan',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1B1B1F)),
            ),
          ),

          const SizedBox(height: 20),

          // UMKM Info
          if (p.umkmName != null) ...[
            _card(
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront, color: Color(0xFF1A4B84)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.umkmName!,
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        if (p.umkmCity != null)
                          Text(p.umkmCity!,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: const Color(0xFF424750))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Progress bar (owner view)
          if (widget.isOwner) ...[
            _sectionTitle('Progress Proyek'),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_getProgressFromStatus(p.status)}%  Berjalan',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF424750)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _getProgressFromStatus(p.status) / 100,
                      backgroundColor: const Color(0xFFEAE7ED),
                      color: const Color(0xFF006D77),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _applicants.isEmpty
                        ? 'Belum ada creative worker yang apply. Progress masih 0%.'
                        : 'Belum ada update progress yang dikirim creative worker.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF424750).withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Apply button (creative view)
          if (!widget.isOwner && p.status == 'open') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isApplying ? null : _showApplyConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006D77),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isApplying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Lamar Proyek',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2: PELAMAR (hanya untuk owner)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildApplicantsTab() {
    if (_isLoadingApplicants) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '${_applicants.length} Pelamar',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B1F)),
          ),
        ),
        Expanded(
          child: _applicants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: const Color(0xFF424750).withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('Belum ada creative worker yang apply ke proyek ini.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: const Color(0xFF424750))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadApplicants,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _applicants.length,
                    itemBuilder: (context, index) =>
                        _buildApplicantCard(_applicants[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> applicant) {
    final id = applicant['id']?.toString() ?? '';
    final name = applicant['creative_name']?.toString() ?? 'Tanpa Nama';
    final city = applicant['creative_city']?.toString() ?? '';
    final message = applicant['message']?.toString() ?? '';
    final proposalUrl = applicant['proposal_url']?.toString();
    final status = applicant['status']?.toString() ?? 'applied';
    final appliedAt = applicant['applied_at']?.toString();
    final avatar = applicant['creative_avatar']?.toString();

    final isApproved = status == 'approved';
    final isApprovingThis = _approvingId?.toString() == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApproved
              ? const Color(0xFF006D77).withOpacity(0.3)
              : const Color(0xFFC3C6D1).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatarWidget(avatar, name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    if (city.isNotEmpty)
                      Row(children: [
                        Icon(Icons.location_on, size: 12, color: const Color(0xFF424750)),
                        const SizedBox(width: 4),
                        Text(city,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: const Color(0xFF424750))),
                      ]),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved
                      ? const Color(0xFF006D77).withOpacity(0.1)
                      : const Color(0xFFE29578).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isApproved ? 'DISETUJUI' : 'MENUNGGU',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isApproved ? const Color(0xFF006D77) : const Color(0xFFE29578),
                  ),
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Pesan Lamaran:',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF424750))),
            const SizedBox(height: 4),
            Text(message,
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF424750), height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
          if (appliedAt != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.access_time, size: 12, color: const Color(0xFF424750)),
              const SizedBox(width: 4),
              Text('Melamar: ${_formatDateStr(appliedAt)}',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF424750))),
            ]),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (proposalUrl != null && proposalUrl.isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Proposal: $proposalUrl'))),
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text('Lihat Proposal'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A4B84),
                      side: const BorderSide(color: Color(0xFF1A4B84)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (!isApproved)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isApproving && isApprovingThis)
                        ? null
                        : () => _approveApplicant(int.tryParse(id) ?? 0, name),
                    icon: isApprovingThis
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(isApprovingThis ? 'Menyetujui...' : 'Setujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006D77),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER WIDGETS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _statusBadge(String status) {
    final isOpen = status == 'open' || status == 'published' || status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFF68FADD).withOpacity(0.2) : Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'OPEN' : status.toUpperCase(),
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isOpen ? const Color(0xFF68FADD) : Colors.white70),
      ),
    );
  }

  Widget _headerStat(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
        Text(value,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: highlight ? 18 : 15,
              color: highlight ? const Color(0xFF68FADD) : Colors.white,
            )),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF1A4B84)),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
          ],
        ),
        child: child,
      );

  Widget _skillChip(String skill) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A4B84).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1A4B84).withOpacity(0.2)),
        ),
        child: Text(skill,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A4B84))),
      );

  Widget _avatarWidget(String? avatar, String name) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFEAE7ED),
          shape: BoxShape.circle,
          image: (avatar != null && avatar.isNotEmpty)
              ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover)
              : null,
        ),
        child: (avatar == null || avatar.isEmpty)
            ? Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: const Color(0xFF1A4B84)),
                ),
              )
            : null,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  int _getProgressFromStatus(String status) {
    switch (status) {
      case 'completed':
      case 'done':
        return 100;
      case 'in_progress':
      case 'ongoing':
        return 65;
      case 'hired':
        return 10;
      default:
        return 0;
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateLong(DateTime date) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateStr(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return _formatDate(date);
    } catch (_) {
      return dateStr;
    }
  }
}
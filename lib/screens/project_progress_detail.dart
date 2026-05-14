// lib/screens/project_progress_detail.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';
import 'rating_bottom_sheet.dart';
import 'project_applicants.dart';

class ProjectProgressDetailPage extends StatefulWidget {
  final Project project;

  const ProjectProgressDetailPage({super.key, required this.project});

  @override
  State<ProjectProgressDetailPage> createState() =>
      _ProjectProgressDetailPageState();
}

class _ProjectProgressDetailPageState
    extends State<ProjectProgressDetailPage> {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _projectData;
  List<Map<String, dynamic>> _progressUpdates = [];
  List<Map<String, dynamic>> _applicants = [];
  bool _isLoading = true;
  bool _isDeleting = false;

  static const List<Map<String, String>> _steps = [
    {'label': 'PILIH WORKER', 'sub': 'Review pelamar'},
    {'label': 'DRAFT 100%', 'sub': 'Tunggu progress'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);

    final result = await _api.getUmkmProjects();
    final appResult = await _api.getProjectApplications(widget.project.id);

    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      final raw = result['data'];
      List<dynamic> allProjects = raw is List
          ? raw
          : (raw is Map ? (raw['projects'] ?? raw['data'] ?? []) : []);

      final matched = allProjects
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (p) => p['id'].toString() == widget.project.id.toString(),
            orElse: () => <String, dynamic>{},
          );

      if (matched.isNotEmpty) {
        final updates = matched['progress_updates'];
        _projectData = matched;
        _progressUpdates = updates is List
            ? updates.map((u) => Map<String, dynamic>.from(u)).toList()
            : [];
      } else {
        _projectData = widget.project.toJson();
        _progressUpdates = [];
      }
    } else {
      _projectData = widget.project.toJson();
      _progressUpdates = [];
    }

    if (appResult['success'] == true && appResult['data'] != null) {
      final d = appResult['data'];
      if (d is List) {
        _applicants = d.map((e) => Map<String, dynamic>.from(e)).toList();
      } else if (d is Map && d['applications'] is List) {
        _applicants = (d['applications'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  String get _currentStatus =>
      _projectData?['status']?.toString() ?? widget.project.status;

  int get _currentProgress {
    if (_projectData != null) {
      return int.tryParse(
              _projectData!['progress_percentage']?.toString() ?? '0') ??
          0;
    }
    if (_currentStatus == 'completed') return 100;
    if (_currentStatus == 'in_progress') return 50;
    return 0;
  }

  bool get _isCompleted =>
      _currentStatus == 'completed' || _currentStatus == 'done';
  bool get _isOpen => _currentStatus == 'open' ||
      _currentStatus == 'pending' ||
      _currentStatus == 'published';
  bool get _isHired => _currentStatus == 'hired';
  bool get _isInProgress =>
      _currentStatus == 'in_progress' || _currentStatus == 'ongoing';

  int get _activeStep {
    switch (_currentStatus) {
      case 'open':
      case 'pending':
      case 'published':
        return 0;
      case 'hired':
        return 1;
      case 'in_progress':
      case 'ongoing':
        return 2;
      case 'reviewing':
        return 3;
      case 'completed':
      case 'done':
        return 4;
      default:
        return 0;
    }
  }

  String get _nextActionTitle {
    switch (_activeStep) {
      case 0:
        return _applicants.isEmpty ? 'Menunggu apply' : 'Review & Pilih Kreator';
      case 1:
        return 'Tunggu draft selesai';
      case 2:
        return 'Amankan dana escrow';
      case 3:
        return 'Review hasil kerja';
      case 4:
        return 'Selesai! Dana dicairkan';
      default:
        return '-';
    }
  }

  String get _nextActionDesc {
    switch (_activeStep) {
      case 0:
        return _applicants.isEmpty
            ? 'Proyek belum punya pelamar. Jika belum dibutuhkan, proyek masih bisa dihapus.'
            : 'Ada ${_applicants.length} pelamar menunggu. Pilih kreator terbaik untuk proyekmu.';
      case 1:
        return 'Kreator sedang mengerjakan draft. Pantau update progress di bawah.';
      case 2:
        return 'UMKM wajib membayar setelah draft 100%. Dana ditahan platform, bukan langsung cair ke creative worker.';
      case 3:
        return 'Periksa hasil kerja kreator. Approve jika sesuai, atau minta revisi.';
      case 4:
        return 'Proyek selesai. Admin akan mencairkan dana ke kreator setelah konfirmasi.';
      default:
        return '';
    }
  }

  Map<String, dynamic>? get _approvedApplicant {
    try {
      return _applicants.firstWhere(
        (a) => a['status']?.toString() == 'approved',
      );
    } catch (_) {
      return null;
    }
  }

  String get _escrowStatus =>
      _projectData?['escrow_status']?.toString() ?? 'UNPAID';

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

  String get _resolvedProjectId {
    if (widget.project.id.isNotEmpty) return widget.project.id;
    final fromServer = _projectData?['id'];
    if (fromServer != null && fromServer.toString().isNotEmpty) {
      return fromServer.toString();
    }
    return '';
  }

  Future<void> _handleDeleteProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Proyek',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Apakah Anda yakin ingin menghapus proyek "${widget.project.title}"?\n\nProyek yang sudah dihapus tidak dapat dikembalikan.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Hapus', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final projectId = _resolvedProjectId;
    if (projectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Gagal: ID proyek tidak valid. Coba refresh halaman.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isDeleting = true);
    final result = await _api.deleteUmkmProject(projectId);
    if (!mounted) return;
    setState(() => _isDeleting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['message'] ?? 'Proyek dihapus'),
      backgroundColor:
          result['success'] == true ? const Color(0xFF006D77) : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
    if (result['success'] == true) Navigator.pop(context, true);
  }

  void _handleRate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RatingBottomSheet(
        projectId: widget.project.id,
        projectTitle: widget.project.title,
        onRated: () {
          Navigator.pop(context);
          _loadDetail();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          'Progress Proyek',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A4B84)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Color(0xFF424750)),
            onPressed: () {},
          ),
          if (_projectData?['user_avatar'] != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundImage:
                    NetworkImage(_projectData!['user_avatar'].toString()),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF1A4B84),
                child: Text(
                  (widget.project.umkmName ?? 'U').substring(0, 1).toUpperCase(),
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 12),
                    _buildStepperSection(),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildProgressCard(),
                          const SizedBox(height: 10),
                          _buildNextActionCard(),
                          const SizedBox(height: 10),
                          _buildDanaSummaryCard(),
                          const SizedBox(height: 10),
                          _buildApplicantsSection(),
                          const SizedBox(height: 10),
                          _buildProgressUpdatesSection(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStepperSection() {
    final step0Done = _currentStatus != 'open' &&
        _currentStatus != 'pending' &&
        _currentStatus != 'published';
    final step0Active = _isOpen;
    final step1Done = _currentProgress >= 100;
    final step1Active = step0Done && !step1Done;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepItem(
            number: 1,
            label: _steps[0]['label']!,
            sub: _steps[0]['sub']!,
            isDone: step0Done,
            isActive: step0Active,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 20),
              color: step0Done ? const Color(0xFF006D77) : const Color(0xFFE0E0E0),
            ),
          ),
          _stepItem(
            number: 2,
            label: _steps[1]['label']!,
            sub: _steps[1]['sub']!,
            isDone: step1Done,
            isActive: step1Active,
          ),
        ],
      ),
    );
  }

  Widget _stepItem({
    required int number,
    required String label,
    required String sub,
    required bool isDone,
    required bool isActive,
  }) {
    Color circleBg;
    Color textColor;
    Widget numberWidget;

    if (isDone) {
      circleBg = const Color(0xFF006D77);
      textColor = const Color(0xFF006D77);
      numberWidget = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isActive) {
      circleBg = const Color(0xFF1A4B84);
      textColor = const Color(0xFF1A4B84);
      numberWidget = Text('$number',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white));
    } else {
      circleBg = const Color(0xFFE0E0E0);
      textColor = const Color(0xFF9E9E9E);
      numberWidget = Text('$number',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white));
    }

    return Container(
      width: 90,
      padding: isActive
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: isActive
          ? BoxDecoration(
              border: Border.all(color: const Color(0xFF1A4B84), width: 1.5),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
            child: Center(child: numberWidget),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: textColor),
          ),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 8, color: const Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.project.thumbnail != null && widget.project.thumbnail!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.project.thumbnail!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: const Color(0xFFEAE7ED),
                    child: const Icon(Icons.image_outlined,
                        size: 48, color: Color(0xFF424750)),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: const Color(0xFF1A4B84),
                  child: const Center(
                    child: Icon(Icons.work_outline, size: 64, color: Colors.white38),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _badge(widget.project.category.toUpperCase(),
                        const Color(0xFF1A4B84)),
                    const SizedBox(width: 6),
                    if (_isOpen)
                      _badge('BELUM ADA APPLY', const Color(0xFF424750)),
                    if (_isOpen) ...[
                      const SizedBox(width: 6),
                      _badge('0 APPLY', const Color(0xFF424750)),
                    ],
                    if (_isHired || _isInProgress)
                      _badge('${_applicants.length} APPLY', const Color(0xFF006D77)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.project.title,
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: const Color(0xFF1B1B1F)),
                ),
                const SizedBox(height: 6),
                if (widget.project.description != null &&
                    widget.project.description!.isNotEmpty)
                  Text(
                    widget.project.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF424750),
                        height: 1.4),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: Color(0xFF424750)),
                      const SizedBox(width: 4),
                      Text(
                        'Deadline ${_formatDate(widget.project.deadline?.toIso8601String())}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF424750)),
                      ),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 13, color: Color(0xFF006D77)),
                      const SizedBox(width: 4),
                      Text(
                        widget.project.budget,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF006D77),
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                    if (_approvedApplicant != null)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.person_outline,
                            size: 13, color: Color(0xFF1A4B84)),
                        const SizedBox(width: 4),
                        Text(
                          _approvedApplicant!['creative_name']?.toString() ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF1A4B84)),
                        ),
                      ]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final pct = _currentProgress;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROGRESS',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF424750),
                      letterSpacing: 1.0)),
              Text(
                '$pct%',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: pct >= 100
                        ? const Color(0xFF006D77)
                        : const Color(0xFF1A4B84)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: const Color(0xFFEAE7ED),
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 100
                    ? const Color(0xFF006D77)
                    : pct >= 50
                        ? const Color(0xFFE29578)
                        : const Color(0xFF1A4B84),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct >= 100
                ? 'Pekerjaan selesai 100%!'
                : _isOpen
                    ? 'Belum ada creative worker yang apply. Progress masih 0%.'
                    : 'Creative worker sedang mengerjakan projekmu.',
            style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF424750).withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildNextActionCard() {
    final isDelete = _isOpen && _applicants.isEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AKSI BERIKUTNYA',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF006D77),
                  letterSpacing: 1.0)),
          const SizedBox(height: 6),
          Text(
            _nextActionTitle,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: const Color(0xFF1B1B1F)),
          ),
          const SizedBox(height: 6),
          Text(
            _nextActionDesc,
            style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF424750),
                height: 1.4),
          ),
          const SizedBox(height: 12),

          if (isDelete)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isDeleting ? null : _handleDeleteProject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE85D04),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  textStyle:
                      GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('HAPUS PROYEK'),
              ),
            )
          else if (_activeStep == 0 && _applicants.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProjectApplicantsPage(project: widget.project),
                  ),
                ).then((_) => _loadDetail()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A4B84),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  textStyle:
                      GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                child: const Text('PILIH KREATOR'),
              ),
            )
          else if (_activeStep == 2)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Halaman pembayaran akan segera hadir'),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE85D04),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  textStyle:
                      GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                child: const Text('LIHAT VERIFIKASI BUKTI'),
              ),
            )
          else if (_isCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleRate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006D77),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  textStyle:
                      GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                child: const Text('BERI RATING'),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== RINGKASAN DANA (tanpa subjudul tambahan) ====================
  Widget _buildDanaSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RINGKASAN DANA',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF424750),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _danaRow('Budget', widget.project.budget, isHighlight: true),
          const SizedBox(height: 8),
          _danaRow(
            'Escrow',
            _escrowStatus,
            valueColor: _escrowStatus == 'PAID'
                ? const Color(0xFF006D77)
                : const Color(0xFFE29578),
          ),
          const SizedBox(height: 8),
          _danaRow('Pelamar', '${_applicants.length}'),
        ],
      ),
    );
  }

  Widget _danaRow(String label, String value,
      {bool isHighlight = false, Color? valueColor}) {
    final bool isBadge = value == 'UNPAID' || value == 'PAID';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF424750),
          ),
        ),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: (valueColor ?? const Color(0xFFE29578)).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFFE29578),
              ),
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ??
                  (isHighlight
                      ? const Color(0xFF1B1B1F)
                      : const Color(0xFF424750)),
            ),
          ),
      ],
    );
  }

  // ==================== PELAMAR ====================
  Widget _buildApplicantsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PELAMAR',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF424750),
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectApplicantsPage(project: widget.project),
                  ),
                ).then((_) => _loadDetail()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A4B84).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Lihat Detail',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A4B84),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Proposal Creative Worker',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 12),

          if (_applicants.isEmpty)
            _buildEmptyApplicantState()
          else
            Column(
              children: [
                ...List.generate(
                  _applicants.length > 3 ? 3 : _applicants.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _applicantTile(_applicants[i]),
                  ),
                ),
                if (_applicants.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Center(
                      child: Text(
                        '+${_applicants.length - 3} lainnya',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF1A4B84),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyApplicantState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 36,
            color: const Color(0xFF424750).withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada apply masuk',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF424750),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Proposal creative worker akan muncul di sini setelah mereka apply.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF424750).withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicantTile(Map<String, dynamic> applicant) {
    final name = applicant['creative_name']?.toString() ?? 'Tanpa Nama';
    final city = applicant['creative_city']?.toString() ?? '';
    final message = applicant['message']?.toString() ?? '';
    final status = applicant['status']?.toString() ?? 'applied';
    final avatar = applicant['creative_avatar']?.toString();
    final isApproved = status == 'approved';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isApproved
            ? const Color(0xFF006D77).withOpacity(0.06)
            : const Color(0xFFF5F3F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isApproved
              ? const Color(0xFF006D77).withOpacity(0.2)
              : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1A4B84),
              shape: BoxShape.circle,
              image: (avatar != null && avatar.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(avatar), fit: BoxFit.cover)
                  : null,
            ),
            child: (avatar == null || avatar.isEmpty)
                ? Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isApproved) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006D77).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'APPROVED',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF006D77),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (city.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    city,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF424750),
                    ),
                  ),
                ],
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF424750),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== RIWAYAT UPDATE PROGRESS ====================
  Widget _buildProgressUpdatesSection() {
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RIWAYAT',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF424750),
                    letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text('Update Progress',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF1B1B1F))),
            const SizedBox(height: 12),
            if (_progressUpdates.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history,
                        size: 36,
                        color: const Color(0xFF424750).withOpacity(0.3)),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada update progress',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF424750)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Update dari creative worker akan tampil sebagai timeline di sini.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF424750).withOpacity(0.6)),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(
                _progressUpdates.length,
                (i) => _buildTimelineItem(
                    _progressUpdates[i], i == _progressUpdates.length - 1),
              ),
          ],
        ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> update, bool isLast) {
    final pct = int.tryParse(update['percentage']?.toString() ??
            update['progress_percentage']?.toString() ??
            '0') ??
        0;
    final note = update['note']?.toString() ?? '';
    final mediaUrl = update['media_url']?.toString();
    final createdAt = update['created_at']?.toString();
    final creativeName = update['creative_name']?.toString() ??
        _projectData?['selected_creative_name']?.toString() ??
        'Creative Worker';

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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(creativeName,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B1B1F))),
                      Text(_formatDate(createdAt),
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF424750))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(note,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF424750),
                          height: 1.4)),
                  if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        mediaUrl,
                        height: 140,
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

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );
}
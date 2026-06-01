// lib/screens/project_progress_detail.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../services/revision_service.dart';
import '../models/project_model.dart';
import 'rating_bottom_sheet.dart';
import 'project_applicants.dart';
import 'escrow_payment_page.dart';
import 'approve_completion_page.dart';
import '../widget/request_revision_bottom_sheet.dart';

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
  final PaymentService _paymentService = PaymentService();
  final RevisionService _revisionService = RevisionService();

  Map<String, dynamic>? _projectData;
  List<Map<String, dynamic>> _progressUpdates = [];
  List<Map<String, dynamic>> _applicants = [];
  PaymentData? _paymentData;
  Map<String, dynamic>? _revisionInfo;
  bool _isLoading = true;
  bool _isDeleting = false;

  // ── Semua step alur proyek ─────────────────────────────────────────────────
  static const List<Map<String, String>> _allSteps = [
    {'label': 'PILIH WORKER', 'sub': 'Review pelamar'},
    {'label': 'DIKERJAKAN', 'sub': 'Progress 0-100%'},
    {'label': 'BAYAR ESCROW', 'sub': 'Amankan dana'},
    {'label': 'REVIEW', 'sub': 'Cek hasil kerja'},
    {'label': 'SELESAI', 'sub': 'Dana cair'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);

    final progressResult = await _api.getUMKMProjectProgress();
    final appResult = await _api.getProjectApplications(widget.project.id);
    final paymentStatus = await _paymentService.checkPaymentStatus(widget.project.id);

    if (!mounted) return;

    // ── Parse payment data ────────────────────────────────────────────────
    if (paymentStatus['success'] == true && paymentStatus['has_payment'] == true) {
      _paymentData = PaymentData.fromJson(paymentStatus['data']);
    } else {
      _paymentData = null;
    }

    // ── Parse progress updates ────────────────────────────────────────────
    if (progressResult['success'] == true) {
      final rawData = progressResult['data'];

      List<dynamic> allProjects = [];
      if (rawData is List) {
        allProjects = rawData;
      } else if (rawData is Map) {
        final inner = rawData['data'] ?? rawData['projects'] ?? rawData['items'];
        if (inner is List) allProjects = inner;
      }

      final matched = allProjects
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (p) => p['id']?.toString() == widget.project.id.toString(),
            orElse: () => <String, dynamic>{},
          );

      if (matched.isNotEmpty) {
        _projectData = matched;
        final updates = matched['progress_updates'];
        if (updates is List) {
          _progressUpdates = updates.map((u) {
            final m = Map<String, dynamic>.from(u);
            if (!m.containsKey('progress_percentage') && m.containsKey('percentage')) {
              m['progress_percentage'] = m['percentage'];
            }
            return m;
          }).toList();
        } else {
          _progressUpdates = [];
        }
      } else {
        _projectData = widget.project.toJson();
        _progressUpdates = [];
      }
    } else {
      _projectData = widget.project.toJson();
      _progressUpdates = [];
    }

    // ── Parse pelamar ─────────────────────────────────────────────────────
    if (appResult['success'] == true && appResult['data'] != null) {
      final d = appResult['data'];
      if (d is List) {
        _applicants = d.map((e) => Map<String, dynamic>.from(e)).toList();
      } else if (d is Map) {
        final inner = d['applications'] ?? d['data'];
        if (inner is List) {
          _applicants = inner.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    }

    // ── Load revision info jika status revision ─────────────────────────────
    if (_status == 'revision') {
      final revisionResult = await _revisionService.getRevisions(widget.project.id);
      if (revisionResult['success'] == true) {
        _revisionInfo = revisionResult['data']['current_revision'];
      }
    } else {
      _revisionInfo = null;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ── Getters ────────────────────────────────────────────────────────────────
  String get _status =>
      _projectData?['status']?.toString() ?? widget.project.status;

  int get _progress {
    if (_progressUpdates.isNotEmpty) {
      final latest = _progressUpdates.first;
      final fromUpdate = int.tryParse(
        (latest['progress_percentage'] ?? latest['percentage'])?.toString() ?? '0'
      ) ?? 0;
      if (fromUpdate > 0) return fromUpdate;
    }
    if (_projectData != null) {
      return int.tryParse(
              _projectData!['progress_percentage']?.toString() ?? '0') ??
          0;
    }
    return widget.project.progressPercentage;
  }

  String get _escrowStatus =>
      _projectData?['escrow_status']?.toString() ?? 'unpaid';

  bool get _isPaymentPending => _paymentData?.status == 'pending';
  bool get _isPaymentPaid => _paymentData?.status == 'paid';
  bool get _isPaymentVerified => _paymentData?.isVerified == true;
  bool get _isPaymentAwaitingVerification => _paymentData?.isAwaitingVerification == true;
  bool get _isPaymentRejected => _paymentData?.status == 'failed';

  bool get _isRevisionOverdue {
    if (_status != 'revision' || _revisionInfo == null) return false;
    final deadline = _revisionInfo?['deadline'];
    if (deadline == null) return false;
    return DateTime.parse(deadline).isBefore(DateTime.now());
  }

  int get _activeStep {
    if (_isPaymentAwaitingVerification) return 2;
    if (_isPaymentVerified && _progress >= 100) return 3;
    
    switch (_status) {
      case 'open':
      case 'pending':
      case 'applied':
        return 0;
      case 'hired':
      case 'in_progress':
      case 'ongoing':
        return 1;
      case 'awaiting_payment':
      case 'payment_pending':
        return 2;
      case 'ready_for_review':
      case 'revision':
      case 'disputed':
        return 3;
      case 'pending_admin_approval':
      case 'completed':
      case 'done':
      case 'payment_refunded':
        return 4;
      default:
        return 0;
    }
  }

  bool get _isOpen =>
      ['open', 'pending', 'applied'].contains(_status);
  bool get _isHired => _status == 'hired';
  bool get _isInProgress =>
      ['in_progress', 'ongoing'].contains(_status);
  bool get _isAwaitingPayment =>
      ['awaiting_payment', 'payment_pending'].contains(_status) || _isPaymentPending;
  bool get _isReadyForReview => _status == 'ready_for_review';
  bool get _isRevision => _status == 'revision';
  bool get _isPendingAdmin => _status == 'pending_admin_approval';
  bool get _isCompleted =>
      ['completed', 'done'].contains(_status);
  bool get _isDisputed => _status == 'disputed';

  Map<String, dynamic>? get _approvedApplicant {
    try {
      return _applicants
          .firstWhere((a) => a['status']?.toString() == 'approved');
    } catch (_) {
      return null;
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

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _handleDelete() async {
    if (_applicants.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Proyek yang sudah punya pelamar tidak bisa dihapus langsung.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Proyek',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Yakin ingin menghapus proyek "${widget.project.title}"? Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.inter(fontSize: 13, height: 1.5),
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

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final result = await _api.deleteUmkmProject(widget.project.id);
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

  void _openEscrowPayment() async {
    final project = _projectData != null
        ? Project.fromJson(_projectData!)
        : widget.project;
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EscrowPaymentPage(project: project)),
    );
    if (paid == true) _loadDetail();
  }

  void _openApproveCompletion() async {
    final project = _projectData != null
        ? Project.fromJson(_projectData!)
        : widget.project;
    final approved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ApproveCompletionPage(
          project: project,
          progressUpdates: _progressUpdates,
        ),
      ),
    );
    if (approved == true) _loadDetail();
  }

  void _openApplicants() async {
    final project = _projectData != null
        ? Project.fromJson(_projectData!)
        : widget.project;
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ProjectApplicantsPage(project: project)),
    );
    _loadDetail();
  }

  void _openRating() {
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

  void _openRequestRevision() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RequestRevisionBottomSheet(
        projectId: widget.project.id,
        projectTitle: widget.project.title,
        onRevisionRequested: _loadDetail,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Detail Proyek',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A4B84)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isOpen && _applicants.isEmpty)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isDeleting ? null : _handleDelete,
              tooltip: 'Hapus Proyek',
            ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Color(0xFF424750)),
            onPressed: _loadDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 14),
                    _buildStepper(),
                    const SizedBox(height: 14),
                    _buildProgressCard(),
                    const SizedBox(height: 14),
                    if (_isRevision && _revisionInfo != null)
                      _buildRevisionInfoCard(),
                    _buildStatusInfoCard(),
                    const SizedBox(height: 14),
                    _buildPaymentStatusCard(),
                    const SizedBox(height: 14),
                    _buildActionButton(),
                    const SizedBox(height: 14),
                    _buildApplicantsCard(),
                    const SizedBox(height: 14),
                    _buildProgressUpdatesCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Revision Info Card ─────────────────────────────────────────────────────
  Widget _buildRevisionInfoCard() {
    final reason = _revisionInfo?['reason'] ?? '-';
    final feedback = _revisionInfo?['feedback'];
    final deadline = _revisionInfo?['deadline'];
    final revisionNumber = _revisionInfo?['revision_count'] ?? 1;
    final isOverdue = _isRevisionOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red.withOpacity(0.05) : Colors.deepOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue ? Colors.red.withOpacity(0.3) : Colors.deepOrange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_outlined,
                size: 20,
                color: isOverdue ? Colors.red : Colors.deepOrange,
              ),
              const SizedBox(width: 8),
              Text(
                'Revisi #$revisionNumber',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isOverdue ? Colors.red : Colors.deepOrange,
                ),
              ),
              if (isOverdue)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'OVERDUE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Alasan Revisi:',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          if (feedback != null && feedback.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Catatan:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              feedback,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF424750),
              ),
            ),
          ],
          if (deadline != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: isOverdue ? Colors.red : Colors.deepOrange,
                ),
                const SizedBox(width: 6),
                Text(
                  'Deadline: ${_formatDate(deadline)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOverdue ? Colors.red : Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Creative worker sedang merevisi pekerjaan. Setelah revisi disubmit, Anda akan dapat mereview kembali.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                      height: 1.4,
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

  // ── Payment Status Card ────────────────────────────────────────────────────
  Widget _buildPaymentStatusCard() {
    if (_paymentData == null) return const SizedBox.shrink();
    
    Color bgColor;
    Color textColor;
    IconData icon;
    String title;
    String message;
    
    if (_isPaymentVerified) {
      bgColor = const Color(0xFF006D77).withOpacity(0.1);
      textColor = const Color(0xFF006D77);
      icon = Icons.check_circle_rounded;
      title = 'Pembayaran Terverifikasi';
      message = 'Dana telah aman disimpan di escrow. Silakan review hasil kerja creative worker.';
    } else if (_isPaymentAwaitingVerification) {
      bgColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange;
      icon = Icons.hourglass_empty;
      title = 'Menunggu Verifikasi Admin';
      message = 'Bukti pembayaran sudah diupload. Admin akan memverifikasi dalam waktu 1x24 jam.';
    } else if (_isPaymentRejected) {
      bgColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
      icon = Icons.error_outline;
      title = 'Pembayaran Ditolak';
      message = 'Bukti pembayaran ditolak admin: ${_paymentData?.rejectionReason ?? "Silakan upload ulang bukti yang valid."}';
    } else if (_isPaymentPending) {
      bgColor = const Color(0xFFFFF8E1);
      textColor = Colors.orange.shade800;
      icon = Icons.payment_outlined;
      title = 'Menunggu Pembayaran';
      message = 'Transfer ke Virtual Account BCA: ${_paymentData?.virtualAccountNumber ?? "-"}';
    } else {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: textColor)),
                const SizedBox(height: 2),
                Text(message,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: textColor.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF002B5C), Color(0xFF1A4B84)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _chip(widget.project.category.toUpperCase(),
                  Colors.white.withOpacity(0.2), Colors.white),
              const SizedBox(width: 8),
              _chip(_statusBadgeLabel(), _statusBadgeColor().withOpacity(0.2),
                  _statusBadgeColor()),
            ],
          ),
          const SizedBox(height: 12),
          Text(widget.project.title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            widget.project.description.length > 120
                ? '${widget.project.description.substring(0, 120)}...'
                : widget.project.description,
            style: GoogleFonts.inter(
                fontSize: 13, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _metaItem(Icons.account_balance_wallet_outlined,
                  'Rp ${widget.project.budget}', const Color(0xFF68FADD)),
              _metaItem(
                  Icons.calendar_today_outlined,
                  'Deadline ${_formatDate(widget.project.deadline?.toIso8601String())}',
                  Colors.white70),
              if (_approvedApplicant != null)
                _metaItem(
                    Icons.person_outline,
                    _approvedApplicant!['creative_name']?.toString() ?? '',
                    Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _metaItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── Stepper ────────────────────────────────────────────────────────────────
  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
        children: List.generate(_allSteps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            final done = _activeStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: done
                    ? const Color(0xFF006D77)
                    : const Color(0xFFEAE7ED),
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = _activeStep > stepIndex;
          final isActive = _activeStep == stepIndex;
          return _stepNode(
            number: stepIndex + 1,
            label: _allSteps[stepIndex]['label']!,
            sub: _allSteps[stepIndex]['sub']!,
            isDone: isDone,
            isActive: isActive,
          );
        }),
      ),
    );
  }

  Widget _stepNode({
    required int number,
    required String label,
    required String sub,
    required bool isDone,
    required bool isActive,
  }) {
    Color circleBg;
    Widget inner;

    if (isDone) {
      circleBg = const Color(0xFF006D77);
      inner = const Icon(Icons.check, size: 12, color: Colors.white);
    } else if (isActive) {
      circleBg = const Color(0xFF1A4B84);
      inner = Text('$number',
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white));
    } else {
      circleBg = const Color(0xFFE0E0E0);
      inner = Text('$number',
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white));
    }

    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
            child: Center(child: inner),
          ),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: isDone || isActive
                      ? const Color(0xFF1B1B1F)
                      : const Color(0xFF9E9E9E))),
          Text(sub,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 8, color: const Color(0xFF9E9E9E))),
        ],
      ),
    );
  }

  // ── Progress Card ──────────────────────────────────────────────────────────
  Widget _buildProgressCard() {
    final pct = _progress;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress Keseluruhan',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B1B1F))),
              Text('$pct%',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: pct >= 100
                          ? const Color(0xFF006D77)
                          : const Color(0xFF1A4B84))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: const Color(0xFFEAE7ED),
              color:
                  pct >= 100 ? const Color(0xFF006D77) : const Color(0xFF1A4B84),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Info Card ───────────────────────────────────────────────────────
  Widget _buildStatusInfoCard() {
    final label = _statusLabel();
    final desc = _statusDesc();
    final color = _statusBadgeColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_statusIcon(), size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color)),
                const SizedBox(height: 4),
                Text(desc,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF424750),
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Button ──────────────────────────────────────────────────────────
  Widget _buildActionButton() {
    // Pilih worker (ada pelamar, status open/applied)
    if (_isOpen && _applicants.isNotEmpty) {
      return _actionBtn(
        label: 'Lihat & Pilih Pelamar (${_applicants.length})',
        icon: Icons.people_outline,
        color: const Color(0xFF1A4B84),
        onTap: _openApplicants,
      );
    }

    // Status hired: creative sudah dipilih, UMKM bisa langsung bayar escrow
    if (_isHired) {
      return Column(
        children: [
          _actionBtn(
            label: 'Bayar Escrow Sekarang',
            icon: Icons.payment_outlined,
            color: const Color(0xFF1A4B84),
            onTap: _openEscrowPayment,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Creative worker sudah dipilih. Bayar escrow agar pekerjaan bisa segera dimulai.',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Bayar escrow (progress 100% tapi belum bayar) ATAU payment pending
    if (_isAwaitingPayment) {
      String buttonLabel;
      if (_isPaymentPending) {
        buttonLabel = 'Lanjutkan Pembayaran Escrow';
      } else if (_isPaymentRejected) {
        buttonLabel = 'Upload Ulang Bukti Pembayaran';
      } else {
        buttonLabel = 'Bayar Escrow Sekarang';
      }
      
      return _actionBtn(
        label: buttonLabel,
        icon: Icons.payment_outlined,
        color: const Color(0xFFE29578),
        onTap: _openEscrowPayment,
      );
    }

    // Review & approve completion
    if (_isReadyForReview) {
      return Column(
        children: [
          _actionBtn(
            label: 'Review & Setujui Hasil Kerja',
            icon: Icons.verified_outlined,
            color: const Color(0xFF006D77),
            onTap: _openApproveCompletion,
          ),
          const SizedBox(height: 8),
          _actionBtn(
            label: 'Request Revisi',
            icon: Icons.edit_note_outlined,
            color: const Color(0xFFE29578),
            onTap: _openRequestRevision,
            isOutlined: true,
          ),
        ],
      );
    }

    // Beri rating (completed)
    if (_isCompleted) {
      return _actionBtn(
        label: 'Beri Rating Creative Worker',
        icon: Icons.star_outline_rounded,
        color: const Color(0xFFFFC107),
        onTap: _openRating,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Pelamar Mini Card ──────────────────────────────────────────────────────
  Widget _buildApplicantsCard() {
    if (_applicants.isEmpty && _isOpen) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Row(
          children: [
            const Icon(Icons.people_outline, color: Color(0xFF9E9E9E), size: 20),
            const SizedBox(width: 10),
            Text('Belum ada yang melamar',
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF9E9E9E))),
          ],
        ),
      );
    }

    if (_applicants.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pelamar (${_applicants.length})',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF1B1B1F))),
              TextButton(
                onPressed: _openApplicants,
                child: Text('Lihat Semua',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF1A4B84),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          ...(_applicants.take(2).map((a) => _miniApplicantTile(a))),
        ],
      ),
    );
  }

  Widget _miniApplicantTile(Map<String, dynamic> a) {
    final name = a['creative_name']?.toString() ?? '-';
    final status = a['status']?.toString() ?? 'applied';
    final avatar = a['creative_avatar']?.toString();
    final isApproved = status == 'approved';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEAE7ED),
            backgroundImage:
                avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar == null || avatar.isEmpty
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A4B84)))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isApproved
                  ? const Color(0xFF006D77).withOpacity(0.1)
                  : const Color(0xFFEAE7ED),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isApproved ? 'Dipilih' : 'Menunggu',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isApproved
                      ? const Color(0xFF006D77)
                      : const Color(0xFF424750)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress Updates ───────────────────────────────────────────────────────
  Widget _buildProgressUpdatesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Riwayat Update Progress',
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
              child: Center(
                child: Text(
                  _isOpen
                      ? 'Belum ada creative worker yang dipilih.'
                      : 'Belum ada update progress dari creative worker.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF424750)),
                ),
              ),
            )
          else
            ...List.generate(
              _progressUpdates.length,
              (i) => _timelineItem(
                  _progressUpdates[i], i == _progressUpdates.length - 1),
            ),
        ],
      ),
    );
  }

  Widget _timelineItem(Map<String, dynamic> upd, bool isLast) {
    final pct = int.tryParse(upd['percentage']?.toString() ??
            upd['progress_percentage']?.toString() ??
            '0') ??
        0;
    final note = upd['note']?.toString() ?? '';
    final mediaUrl = upd['media_url']?.toString();
    final createdAt = upd['created_at']?.toString();
    final creativeName =
        upd['creative_name']?.toString() ??
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
                              fontSize: 10, color: const Color(0xFF424750))),
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

  // ── Helpers ────────────────────────────────────────────────────────────────
  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      );

  Color _statusBadgeColor() {
    if (_isPaymentAwaitingVerification) return Colors.orange;
    if (_isPaymentVerified && _progress >= 100) return const Color(0xFF006D77);
    
    switch (_status) {
      case 'open': return const Color(0xFF424750);
      case 'hired': return const Color(0xFF1A4B84);
      case 'in_progress':
      case 'ongoing': return const Color(0xFFE29578);
      case 'awaiting_payment':
      case 'payment_pending': return Colors.orange;
      case 'ready_for_review': return const Color(0xFF006D77);
      case 'pending_admin_approval': return Colors.purple;
      case 'revision': return _isRevisionOverdue ? Colors.red : Colors.deepOrange;
      case 'disputed': return Colors.red;
      case 'completed':
      case 'done': return const Color(0xFF006D77);
      default: return const Color(0xFF424750);
    }
  }

  String _statusBadgeLabel() {
    if (_isPaymentAwaitingVerification) return 'VERIFIKASI';
    if (_isPaymentVerified && _progress >= 100) return 'DANA DITAHAN';
    
    switch (_status) {
      case 'open': return 'TERBUKA';
      case 'hired': return 'WORKER DIPILIH';
      case 'in_progress':
      case 'ongoing': return 'SEDANG DIKERJAKAN';
      case 'awaiting_payment': return 'MENUNGGU PEMBAYARAN';
      case 'payment_pending': return 'VA MENUNGGU TRANSFER';
      case 'ready_for_review': return 'SIAP DIREVIEW';
      case 'pending_admin_approval': return 'MENUNGGU ADMIN';
      case 'revision': return _isRevisionOverdue ? 'OVERDUE' : 'REVISI';
      case 'disputed': return 'DISPUTE';
      case 'completed':
      case 'done': return 'SELESAI';
      default: return _status.toUpperCase();
    }
  }

  IconData _statusIcon() {
    if (_isPaymentAwaitingVerification) return Icons.hourglass_empty;
    if (_isPaymentVerified && _progress >= 100) return Icons.verified_outlined;
    
    switch (_status) {
      case 'open': return Icons.people_outline;
      case 'hired': return Icons.person_outline;
      case 'in_progress':
      case 'ongoing': return Icons.pending_outlined;
      case 'awaiting_payment': return Icons.payment_outlined;
      case 'payment_pending': return Icons.account_balance_outlined;
      case 'ready_for_review': return Icons.rate_review_outlined;
      case 'pending_admin_approval': return Icons.admin_panel_settings_outlined;
      case 'revision': return Icons.edit_note_outlined;
      case 'disputed': return Icons.gavel_outlined;
      case 'completed':
      case 'done': return Icons.verified_outlined;
      default: return Icons.info_outline;
    }
  }

  String _statusLabel() {
    if (_isPaymentAwaitingVerification) {
      return 'Menunggu Verifikasi Admin';
    }
    if (_isPaymentVerified && _progress >= 100) {
      return 'Dana Tersimpan di Escrow — Review Hasil Kerja!';
    }
    
    switch (_status) {
      case 'open': return _applicants.isEmpty
          ? 'Menunggu Pelamar'
          : 'Ada ${_applicants.length} Pelamar — Pilih Sekarang!';
      case 'hired': return 'Creative Worker Sudah Dipilih';
      case 'in_progress':
      case 'ongoing': return 'Proyek Sedang Dikerjakan';
      case 'awaiting_payment': return 'Draft 100% — Bayar Escrow!';
      case 'payment_pending': return 'Menunggu Transfer VA';
      case 'ready_for_review': return 'Siap Direview — Dana Ditahan Platform';
      case 'pending_admin_approval': return 'Menunggu Verifikasi Admin';
      case 'revision': return _isRevisionOverdue 
          ? '⚠️ Deadline Revisi Terlewat! ⚠️' 
          : 'Sedang Dalam Revisi';
      case 'disputed': return 'Proyek Dispute';
      case 'completed':
      case 'done': return 'Proyek Selesai!';
      default: return _status;
    }
  }

  String _statusDesc() {
    if (_isPaymentAwaitingVerification) {
      return 'Bukti pembayaran sudah diupload. Admin akan memverifikasi dalam waktu 1x24 jam. Setelah diverifikasi, dana akan ditahan di escrow.';
    }
    if (_isPaymentVerified && _progress >= 100) {
      return 'Dana sudah ditahan platform. Periksa hasil kerja kreator dan setujui jika sudah sesuai ekspektasimu.';
    }
    
    switch (_status) {
      case 'open':
        return _applicants.isEmpty
            ? 'Proyek belum punya pelamar. Bagikan proyek untuk menarik creative worker.'
            : 'Ada ${_applicants.length} pelamar menunggu. Review dan pilih creative worker terbaik.';
      case 'hired':
        return 'Creative worker sudah dipilih dan sedang mengerjakan draft. Pantau update progress di bawah.';
      case 'in_progress':
      case 'ongoing':
        return 'Kolaborasi sedang berjalan. Pantau update progress dari creative worker.';
      case 'awaiting_payment':
        return 'Progress sudah 100%! Kamu wajib membayar escrow sebelum menyetujui hasil akhir. Transfer ke VA dan upload bukti.';
      case 'payment_pending':
        return 'Virtual account sudah dibuat. Segera transfer dan upload bukti transfer agar admin bisa menahan dana di escrow.';
      case 'ready_for_review':
        return 'Dana sudah ditahan platform. Periksa hasil kerja kreator dan setujui jika sudah sesuai ekspektasimu.';
      case 'pending_admin_approval':
        return 'Kamu sudah menyetujui hasil kerja. Admin sedang memverifikasi sebelum dana dicairkan ke creative worker.';
      case 'revision':
        return _isRevisionOverdue
            ? 'Deadline revisi telah lewat! Segera hubungi creative worker untuk menyelesaikan revisi.'
            : 'Creative worker sedang merevisi pekerjaan berdasarkan feedback yang diberikan.';
      case 'disputed':
        return 'Ada sengketa pada proyek ini. Admin/mediator akan menentukan apakah dana dicairkan atau dikembalikan.';
      case 'completed':
      case 'done':
        return 'Proyek selesai! Dana sudah dicairkan ke creative worker. Jangan lupa beri rating!';
      default:
        return '';
    }
  }
}
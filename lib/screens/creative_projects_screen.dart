// lib/screens/creative_projects_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/project_progress_service.dart';
import '../services/escrow_service.dart';
import '../services/revision_service.dart';
import '../models/project_progress_model.dart';
import '../models/escrow_model.dart';
import 'update_progress_screen.dart';
import 'escrow_detail_screen.dart';
import 'submit_revision_screen.dart';

class CreativeProjectsScreen extends StatefulWidget {
  const CreativeProjectsScreen({super.key});

  @override
  State<CreativeProjectsScreen> createState() => _CreativeProjectsScreenState();
}

class _CreativeProjectsScreenState extends State<CreativeProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProjectProgressService _projectService = ProjectProgressService();
  final EscrowService _escrowService = EscrowService();
  final RevisionService _revisionService = RevisionService();

  List<ProjectProgressModel> _projects = [];
  EarningsSummary? _earnings;
  bool _isLoading = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadProjects(),
      _loadEarnings(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadProjects() async {
    final result = await _projectService.getCreativeProjects();
    if (result['success'] == true) {
      setState(() => _projects = result['projects']);
    } else {
      setState(() => _errorMsg = result['message']);
    }
  }

  Future<void> _loadEarnings() async {
    final result = await _escrowService.getEarnings();
    if (result['success'] == true) {
      setState(() => _earnings = result['earnings']);
    }
  }

  List<ProjectProgressModel> get _revisionProjects =>
      _projects.where((p) => p.status == 'revision').toList();

  List<ProjectProgressModel> get _activeProjects =>
      _projects.where((p) => p.isActive && p.status != 'revision').toList();

  List<ProjectProgressModel> get _waitingProjects =>
      _projects.where((p) => p.isWaitingPayment).toList();

  List<ProjectProgressModel> get _completedProjects =>
      _projects.where((p) => p.isCompleted).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF003466),
          onRefresh: _loadData,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildEarningsCard()),
              SliverToBoxAdapter(child: _buildTabBar()),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProjectList(_revisionProjects, isActive: true, isRevisionTab: true),
                    _buildProjectList(_activeProjects, isActive: true, isRevisionTab: false),
                    _buildProjectList(_waitingProjects, isActive: false, isRevisionTab: false),
                    _buildProjectList(_completedProjects, isActive: false, isRevisionTab: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proyek Saya',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola dan update progress proyek Anda',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    if (_earnings == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003466), Color(0xFF0056A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003466).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pendapatan',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      _earnings!.formattedTotalEarned,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EscrowDetailScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Detail',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _EarningsStat(
                label: 'Ditahan',
                value: 'Rp ${(_earnings!.pendingRelease / 1000).toStringAsFixed(0)}rb',
                icon: Icons.pending_actions_rounded,
              ),
              const SizedBox(width: 12),
              _EarningsStat(
                label: 'Proses Cair',
                value: 'Rp ${(_earnings!.inDisbursement / 1000).toStringAsFixed(0)}rb',
                icon: Icons.sync_rounded,
              ),
              const SizedBox(width: 12),
              _EarningsStat(
                label: 'Selesai',
                value: '${_earnings!.releasedCount} proyek',
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF003466),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: const Color(0xFF003466),
        unselectedLabelColor: const Color(0xFF9CA3AF),
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        tabs: [
          Tab(text: 'Revisi (${_revisionProjects.length})'),
          Tab(text: 'Aktif (${_activeProjects.length})'),
          Tab(text: 'Menunggu (${_waitingProjects.length})'),
          Tab(text: 'Selesai (${_completedProjects.length})'),
        ],
      ),
    );
  }

  Widget _buildProjectList(List<ProjectProgressModel> projects, 
      {required bool isActive, required bool isRevisionTab}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF003466)));
    }

    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isRevisionTab ? Icons.edit_note_outlined : 
                (isActive ? Icons.work_outline_rounded : Icons.check_circle_outline_rounded),
                size: 48,
                color: const Color(0xFF003466),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isRevisionTab ? 'Tidak ada proyek yang perlu revisi' :
              (isActive ? 'Belum ada proyek aktif' : 'Tidak ada proyek di tab ini'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1B1F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isRevisionTab ? 'Proyek yang membutuhkan revisi akan muncul di sini' :
              (isActive ? 'Jelajahi dan lamar proyek terlebih dahulu' : 'Proyek akan muncul di sini'),
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
            ),
            if (isActive && !isRevisionTab)
              const SizedBox(height: 20),
            if (isActive && !isRevisionTab)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/explore');
                },
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: Text(
                  'Cari Proyek',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003466),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ProjectCard(
            project: project,
            isRevisionTab: isRevisionTab,
            onUpdateProgress: (isActive && !isRevisionTab && project.progressPercentage < 100) 
                ? () => _openUpdateProgress(project) 
                : null,
            onSubmitRevision: isRevisionTab ? () => _openSubmitRevision(project) : null,
          ),
        );
      },
    );
  }

  void _openUpdateProgress(ProjectProgressModel project) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateProgressScreen(project: project),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _openSubmitRevision(ProjectProgressModel project) async {
    // Load revision data first
    final revisionResult = await _revisionService.getRevisions(project.id);
    
    if (!mounted) return;
    
    if (revisionResult['success'] == true) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubmitRevisionScreen(
            project: project,
            revisionData: revisionResult['data']['current_revision'],
          ),
        ),
      );
      if (result == true) {
        _loadData();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(revisionResult['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _EarningsStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _EarningsStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectProgressModel project;
  final VoidCallback? onUpdateProgress;
  final VoidCallback? onSubmitRevision;
  final bool isRevisionTab;

  const _ProjectCard({
    required this.project, 
    this.onUpdateProgress, 
    this.onSubmitRevision,
    this.isRevisionTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = project.status == 'revision' && 
        project.revisionDeadline != null && 
        project.revisionDeadline!.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOverdue ? Colors.red.withOpacity(0.3) : const Color(0xFFE8ECF0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  project.thumbnail != null
                      ? Image.network(project.thumbnail!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _PlaceholderThumbnail(category: project.category))
                      : _PlaceholderThumbnail(category: project.category),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _StatusBadge(status: project.status, isOverdue: isOverdue),
                  ),
                  if (project.status == 'revision')
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isOverdue ? Colors.red : Colors.deepOrange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_note_outlined, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'REVISI',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.percent_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${project.progressPercentage}%',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1B1F),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFF003466),
                      backgroundImage: project.clientAvatar.isNotEmpty ? NetworkImage(project.clientAvatar) : null,
                      child: project.clientAvatar.isEmpty
                          ? Text(project.clientName[0].toUpperCase(), style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        project.clientName,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: project.progressPercentage / 100,
                  backgroundColor: const Color(0xFFE8ECF0),
                  color: project.progressPercentage >= 100 ? const Color(0xFF20C997) : const Color(0xFF003466),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.attach_money_rounded, size: 16, color: const Color(0xFF20C997)),
                    const SizedBox(width: 4),
                    Text(
                      project.formattedBudget,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF003466)),
                    ),
                    const Spacer(),
                    if (project.deadlineLabel.isNotEmpty) ...[
                      Icon(Icons.access_time_rounded, size: 12, color: project.deadlineLabel.contains('Lewat') ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        project.deadlineLabel,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: project.deadlineLabel.contains('Lewat') ? const Color(0xFFEF4444) : const Color(0xFF6B7280)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Revision Deadline Info
                if (project.status == 'revision' && project.revisionDeadline != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: isOverdue ? Colors.red : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isOverdue 
                                ? 'Deadline revisi telah lewat! Segera submit revisi.'
                                : 'Deadline revisi: ${_formatDate(project.revisionDeadline!)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isOverdue ? Colors.red : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Action Buttons
                if (onSubmitRevision != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onSubmitRevision,
                      icon: const Icon(Icons.edit_note_outlined, size: 16),
                      label: Text(
                        'Submit Hasil Revisi',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (onUpdateProgress != null && project.progressPercentage < 100)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onUpdateProgress,
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: Text(
                        'Update Progress',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003466),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (project.progressPercentage >= 100 && project.status != 'completed' && project.status != 'revision')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF20C997).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF20C997)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF20C997)),
                        const SizedBox(width: 8),
                        Text(
                          project.status == 'ready_for_review' ? 'Menunggu Review UMKM' : '100% Selesai',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF20C997)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isOverdue;

  const _StatusBadge({required this.status, this.isOverdue = false});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> config;
    switch (status) {
      case 'revision':
        config = {
          'dot': isOverdue ? const Color(0xFFEF4444) : const Color(0xFFEA580C), 
          'label': isOverdue ? 'OVERDUE' : 'REVISION', 
          'bg': isOverdue ? const Color(0xFFFEE2E2) : const Color(0xFFFFEDD5), 
          'text': isOverdue ? const Color(0xFF991B1B) : const Color(0xFF9A3412)
        };
        break;
      case 'in_progress':
        config = {'dot': const Color(0xFFF59E0B), 'label': 'ONGOING', 'bg': const Color(0xFFFEF3C7), 'text': const Color(0xFF92400E)};
        break;
      case 'hired':
        config = {'dot': const Color(0xFF3B82F6), 'label': 'HIRED', 'bg': const Color(0xFFDCEFFD), 'text': const Color(0xFF1E40AF)};
        break;
      case 'awaiting_payment':
        config = {'dot': const Color(0xFFEF4444), 'label': 'WAITING PAYMENT', 'bg': const Color(0xFFFEE2E2), 'text': const Color(0xFF991B1B)};
        break;
      case 'ready_for_review':
        config = {'dot': const Color(0xFF8B5CF6), 'label': 'READY FOR REVIEW', 'bg': const Color(0xFFEDE9FE), 'text': const Color(0xFF5B21B6)};
        break;
      case 'completed':
        config = {'dot': const Color(0xFF20C997), 'label': 'COMPLETED', 'bg': const Color(0xFFD1FAE5), 'text': const Color(0xFF065F46)};
        break;
      default:
        config = {'dot': const Color(0xFF9CA3AF), 'label': status.toUpperCase(), 'bg': const Color(0xFFF3F4F6), 'text': const Color(0xFF6B7280)};
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: config['bg'], borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: config['dot'], shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(config['label'], style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: config['text'])),
      ]),
    );
  }
}

class _PlaceholderThumbnail extends StatelessWidget {
  final String category;
  const _PlaceholderThumbnail({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF003466), Color(0xFF0056A8)])),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.work_outline_rounded, size: 36, color: Colors.white54),
          const SizedBox(height: 6),
          Text(category.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white54, letterSpacing: 0.8)),
        ]),
      ),
    );
  }
}
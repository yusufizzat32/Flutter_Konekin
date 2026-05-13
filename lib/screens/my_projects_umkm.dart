// lib/screens/my_projects_umkm.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';
import 'create_project.dart';
import 'project_progress_detail.dart';

class MyProjectsUmkmPage extends StatefulWidget {
  const MyProjectsUmkmPage({super.key});

  @override
  State<MyProjectsUmkmPage> createState() => _MyProjectsUmkmPageState();
}

class _MyProjectsUmkmPageState extends State<MyProjectsUmkmPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ApiService _api = ApiService();
  List<Project> _projects = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Semua, 1: Berjalan, 2: Selesai

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final result = await _api.getUmkmProjects();

    if (mounted) {
      setState(() {
        if (result['success'] == true && result['data'] != null) {
          final data = result['data'];
          List<dynamic> projectsList = [];
          if (data is List) {
            projectsList = data;
          } else if (data is Map) {
            projectsList = data['projects'] ?? data['data'] ?? [];
          }
          _projects = projectsList
              .map((e) => Project.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else {
          _projects = [];
        }
        _isLoading = false;
      });
    }
  }

  List<Project> get _filteredProjects {
    if (_selectedTab == 0) return _projects;
    if (_selectedTab == 1) {
      return _projects.where((p) =>
          p.status != 'completed' && p.status != 'done' && p.status != 'closed').toList();
    }
    return _projects.where((p) =>
        p.status == 'completed' || p.status == 'done').toList();
  }

  void _navigateToCreateProject() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateProjectPage()),
    ).then((_) => _loadProjects());
  }

  void _navigateToProjectStatus(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectProgressDetailPage(project: project),
      ),
    ).then((_) => _loadProjects());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          'Proyek Saya',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1A4B84)),
            onPressed: _navigateToCreateProject,
            tooltip: 'Buat Proyek Baru',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTab('Semua', 0),
                const SizedBox(width: 16),
                _buildTab('Berjalan', 1),
                const SizedBox(width: 16),
                _buildTab('Selesai', 2),
              ],
            ),
          ),
          const Divider(height: 0, thickness: 1, color: Color(0xFFEAE7ED)),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProjects.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProjects,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProjects.length,
                          itemBuilder: (context, index) {
                            final project = _filteredProjects[index];
                            return _ProjectStatusCard(
                              project: project,
                              onTap: () => _navigateToProjectStatus(project),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF1A4B84) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
              color: isSelected ? const Color(0xFF1A4B84) : const Color(0xFF424750),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 80,
            color: const Color(0xFF424750).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Proyek',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ayo mulai kolaborasi dengan kreator terbaik\nuntuk memajukan bisnismu sekarang.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF424750),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _navigateToCreateProject,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A4B84),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Publikasikan Proyek',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// CARD STATUS PROYEK (sesuai desain gambar)
// ==========================================================================
class _ProjectStatusCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectStatusCard({required this.project, required this.onTap});

  int get _progressValue {
    if (project.status == 'completed' || project.status == 'done') return 100;
    if (project.status == 'in_progress' || project.status == 'ongoing') return 65;
    if (project.status == 'hired') return 10;
    return 0;
  }

  String get _statusLabel {
    switch (project.status) {
      case 'open':
        return 'MENUNGGU APPLY';
      case 'hired':
        return 'KREATOR DIPILIH';
      case 'in_progress':
      case 'ongoing':
        return 'SEDANG DIKERJAKAN';
      case 'completed':
      case 'done':
        return 'SELESAI';
      default:
        return project.status.toUpperCase();
    }
  }

  Color get _statusColor {
    switch (project.status) {
      case 'open':
        return const Color(0xFFE29578);
      case 'hired':
        return const Color(0xFF1A4B84);
      case 'in_progress':
      case 'ongoing':
        return const Color(0xFF006D77);
      case 'completed':
      case 'done':
        return const Color(0xFF83C5BE);
      default:
        return const Color(0xFF424750);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Header: Kategori & Status
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A4B84).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      project.category.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A4B84),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    project.description.length > 80
                        ? '${project.description.substring(0, 80)}...'
                        : project.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF424750),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: Color(0xFF424750)),
                      const SizedBox(width: 4),
                      Text(
                        'Deadline: ${_formatDate(project.deadline)}',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF424750)),
                      ),
                      const Spacer(),
                      const Icon(Icons.attach_money, size: 14, color: Color(0xFF006D77)),
                      const SizedBox(width: 4),
                      Text(
                        project.budget,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF006D77),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF424750),
                            ),
                          ),
                          Text(
                            '$_progressValue%',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF006D77),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _progressValue / 100,
                          backgroundColor: const Color(0xFFEAE7ED),
                          color: const Color(0xFF006D77),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tombol Lihat Detail
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1A4B84)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        'Lihat Detail',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A4B84),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tidak ditentukan';
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }
}
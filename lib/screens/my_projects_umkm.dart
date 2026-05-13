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
  int _selectedTab = 0; // 0: Aktif, 1: Selesai

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final result = await _api.getUmkmProjects();

    debugPrint('🔍 getUmkmProjects result: $result');

    if (mounted) {
      setState(() {
        if (result['success'] == true && result['data'] != null) {
          final data = result['data'];
          List<dynamic> projectsList = [];

          if (data is List) {
            projectsList = data;
          } else if (data is Map) {
            projectsList = (data['projects'] ??
                            data['data'] ??
                            data['items'] ??
                            []) as List<dynamic>;
          }

          debugPrint('🔍 Total projects dari API: ${projectsList.length}');

          _projects = projectsList.map((e) {
            try {
              final p = Project.fromJson(Map<String, dynamic>.from(e));
              if (p.id == 0) {
                // ── FIX: log raw data kalau ID masih 0 untuk debugging ──
                debugPrint('⚠️ Project ID=0! Raw JSON keys: ${e.keys.toList()}');
                debugPrint('⚠️ Raw: $e');
              } else {
                debugPrint('✅ Project: id=${p.id}, title=${p.title}, status=${p.status}');
              }
              return p;
            } catch (err) {
              debugPrint('❌ Error parsing project: $err | raw: $e');
              return null;
            }
          }).whereType<Project>().toList();
        } else {
          debugPrint('🔴 gagal load projects: ${result['message']}');
        }
        _isLoading = false;
      });
    }
  }

  List<Project> get _filteredProjects {
    return _projects.where((p) {
      if (_selectedTab == 0) {
        // TAB AKTIF: semua status yang bukan selesai/dibatalkan
        return p.status == 'open' ||
               p.status == 'in_progress' ||
               p.status == 'ongoing' ||
               p.status == 'hired' ||
               p.status == 'pending' ||
               p.status == 'active' ||
               p.status == 'published';
      } else {
        // TAB SELESAI
        return p.status == 'completed' || p.status == 'done';
      }
    }).toList();
  }

  void _navigateToCreateProject() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateProjectPage()),
    ).then((_) => _loadProjects());
  }


  void _onProjectTap(Project project) {
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
          // TAB
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTab('Aktif', 0),
                const SizedBox(width: 16),
                _buildTab('Selesai', 1),
              ],
            ),
          ),
          const Divider(height: 0, thickness: 1, color: Color(0xFFEAE7ED)),

          // CONTENT
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
                            return _ProjectCard(
                              project: project,
                              onTap: () => _onProjectTap(project),
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
// CARD PROYEK
// ==========================================================================
class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  Color _getStatusColor() {
    switch (project.status) {
      case 'open':
      case 'pending':
      case 'published':
      case 'active':
        return const Color(0xFF006D77);
      case 'hired':
        return const Color(0xFF1A4B84);
      case 'in_progress':
      case 'ongoing':
        return const Color(0xFFE29578);
      case 'completed':
      case 'done':
        return const Color(0xFF83C5BE);
      default:
        return const Color(0xFF424750);
    }
  }

  String _getStatusText() {
    switch (project.status) {
      case 'open':
        return 'OPEN';
      case 'pending':
        return 'MENUNGGU';
      case 'published':
      case 'active':
        return 'AKTIF';
      case 'hired':
        return 'KREATOR DIPILIH';
      case 'in_progress':
      case 'ongoing':
        return 'SEDANG BERJALAN';
      case 'completed':
      case 'done':
        return 'SELESAI';
      default:
        return project.status.toUpperCase();
    }
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

  int _getProgressValue() {
    if (project.status == 'completed' || project.status == 'done') return 100;
    if (project.status == 'in_progress' || project.status == 'ongoing') return 65;
    if (project.status == 'hired') return 10;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isOngoing = project.status == 'in_progress' ||
                      project.status == 'ongoing' ||
                      project.status == 'hired';
    final statusColor = _getStatusColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (project.applicantCount != null &&
                    project.applicantCount! > 0 &&
                    (project.status == 'open' ||
                     project.status == 'pending' ||
                     project.status == 'published'))
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 12, color: Color(0xFF424750)),
                      const SizedBox(width: 4),
                      Text(
                        '${project.applicantCount} pelamar',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF424750),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              project.title,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              project.description.length > 100
                  ? '${project.description.substring(0, 100)}...'
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
                const Icon(Icons.attach_money, size: 14, color: Color(0xFF006D77)),
                const SizedBox(width: 4),
                Text(
                  project.budget,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF006D77),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 12, color: Color(0xFF424750)),
                const SizedBox(width: 4),
                Text(
                  'Deadline: ${_formatDate(project.deadline)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF424750),
                  ),
                ),
              ],
            ),
            if (isOngoing) ...[
              const SizedBox(height: 12),
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
                        '${_getProgressValue()}%',
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
                      value: _getProgressValue() / 100,
                      backgroundColor: const Color(0xFFEAE7ED),
                      color: const Color(0xFF006D77),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1A4B84)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
          ],
        ),
      ),
    );
  }
}
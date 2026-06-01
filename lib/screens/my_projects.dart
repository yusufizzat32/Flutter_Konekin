import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';

class MyProjectsPage extends StatefulWidget {
  final String userType; // 'creative' or 'umkm'
  
  const MyProjectsPage({super.key, required this.userType});

  @override
  State<MyProjectsPage> createState() => _MyProjectsPageState();
}

class _MyProjectsPageState extends State<MyProjectsPage> {
  final ApiService _api = ApiService();
  List<MyProjectProgress> _projects = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0: ongoing, 1: completed

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    
    final result = widget.userType == 'creative'
        ? await _api.getCreativeProjects()
        : await _api.getCreativeProjects(); // TODO: add UMKM projects endpoint
    
    if (mounted) {
      setState(() {
        if (result['success'] && result['data'] != null) {
          final projectsData = result['data']['projects'] ?? result['data'];
          if (projectsData is List) {
            _projects = projectsData.map((e) => MyProjectProgress.fromJson(e)).toList();
          }
        }
        _isLoading = false;
      });
    }
  }

  List<MyProjectProgress> get _filteredProjects {
    return _projects.where((p) {
      if (_selectedTab == 0) {
        return p.status == 'ongoing' || p.status == 'in_progress';
      } else {
        return p.status == 'completed' || p.status == 'done';
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          'Proyek Saya',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A4B84)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Tab
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTab('Sedang Berjalan', 0),
                const SizedBox(width: 16),
                _buildTab('Selesai', 1),
              ],
            ),
          ),
          const Divider(height: 0),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open_outlined,
                              size: 64,
                              color: const Color(0xFF424750).withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedTab == 0
                                  ? 'Belum ada proyek berjalan'
                                  : 'Belum ada proyek selesai',
                              style: GoogleFonts.inter(color: const Color(0xFF424750)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = _filteredProjects[index];
                          return _ProjectProgressCard(project: project);
                        },
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
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
              color: isSelected ? const Color(0xFF1A4B84) : const Color(0xFF424750),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectProgressCard extends StatelessWidget {
  final MyProjectProgress project;
  
  const _ProjectProgressCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  color: project.status == 'ongoing' || project.status == 'in_progress'
                      ? const Color(0xFF006D77).withOpacity(0.1)
                      : const Color(0xFF83C5BE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  project.status == 'ongoing' || project.status == 'in_progress'
                      ? 'SEDANG BERJALAN'
                      : 'SELESAI',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: project.status == 'ongoing' || project.status == 'in_progress'
                        ? const Color(0xFF006D77)
                        : const Color(0xFF83C5BE),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                project.umkmName ?? project.creativeName ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF424750),
                ),
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
          const SizedBox(height: 12),
          if (project.progress > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF424750),
                      ),
                    ),
                    Text(
                      '${project.progress}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF006D77),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: project.progress / 100,
                    backgroundColor: const Color(0xFFEAE7ED),
                    color: const Color(0xFF006D77),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (project.deadline != null)
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: const Color(0xFF424750)),
                const SizedBox(width: 6),
                Text(
                  'Deadline: ${_formatDate(project.deadline!)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF424750),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonth(date.month)} ${date.year}';
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }
}
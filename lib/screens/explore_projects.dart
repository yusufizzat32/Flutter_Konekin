import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';
import 'project_detail.dart';

class ExploreProjectsPage extends StatefulWidget {
  const ExploreProjectsPage({super.key});

  @override
  State<ExploreProjectsPage> createState() => _ExploreProjectsPageState();
}

class _ExploreProjectsPageState extends State<ExploreProjectsPage> {
  final ApiService _api = ApiService();
  List<Project> _projects = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _categories = ['All', 'Graphic Design', 'Social Media', 'UI/UX Design', 'Motion Graphics', 'Branding', 'Video Production'];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    
    final result = await _api.getProjects(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );
    
    if (mounted) {
      setState(() {
        if (result['success'] && result['data'] != null) {
          final projectsData = result['data']['projects'] ?? result['data'];
          if (projectsData is List) {
            _projects = projectsData.map((e) => Project.fromJson(e)).toList();
          } else if (projectsData is Map && projectsData['data'] is List) {
            _projects = (projectsData['data'] as List).map((e) => Project.fromJson(e)).toList();
          }
        }
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          'Cari Proyek',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color(0xFF1B1B1F),
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEAE7ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _onSearch(),
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari proyek...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF424750).withOpacity(0.6)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF424750)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          
          // Category Filter
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: GoogleFonts.inter(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                      _loadProjects();
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF1A4B84),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF424750)),
                    shape: StadiumBorder(
                      side: BorderSide(color: const Color(0xFFC3C6D1).withOpacity(0.5)),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Projects List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _projects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: const Color(0xFF424750).withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada proyek ditemukan',
                              style: GoogleFonts.inter(color: const Color(0xFF424750)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _projects.length,
                        itemBuilder: (context, index) {
                          final project = _projects[index];
                          return _ProjectCard(project: project);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectDetailPage(projectId: project.id),
              ),
            ).then((_) => _refreshIfNeeded(context));
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: project.status == 'open'
                            ? const Color(0xFF006D77).withOpacity(0.1)
                            : const Color(0xFFE29578).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        project.status == 'open' ? 'OPEN' : project.status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: project.status == 'open' ? const Color(0xFF006D77) : const Color(0xFFE29578),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (project.umkmName != null)
                      Text(
                        project.umkmName!,
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
                    color: const Color(0xFF1B1B1F),
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
                // Skills
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: project.skills.take(3).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAE7ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        skill,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF424750),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: const Color(0xFF006D77)),
                    const SizedBox(width: 4),
                    Text(
                      'Budget: ${project.budget}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF006D77),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, size: 14, color: const Color(0xFF424750)),
                    const SizedBox(width: 4),
                    Text(
                      project.duration,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF424750),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _refreshIfNeeded(BuildContext context) {
    // Callback untuk refresh setelah kembali dari detail
    if (context.mounted) {
      // Bisa trigger refresh
    }
  }
}
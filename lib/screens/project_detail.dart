// lib/screens/project_detail.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';

class ProjectDetailPage extends StatefulWidget {
  final int projectId;
  
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final ApiService _api = ApiService();
  Project? _project;
  bool _isLoading = true;
  bool _isApplying = false;
  bool _hasApplied = false;

  @override
  void initState() {
    super.initState();
    _loadProjectDetail();
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
      
      if (result['success']) {
        setState(() => _hasApplied = true);
        Navigator.pop(context);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          'Detail Proyek',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
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
          : _project == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: const Color(0xFF424750).withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Proyek tidak ditemukan',
                        style: GoogleFonts.inter(color: const Color(0xFF424750)),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _project!.status == 'open'
                                        ? const Color(0xFF68FADD).withOpacity(0.2)
                                        : Colors.white24,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _project!.status == 'open' ? 'OPEN' : _project!.status.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _project!.status == 'open' ? const Color(0xFF68FADD) : Colors.white70,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (_project!.umkmName != null)
                                  Text(
                                    _project!.umkmName!,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _project!.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Budget',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        _project!.budget,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          color: const Color(0xFF68FADD),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Durasi',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        _project!.duration,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Deskripsi
                      Text(
                        'Deskripsi Proyek',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: const Color(0xFF1B1B1F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          _project!.description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF424750),
                            height: 1.5,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Skills Required
                      Text(
                        'Skill yang Dibutuhkan',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: const Color(0xFF1B1B1F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _project!.skills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A4B84).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF1A4B84).withOpacity(0.2)),
                            ),
                            child: Text(
                              skill,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1A4B84),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // UMKM Info
                      if (_project!.umkmName != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFC3C6D1).withOpacity(0.3)),
                          ),
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
                                    Text(
                                      _project!.umkmName!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (_project!.umkmCity != null)
                                      Text(
                                        _project!.umkmCity!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF424750),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  // Navigate to UMKM profile
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Fitur dalam pengembangan')),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Lihat Profile'),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 32),
                      
                      // Apply Button
                      if (_project!.status == 'open')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isApplying ? null : _showApplyConfirmation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006D77),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isApplying
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Lamar Proyek',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}
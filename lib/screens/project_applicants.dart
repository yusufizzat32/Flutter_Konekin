import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/project_model.dart';
import 'proposal_preview_page.dart';

class ProjectApplicantsPage extends StatefulWidget {
  final Project project;
  
  const ProjectApplicantsPage({super.key, required this.project});

  @override
  State<ProjectApplicantsPage> createState() => _ProjectApplicantsPageState();
}

class _ProjectApplicantsPageState extends State<ProjectApplicantsPage> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _applicants = [];
  bool _isLoading = true;
  bool _isApproving = false;
  String? _approvingId;

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    setState(() => _isLoading = true);
    
    final result = await _api.getProjectApplications(widget.project.id);
    
    print('=== APPLICANTS RESPONSE ===');
    print(result);
    
    if (mounted) {
      setState(() {
        if (result['success'] && result['data'] != null) {
          final data = result['data'];
          if (data is List) {
            _applicants = data.map((e) => Map<String, dynamic>.from(e)).toList();
          } else if (data is Map && data['applications'] is List) {
            _applicants = (data['applications'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
          }
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _approveApplicant(String applicationId, String creativeName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
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
    
    final result = await _api.approveApplication(widget.project.id, applicationId);
    
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
      
      if (result['success']) {
        _loadApplicants();
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE),
      appBar: AppBar(
        title: Text(
          'Pelamar Proyek',
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
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Info Header
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF003466), Color(0xFF1A4B84)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.project.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Budget: ${widget.project.budget}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Applicants Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${_applicants.length} Pelamar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1F),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Applicants List
                Expanded(
                  child: _applicants.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: const Color(0xFF424750).withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada pelamar',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF424750),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _applicants.length,
                          itemBuilder: (context, index) {
                            final applicant = _applicants[index];
                            return _buildApplicantCard(applicant);
                          },
                        ),
                ),
              ],
            ),
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Status
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE7ED),
                  shape: BoxShape.circle,
                  image: avatar != null && avatar.isNotEmpty
                      ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover)
                      : null,
                ),
                child: avatar == null || avatar.isEmpty
                    ? Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: const Color(0xFF1A4B84),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (city.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: const Color(0xFF424750)),
                          const SizedBox(width: 4),
                          Text(
                            city,
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF424750)),
                          ),
                        ],
                      ),
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
          
          const SizedBox(height: 12),
          
          // Message
          if (message.isNotEmpty) ...[
            Text(
              'Pesan Lamaran:',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF424750)),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF424750), height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          
          // Date
          if (appliedAt != null) ...[
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: const Color(0xFF424750)),
                const SizedBox(width: 4),
                Text(
                  'Melamar: ${_formatDate(appliedAt)}',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF424750)),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Actions
          Row(
            children: [
              if (proposalUrl != null && proposalUrl.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final proposalType = applicant['proposal_type']?.toString() ?? 'pdf';
                      final downloadUrl = applicant['proposal_download_url']?.toString();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProposalPreviewPage(
                            proposalUrl: proposalUrl,
                            proposalType: proposalType,
                            applicantName: name,
                            downloadUrl: downloadUrl,
                          ),
                        ),
                      );
                    },
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
              if (proposalUrl != null && proposalUrl.isNotEmpty)
                const SizedBox(width: 8),
              if (!isApproved)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isApproving && isApprovingThis) 
                        ? null 
                        : () => _approveApplicant(id, name),
                    icon: isApprovingThis
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
}
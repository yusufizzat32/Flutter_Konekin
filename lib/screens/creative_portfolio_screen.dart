// lib/screens/creative_portfolio_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/portfolio_service.dart';
import '../models/portfolio1_model.dart';
import 'portfolio_detail_screen.dart';

class CreativePortfolioScreen extends StatefulWidget {
  const CreativePortfolioScreen({super.key});

  @override
  State<CreativePortfolioScreen> createState() => _CreativePortfolioScreenState();
}

class _CreativePortfolioScreenState extends State<CreativePortfolioScreen> {
  final PortfolioService _portfolioService = PortfolioService();
  List<Portfolio> _portfolios = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPortfolios();
  }

  Future<void> _loadPortfolios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final portfolios = await _portfolioService.getPortfolios();
      setState(() {
        _portfolios = portfolios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadPortfolio() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _UploadPortfolioDialog(),
    );

    if (result != null && mounted) {
      setState(() => _isUploading = true);
      
      try {
        await _portfolioService.createPortfolio(
          title: result['title'],
          description: result['description'],
          image: result['image'],
          attachment: result['attachment'],
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Portfolio berhasil ditambahkan!'),
              backgroundColor: Color(0xFF20C997),
              behavior: SnackBarBehavior.floating,
            ),
          );
          await _loadPortfolios();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal upload: ${e.toString()}'),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  Future<void> _confirmDelete(Portfolio portfolio) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Portfolio?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${portfolio.title}"?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Hapus', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _portfolioService.deletePortfolio(portfolio.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Portfolio berhasil dihapus'),
              backgroundColor: Color(0xFF20C997),
              behavior: SnackBarBehavior.floating,
            ),
          );
          await _loadPortfolios();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal hapus: ${e.toString()}'),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF003466),
          onRefresh: _loadPortfolios,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              
              // Upload Button
              SliverToBoxAdapter(
                child: _buildUploadButton(),
              ),
              
              // Content
              if (_isLoading)
                _buildSkeletonLoader()
              else if (_errorMessage != null)
                SliverFillRemaining(
                  child: _buildErrorWidget(),
                )
              else if (_portfolios.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyWidget(),
                )
              else
                _buildPortfolioGrid(),
            ],
          ),
        ),
      ),
      floatingActionButton: _isUploading
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF003466)),
                ),
              ),
            )
          : FloatingActionButton(
              onPressed: _uploadPortfolio,
              backgroundColor: const Color(0xFF003466),
              elevation: 2,
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portofolio Saya',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tunjukkan karya terbaik Anda kepada klien',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: GestureDetector(
        onTap: _uploadPortfolio,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEFF6FF), Color(0xFFE0F2FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF003466),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tambah Portfolio Baru',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF003466),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Upload thumbnail + file pendukung (PDF/Video)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF003466)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final portfolio = _portfolios[index];
            return _PortfolioCard(
              portfolio: portfolio,
              onTap: () => _openDetail(portfolio),
              onDelete: () => _confirmDelete(portfolio),
            );
          },
          childCount: _portfolios.length,
        ),
      ),
    );
  }

  void _openDetail(Portfolio portfolio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PortfolioDetailScreen(
          portfolio: portfolio,
          onDelete: () => _confirmDelete(portfolio),
          onRefresh: _loadPortfolios,
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const _SkeletonCard(),
          childCount: 4,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 16),
          Text(
            'Gagal Memuat Portfolio',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? 'Terjadi kesalahan',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadPortfolios,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('Coba Lagi', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003466),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.folder_open_outlined, size: 56, color: Color(0xFF003466)),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum Ada Portfolio',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai tunjukkan karya terbaik Anda',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _uploadPortfolio,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Tambah Portfolio', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003466),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// Portfolio Card Component
class _PortfolioCard extends StatelessWidget {
  final Portfolio portfolio;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PortfolioCard({
    required this.portfolio,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: portfolio.imageUrl.isNotEmpty
                        ? Image.network(
                            portfolio.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _PlaceholderThumbnail(),
                          )
                        : _PlaceholderThumbnail(),
                  ),
                  // Video/File badge
                  if (portfolio.hasAttachment)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          portfolio.isVideo ? Icons.videocam_rounded : Icons.picture_as_pdf_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // Delete button
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    portfolio.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(portfolio.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF9CA3AF),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} hari lalu';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam lalu';
    } else {
      return 'baru saja';
    }
  }
}

class _PlaceholderThumbnail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003466), Color(0xFF0056A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.work_outline_rounded, size: 40, color: Colors.white54),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF0),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECF0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECF0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Upload Dialog
class _UploadPortfolioDialog extends StatefulWidget {
  const _UploadPortfolioDialog();

  @override
  State<_UploadPortfolioDialog> createState() => _UploadPortfolioDialogState();
}

class _UploadPortfolioDialogState extends State<_UploadPortfolioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedImage;
  File? _selectedAttachment;
  bool _isImagePicking = false;
  bool _isAttachmentPicking = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _isImagePicking = true);
    try {
      final picker = ImagePicker();
      final result = await picker.pickImage(source: ImageSource.gallery);
      if (result != null) {
        setState(() => _selectedImage = File(result.path));
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _isImagePicking = false);
    }
  }

  Future<void> _pickAttachment() async {
    setState(() => _isAttachmentPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'mp4', 'mov', 'zip', 'docx'],
      );
      if (result != null) {
        setState(() => _selectedAttachment = File(result.files.single.path!));
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _isAttachmentPicking = false);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap pilih thumbnail'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      Navigator.pop(context, {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image': _selectedImage!,
        'attachment': _selectedAttachment,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tambah Portfolio',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B1B1F),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Title Field
              TextFormField(
                controller: _titleController,
                validator: (v) => v?.isEmpty == true ? 'Judul harus diisi' : null,
                decoration: InputDecoration(
                  labelText: 'Judul Portfolio',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              
              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                validator: (v) => v?.isEmpty == true ? 'Deskripsi harus diisi' : null,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE8ECF0)),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedImage != null ? const Color(0xFFF0FDF4) : Colors.white,
                  ),
                  child: Row(
                    children: [
                      _isImagePicking
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(_selectedImage == null ? Icons.cloud_upload_outlined : Icons.check_circle,
                              color: _selectedImage == null ? const Color(0xFF9CA3AF) : const Color(0xFF20C997)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedImage == null ? 'Pilih Thumbnail (JPG/PNG) *' : _selectedImage!.path.split('/').last,
                          style: GoogleFonts.inter(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Attachment Picker
              GestureDetector(
                onTap: _pickAttachment,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE8ECF0)),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedAttachment != null ? const Color(0xFFF0FDF4) : Colors.white,
                  ),
                  child: Row(
                    children: [
                      _isAttachmentPicking
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(_selectedAttachment == null ? Icons.attach_file : Icons.check_circle,
                              color: _selectedAttachment == null ? const Color(0xFF9CA3AF) : const Color(0xFF20C997)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedAttachment == null 
                              ? 'File Pendukung (PDF/Video/Zip) - Opsional' 
                              : _selectedAttachment!.path.split('/').last,
                          style: GoogleFonts.inter(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Batal', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003466),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Upload', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
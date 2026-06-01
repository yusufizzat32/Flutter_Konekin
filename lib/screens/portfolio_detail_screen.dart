// lib/screens/portfolio_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../models/portfolio1_model.dart';

class PortfolioDetailScreen extends StatefulWidget {
  final Portfolio portfolio;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  const PortfolioDetailScreen({
    super.key,
    required this.portfolio,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  State<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends State<PortfolioDetailScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    if (widget.portfolio.isVideo && widget.portfolio.fileUrl != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.portfolio.fileUrl!));
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF003466),
          handleColor: const Color(0xFF003466),
          backgroundColor: Colors.grey[300]!,
          bufferedColor: Colors.grey[400]!,
        ),
      );
      setState(() => _isVideoInitialized = true);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B1B1F)),
        ),
        title: Text(
          'Detail Portfolio',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1B1F),
          ),
        ),
        actions: [
          IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / Video Player
            _buildMediaSection(),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  if (widget.portfolio.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.portfolio.category!.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF003466),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    widget.portfolio.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B1B1F),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Date
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(widget.portfolio.createdAt),
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Divider
                  const Divider(color: Color(0xFFE8ECF0), height: 1),
                  const SizedBox(height: 20),
                  
                  // Description
                  Text(
                    'Deskripsi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1F),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8ECF0)),
                    ),
                    child: Text(
                      widget.portfolio.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF374151),
                        height: 1.6,
                      ),
                    ),
                  ),
                  
                  // Attachment Section
                  if (widget.portfolio.hasAttachment && !widget.portfolio.isVideo)
                    ...[
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFE8ECF0), height: 1),
                      const SizedBox(height: 20),
                      Text(
                        'File Pendukung',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1B1F),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _openAttachment,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE8ECF0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: widget.portfolio.isPdf
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  widget.portfolio.isPdf
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.insert_drive_file_rounded,
                                  color: widget.portfolio.isPdf
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF003466),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lihat File',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1B1B1F),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.portfolio.fileType?.toUpperCase() ?? 'File',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.open_in_new_rounded, size: 18, color: Color(0xFF003466)),
                            ],
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    if (widget.portfolio.isVideo && _isVideoInitialized && _chewieController != null) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      );
    } else if (widget.portfolio.imageUrl.isNotEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          widget.portfolio.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _PlaceholderImage(),
        ),
      );
    } else {
    return AspectRatio(  // ← Hapus const
      aspectRatio: 16 / 9,
      child: _PlaceholderImage(),
    );
  }
}

  void _openAttachment() {
    if (widget.portfolio.fileOpenUrl != null) {
      // TODO: Implement opening URL with url_launcher
      // await launchUrl(Uri.parse(widget.portfolio.fileOpenUrl!));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }
}

class _PlaceholderImage extends StatelessWidget {
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
        child: Icon(Icons.work_outline_rounded, size: 48, color: Colors.white54),
      ),
    );
  }
}
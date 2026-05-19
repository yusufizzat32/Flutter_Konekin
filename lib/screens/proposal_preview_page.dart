import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// Conditional import: gunakan iframe di Web, WebView di Android/iOS
import 'proposal_viewer_stub.dart'
    if (dart.library.html) 'proposal_viewer_web.dart'
    if (dart.library.io) 'proposal_viewer_mobile.dart';

/// Halaman preview proposal yang dikirim oleh creative worker.
/// - Flutter Web  → iframe via HtmlElementView (Google Docs Viewer)
/// - Android/iOS  → WebViewController (Google Docs Viewer)
/// - Gambar       → Image.network + zoom
class ProposalPreviewPage extends StatefulWidget {
  final String proposalUrl;
  final String proposalType;
  final String applicantName;
  final String? downloadUrl;

  const ProposalPreviewPage({
    super.key,
    required this.proposalUrl,
    required this.proposalType,
    required this.applicantName,
    this.downloadUrl,
  });

  @override
  State<ProposalPreviewPage> createState() => _ProposalPreviewPageState();
}

class _ProposalPreviewPageState extends State<ProposalPreviewPage> {
  bool _isLoading = true;
  bool _hasError = false;

  static const Set<String> _imageTypes = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};

  bool get _isImageType =>
      _imageTypes.contains(widget.proposalType.toLowerCase().replaceAll('.', ''));

  String get _viewerUrl {
    final encoded = Uri.encodeComponent(widget.proposalUrl);
    return 'https://docs.google.com/viewer?url=$encoded&embedded=true';
  }

  String get _fileIcon {
    final type = widget.proposalType.toLowerCase().replaceAll('.', '');
    if (type == 'pdf') return '📄';
    if (type.startsWith('ppt')) return '📊';
    if (type.startsWith('doc')) return '📝';
    if (type.startsWith('xls')) return '📈';
    if (_imageTypes.contains(type)) return '🖼️';
    return '📎';
  }

  String get _typeBadge =>
      widget.proposalType.toUpperCase().replaceAll('.', '');

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.proposalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _download() async {
    final url = widget.downloadUrl ?? widget.proposalUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _retryLoad() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proposal ${widget.applicantName}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF006D77),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$_fileIcon  $_typeBadge',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Buka di Browser',
            icon: const Icon(Icons.open_in_new, color: Colors.white70, size: 20),
            onPressed: _openInBrowser,
          ),
          IconButton(
            tooltip: 'Download',
            icon: const Icon(Icons.download_rounded, color: Colors.white70, size: 20),
            onPressed: _download,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ── Gambar ──────────────────────────────────────────────────────────────
    if (_isImageType) {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            widget.proposalUrl,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return _loadingWidget();
            },
            errorBuilder: (_, __, ___) => _errorWidget(),
          ),
        ),
      );
    }

    // ── Dokumen (PDF / PPTX / DOCX / dll) ──────────────────────────────────
    if (_hasError) return _errorWidget();

    return Stack(
      children: [
        // Key dipakai agar widget di-rebuild saat retry
        KeyedSubtree(
          key: ValueKey('viewer-$_hasError'),
          child: ProposalViewerImpl(
            viewerUrl: _viewerUrl,
            onLoaded: () {
              if (mounted) setState(() => _isLoading = false);
            },
            onError: () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              }
            },
          ),
        ),
        if (_isLoading) _loadingWidget(),
      ],
    );
  }

  Widget _loadingWidget() {
    return Container(
      color: const Color(0xFF1B1B1F),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF006D77)),
            const SizedBox(height: 16),
            Text('Memuat proposal...',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 6),
            Text('Mohon tunggu sebentar',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _errorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Text(_fileIcon, style: const TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 20),
            Text(
              'Tidak dapat menampilkan preview',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'File $_typeBadge mungkin butuh waktu lebih lama\natau buka langsung di browser.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white54, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _retryLoad,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Coba Lagi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openInBrowser,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Buka Browser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006D77),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            if (widget.downloadUrl != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _download,
                icon: const Icon(Icons.download_rounded,
                    size: 16, color: Color(0xFF006D77)),
                label: Text(
                  'Download File',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF006D77),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
// proposal_viewer_stub.dart
// Stub ini tidak pernah dipakai di runtime — hanya untuk membuat
// conditional import bisa compile tanpa error di semua platform.
import 'package:flutter/material.dart';

class ProposalViewerImpl extends StatelessWidget {
  final String viewerUrl;
  final VoidCallback onLoaded;
  final VoidCallback onError;

  const ProposalViewerImpl({
    super.key,
    required this.viewerUrl,
    required this.onLoaded,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    // Tidak akan pernah di-render — mobile pakai _mobile, web pakai _web
    return const SizedBox.shrink();
  }
}
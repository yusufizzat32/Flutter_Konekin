// proposal_viewer_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

class ProposalViewerImpl extends StatefulWidget {
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
  State<ProposalViewerImpl> createState() => _ProposalViewerImplState();
}

class _ProposalViewerImplState extends State<ProposalViewerImpl> {
  late final String _viewId;
  late final html.IFrameElement _iframe;

  @override
  void initState() {
    super.initState();
    _viewId = 'proposal-iframe-${DateTime.now().millisecondsSinceEpoch}';

    _iframe = html.IFrameElement()
      ..src = widget.viewerUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'fullscreen'
      ..setAttribute('allowfullscreen', 'true');

    _iframe.onLoad.listen((_) => widget.onLoaded());
    _iframe.onError.listen((_) => widget.onError());

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _iframe,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
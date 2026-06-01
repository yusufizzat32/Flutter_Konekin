// proposal_viewer_mobile.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => widget.onLoaded(),
        onWebResourceError: (_) => widget.onError(),
      ))
      ..loadRequest(Uri.parse(widget.viewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YouTubeViewer extends StatefulWidget {
  final String youTubeVideoUrl;

  const YouTubeViewer({super.key, required this.youTubeVideoUrl});

  @override
  YouTubeViewerState createState() => YouTubeViewerState();
}

class YouTubeViewerState extends State<YouTubeViewer> {

  late WebViewController webController;

  @override
  void initState() {
    super.initState();
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.youTubeVideoUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Results'),
      ),
      body: WebViewWidget(
        controller: webController,
      ),
    );
  }
}
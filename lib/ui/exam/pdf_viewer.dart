
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_shared_widgets/widgets/org_logo_widget.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:webview_flutter/webview_flutter.dart';


class PDFViewer extends StatefulWidget {
  final String pdfUrl;
  final ExamLink examLink;

  const PDFViewer({super.key, required this.pdfUrl, required this.examLink});

  @override
  PDFViewerState createState() => PDFViewerState();
}

class PDFViewerState extends State<PDFViewer> {

  late WebViewController webController;
  Prefs prefs = GetIt.instance<Prefs>();
  Branding? branding;
  @override
  void initState() {
    super.initState();
    _getBrand();
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
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.pdfUrl));
      // ..clearCache();
  }

  _getBrand() {
    branding = prefs.getBrand();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: OrgLogoWidget(
          branding: branding, height: 24,
        ),
      ),
      body: WebViewWidget(
        controller: webController,
      ),
    );
  }
}
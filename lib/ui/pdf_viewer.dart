
import 'package:edu_chatbot/data/exam_link.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../util/functions.dart';

class PDFViewer extends StatefulWidget {
  final String pdfUrl;
  final ExamLink examLink;

  const PDFViewer({super.key, required this.pdfUrl, required this.examLink});

  @override
  PDFViewerState createState() => PDFViewerState();
}

class PDFViewerState extends State<PDFViewer> {

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
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.pdfUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('${widget.examLink.title}', style: myTextStyleSmall(context)),
            Text('${widget.examLink.subjectTitle}', style: myTextStyleSmallPrimaryColor(context)),
            Text('${widget.examLink.documentTitle}', style: myTextStyleSmall(context)),
          ],
        ),
      ),
      body: WebViewWidget(
        controller: webController,
      ),
    );
  }
}
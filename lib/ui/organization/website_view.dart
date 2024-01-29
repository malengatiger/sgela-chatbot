import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../util/functions.dart';

class WebsiteView extends StatefulWidget {
  const WebsiteView({super.key, required this.url, required this.title});

  final String url, title;

  @override
  State<WebsiteView> createState() => _WebsiteViewState();
}

class _WebsiteViewState extends State<WebsiteView> {
  late WebViewController webViewController;
  static const mm = ' 💚💚💚💚 WebsiteView  💚💚';

  @override
  void initState() {
    super.initState();
    _setController();
  }

  _setController() {
    pp('$mm ... url: ${widget.url}');
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            pp('$mm ... onPageStarted ... url: $url');
          },
          onPageFinished: (String url) {
            pp('$mm ... onPageFinished... url: $url');
            //Navigator.of(context).pop(true);
          },
          onWebResourceError: (WebResourceError error) {
            pp('$mm ... onWebResourceError ... error: ${error.description}');
            Navigator.of(context).pop(false);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title, style: myTextStyleSmall(context),),
          ),
          body: ScreenTypeLayout.builder(
            mobile: (_) {
              return Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          widget.title,
                          style: myTextStyle(context,
                              Theme.of(context).primaryColor, 16, FontWeight.w900),
                        ),
                      ),
                      Expanded(child: WebViewWidget(controller: webViewController))
                    ],
                  )
                ],
              );
            },
            tablet: (_) {
              return const Stack();
            },
            desktop: (_) {
              return const Stack();
            },
          ),
        ));
  }
}

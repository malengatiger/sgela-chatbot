import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sgela_shared_widgets/util/styles.dart';

class OpenAiAssistantDocument extends StatefulWidget {
  const OpenAiAssistantDocument({super.key});

  @override
  OpenAiAssistantDocumentState createState() => OpenAiAssistantDocumentState();
}

class OpenAiAssistantDocumentState extends State<OpenAiAssistantDocument>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (_) {
        return Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Assistant Document',
                  style:
                      myTextStyle(context, Colors.pink, 32, FontWeight.w900),
                )
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
    );
  }
}

import 'package:edu_chatbot/local_util/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:sgela_services/sgela_util/functions.dart';

class SgelaMarkdownWidget extends StatelessWidget {
  const SgelaMarkdownWidget(
      {super.key, required this.text, this.backgroundColor});

  final String text;
  final Color? backgroundColor;

  double calculateTextHeight(
      String text, TextStyle textStyle, double maxWidth) {
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: null,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: maxWidth);

    return textPainter.height;
  }

  @override
  Widget build(BuildContext context) {
    var height = calculateTextHeight(
        text, myTextStyleMediumLarge(context, 14), double.infinity);
    pp('Text length: ${text.length}');
    return SingleChildScrollView(
      child: SizedBox(
        height: 500,
        child: Markdown(
          data: text,
          selectable: true,
          controller: ScrollController(),
          onTapText: () {
            pp('Markdown: onTap .........................');
          },
        ),
      ),
    );
  }
}

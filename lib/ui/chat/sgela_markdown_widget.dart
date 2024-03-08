import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:sgela_services/sgela_util/functions.dart';

class SgelaMarkdownWidget extends StatelessWidget {
  const SgelaMarkdownWidget({super.key, required this.text,  this.backgroundColor});

  final String text;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    var height = 400.0;

    return SingleChildScrollView(
      child: Card(
        elevation: 8,
        color: backgroundColor?? Colors.purple,
        child: SizedBox(height: height,
          child: Markdown(
            data: text,
            selectable: true,
            controller: ScrollController(),
            onTapText: (){
              pp('Markdown: onTap .........................');
            },
          ),
        ),
      ),
    );
  }
}
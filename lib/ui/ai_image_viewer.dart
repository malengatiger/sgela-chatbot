import 'dart:io';

import 'package:flutter/material.dart';

class AImageViewer extends StatelessWidget {
  final File file;

  const AImageViewer({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.file(file),
    ));
  }
}
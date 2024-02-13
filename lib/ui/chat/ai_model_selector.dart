import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';

class AiModelSelector extends StatelessWidget {
  const AiModelSelector({super.key, required this.onModelSelected});

  final Function(String) onModelSelected;

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem(value: 'OpenAI', child: Text('OpenAI')),
      const DropdownMenuItem(value: 'GeminiAI', child: Text('GeminiAI')),
      const DropdownMenuItem(value: 'Anthropic', child: Text('Anthropic')),

    ];
    return DropdownButton(
        hint:  Text('Select AI Model', style: myTextStyleSmall(context),),
        items: items,
        onChanged: (c) {
          if (c != null) {
            onModelSelected(c);
          }
        });
  }
}

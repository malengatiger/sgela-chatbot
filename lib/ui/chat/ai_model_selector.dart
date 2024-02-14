import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';

class AiModelSelector extends StatelessWidget {
  const AiModelSelector({super.key, required this.onModelSelected});

  final Function(String) onModelSelected;

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem(value: modelOpenAI, child: Text(modelOpenAI)),
      const DropdownMenuItem(value: modelGeminiAI, child: Text(modelGeminiAI)),
      const DropdownMenuItem(value: modelAnthropic, child: Text(modelAnthropic)),

    ];
    return DropdownButton(
        hint:  Text('Select AI Model', style: myTextStyleSmall(context),),
        items: items,
        onChanged: (c) {
          if (c != null) {
            onModelSelected(c);
          } else {
            onModelSelected(modelGeminiAI);
          }
        });
  }
}

const modelOpenAI  = 'OpenAI';
const modelGeminiAI  = 'GeminiAI';
const modelAnthropic  = 'Anthropic';
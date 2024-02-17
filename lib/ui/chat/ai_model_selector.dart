import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';

class AiModelSelector extends StatelessWidget {
  const AiModelSelector({super.key, required this.onModelSelected, required this.isDropDown});

  final Function(String) onModelSelected;
  final bool isDropDown;

  @override
  Widget build(BuildContext context) {
    if (isDropDown) {
      final List<DropdownMenuItem<String>> items = [
        const DropdownMenuItem(value: modelOpenAI, child: Text(modelOpenAI)),
        const DropdownMenuItem(value: modelGeminiAI, child: Text(modelGeminiAI)),
        const DropdownMenuItem(value: modelMistral, child: Text(modelMistral)),

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
    final List<String> items = [
      modelGeminiAI,
      modelOpenAI,
      modelMistral
    ];
    return Card(
      elevation: 8,
      child: SizedBox(height: 120.0 * items.length,
        child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, index){
              var model = items.elementAt(index);
              return GestureDetector(
                onTap: (){
                  onModelSelected(model);
                },
                child: Card(
                  elevation: 8,
                  child: Text(model, style: myTextStyleMediumLarge(context, 20),),
                ),
              );
        }),
      ),
    );

  }
}

const modelOpenAI  = 'OpenAI';
const modelGeminiAI  = 'GeminiAI';
const modelMistral = 'Mistral';
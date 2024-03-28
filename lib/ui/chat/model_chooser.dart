import 'package:edu_chatbot/local_util/functions.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';

class ModelChooser extends StatelessWidget {
  const ModelChooser({super.key, required this.onSelected});

  final Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    Prefs prefs = GetIt.instance<Prefs>();
    String model = prefs.getCurrentModel();
    pp('$mm model: $model is the current model');
    List<DropdownMenuItem<String>> items = [
      DropdownMenuItem(
          value: modelMixtral,
          child: Text(modelMixtral, style: myTextStyleSmall(context))),
      DropdownMenuItem(
        value: modelGeminiAI,
        child: Text(modelGeminiAI, style: myTextStyleSmall(context)),
      ),
      DropdownMenuItem(
          value: modelOpenAI,
          child: Text(modelOpenAI, style: myTextStyleSmall(context))),
      DropdownMenuItem(
          value: modelClaude,
          child: Text(modelClaude, style: myTextStyleSmall(context))),
      DropdownMenuItem(
          value: modelMistral,
          child: Text(modelMistral, style: myTextStyleSmall(context))),
      DropdownMenuItem(
          value: modelGemma,
          child: Text(modelGemma, style: myTextStyleSmall(context))),
      DropdownMenuItem(
          value: modelLlama2,
          child: Text(modelLlama2, style: myTextStyleSmall(context))),
    ];
    return DropdownButton(
        // hint: const Text('AI Model'),
        items: items,
        value: model,
        onChanged: (m) {
          if (m != null) {
            if (m == modelClaude ||
                m == modelMistral ||
                m == modelGemma ||
                m == modelLlama2) {
              pp('$mm model: $m is not available yet');
              showToast(message: '$m not available yet', context: context);
              return;
            }
            pp('$mm model: $model has been selected');
            onSelected(m);
            prefs.saveCurrentModel(m);
          }
        });
  }

  static const mm = '♻️♻️♻️♻️ModelChooser ♻️';
}

const modelClaude = 'Claude';
const modelGeminiAI = 'Gemini';
const modelOpenAI = 'OpenAI';
const modelMistral = 'Mistral';
const modelPerplexityAI = 'PerplexityA';
const modelLlama2 = 'Llama2';
const modelMixtral = 'Groq';
const modelGemma = 'Gemma';

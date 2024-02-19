import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../data/organization.dart';
import '../../util/functions.dart';
import '../../util/prefs.dart';
import '../chat/ai_model_selector.dart';

class ModelSegmentButton extends StatefulWidget {
  const ModelSegmentButton({super.key, required this.onModelSelected});

  final Function(String) onModelSelected;

  @override
  ModelSegmentButtonState createState() => ModelSegmentButtonState();
}

class ModelSegmentButtonState extends State<ModelSegmentButton>
    with SingleTickerProviderStateMixin {
  Organization? organization;
  Prefs prefs = GetIt.instance<Prefs>();
  static const mm = '🔵🔵🔵🔵 ModelSegmentButton  🔵🔵';
  List<ButtonSegment<String>> buttons = [];

  @override
  void initState() {
    super.initState();
    _buildButtons();
  }

  Set<String> _selectedButton = {modelGeminiAI};
  _buildButtons() {
    buttons.add(ButtonSegment(
        value: modelGeminiAI,
        label: Text(
          modelGeminiAI,
          style: myTextStyleTiny(context),
        )));
    buttons.add(ButtonSegment(
        value: modelOpenAI,
        label: Text(modelOpenAI, style: myTextStyleTiny(context))));
    buttons.add(ButtonSegment(
        value: modelMistral,
        label: Text(modelMistral, style: myTextStyleTiny(context))));
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return buttons.isEmpty? gapW4: Card(
      child: SegmentedButton(
        emptySelectionAllowed: true,
        segments: buttons,
        onSelectionChanged: (sel) {
          pp('$mm ... ai model selection button selected: $sel');
          if (sel.isNotEmpty) {
            switch (sel.first) {
              case modelGeminiAI:
                prefs.saveCurrentModel(modelGeminiAI);
                _selectedButton = {modelGeminiAI};
                widget.onModelSelected(modelGeminiAI);
                break;
              case modelOpenAI:
                prefs.saveCurrentModel(modelOpenAI);
                _selectedButton = {modelOpenAI};
                widget.onModelSelected(modelOpenAI);
                break;
              case modelMistral:
                showToast(
                    message: 'Mistral model not available yet', context: context);
                prefs.saveCurrentModel(modelGeminiAI);
                _selectedButton = {modelGeminiAI};
                widget.onModelSelected(modelGeminiAI);
                break;
              default:
                break;
            }
          } else {
            _selectedButton = {modelGeminiAI};
          }
          setState(() {});
        },
        selected: _selectedButton,
      ),
    );
  }
}
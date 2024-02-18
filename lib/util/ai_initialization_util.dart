import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

import 'environment.dart';
import 'functions.dart';

class AiInitializationUtil {
  static const String mx = '💛💛 AiInitializationUtil: 💛💛';

  static Future<void> initOpenAI() async {
    pp('$mx ............. _initOpenAI ....');

    var openAIKey = await ChatbotEnvironment.getOpenAIKey();

    OpenAI.apiKey = openAIKey;
    OpenAI.requestsTimeOut = const Duration(seconds: 180); // 3 minutes.
    OpenAI.showLogs = false;
    OpenAI.showResponsesLogs = false;

    pp('$mx OpenAI has been initialized and timeOut set!!\n'
        '💛💛 model.endpoint: ${OpenAI.instance.model.endpoint} '
        '💛💛 openAIKey: $openAIKey : ${OpenAI.instance.toString()}');

    try {
      var models = await OpenAI.instance.model.list();
      for (var model in models) {
        pp('$mx OpenAI model: ${model.id} 🔵🔵ownedBy: ${model.ownedBy}');
      }
    } catch (e, s) {
      pp('$mx ... $e $s');
    }

    pp('\n$mx OpenAI initialized!\n');
  }

  static Future<Gemini> initGemini() async {
    pp('$mx ............. _initGemini ....');
    var geminiAPIKey = ChatbotEnvironment.getGeminiAPIKey();
    var gem = Gemini.init(
        apiKey: geminiAPIKey,
        generationConfig:
            GenerationConfig(temperature: 0.1, maxOutputTokens: 1000),
        enableDebugging: ChatbotEnvironment.isChatDebuggingEnabled());

    try {
      var geminiModels = await Gemini.instance.listModels();
      for (var model in geminiModels) {
        pp('$mx Gemini AI model: ${model.displayName} 🔵🔵name: ${model.name} 🔵🔵 ${model.description}');
      }
    } catch (e, s) {
      pp('$mx $e $s');
    }

    pp('$mx Gemini AI API has been initialized!! \n$mx'
        ' 🔵🔵 Gemini apiKey: $geminiAPIKey 🔵🔵 ');
    return gem;
  }
}

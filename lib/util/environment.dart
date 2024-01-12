import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dot;

import 'functions.dart';

class ChatbotEnvironment {
  //💙Skunk backend -
  static const _devSkunkUrl = 'http://192.168.86.242:8080/skunk-service/';
  static const _prodSkunkUrl = 'https://skunkworks-backend-service-knzs6eczwq-nw.a.run.app/';

  //TODO - refresh url links after Skunk deployment

  //💙Chatbot Backend
  static const _devGeminiUrl = 'http://192.168.86.242:3010/';
  static const _prodGeminiUrl = 'https://sgela-ai-knzs6eczwq-nw.a.run.app/';

  static const _devFirebaseName = 'sgela-ai-33';
  static const _prodFirebaseName = 'sgela-ai-33';

  static String getSkunkUrl() {
    //todo - REMOVE AFTER PROD TEST
    if (kDebugMode) {
      return _devSkunkUrl;
    } else {
      return _prodSkunkUrl;
    }
    // return _prodSkunkUrl;
  }

  static String getGeminiUrl() {
    if (kDebugMode) {
      return _devGeminiUrl;
    } else {
      return _prodGeminiUrl;
    }
    // return _prodGeminiUrl;

  }

  static String getFirebaseName() {
    if (kDebugMode) {
      return _devFirebaseName;
    } else {
      return _prodFirebaseName;
    }
  }
  static int maxResults = 48;

  static bool isDotLoaded = false;
  //AIza
  static String part1 = 'SyAUXc8lM1wPsR-Rrow0XLms3i';
  static String part2 = 'Tbok7FjDA';
  static String part0 = 'AIza';
  static String cpart1 = '6JYaZCnxXBlul3XGHuRBT3Blbk';
  static String cpart2 = 'FJZ6XfXvncD9zGDK9ZSm9p';
  static String cpart0 = 'sk-';
  static String getGeminiAPIKey()  {
    return '$part0$part1$part2';

  }
  static String getChatGPTAPIKey()  {
    return '$cpart0$cpart1$cpart2';

  }

  static const _devClientId = "";
  static const _prodClientId = "";
  static String getGoogleClientId() {
    if (kDebugMode) {
      return _devClientId;
    } else {
      return _prodClientId;
    }
  }

  static bool isChatDebuggingEnabled() {
    if (kDebugMode) {
      return true;  //todo - change back to true in production
    } else {
      return false;
    }
  }

}

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dot;

import 'functions.dart';

class ChatbotEnvironment {
  //💙Skunk backend -

  static const _ipNormal = '192.168.86.242';
  static const _ipFibreDown = '192.168.86.230';
  static const bool isFibreDown = false;
  static const _devSkunkUrl = 'http://${isFibreDown? _ipFibreDown: _ipNormal}:8080/skunk-service/';
  static const _prodSkunkUrl = 'https://skunkworks-backend-service-knzs6eczwq-nw.a.run.app/';

  //TODO - refresh url links after Skunk deployment

  //💙Chatbot Backend
  static const _devGeminiUrl = 'http://${isFibreDown? _ipFibreDown: _ipNormal}:3010/';
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

  static String sgelaLogoUrl = 'https://storage.googleapis.com/sgela-ai-33.appspot.com/skunkMedia/Users/aubreymalabie/Work/education_skunk/cloudstorage/sgelaAI_orgImage_2391227687307161932_1705233061091.png?GoogleAccessId=firebase-adminsdk-pwe9o@sgela-ai-33.iam.gserviceaccount.com&Expires=2020593064&Signature=MZkE0IsOtvfRKNgX%2FuuSoOmBDx8b67a5U%2FFe4MtseEORgtmrliBALwA2e%2FBaApII3ZOfbwSJGjKnHGOMsb97UL2Opa7oUvw5fI9bVsXoa8C8cDlBmvIc9WcrgqWSXXBbAx5IB%2BVXWjH%2Ffz7EEDBqV3dueDD6PllnKtY9OEHURZVN6oBv8w2fLzfK1oG97IfS3WDEHEqDn5EAWsJpXdH6Q3luIq4ub7O%2BQeh53ByKlCG38CfeRIXQ5lVegspeQHebq%2Fff1NQke6yQNTwlcOyF43tC%2FVnFkF84KztvnuXt60iZ%2BbRlu1xPWZE6LVo9nEms4q7vqKfEGGcW9H1uqDrEjg%3D%3D';
  static String sgelaSplashUrl = 'https://storage.googleapis.com/sgela-ai-33.appspot.com/skunkMedia/Users/aubreymalabie/Work/education_skunk/cloudstorage/sgelaAI_orgImage_2391227687307161932_1705233064565.jpg?GoogleAccessId=firebase-adminsdk-pwe9o@sgela-ai-33.iam.gserviceaccount.com&Expires=2020593067&Signature=empRi7EgHfBp%2FXil9OFhgUhSqAcFu62Uay%2F80UZJSuFOsp8o1a9wCiZUTuYeJAtWbs90Q3ctowLH3uGhYyQPiQIuznfH1LtFQjKPuIbpwiHjV4pHlVv1Yf7si%2F6fQwO6Io1bRVi8Tu%2FlgvQTs7x%2FGVWrQibdtPJMZstq0rcwnEzfuhpBB6%2BNQLBCf2xw9cXWLi%2F0LUgJnxSVLQTIG7oV0wSS1YIKn1OUkBrSUEgqLcrgG1cJoyYyIfblLHvUbfg%2F1HW1LKWwZuU%2FkjffY4GiSJ1CX3Lcn%2Fj3W77eWNBCaaFJKq6SDie88tho4UzL3W1MiK4I77HmpS7tmveA3AgrAg%3D%3D';


}

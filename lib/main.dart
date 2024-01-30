import 'package:dart_openai/dart_openai.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/downloader_isolate.dart';
import 'package:edu_chatbot/services/you_tube_service.dart';
import 'package:edu_chatbot/ui/landing_page.dart';
import 'package:edu_chatbot/util/dark_light_control.dart';
import 'package:edu_chatbot/util/environment.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:edu_chatbot/util/register_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:get_it/get_it.dart';

import 'firebase_options.dart';

const String mx = '🍎 🍎 🍎 main: ';
final actionCodeSettings = ActionCodeSettings(
  url: 'https://sgela-ai-33.firebaseapp.com',
  handleCodeInApp: true,
  androidMinimumVersion: '1',
  androidPackageName: 'com.boha.edu_chatbot',
  iOSBundleId: 'io.flutter.plugins.fireabaseUiExample',
);
final emailLinkProviderConfig = EmailLinkAuthProvider(
  actionCodeSettings: actionCodeSettings,
);

Future<void> main() async {
  pp('$mx SgelaAI Chatbot starting .... $mx');
  WidgetsFlutterBinding.ensureInitialized();
  var app = await Firebase.initializeApp(
    name: ChatbotEnvironment.getFirebaseName(),
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  pp('$mx Firebase has been initialized!! $mx name: ${app.name}');

  FirebaseUIAuth.configureProviders([
    emailLinkProviderConfig,
  ]);
  pp('$mx Firebase Auth providers have been setup!!');
  pp('${app.options.asMap}');

  var geminiAPIKey = ChatbotEnvironment.getGeminiAPIKey();
  var chatGPTAPIKey = ChatbotEnvironment.getChatGPTAPIKey();

  OpenAI.apiKey = chatGPTAPIKey;
  OpenAI.requestsTimeOut = const Duration(seconds: 180); // 3 minutes.
  OpenAI.showLogs = true;
  OpenAI.showResponsesLogs = true;

  pp('$mx OpenAI has been initialized and timeOut set!!');

  Gemini.init(
      apiKey: ChatbotEnvironment.getGeminiAPIKey(),
      enableDebugging: ChatbotEnvironment.isChatDebuggingEnabled());
  pp('$mx Gemini AI API has been initialized!! \n$mx'
      ' 🔵🔵 Gemini apiKey: $geminiAPIKey 🔵🔵 ChatGPT apiKey: $chatGPTAPIKey');
  // Register services
  await registerServices();
  //
  var prefs = GetIt.instance<Prefs>();
  var mode = prefs.getMode();
  var colorIndex = prefs.getColorIndex();
  modeAndColor = ModeAndColor(mode, colorIndex);
  //
  runApp(const MyApp());
}

late ModeAndColor modeAndColor;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  void _dismissKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.hasFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var repository = GetIt.instance<Repository>();
    var youTubeService = GetIt.instance<YouTubeService>();
    var downloaderService = GetIt.instance<DownloaderService>();
    var dlc = GetIt.instance<DarkLightControl>();
    var gemini = GetIt.instance<Gemini>();

    return GestureDetector(
      onTap: () {
        pp('main: ... dismiss keyboard? Tapped somewhere ...');
        _dismissKeyboard(context);
      },
      child: StreamBuilder(
          stream: dlc.darkLightStream,
          // Replace myStream with your actual stream
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              // pp('main:dlc.darkLightStream: 🍎 mode could be changing, '
              //     'mode: ${snapshot.data!.mode} colorIndex: ${snapshot.data!.colorIndex}');
              modeAndColor = snapshot.data!;
            }

            return MaterialApp(
              title: 'SgelaAI',
              debugShowCheckedModeBanner: false,
              theme: _getTheme(context),
              home: const LandingPage(),
            );
          }),
    );
  }

  ThemeData _getTheme(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    if (modeAndColor.mode > -1) {
      if (modeAndColor.mode == 0) {
        return ThemeData.light().copyWith(
          primaryColor: getColors()
              .elementAt(modeAndColor.colorIndex), // Set the primary color
        );
      } else {
        return ThemeData.dark().copyWith(
          primaryColor: getColors()
              .elementAt(modeAndColor.colorIndex), // Set the primary color
        );
      }
    }
    if (brightness == Brightness.dark) {
      return ThemeData.dark().copyWith(
        primaryColor: getColors()
            .elementAt(modeAndColor.colorIndex), // Set the primary color
      );
    } else {
      return ThemeData.light().copyWith(
        primaryColor: getColors()
            .elementAt(modeAndColor.colorIndex), // Set the primary color
      );
    }
  }
}

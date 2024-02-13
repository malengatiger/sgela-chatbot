import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
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
  pp('${app.options.asMap}');
  //
  try {
    var fbf = FirebaseFirestore.instance;
    await _initGemini();
    await registerServices(fbf, Gemini.instance);
    _initOpenAI();
    //
    var prefs = GetIt.instance<Prefs>();
    var mode = prefs.getMode();
    var colorIndex = prefs.getColorIndex();
    modeAndColor = ModeAndColor(mode, colorIndex);
  } catch (e,s) {
    pp(e);
    pp(s);
  }
  runApp(const MyApp());
}

Future<void> _initOpenAI() async {
  pp('$mx _initOpenAI ....');

  var openAIKey = await ChatbotEnvironment.getOpenAIKey();

  OpenAI.apiKey = openAIKey;
  OpenAI.requestsTimeOut = const Duration(seconds: 180); // 3 minutes.
  OpenAI.showLogs = false;
  OpenAI.showResponsesLogs = false;

  pp('$mx OpenAI has been initialized and timeOut set!!\n'
      '💛💛 model.endpoint: ${OpenAI.instance.model.endpoint} '
      '💛💛 openAIKey: $openAIKey');

  var x = await OpenAI.instance.model.list();
  for (var model in x) {
    pp('$mx OpenAI model: ${model.id} 🔵🔵ownedBy: ${model.ownedBy}');
  }

  pp('\n$mx OpenAI initialized!\n');

}

Future<void> _initGemini() async {
  var geminiAPIKey = ChatbotEnvironment.getGeminiAPIKey();

  Gemini.init(
      apiKey: geminiAPIKey,
      enableDebugging: ChatbotEnvironment.isChatDebuggingEnabled());

  var geminiModels = await Gemini.instance.listModels();
  for (var model in geminiModels) {
    pp('$mx Gemini AI model: ${model.displayName} 🔵🔵name: ${model.name} 🔵🔵 ${model.description}');
  }
  pp('$mx Gemini AI API has been initialized!! \n$mx'
      ' 🔵🔵 Gemini apiKey: $geminiAPIKey 🔵🔵 ');
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

    var dlc = GetIt.instance<DarkLightControl>();
    var prefs = GetIt.instance<Prefs>();
    var fs = GetIt.instance<FirestoreService>();

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
              theme: _getTheme(context, prefs),
              home:  const LandingPage(
                hideButtons: false,
              ),
            );
          }),
    );
  }

  ThemeData _getTheme(BuildContext context, Prefs prefs ) {
    var colorIndex = prefs.getColorIndex();
    var mode = prefs.getMode();
    if (mode == DARK) {
      return ThemeData.dark().copyWith(
        primaryColor:
        getColors().elementAt(colorIndex), // Set the primary color
      );
    } else {
      return ThemeData.light().copyWith(
        primaryColor:
        getColors().elementAt(colorIndex), // Set the primary color
      );
    }
  }
}

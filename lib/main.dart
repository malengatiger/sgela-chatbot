import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/chat_service.dart';
import 'package:edu_chatbot/services/downloader_isolate.dart';
import 'package:edu_chatbot/services/local_data_service.dart';
import 'package:edu_chatbot/services/you_tube_service.dart';
import 'package:edu_chatbot/ui/subject_search.dart';
import 'package:edu_chatbot/util/dark_light_control.dart';
import 'package:edu_chatbot/util/environment.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:edu_chatbot/util/register_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneAuthProvider, EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneAuthProvider, EmailAuthProvider;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
// import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
// import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
// import 'package:firebase_ui_oauth_facebook/firebase_ui_oauth_facebook.dart';
// import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
// import 'package:firebase_ui_oauth_twitter/firebase_ui_oauth_twitter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'firebase_options.dart';

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
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  pp('$mx Firebase has been initialized!! $mx name: ${app.name}');

  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    emailLinkProviderConfig,
    PhoneAuthProvider(),

  ]);
  pp('$mx Firebase Auth providers have been setup!!');
  pp('${app.options.asMap}');

  Gemini.init(apiKey: ChatbotEnvironment.getGeminiAPIKey(),
      enableDebugging: ChatbotEnvironment.isChatDebuggingEnabled());
  pp('$mx Gemini AI API has been initialized!! $mx'
      ' Gemini apiKey: ${ChatbotEnvironment.getGeminiAPIKey()}');
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
              pp('main:dlc.darkLightStream: 🍎 mode could be changing, '
                  'mode: ${snapshot.data!.mode} colorIndex: ${snapshot.data!.colorIndex}');
              modeAndColor = snapshot.data!;
            }

            return MaterialApp(
              title: 'SgelaAI',
              debugShowCheckedModeBanner: false,
              theme: _getTheme(context),
              home: SubjectSearch(
                repository: repository,
                gemini: gemini,
                prefs: GetIt.instance<Prefs>(),
                downloaderService: GetIt.instance<DownloaderService>(),
                localDataService: GetIt.instance<LocalDataService>(),
                chatService: GetIt.instance<ChatService>(),
                youTubeService: youTubeService,
                colorWatcher:  GetIt.instance<ColorWatcher>(),
                darkLightControl:  GetIt.instance<DarkLightControl>(),
              ),
            );
          }),
    );
  }

  ThemeData _getTheme(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    if ( modeAndColor.mode > -1) {
      if (modeAndColor.mode == 0) {
        return ThemeData.light().copyWith(
          primaryColor: getColors().elementAt(modeAndColor.colorIndex), // Set the primary color
        );
      } else {
        return ThemeData.dark().copyWith(
          primaryColor: getColors().elementAt(modeAndColor.colorIndex), // Set the primary color
        );
      }
    }
    if (brightness == Brightness.dark) {
      return ThemeData.dark().copyWith(
        primaryColor: getColors().elementAt(modeAndColor.colorIndex), // Set the primary color
      );
    } else {
      return ThemeData.light().copyWith(
        primaryColor: getColors().elementAt(modeAndColor.colorIndex), // Set the primary color
      );    }
  }
}

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

import 'firebase_options.dart';
const String mx = '🍎 🍎 🍎 main: ';
Future<void> main() async {
  pp('$mx AI ChatBuddy starting .... $mx');
  WidgetsFlutterBinding.ensureInitialized();
  var app = await Firebase.initializeApp(
    name: ChatbotEnvironment.getFirebaseName(),
    options: DefaultFirebaseOptions.currentPlatform,
  );
  pp('$mx Firebase has been initialized!! $mx name: ${app.name}');
  pp('${app.options.asMap}');
  // Register services
  await registerServices();
  Gemini.init(apiKey: ChatbotEnvironment.getGeminiAPIKey());
  pp('$mx Gemini AI API has been initialized!! $mx'
      ' Gemini apiKey: ${ChatbotEnvironment.getGeminiAPIKey()}');
  mode = await Prefs.getMode();
  runApp(const MyApp());
}


int mode = 0;

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

    return GestureDetector(
      onTap: () {
        pp('main: ... dismiss keyboard? Tapped somewhere ...');
        _dismissKeyboard(context);
      },
      child: StreamBuilder(
          stream: DarkLightControl.darkLightStream,
          // Replace myStream with your actual stream
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              pp('🍎 mode could be changing, mode: ${snapshot.data!}');
              mode = snapshot.data!;
            }

            return MaterialApp(
              title: 'SgelaAI',
              debugShowCheckedModeBanner: false,
              theme: _getTheme(context),
              home: SubjectSearch(
                repository: repository,
                downloaderService: GetIt.instance<DownloaderService>(),
                localDataService: GetIt.instance<LocalDataService>(),
                chatService: GetIt.instance<ChatService>(),
                youTubeService: youTubeService,
              ),
            );
          }),
    );
  }

  ThemeData _getTheme(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    if ( mode > -1) {
      if (mode == 0) {
        pp('... we are in own LIGHT mode ... ');
        return ThemeData.light(useMaterial3: true,);
      } else {
        pp('... we are in own DARK mode ... ');
        return ThemeData.dark(useMaterial3: true,);
      }
    }
    if (brightness == Brightness.dark) {
      pp('... we are in device DARK mode ... ');
      return ThemeData.dark(useMaterial3: true,);
    } else {
      pp('... we are in device LIGHT mode ... ');
      return ThemeData.light(useMaterial3: true,);
    }
  }
}

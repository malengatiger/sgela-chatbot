import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:edu_chatbot/ui/chat/generative_ai.dart';
import 'package:edu_chatbot/ui/landing_page.dart';
import 'package:edu_chatbot/util/ai_initialization_util.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
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

late Prefs mPrefs;
Future<void> main() async {
  pp('$mx SgelaAI Chatbot starting .... $mx');
  WidgetsFlutterBinding.ensureInitialized();
  var app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  pp('$mx Firebase has been initialized!! $mx name: ${app.name}');
  pp('${app.options.asMap}');
  //
  mPrefs = Prefs(await SharedPreferences.getInstance());

  try {
    var fbf = FirebaseFirestore.instanceFor(app: app);
    var auth = FirebaseAuth.instanceFor(app: app);
    var gem = await AiInitializationUtil.initGemini();
    await AiInitializationUtil.initOpenAI();
    await registerServices(fbf, auth,gem);
    //
  } catch (e,s) {
    pp(e);
    pp(s);
  }
  runApp(const MyApp());
}

late ModeAndColor modeAndColor;
void dismissKeyboard(BuildContext context) {
  final currentFocus = FocusScope.of(context);
  if (!currentFocus.hasPrimaryFocus && currentFocus.hasFocus) {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    var dlc = GetIt.instance<DarkLightControl>();
    return GestureDetector(
      onTap: () {
        pp('main: ... dismiss keyboard? Tapped somewhere ...');
        dismissKeyboard(context);
      },
      child: StreamBuilder(
          stream: dlc.darkLightStream,
          // Replace myStream with your actual stream
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              modeAndColor = snapshot.data!;
            }

            return MaterialApp(
              title: 'SgelaAI',
              debugShowCheckedModeBanner: false,
              theme: _getTheme(context),
              // home: const GenerativeChatScreen('Gemini',),
              home:  const LandingPage(
                hideButtons: false,
              ),
            );
          }),
    );
  }


  ThemeData _getTheme(BuildContext context )  {
    var colorIndex = mPrefs.getColorIndex();
    var mode = mPrefs.getMode();
    if (mode == -1) {
      mode = DARK;
    }
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

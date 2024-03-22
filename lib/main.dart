import 'dart:io';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_chatbot/ui/organization/organization_splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sgela_services/sgela_util/ai_initialization_util.dart';
import 'package:sgela_services/sgela_util/dark_light_control.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:sgela_services/sgela_util/register_services.dart';
import 'package:sgela_shared_widgets/widgets/splash_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'local_util/functions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const String mx = '🍎🍎🍎 main: ';
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

Map<String, String> loadEnvFile() {
  final envFile = File('.env');
  final envVars = <String, String>{};

  if (envFile.existsSync()) {
    final lines = envFile.readAsLinesSync();
    for (final line in lines) {
      final parts = line.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        envVars[key] = value;
      }
    }
  }

  pp('$mx ENVIRONMENT VARS: 🍎🍎🍎 $envVars 💛💛💛💛');
  return envVars;
}


Future<void> main() async {
  pp('$mx SgelaAI Chatbot starting .... $mx');
  WidgetsFlutterBinding.ensureInitialized();
  mPrefs = Prefs(await SharedPreferences.getInstance());

  try {
    await dotenv.load(fileName: '.env');
    pp('$mx env loaded ??? PINECONE_ENVIRONMENT:'
        ' ${dotenv.env['PINECONE_ENVIRONMENT']}');
  } catch (e,s) {
    pp('$mx $e $s');
  }
  // loadEnvFile();
  await _performSetup();
  runApp(const MyApp());
}

late ModeAndColor modeAndColor;

void dismissKeyboard(BuildContext context) {
  final currentFocus = FocusScope.of(context);
  if (!currentFocus.hasPrimaryFocus && currentFocus.hasFocus) {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

Future _performSetup() async {
  try {
    var app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    pp('$mx Firebase has been initialized! name: ${app.name}');
    pp('${app.options.asMap}');
    var fbf = FirebaseFirestore.instanceFor(app: app);
    var auth = FirebaseAuth.instanceFor(app: app);
    var gem = await AiInitializationUtil.initGemini();
    await AiInitializationUtil.initOpenAI();
    await registerServices(
        gemini: gem, firebaseFirestore: fbf, firebaseAuth: auth);
    //
  } catch (e, s) {
    pp(e);
    pp(s);
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
                // home:  const OrganizationSplash( ),
                home: AnimatedSplashScreen(
                  splash: const SplashWidget(),
                  animationDuration: const Duration(milliseconds: 3000),
                  curve: Curves.easeInCirc,
                  splashIconSize: 160.0,
                  nextScreen: const OrganizationSplash(),
                  splashTransition: SplashTransition.fadeTransition,
                  pageTransitionType: PageTransitionType.leftToRight,
                  backgroundColor: Colors.teal.shade900,
                ));
          }),
    );
  }

  ThemeData _getTheme(BuildContext context) {
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:edu_chatbot/services/busy_stream_service.dart';
import 'package:edu_chatbot/services/chat_gpt_service.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/util/dark_light_control.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/repository.dart';
import '../services/accounting_service.dart';
import '../services/agriculture_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/downloader_isolate.dart';
import '../services/local_data_service.dart';
import '../services/math_service.dart';
import '../services/physics_service.dart';
import '../services/you_tube_service.dart';
import 'dio_util.dart';
import 'functions.dart';

Future<void> registerServices() async {
  pp('🍎🍎🍎🍎🍎🍎 registerServices: initialize service singletons with GetIt .... 🍎🍎🍎');

  var lds = LocalDataService();
  await lds.init();
  Dio dio = Dio();
  var dioUtil = DioUtil(dio, lds);
  var repository = Repository(dioUtil, lds, dio);
  var prefs = Prefs(await SharedPreferences.getInstance());
  var dlc = DarkLightControl(prefs);
  var cWatcher = ColorWatcher(dlc, prefs);
  var firestoreService = FirestoreService(FirebaseFirestore.instance, prefs,cWatcher);
  GetIt.instance.registerLazySingleton<BusyStreamService>(
          () => BusyStreamService());
  GetIt.instance.registerLazySingleton<MathService>(() => MathService());
  GetIt.instance.registerLazySingleton<ChatService>(() => ChatService(dioUtil));
  GetIt.instance
      .registerLazySingleton<AgricultureService>(() => AgricultureService());
  GetIt.instance.registerLazySingleton<PhysicsService>(() => PhysicsService());
  GetIt.instance
      .registerLazySingleton<Repository>(() => repository);
  GetIt.instance.registerLazySingleton<AuthService>(() => AuthService(FirebaseAuth.instance, prefs, firestoreService));
  GetIt.instance
      .registerLazySingleton<AccountingService>(() => AccountingService());
  GetIt.instance.registerLazySingleton<LocalDataService>(() => lds);
  GetIt.instance.registerLazySingleton<YouTubeService>(
          () => YouTubeService(dioUtil, lds));
  GetIt.instance.registerLazySingleton<DownloaderService>(
          () => DownloaderService(firestoreService, lds));
  GetIt.instance.registerLazySingleton<Prefs>(
          () => prefs);
  GetIt.instance.registerLazySingleton<ColorWatcher>(
          () => cWatcher);
  GetIt.instance.registerLazySingleton<DarkLightControl>(
          () => dlc);
  GetIt.instance.registerLazySingleton<Gemini>(
          () => Gemini.instance);
  GetIt.instance.registerLazySingleton<ChatGptService>(
          () => ChatGptService());
  GetIt.instance.registerLazySingleton<FirestoreService>(
          () => firestoreService);

  pp('🍎🍎🍎🍎🍎🍎 registerServices: GetIt has registered 15 services. 🍎 Cool!! 🍎🍎🍎');
}
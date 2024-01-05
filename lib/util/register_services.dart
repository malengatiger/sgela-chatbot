import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

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
  GetIt.instance.registerLazySingleton<MathService>(() => MathService());
  GetIt.instance.registerLazySingleton<ChatService>(() => ChatService(dioUtil));
  GetIt.instance
      .registerLazySingleton<AgricultureService>(() => AgricultureService());
  GetIt.instance.registerLazySingleton<PhysicsService>(() => PhysicsService());
  GetIt.instance
      .registerLazySingleton<Repository>(() => repository);
  GetIt.instance.registerLazySingleton<AuthService>(() => AuthService());
  GetIt.instance
      .registerLazySingleton<AccountingService>(() => AccountingService());
  GetIt.instance.registerLazySingleton<LocalDataService>(() => lds);
  GetIt.instance.registerLazySingleton<YouTubeService>(
          () => YouTubeService(dioUtil, lds));
  GetIt.instance.registerLazySingleton<DownloaderService>(
          () => DownloaderService(repository, lds));

  pp('🍎🍎🍎🍎🍎🍎 registerServices: GetIt has registered 10 services. 🍎Cool! 🍎🍎🍎');
}
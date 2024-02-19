
import 'package:dio/dio.dart';
import 'package:edu_chatbot/util/functions.dart';

import '../services/local_data_service.dart';

class DioUtil {
  final Dio dio;
  static const mm = '🥬🥬🥬🥬 DioUtil 🥬';
final LocalDataService localDataService;
  DioUtil(this.dio, this.localDataService);


  Future<dynamic> sendGetRequest(
      String path, Map<String, dynamic> queryParameters) async {
    pp('$mm Dio starting ...: 🍎🍎🍎 path: $path 🍎🍎');
    try {
      Response response;
      // The below request is the same as above.
      response = await dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.json),
      );

      pp('$mm Dio network response: 🥬🥬🥬🥬🥬🥬 status code: ${response.statusCode}');
      return response.data;
    } catch (e) {
      pp('$mm Dio network response: 👿👿👿👿 ERROR: $e');
      pp(e);
      rethrow;
    }
  }

  Future<dynamic> sendPostRequest(String path, dynamic body) async {
    pp('$mm Dio sendPostRequest ...: 🍎🍎🍎 path: $path 🍎🍎');
    try {
      Response response;
      response = await dio
          .post(
            path,
            data: body,
            options: Options(responseType: ResponseType.json),
            onReceiveProgress: (count, total) {
              // pp('$mm onReceiveProgress: count: $count total: $total');
            },
            onSendProgress: (count, total) {
              // pp('$mm onSendProgress: count: $count total: $total');
            },
          )
          .timeout(const Duration(seconds: 300))
          .catchError((error, stackTrace) {
            pp('$mm Error occurred during the POST request: $error');
          });
      pp('$mm .... network POST response, 💚status code: ${response.statusCode} 💚💚');
      return response.data;
    } catch (e) {
      pp('$mm .... network POST error response, '
          '👿👿👿👿 $e 👿👿👿👿');
      pp(e);
      rethrow;
    }
  }
}

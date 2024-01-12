import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/services/local_data_service.dart';
import 'package:edu_chatbot/util/dio_util.dart';
import 'package:edu_chatbot/util/environment.dart';

import '../data/user.dart';
import '../util/functions.dart';

class UserRepository {
  final DioUtil dioUtil;
  final LocalDataService localDataService;

  static const mm = '💦💦💦💦 UserRepository 💦';


  UserRepository(this.dioUtil, this.localDataService);

  Future<User?> registerUser(User user) async {
    return null;
  }

  Future<List<User>> getUsers(String organizationId) async {

      return [];

  }


}

import 'package:edu_chatbot/data/subject.dart';
import 'package:edu_chatbot/services/local_data_service.dart';
import 'package:edu_chatbot/util/dio_util.dart';
import 'package:edu_chatbot/util/environment.dart';

import '../data/sgela_user.dart';
import '../util/functions.dart';

class SgelaUserRepository {
  final DioUtil dioUtil;
  final LocalDataService localDataService;

  static const mm = '💦💦💦💦 SgelaUserRepository 💦';


  SgelaUserRepository(this.dioUtil, this.localDataService);

  Future<SgelaUser?> registerSgelaUser(SgelaUser user) async {
    return null;
  }

  Future<List<SgelaUser>> getSgelaUsers(String organizationId) async {

      return [];

  }


}

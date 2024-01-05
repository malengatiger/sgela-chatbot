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

  Future<List<Subject>> _readSubjects() async {
    var url = ChatbotEnvironment.getSkunkUrl();
    var res = await dioUtil.sendGetRequest('${url}links/getSubjects', {});
    // Assuming the response data is a list of subjects
    pp(res);
    List<dynamic> responseData = res;
    List<Subject> subjects = [];

    for (var subjectData in responseData) {
      Subject subject = Subject.fromJson(subjectData);
      subjects.add(subject);
    }
    pp("$mm Subjects found: ${subjects.length} ");
    if (subjects.isNotEmpty) {
      await localDataService.addSubjects(subjects);
    }
    return subjects;
  }

}

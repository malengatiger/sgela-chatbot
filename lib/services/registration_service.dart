import '../data/organization.dart';
import '../data/user.dart';
import '../util/dio_util.dart';
import '../util/environment.dart';

class RegistrationService {
  final DioUtil dioUtil;

  RegistrationService(this.dioUtil);

  final String urlPrefix = ChatbotEnvironment.getSkunkUrl();

  Future registerOrganization(Organization organization) async {
    String url = '${urlPrefix}organizations/registerOrganization';
  }
  Future registerUser(User user) async {
    String url = '${urlPrefix}organizations/registerOrganization';

  }

}

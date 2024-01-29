import '../data/organization.dart';
import '../data/sgela_user.dart';
import '../util/dio_util.dart';
import '../util/environment.dart';

class RegistrationService {
  final DioUtil dioUtil;

  RegistrationService(this.dioUtil);

  final String urlPrefix = ChatbotEnvironment.getSkunkUrl();

  Future registerOrganization(Organization organization) async {
    String url = '${urlPrefix}organizations/registerOrganization';
  }
  Future registerUser(SgelaUser user) async {
    String url = '${urlPrefix}organizations/registerOrganization';

  }

}

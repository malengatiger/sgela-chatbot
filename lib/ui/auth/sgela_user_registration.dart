import 'package:edu_chatbot/ui/auth/sponsoree_registration.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/city.dart';
import 'package:sgela_services/data/country.dart';
import 'package:sgela_services/data/sgela_user.dart';
import 'package:sgela_services/services/auth_service.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/navigation_util.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:sgela_shared_widgets/util/styles.dart' as styles;
import 'package:sgela_shared_widgets/widgets/busy_indicator.dart';
import 'package:sgela_shared_widgets/widgets/org_logo_widget.dart';

import '../../local_util/functions.dart';
import '../organization/organization_selector.dart';

class SgelaUserRegistration extends StatefulWidget {
  const SgelaUserRegistration({
    super.key,
  });


  @override
  SgelaUserRegistrationState createState() => SgelaUserRegistrationState();
}

class SgelaUserRegistrationState extends State<SgelaUserRegistration> {
  static const String mm = '🍎🍎🍎 UserRegistration: ';

  FirestoreService firestoreService = GetIt.instance<FirestoreService>();
  AuthService authService = GetIt.instance<AuthService>();
  Prefs prefs = GetIt.instance<Prefs>();

  City? city;
  Country? country;
  SgelaUser? sgelaUser;

  @override
  void initState() {
    super.initState();
    _getCountryAndCity();
  }

  bool _busy = false;

  _getCountryAndCity() async {
    setState(() {
      _busy = true;
    });
    try {
      country = prefs.getCountry();
      sgelaUser = prefs.getUser();
      city = firestoreService.city;
      _setControllers();
    } catch (e, s) {
      pp(e);
      pp(s);
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {
      _busy = false;
    });
  }

  _setControllers() {
    firstNameController = TextEditingController(text: sgelaUser!.firstName!);
    lastNameController = TextEditingController(text: sgelaUser!.lastName!);
    emailController = TextEditingController(text: sgelaUser!.email!);
    cellphoneController = TextEditingController(text: sgelaUser!.cellphone!);
  }

  Future _submit() async {
    pp('$mm ... submit SgelaUser .....');
    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
    });
    if (sgelaUser != null) {}
    var user = SgelaUser(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        email: emailController.text,
        cellphone: cellphoneController.text,
        date: DateTime.now().toIso8601String(),
        countryId: country?.id,
        cityId: city?.id,
        countryName: country?.name,
        cityName: city?.name,
        firebaseUserId: null,
        institutionName: null,
        id: DateTime.now().toUtc().millisecondsSinceEpoch);

    try {
      sgelaUser = await authService.registerUser(user);
      pp('$mm ... submit: SgelaUser registered: ${sgelaUser!.toJson()}');
      setState(() {
        _busy = false;
      });
      if (mounted) {
        Navigator.of(context).pop();
        var ok = await NavigationUtils.navigateToPage(
            context: context, widget: const OrganizationSelector());
      }

    } catch (e, s) {
      pp(e);
      pp(s);
      if (mounted) {
        showErrorDialog(context, '$e');
      }
      setState(() {
        _busy = false;
      });
      return;
    }

    if (mounted && sgelaUser != null) {
      Navigator.of(context).pop(sgelaUser);
    }
  }

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController cellphoneController = TextEditingController();

  late FormGroup formGroup;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const OrgLogoWidget(
          ),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      gapH32,
                      Row(
                        children: [
                          country == null ? gapW4 : Text('${country!.emoji}'),
                          // Row(
                          //   children: [
                          //     const Text('Sponsored by:'),
                          //     gapW16,
                          //     Text('${widget.branding.organizationName}',
                          //         style: styles.myTextStyleMediumLarge(
                          //             context, 20))
                          //   ],
                          // ),
                        ],
                      ),
                      gapH16,
                      _busy
                          ? const BusyIndicator(
                              caption: 'Registering you in the system',
                              showClock: true,
                            )
                          : Expanded(
                              child: SingleChildScrollView(
                                child: ReactiveFormConfig(
                                    validationMessages: {
                                      ValidationMessage.required: (_) =>
                                          'Field is mandatory',
                                      ValidationMessage.email: (_) =>
                                          'Must enter a valid email',
                                      'uniqueEmail': (_) =>
                                          'This email is already in use',
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: UserForm(
                                          firstNameController:
                                              firstNameController,
                                          lastNameController:
                                              lastNameController,
                                          emailController: emailController,
                                          cellphoneController:
                                              cellphoneController,
                                          onSubmit: () {
                                            _submit();
                                          },
                                        ),
                                      ),
                                    )),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

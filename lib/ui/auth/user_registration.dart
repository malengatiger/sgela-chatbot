import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/data/sgela_user.dart';
import 'package:edu_chatbot/services/auth_service.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';
import 'package:edu_chatbot/ui/organization/org_logo_widget.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../data/city.dart';
import '../../data/country.dart';

class UserRegistration extends StatefulWidget {
  const UserRegistration({super.key, required this.branding});

  final Branding branding;

  @override
  UserRegistrationState createState() => UserRegistrationState();
}

class UserRegistrationState extends State<UserRegistration> {
  static const String mm = '🍎🍎🍎 UserRegistration: ';

  FirestoreService firestoreService = GetIt.instance<FirestoreService>();
  AuthService authService = GetIt.instance<AuthService>();

  City? city;
  Country? country;

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
      country = await firestoreService.getLocalCountry();
      city = firestoreService.city;
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

  Future _submit(FormGroup form) async {
    pp('$mm ... submit SgelaUser .....');
    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
    });
    var user = SgelaUser(
        firstName: form.controls['firstName']?.value as String?,
        lastName: form.controls['lastName']?.value as String?,
        email: form.controls['email']?.value as String?,
        cellphone: form.controls['cellphone']?.value as String?,
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

  SgelaUser? sgelaUser;

  @override
  Widget build(BuildContext context) {
    FormGroup buildForm() => fb.group(<String, Object>{
          'email': FormControl<String>(
            validators: [Validators.required, Validators.email],
          ),
          'firstName': FormControl<String>(
            validators: [Validators.requiredTrue],
          ),
          'lastName': FormControl<String>(
            validators: [Validators.requiredTrue],
          ),
          'cellphone': FormControl<String>(
            validators: [Validators.requiredTrue],
          ),
          'password': FormControl<String>(
            validators: [Validators.requiredTrue],
          ),
        });
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: OrgLogoWidget(
            branding: widget.branding,
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
                          Row(
                            children: [
                              const Text('Sponsored by:'),
                              gapW16,
                              Text(
                                '${widget.branding.organizationName}',
                                style: myTextStyleMediumBold(context),
                              )
                            ],
                          ),
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
                                      child: ReactiveFormBuilder(
                                          form: buildForm,
                                          builder: (context, form, widget) {
                                            return Column(
                                              children: [
                                                ReactiveTextField<String>(
                                                  formControlName: 'firstName',
                                                  validationMessages: {
                                                    ValidationMessage.required:
                                                        (_) =>
                                                            'The name must not be empty',
                                                  },
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'First Name',
                                                    helperText: '',
                                                    helperStyle:
                                                        TextStyle(height: 0.7),
                                                    errorStyle:
                                                        TextStyle(height: 0.7),
                                                  ),
                                                ),
                                                gapH4,
                                                ReactiveTextField<String>(
                                                  formControlName: 'lastName',
                                                  validationMessages: {
                                                    ValidationMessage.required:
                                                        (_) =>
                                                            'The last name must not be empty',
                                                  },
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Last Name',
                                                    helperText: '',
                                                    helperStyle:
                                                        TextStyle(height: 0.7),
                                                    errorStyle:
                                                        TextStyle(height: 0.7),
                                                  ),
                                                ),
                                                gapH4,
                                                ReactiveTextField<String>(
                                                  formControlName: 'email',
                                                  validationMessages: {
                                                    ValidationMessage.required:
                                                        (_) =>
                                                            'The email must not be empty',
                                                    ValidationMessage.email: (_) =>
                                                        'The email value must be a valid email',
                                                    'unique': (_) =>
                                                        'This email is already in use',
                                                  },
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Email',
                                                    helperText: '',
                                                    helperStyle:
                                                        TextStyle(height: 0.7),
                                                    errorStyle:
                                                        TextStyle(height: 0.7),
                                                  ),
                                                ),
                                                gapH4,
                                                ReactiveTextField<String>(
                                                  formControlName: 'cellphone',
                                                  validationMessages: {
                                                    ValidationMessage.required:
                                                        (_) =>
                                                            'The cellphone number must not be empty',
                                                  },
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Cellphone',
                                                    helperText: '',
                                                    helperStyle:
                                                        TextStyle(height: 0.7),
                                                    errorStyle:
                                                        TextStyle(height: 0.7),
                                                  ),
                                                ),
                                                gapH4,
                                                ReactiveTextField<String>(
                                                  formControlName: 'password',
                                                  obscureText: true,
                                                  validationMessages: {
                                                    ValidationMessage.required:
                                                        (_) =>
                                                            'The password must not be empty',
                                                    ValidationMessage.minLength:
                                                        (_) =>
                                                            'The password must be at least 8 characters',
                                                  },
                                                  textInputAction:
                                                      TextInputAction.done,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Password',
                                                    helperText: '',
                                                    helperStyle:
                                                        TextStyle(height: 0.7),
                                                    errorStyle:
                                                        TextStyle(height: 0.7),
                                                  ),
                                                ),
                                                gapH16,
                                                SizedBox(
                                                  width: 300,
                                                  child: ElevatedButton(
                                                    style: const ButtonStyle(
                                                      elevation:
                                                          MaterialStatePropertyAll(
                                                              8.0),
                                                    ),
                                                    onPressed: () {
                                                      if (form.valid) {
                                                        pp(form.value);
                                                      } else {
                                                        form.markAllAsTouched();
                                                      }
                                                      _submit(form);
                                                    },
                                                    child: const Padding(
                                                      padding:
                                                          EdgeInsets.all(16.0),
                                                      child: Text('Sign Up'),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
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

class CountrySelector extends StatefulWidget {
  const CountrySelector({super.key, required this.onCountrySelected});

  final Function(Country) onCountrySelected;

  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {
  List<Country> countries = [];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: countries.length,
        itemBuilder: (_, index) {
          var country = countries.elementAt(index);
          return Card(
            elevation: 8,
            child: Column(
              children: [
                Text('${country.name}'),
                Text('${country.iso2}'),
              ],
            ),
          );
        });
  }
}

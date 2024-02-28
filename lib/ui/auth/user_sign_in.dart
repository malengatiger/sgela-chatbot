
import 'package:edu_chatbot/ui/misc/busy_indicator.dart';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sgela_services/data/city.dart';
import 'package:sgela_services/data/country.dart';
import 'package:sgela_services/data/sgela_user.dart';
import 'package:sgela_services/services/auth_service.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';

import '../../local_util/functions.dart';


class UserSignIn extends StatefulWidget {
  const UserSignIn({super.key});

  @override
  UserSignInState createState() => UserSignInState();
}

class UserSignInState extends State<UserSignIn> {
  static const String mm = '🍎🍎🍎 UserSignIn: ';

  FirestoreService firestoreService = GetIt.instance<FirestoreService>();
  AuthService authService = GetIt.instance<AuthService>();

  City? city;
  Country? country;

  SgelaUser? sgelaUser;

  @override
  void initState() {
    super.initState();
    _getCountryAndCity();
  }

  _getCountryAndCity() async {
    country = await firestoreService.getLocalCountry();
    city = firestoreService.city;
  }

  bool _busy = false;

  Future _submit(FormGroup form) async {
    pp('$mm ... submit SgelaUser .....');

    var email = form.controls['email']?.value as String?;
    var password = form.controls['password']?.value as String?;

    if (email == null || password == null) {
      return;
    }
    setState(() {
      _busy = true;
    });
    try {
      FocusScope.of(context).unfocus();
      var user = await authService.signInSgelaUser(email, password);
      if (user != null) {
        pp('$mm ... submit: SgelaUser signed in: ${user.toJson()}');
        if (mounted) {
          Navigator.of(context).pop(user);
          return;
        }
      }
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
//  cabo@dogs.com  pass123
  Future _forgotPassword(FormGroup form) async {
    pp('$mm ... _forgotPassword ....');
    var email = form.controls['email']?.value as String?;
    if (email == null) {
      showToast(
          message: 'Please enter email',
          padding: 20,
          backgroundColor: Colors.red,
          textStyle: const TextStyle(color: Colors.white),
          context: context);
      return;
    }
    await authService.forgotPassword(email);
    if (mounted) {
      showToast(
          message: 'A password reset email has been sent to $email',
          padding: 20,
          backgroundColor: Colors.blue,
          textStyle: const TextStyle(color: Colors.white),
          context: context);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    FormGroup buildForm() => fb.group(<String, Object>{
          'email': FormControl<String>(
            validators: [Validators.required, Validators.email],
          ),
          'password': FormControl<String>(
            validators: [Validators.requiredTrue],
          ),
        });
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'SgelaAI Sign In',
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 32,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 8,
                      child: SizedBox(
                        height: 520,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              gapH32,
                             _busy? const BusyIndicator(
                               caption: 'Signing you in ... please wait',
                               showClock: true,
                             ): ReactiveFormConfig(
                                  validationMessages: {
                                    ValidationMessage.required: (_) =>
                                        'Field is mandatory',
                                    ValidationMessage.email: (_) =>
                                        'Must enter a valid email',
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ReactiveFormBuilder(
                                        form: buildForm,
                                        builder: (context, form, widget) {
                                          return Column(
                                            children: [
                                              gapH16,
                                              ReactiveTextField<String>(
                                                formControlName: 'email',
                                                validationMessages: {
                                                  ValidationMessage.required: (_) =>
                                                      'The email must not be empty',
                                                  ValidationMessage.email: (_) =>
                                                      'The email value must be a valid email',
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
                                              gapH16,
                                              ReactiveTextField<String>(
                                                formControlName: 'password',
                                                obscureText: true,
                                                validationMessages: {
                                                  ValidationMessage.required: (_) =>
                                                      'The password must not be empty',
                                                  ValidationMessage.minLength:
                                                      (_) =>
                                                          'The password must be at least 8 characters',
                                                },
                                                textInputAction:
                                                    TextInputAction.next,
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
                                              gapH32,
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
                                                    child: Text('Sign In'),
                                                  ),
                                                ),
                                              ),
                                              gapH32,
                                              SizedBox(
                                                width: 300,
                                                child: ElevatedButton(
                                                  style: const ButtonStyle(
                                                    elevation:
                                                        MaterialStatePropertyAll(
                                                            8.0),
                                                  ),
                                                  onPressed: () {
                                                    _forgotPassword(form);
                                                  },
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.all(16.0),
                                                    child:
                                                        Text('Forgot Password'),
                                                  ),
                                                ),
                                              ),
                                              gapH32,
                                            ],
                                          );
                                        }),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
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

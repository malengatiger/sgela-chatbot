import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../data/country.dart';

class OrgRegistration extends StatefulWidget {
  const OrgRegistration({super.key});

  @override
  OrgRegistrationState createState() => OrgRegistrationState();
}

class OrgRegistrationState extends State<OrgRegistration> {
  static const String mm = '🍎 🍎 🍎 OrgRegistration: ';

  List<Country> countries = [];
  @override
  void initState() {
    super.initState();
    _getCountries();
  }
  _getCountries() async {

  }
  Future _submit() async {

  }
  @override
  Widget build(BuildContext context) {
    FormGroup buildForm() => fb.group(<String, Object>{
          'email': FormControl<String>(
            validators: [Validators.required, Validators.email],
          ),
          'password': ['', Validators.required, Validators.minLength(8)],
          'acceptTerms': FormControl<bool>(
            value: false,
            validators: [Validators.requiredTrue],
          ),
        });
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'SgelaAI Registration',
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                const Text('Register your organization for SgelaAI'),
                gapH8,
                Expanded(
                  child: ReactiveFormConfig(
                      validationMessages: {
                        ValidationMessage.required: (_) => 'Field is mandatory',
                        ValidationMessage.email: (_) =>
                            'Must enter a valid email',
                        'uniqueEmail': (_) => 'This email is already in use',
                      },
                      child: ReactiveFormBuilder(
                          form: buildForm,
                          builder: (context, form, widget) {
                            return Column(
                              children: [
                                ReactiveTextField<String>(
                                  formControlName: 'orgName',
                                  validationMessages: {
                                    ValidationMessage.required: (_) =>
                                    'The name of the organization must not be empty',
                                  },
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                    helperText: '',
                                    helperStyle: TextStyle(height: 0.7),
                                    errorStyle: TextStyle(height: 0.7),
                                  ),
                                ),
                                gapH16,
                                ReactiveTextField<String>(
                                  formControlName: 'adminName',
                                  validationMessages: {
                                    ValidationMessage.required: (_) =>
                                    'The name of the administrator must not be empty',
                                  },
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Administrator',
                                    helperText: '',
                                    helperStyle: TextStyle(height: 0.7),
                                    errorStyle: TextStyle(height: 0.7),
                                  ),
                                ),
                                gapH16,
                                ReactiveTextField<String>(
                                  formControlName: 'email',
                                  validationMessages: {
                                    ValidationMessage.required: (_) =>
                                        'The email must not be empty',
                                    ValidationMessage.email: (_) =>
                                        'The email value must be a valid email',
                                    'unique': (_) =>
                                        'This email is already in use',
                                  },
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    helperText: '',
                                    helperStyle: TextStyle(height: 0.7),
                                    errorStyle: TextStyle(height: 0.7),
                                  ),
                                ),
                                ReactiveTextField<String>(
                                  formControlName: 'cellphone',
                                  validationMessages: {
                                    ValidationMessage.required: (_) =>
                                    'The cellphone of the administrator must not be empty',
                                  },
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Cellphone',
                                    helperText: '',
                                    helperStyle: TextStyle(height: 0.7),
                                    errorStyle: TextStyle(height: 0.7),
                                  ),
                                ),
                                gapH16,
                                ReactiveTextField<String>(
                                  formControlName: 'password',
                                  obscureText: true,
                                  validationMessages: {
                                    ValidationMessage.required: (_) =>
                                    'The password must not be empty',
                                    ValidationMessage.minLength: (_) =>
                                    'The password must be at least 8 characters',
                                  },
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                    helperText: '',
                                    helperStyle: TextStyle(height: 0.7),
                                    errorStyle: TextStyle(height: 0.7),
                                  ),
                                ),
                                gapH16,
                                ElevatedButton(
                                  onPressed: () {
                                    if (form.valid) {
                                      pp(form.value);
                                    } else {
                                      form.markAllAsTouched();
                                    }
                                  },
                                  child: const Text('Sign Up'),
                                ),
                                ElevatedButton(
                                  onPressed: () => form.resetState(
                                    {
                                      'email': ControlState<String>(value: null),
                                      'password': ControlState<String>(value: null),
                                      'acceptTerms': ControlState<bool>(value: false),
                                    },
                                    removeFocus: true,
                                  ),
                                  child: const Text('Reset all'),
                                ),
                              ],
                            );
                          })),
                ),
              ],
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
    return GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: countries.length,
        itemBuilder: (_,index){
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


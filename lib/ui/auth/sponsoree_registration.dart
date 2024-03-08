import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/city.dart';
import 'package:sgela_services/data/country.dart';
import 'package:sgela_services/data/organization.dart';
import 'package:sgela_services/data/sgela_user.dart';
import 'package:sgela_services/data/sponsoree.dart';
import 'package:sgela_services/services/auth_service.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:sgela_shared_widgets/util/styles.dart' as styles;
import 'package:sgela_shared_widgets/widgets/busy_indicator.dart';
import 'package:sgela_shared_widgets/widgets/org_logo_widget.dart';

import '../../local_util/functions.dart';

class SponsoreeRegistration extends StatefulWidget {
  const SponsoreeRegistration({
    super.key,
    required this.branding,
    required this.organization,
  });

  final Branding branding;
  final Organization organization;

  @override
  SponsoreeRegistrationState createState() => SponsoreeRegistrationState();
}

class SponsoreeRegistrationState extends State<SponsoreeRegistration> {
  static const String mm = '🍎🍎🍎 SponsoreeRegistration: ';

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
      sgelaUser = prefs.getUser();
      city = firestoreService.city;
      country = prefs.getCountry();
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

  Future _submit() async {
    pp('$mm ... submit SgelaUser .....');
    FocusScope.of(context).unfocus();

    late Sponsoree sponsoree;
    setState(() {
      _busy = true;
    });

    try {
      if (sgelaUser != null) {
        sponsoree = Sponsoree(
            organizationId: widget.branding.organizationId,
            id: DateTime.now().millisecondsSinceEpoch,
            date: DateTime.now().toUtc().toIso8601String(),
            organizationName: widget.branding.organizationName,
            activeFlag: true,
            sgelaUserId: sgelaUser!.id!,
            sgelaUserName: '${sgelaUser!.firstName} ${sgelaUser!.lastName}',
            sgelaCellphone: sgelaUser!.cellphone,
            sgelaEmail: sgelaUser!.email,
            sgelaFirebaseId: sgelaUser!.firebaseUserId);

        await firestoreService.addOrgSponsoree(sponsoree);
        prefs.saveSponsoree(sponsoree);
        prefs.saveOrganization(widget.organization);
        var bbs = await firestoreService.getOrganizationBrandings(widget.branding.organizationId!, true);
        pp('$mm ... submit: Sponsoree registered: ${sponsoree.toJson()}; new org ${widget.organization.name} has ${bbs.length}  brandings');
        if (mounted) {
          Navigator.of(context).pop();
        }
      }

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

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  gapH32,
                  // Row(
                  //   children: [
                  //     country == null ? gapW4 : Text('${country!.emoji}'),
                  //     Row(
                  //       children: [
                  //         const Text('Sponsored by:'),
                  //         gapW16,
                  //         Text('${widget.branding.organizationName}',
                  //             style: styles.myTextStyleMediumLarge(context, 20))
                  //       ],
                  //     ),
                  //   ],
                  // ),
                  gapH16,
                  _busy
                      ? const BusyIndicator(
                          caption: 'Registering your Sponsor in the system',
                          showClock: true,
                        )
                      : Card(
                          elevation: 8,
                          child: SizedBox(
                              height: 460,
                              child: Column(
                                children: [
                                  gapH32,gapH32,
                                  Text(
                                    '${sgelaUser!.firstName} ${sgelaUser!.lastName} ',
                                    style: styles.myTextStyleMediumLarge(
                                        context, 24),
                                  ),
                                  gapH32,
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'Confirm that you are requesting SgelaAI sponsorship from',
                                      style: styles.myTextStyleMediumGrey(
                                          context, ),
                                    ),
                                  ),
                                  gapH32,
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      widget.branding.logoUrl == null
                                          ? const Text('Haba URL')
                                          : SizedBox(
                                              height: 36,
                                              child: Image.network(
                                                  widget.branding.logoUrl!)),
                                      gapW16,
                                      Text('${widget.organization.name}'),
                                    ],
                                  ),
                                  gapH32,
                                  gapH32,
                                  SizedBox(
                                    width: 300,
                                    child: ElevatedButton(
                                        style: const ButtonStyle(
                                          elevation:
                                              MaterialStatePropertyAll(8.0),
                                        ),
                                        onPressed: () {
                                          _submit();
                                        },
                                        child:
                                             Padding(
                                              padding: const EdgeInsets.all(20.0),
                                              child: Text('Confirm Sponsorship', style: styles.myTextStyleMediumLarge(context, 18),),
                                            )),
                                  ),
                                  gapH32,
                                ],
                              )),
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

class UserForm extends StatelessWidget {
  const UserForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.cellphoneController,
    required this.onSubmit,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController cellphoneController;

  final Function onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: firstNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: ' First Name',
            helperText: '',
            helperStyle: TextStyle(height: 0.7),
            errorStyle: TextStyle(height: 0.7),
          ),
        ),
        gapH4,
        TextField(
          controller: lastNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            helperText: '',
            helperStyle: TextStyle(height: 0.7),
            errorStyle: TextStyle(height: 0.7),
          ),
        ),
        gapH4,
        TextField(
          controller: emailController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email',
            helperText: '',
            helperStyle: TextStyle(height: 0.7),
            errorStyle: TextStyle(height: 0.7),
          ),
        ),
        gapH4,
        TextField(
          controller: cellphoneController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Cellphone',
            helperText: '',
            helperStyle: TextStyle(height: 0.7),
            errorStyle: TextStyle(height: 0.7),
          ),
        ),
        gapH32,
        gapH32,
        SizedBox(
          width: 300,
          child: ElevatedButton(
            style: const ButtonStyle(
              elevation: MaterialStatePropertyAll(8.0),
            ),
            onPressed: () {
              onSubmit();
            },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Confirm Sponsor',
                style: styles.myTextStyleMediumLarge(context, 24),
              ),
            ),
          ),
        ),
      ],
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

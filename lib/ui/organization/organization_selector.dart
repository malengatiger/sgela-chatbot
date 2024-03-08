import 'dart:collection';

import 'package:badges/badges.dart' as bd;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_chatbot/ui/auth/sponsoree_registration.dart';
import 'package:sgela_shared_widgets/widgets/busy_indicator.dart';import 'package:edu_chatbot/ui/organization/organization_splash.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/city.dart';
import 'package:sgela_services/data/country.dart';
import 'package:sgela_services/data/organization.dart';
import 'package:sgela_services/data/sgela_user.dart';
import 'package:sgela_services/data/sponsoree.dart';
import 'package:sgela_services/repositories/basic_repository.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/navigation_util.dart';
import 'package:sgela_services/sgela_util/prefs.dart';

import '../../local_util/functions.dart';

class OrganizationSelector extends StatefulWidget {
  const OrganizationSelector({super.key});

  @override
  OrganizationSelectorState createState() => OrganizationSelectorState();
}

class OrganizationSelectorState extends State<OrganizationSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Country? country;
  Organization? organization;
  List<Organization> organizations = [];

  List<Branding> brandings = [], filteredBrandings = [];
  List<OrganizationBranding> orgBrandings = [];
  Prefs prefs = GetIt.instance<Prefs>();
  FirestoreService firestoreService = GetIt.instance<FirestoreService>();
  BasicRepository repository = GetIt.instance<BasicRepository>();
  static const mm = ' 🔵🔵🍎🔵🔵 OrganizationSelector   🍎🍎';
  SgelaUser? user;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  bool _busy = false;

  _showToast() {
    Future.delayed(const Duration(milliseconds: 100), () {
      showToast(
          message:
              'Tap to select a Sponsor. The Sponsor helps with the cost of using AI tools',
          context: context,
          padding: 20,
          duration: const Duration(seconds: 6),
          backgroundColor: Colors.blue.shade700,
          textStyle: const TextStyle(color: Colors.white));
    });
  }

  City? city;

  _getData() async {
    pp('$mm ... getting data ...');
    setState(() {
      _busy = true;
    });
    try {
      organization = prefs.getOrganization();
      user = prefs.getUser();
      organizations = await firestoreService.getOrganizations();
      brandings = await firestoreService.getAllBrandings();
      brandings.sort((a, b) => b.date!.compareTo(a.date!));
      _manageBrandings();
      _showToast();
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

  _manageBrandings() {
    HashMap<String, Branding> map = HashMap();
    for (var value in brandings) {
      if (!map.containsKey(value.organizationName)) {
        map[value.organizationName!] = value;
      }
    }
    filteredBrandings.addAll(map.values);
    pp('$mm ... ${filteredBrandings.length} brandings available');
    filteredBrandings
        .sort((a, b) => a.organizationName!.compareTo(b.organizationName!));
    for (var value1 in filteredBrandings) {
      pp('$mm filtered branding:  🍎 ${value1.organizationName!} \t🔵logoUrl: ${value1.logoUrl == null}');
    }
    for (var org in organizations) {
      Branding? branding;
      for (var b in filteredBrandings) {
        if (b.organizationName == org.name!) {
          branding = b;
        }
      }
      if (branding == null) {
        pp('$mm branding is null for 🔵🔵 ${org.name}');
      }
      var ob = OrganizationBranding(org, branding);
      orgBrandings.add(ob);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  OrganizationBranding? selectedOrgBrand;

  _processChosenBrand() async {
    pp('$mm ... Brand chosen, create sgelaUser '
        'and OrgSponsoree: ${selectedOrgBrand!.organization!.name} '
        'url: ${selectedOrgBrand!.branding!.organizationUrl}');

    await NavigationUtils.navigateToPage(
        context: context,
        widget: SponsoreeRegistration(
          branding: selectedOrgBrand!.branding!,
          organization: selectedOrgBrand!.organization!,
        ));

    // if (mounted) {
    //   await NavigationUtils.navigateToPage(
    //       context: context, widget: const OrganizationSplash());
    //
    // }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('SgelaAI Sponsors'),
            ),
            body: ScreenTypeLayout.builder(
              mobile: (_) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          const Text('Sponsor Organizations'),
                          gapH16,
                          _busy
                              ? const Padding(
                                  padding: EdgeInsets.all(28.0),
                                  child: BusyIndicator(
                                    caption: 'Preparing Sponsor list ...',
                                    showClock: true,
                                  ),
                                )
                              : Expanded(
                                  child: bd.Badge(
                                  position: bd.BadgePosition.topEnd(
                                      top: -12, end: -8),
                                  badgeContent: Text("${orgBrandings.length}"),
                                  badgeStyle: bd.BadgeStyle(
                                      badgeColor: Colors.green.shade700,
                                      padding: const EdgeInsets.all(12)),
                                  child: BrandingList(
                                      organizationBrandings: orgBrandings,
                                      onBrandSelected: (ob) {
                                        setState(() {
                                          selectedOrgBrand = ob;
                                        });
                                        _processChosenBrand();
                                      },
                                      isGrid: true),
                                )),
                        ],
                      )
                    ],
                  ),
                );
              },
              tablet: (_) {
                return const Stack();
              },
              desktop: (_) {
                return const Stack();
              },
            )));
  }
}

class BrandingList extends StatelessWidget {
  const BrandingList(
      {super.key,
      required this.organizationBrandings,
      required this.onBrandSelected,
      required this.isGrid});

  final List<OrganizationBranding> organizationBrandings;
  final Function(OrganizationBranding) onBrandSelected;

  final bool isGrid;

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2),
          itemCount: organizationBrandings.length,
          itemBuilder: (_, index) {
            var ob = organizationBrandings.elementAt(index);
            return GestureDetector(
                onTap: () {
                  onBrandSelected(ob);
                },
                child: OrgBrandCard(organizationBranding: ob, isGrid: isGrid));
          });
    }
    return ListView.builder(
        itemCount: organizationBrandings.length,
        itemBuilder: (_, index) {
          var ob = organizationBrandings.elementAt(index);
          return GestureDetector(
              onTap: () {
                onBrandSelected(ob);
              },
              child: OrgBrandCard(organizationBranding: ob, isGrid: isGrid));
        });
  }
}

class OrgBrandCard extends StatelessWidget {
  const OrgBrandCard(
      {super.key, required this.organizationBranding, required this.isGrid});

  final OrganizationBranding organizationBranding;
  final bool isGrid;

  @override
  Widget build(BuildContext context) {
    late Widget mWidget;
    if (isGrid) {
      mWidget = SizedBox(
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            organizationBranding.branding == null
                ? gapW8
                : organizationBranding.branding!.logoUrl == null
                    ? Text(
                        '${organizationBranding.organization!.name}',
                        style: myTextStyle(context, Theme.of(context).primaryColor, 20,
                            FontWeight.bold),
                      )
                    : SizedBox(
                        height: 36,
                        child: CachedNetworkImage(
                          imageUrl: organizationBranding.branding!.logoUrl!,
                          fit: BoxFit.fitHeight,
                        ),
                      ),
            gapH32,
            Text(
              '${organizationBranding.organization!.name}',
              style: myTextStyle(context, Theme.of(context).primaryColor, 14,
                  FontWeight.normal),
            ),
          ],
        ),
      );
    } else {
      mWidget = Row(
        children: [
          organizationBranding.branding == null
              ? gapW8
              : organizationBranding.branding!.logoUrl == null
                  ? Text('${organizationBranding.organization!.name}')
                  : SizedBox(
                      height: 32,
                      child: CachedNetworkImage(
                        imageUrl: organizationBranding.branding!.logoUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
          gapW16,
          Text('${organizationBranding.organization!.name}'),
        ],
      );
    }
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: mWidget,
      ),
    );
  }
}

class OrganizationBranding {
  Organization? organization;
  Branding? branding;

  OrganizationBranding(this.organization, this.branding);
}

import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/data/country.dart';
import 'package:edu_chatbot/data/organization.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/services/firestore_service.dart';
import 'package:edu_chatbot/ui/organization/organization_splash.dart';
import 'package:edu_chatbot/util/navigation_util.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../util/functions.dart';

class OrganizationSelector extends StatefulWidget {
  const OrganizationSelector({super.key});

  @override
  OrganizationSelectorState createState() => OrganizationSelectorState();
}

class OrganizationSelectorState extends State<OrganizationSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Country? country;
  Organization? organization, sgelaOrganization;
  List<Organization> organizations = [];

  List<Branding> brandings = [], filteredBrandings = [];
  List<OrganizationBranding> orgBrandings = [];
  Prefs prefs = GetIt.instance<Prefs>();
  FirestoreService firestoreService = GetIt.instance<FirestoreService>();
  Repository repository = GetIt.instance<Repository>();
  static const mm = ' 🔵🔵🍎🔵🔵 OrganizationSelector   🍎🍎';

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  bool _busy = false;

  _getData() async {
    pp('$mm ... getting data ...');
    setState(() {
      _busy = false;
    });
    try {
      organization = prefs.getOrganization();
      country = prefs.getCountry();
      organizations = await firestoreService.getOrganizations();
      sgelaOrganization = await repository.getSgelaOrganization();
      brandings = await firestoreService.getAllBrandings();
      brandings.sort((a, b) => b.date!.compareTo(a.date!));
      _manageBrandings();
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
      pp('$mm filtered branding:  🍎 ${value1.organizationName!}');
    }
    for (var org in organizations) {
      Branding? branding;
      for (var b in filteredBrandings) {
        if (b.organizationId == org.id!) {
          branding = b;
        }
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

  OrganizationBranding? orgBrand;

  _processChosenBrand() async {
    pp('$mm ... Brand chosen: ${orgBrand!.organization!.name}');
    prefs.saveOrganization(orgBrand!.organization!);
    prefs.saveBrand(orgBrand!.branding!);
    pp('$mm ... Organization and Branding saved to cache!');

    await NavigationUtils.navigateToPage(
        context: context,
        widget: OrganizationSplash(branding: orgBrand!.branding!));
    if (mounted) {
      Navigator.of(context).pop(true);
    }
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
                          Expanded(
                              child: BrandingList(
                                  organizationBrandings: orgBrandings,
                                  onBrandSelected: (ob) {
                                    setState(() {
                                      orgBrand = ob;
                                    });
                                    _processChosenBrand();
                                  },
                                  isGrid: true)),
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
        height: 20,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            organizationBranding.branding == null
                ? gapW8
                : organizationBranding.branding!.logoUrl == null?  Text('${organizationBranding.organization!.name}'): CachedNetworkImage(
                    imageUrl: organizationBranding.branding!.logoUrl!, fit: BoxFit.cover,),
            // gapH4,
            Text('${organizationBranding.organization!.name}'),
          ],
        ),
      );
    } else {
      mWidget = Row(
        children: [
          CachedNetworkImage(imageUrl: organizationBranding.branding!.logoUrl!),
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

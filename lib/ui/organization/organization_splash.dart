import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_chatbot/ui/organization/org_logo_widget.dart';
import 'package:edu_chatbot/ui/organization/website_view.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/country.dart';
import 'package:sgela_services/data/organization.dart';
import 'package:sgela_services/data/sgela_user.dart';
import 'package:sgela_services/data/sponsoree.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/navigation_util.dart';
import 'package:sgela_services/sgela_util/prefs.dart';

import '../../local_util/functions.dart';
import '../exam/subject_search.dart';
import '../landing_page.dart';

class OrganizationSplash extends StatefulWidget {
  const OrganizationSplash({super.key, this.doNotExpire,});

  // final Branding? branding;
  // final int? timeToDisappear;
  final bool? doNotExpire;

  @override
  OrganizationSplashState createState() => OrganizationSplashState();
}

class OrganizationSplashState extends State<OrganizationSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static const mm = '🔵🔵🔵🔵 OrganizationSplash  🔵🔵';

  Prefs prefs = GetIt.instance<Prefs>();

  Country? country;
  Organization? organization;
  SgelaUser? sgelaUser;
  Sponsoree? orgSponsoree;
  bool _busy = false;
  Branding? branding;
  List<Branding> brandings = [];
  FirestoreService firestoreService = GetIt.instance<FirestoreService>();


  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  bool _show = false;
  _getData() async {
    pp('$mm ... getting cached data to decide what happens next ...');
    setState(() {
      _busy = true;
      _show = true;
    });
    try {
      organization = prefs.getOrganization();
      country = prefs.getCountry();
      sgelaUser = prefs.getUser();
      orgSponsoree = prefs.getSponsoree();
      if (organization != null) {
        brandings = await firestoreService.getOrganizationBrandings(organization!.id!, true);
        if (brandings.isNotEmpty) {
          brandings.sort((a, b) => b.date!.compareTo(a.date!));
          branding = brandings.first;
          pp('$mm ... branding: ${branding!.toJson()}...');
        }
      }

      //
      if (sgelaUser == null) {
        pp('$mm ... new or returning SgelaUser. have to navigate to LandingPage ...');
        Future.delayed(const Duration(milliseconds: 100), () {
          NavigationUtils.navigateToPage(
              context: context, widget: const LandingPage(hideButtons: false));
        });
      }
      if (orgSponsoree != null) {
        pp('$mm ... YEBO!!! returning Sponsoree. have to navigate to SubjectSearch'
            ' after ${organization!.brandingElapsedTimeInSeconds} seconds ... '
            '  🍎 orgSponsoree: ${orgSponsoree!.toJson()} ...');
        setState(() {
          _busy = false;
        });
        int seconds = 10;
        if (organization != null) {
          if (organization!.brandingElapsedTimeInSeconds != null) {
            seconds = organization!.brandingElapsedTimeInSeconds!;
          }
        }
        if (widget.doNotExpire != null) {
          if (widget.doNotExpire! == true) {
            //todo - check
          }  else {
            _goToSubjects(seconds);
          }
        }  else {
          _goToSubjects(seconds);
        }
      }
    } catch (e) {
      pp(e);
      if (mounted) {
        showErrorDialog(context, '$e');
      }
    }
    setState(() {
      _busy = false;
    });
  }

  void _goToSubjects(int seconds) {
    Future.delayed(
        Duration(seconds: seconds), () {
      NavigationUtils.navigateToPage(
          context: context, widget: const SubjectSearch());
    });
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _navigateToWebsite() {
    if (branding != null &&
        branding!.organizationUrl!.isNotEmpty) {
      pp('branding url: ${branding!.organizationUrl}');
      NavigationUtils.navigateToPage(
          context: context,
          widget: WebsiteView(
            url: branding!.organizationUrl!,
            title: branding!.organizationName!,
          ));
    } else {
      NavigationUtils.navigateToPage(
          context: context,
          widget: WebsiteView(
            url: 'https://www.sgela-ai.tech',
            title: branding!.organizationName!,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    var tag = '';
    if (branding != null) {
      if (branding!.tagLine != null) {
        tag = branding!.tagLine!;
      }
    }
    return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: OrgLogoWidget(
              branding: branding, height: 24,
            ),
          ),
          body: ScreenTypeLayout.builder(
            mobile: (_) {
              return Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      gapH8,
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                            width: 400,
                            child: Row(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    tag),
                              ],
                            )),
                      ),

                      gapH8,
                      TextButton(
                        onPressed: () {
                          _navigateToWebsite();
                        },
                        child: const Text('Go to Sponsor Website'),
                      ),
                      gapH16,
                      Expanded(
                          child: GestureDetector(
                            onTap: (){
                              Navigator.of(context).pop();
                            },
                            child: branding == null? gapH8: CachedNetworkImage(
                              imageUrl: branding!.splashUrl!,
                              fit: BoxFit.cover, height: double.infinity, width: double.infinity,
                            ),
                          )),
                      gapH16,
                    ],
                  ),
                  _show? const Positioned(
                      bottom: 8,
                      right: 16,
                      child: SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 4, backgroundColor: Colors.pink,
                      ))): gapH8,
                ],
              );
            },
            tablet: (_) {
              return const Stack();
            },
            desktop: (_) {
              return const Stack();
            },
          ),
        ));
  }
}

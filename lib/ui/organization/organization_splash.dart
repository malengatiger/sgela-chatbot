import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_chatbot/ui/organization/organization_selector.dart';
import 'package:edu_chatbot/ui/organization/website_view.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/country.dart';
import 'package:sgela_services/data/sgela_user.dart';
import 'package:sgela_services/data/sponsoree.dart';
import 'package:sgela_services/services/firestore_service.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/navigation_util.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:sgela_shared_widgets/widgets/busy_indicator.dart';
import 'package:sgela_shared_widgets/widgets/org_logo_widget.dart';

import '../../local_util/functions.dart';
import '../exam/subject_search.dart';
import '../landing_page.dart';

class OrganizationSplash extends StatefulWidget {
  const OrganizationSplash({
    super.key,
    this.doNotExpire,
  });

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
  SgelaUser? sgelaUser;
  Sponsoree? orgSponsoree;
  Branding? branding;
  List<Branding> brandings = [];

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  bool _showBusyIndicator = false;

  _getData() async {
    pp('$mm ... getting cached data to decide what happens next ...');
    if (widget.doNotExpire != null && widget.doNotExpire!) {
      _showBusyIndicator = false;
    }
    setState(() {

    });
    try {
      country = prefs.getCountry();
      sgelaUser = prefs.getUser();
      orgSponsoree = prefs.getSponsoree();
      FirestoreService firestoreService = GetIt.instance<FirestoreService>();
      if (sgelaUser == null) {
        pp('$mm ... new or returning SgelaUser. have to navigate to LandingPage ...');
        Future.delayed(const Duration(milliseconds: 100), () {
          Navigator.of(context).pop();
          NavigationUtils.navigateToPage(
              context: context, widget: const LandingPage(hideButtons: false));
        });
        return;
      }
      if (orgSponsoree == null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          Navigator.of(context).pop();
          NavigationUtils.navigateToPage(
              context: context, widget: const OrganizationSelector());
        });
        return;
      }

      //refresh branding ...
      brandings = await firestoreService.getOrganizationBrandings(
          orgSponsoree!.organizationId!, true);
      if (brandings.isNotEmpty) {
        branding = brandings.first;
      } else {
        _goToSubjects(0);
        return;
      }

      int seconds = 10;
      if (branding!.splashTimeInSeconds != null) {
        seconds = branding!.splashTimeInSeconds!;
      }

      if (widget.doNotExpire != null && widget.doNotExpire!) {
        //stick around
      } else {
        _goToSubjects(seconds);
      }
    } catch (e, s) {
      pp('$mm ERROR: $e - $s');
      _goToSubjects(0);
    }
    setState(() {
      _showBusyIndicator = false;
    });
  }

  void _goToSubjects(int seconds) {
    pp('$mm ......... 🔵 🔵 chilling for $seconds seconds, then navigating to SubjectSearch 🔵');
    Future.delayed(Duration(seconds: seconds), () {
      Navigator.of(context).pop();
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
    if (branding != null && branding!.organizationUrl!.isNotEmpty) {
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
          branding: branding,
          height: 36,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tag,
                              style: myTextStyleMediumLarge(context, 20),
                            ),
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
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: branding == null
                        ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                              child: BusyIndicator(
                                showTimerOnly: false,
                                showClock: true,
                              ),
                            ),
                        )
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              // Set the border radius
                              child: CachedNetworkImage(
                                imageUrl: branding!.splashUrl!,
                                fit: BoxFit.cover,
                                // height: double.infinity,
                                // width: double.infinity,
                              ),
                            ),
                          ),
                  )),
                  gapH16,
                ],
              ),
              _showBusyIndicator
                  ? const Positioned(
                      bottom: 48,
                      right: 28,
                      child: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: BusyIndicator(
                          showTimerOnly: true,
                        ),
                      ),
                    )
                  : gapH8,
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

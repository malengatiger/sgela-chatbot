import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:sgela_services/data/branding.dart';
import 'package:sgela_services/data/country.dart';
import 'package:sgela_services/data/exam_link.dart';
import 'package:sgela_services/data/organization.dart';
import 'package:sgela_shared_widgets/widgets/org_logo_widget.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../local_util/functions.dart';
import '../exam/exam_link_details.dart';

class BusyByBrand extends StatefulWidget {
  const BusyByBrand({super.key, required this.examLink,});

  final ExamLink examLink;

  @override
  BusyByBrandState createState() => BusyByBrandState();
}

class BusyByBrandState extends State<BusyByBrand>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Country? country;
  Organization? organization;
  Branding? branding;
  Prefs prefs = GetIt.instance<Prefs>();
  static const mm = ' 🔵🔵 🔵🔵 BusyByBrand  🔵🔵';
  late StreamSubscription<bool> busySubscription;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _runTimer();
    _getData();
  }


  _getData() async {
    pp('$mm ... getting data ...');
    try {
      organization = prefs.getOrganization();
      country = prefs.getCountry();
      branding = prefs.getBrand();
    } catch (e) {
      pp(e);
      showErrorDialog(context, '$e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    timer.cancel();
    super.dispose();
  }

  late Timer timer;
  String elapsedTime = '';

  void _runTimer() {
    pp('$mm ... running timer ...');

    int milliseconds = 0;
    timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      milliseconds += 1000;
      int seconds = (milliseconds / 1000).truncate();
      int minutes = (seconds / 60).truncate();
      seconds %= 60;

      String minutesStr = minutes.toString().padLeft(2, '0');
      String secondsStr = seconds.toString().padLeft(2, '0');

      setState(() {
        elapsedTime = '$minutesStr:$secondsStr';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            title: OrgLogoWidget(
              branding: branding,
            ),
            leading: gapW4,
          ),
          body: ScreenTypeLayout.builder(
            mobile: (_) {
              return Stack(
                children: [
                  Column(
                    children: [
                      ExamLinkDetails(examLink: widget.examLink, pageNumber: 0,),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            elevation: 8,
                            child: CachedNetworkImage(
                              imageUrl: branding!.splashUrl!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const Text('Tagline will come here'),
                    ],
                  ),
                  Positioned(
                    bottom: 28,
                    left: 20,
                    right: 20,
                    child: Card(
                      elevation: 16,
                      child: SizedBox(
                          height: 160, // Adjust the height as needed
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                gapH8,
                                const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    backgroundColor: Colors.pink,
                                    strokeWidth: 4,
                                  ),
                                ),
                                gapH8,
                                const Text(
                                    'SgelaAI is huffing and puffing but will not blow your house down!'),
                                gapH8,
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Time Elapsed:',
                                      style: myTextStyleTiny(context),
                                    ),
                                    gapW16,
                                    Text(
                                      elapsedTime,
                                      style: myTextStyleMediumBoldPrimaryColor(context),
                                    ),
                                  ],
                                ),
                                gapH8,
                              ],
                            ),
                          )),
                    ),
                  ),
                ],
              );
            },
            tablet: (_) {
              return const Stack();
            },
            desktop: (_) {
              return const Stack();
            },
          )),
    );
  }
}

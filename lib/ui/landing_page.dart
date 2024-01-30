import 'package:carousel_slider/carousel_slider.dart';
import 'package:edu_chatbot/data/country.dart';
import 'package:edu_chatbot/data/sponsoree.dart';
import 'package:edu_chatbot/data/organization.dart';
import 'package:edu_chatbot/data/sgela_user.dart';
import 'package:edu_chatbot/ui/auth/user_registration.dart';
import 'package:edu_chatbot/ui/auth/user_sign_in.dart';
import 'package:edu_chatbot/ui/exam/subject_search.dart';
import 'package:edu_chatbot/ui/organization/organization_selector.dart';
import 'package:edu_chatbot/util/navigation_util.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../util/functions.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Country? country;
  Organization? organization;
  SgelaUser? sgelaUser;
  Sponsoree? orgSponsoree;

  Prefs prefs = GetIt.instance<Prefs>();
  static const mm = '🔵🔵🔵🔵 LandingPage  🔵🔵';

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
      sgelaUser = prefs.getUser();
      orgSponsoree = prefs.getSponsoree();

      //
      if (orgSponsoree != null) {
        pp('$mm ... orgSponsoree: ${orgSponsoree!.toJson()} ...');
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          NavigationUtils.navigateToPage(
                      context: context, widget: const SubjectSearch());
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _navigateToRegistration() async {
    pp('$mm _navigateToRegistration ...');
    var ok = await NavigationUtils.navigateToPage(
        context: context, widget: const OrganizationSelector());
    if (ok) {
      if (mounted) {
        Navigator.of(context).pop();
        NavigationUtils.navigateToPage(context: context, widget: const SubjectSearch());
      }
    }
  }

  _navigateToSignIn() {
    pp('$mm _navigateToSignIn ...');
    NavigationUtils.navigateToPage(
        context: context, widget: const UserSignIn());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Welcome to SgelaAI'),
            ),
            body: ScreenTypeLayout.builder(
              mobile: (_) {
                return Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          CarouselSlider(
                            items: const [
                              InfoPage(
                                  filePath: 'assets/image10.webp',
                                  content: 'Ace the Test, Stress Less with AI!',
                                  title: 'Don\'t Worry!'),
                              InfoPage(
                                  filePath: 'assets/image8.jpg',
                                  content: 'Say Goodbye to Exam Anxiety!',
                                  title: 'Be Happy!'),
                              InfoPage(
                                  filePath: 'assets/image7.jpg',
                                  content: 'Study Buddy: Your 24/7 Exam Coach!',
                                  title: 'Easy Does It!'),
                              InfoPage(
                                  filePath: 'assets/image4.webp',
                                  content: 'Teacher\'s Pet in Your Pocket!',
                                  title: 'Always Here'),
                            ],
                            options: CarouselOptions(
                                height: 600,
                                enlargeCenterPage: true,
                                onPageChanged: (index, ccr) {},
                                scrollPhysics: const PageScrollPhysics()),
                          ),
                        ],
                      ),
                    ),
                    orgSponsoree == null
                        ? Positioned(
                            bottom: 8,
                            left: 20,
                            right: 20,
                            child: Card(
                              elevation: 8,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    orgSponsoree == null
                                        ? SizedBox(
                                            width: 140,
                                            child: ElevatedButton(
                                                style: const ButtonStyle(
                                                  elevation:
                                                      MaterialStatePropertyAll(
                                                          8),
                                                ),
                                                onPressed: () {
                                                  _navigateToSignIn();
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text('Sign In'),
                                                )),
                                          )
                                        : gapW4,
                                    // gapW32,
                                    orgSponsoree == null
                                        ? SizedBox(
                                            width: 140,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(2.0),
                                              child: ElevatedButton(
                                                  style: const ButtonStyle(
                                                    elevation:
                                                        MaterialStatePropertyAll(
                                                            8),
                                                  ),
                                                  onPressed: () {
                                                    _navigateToRegistration();
                                                  },
                                                  child:
                                                      const Text('Register')),
                                            ),
                                          )
                                        : gapW4,
                                  ],
                                ),
                              ),
                            ))
                        : gapW4
                  ],
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

class InfoPage extends StatelessWidget {
  const InfoPage(
      {super.key,
      required this.filePath,
      required this.content,
      required this.title});

  final String filePath, content, title;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            gapH32,
            Text(
              title,
              style: myTextStyle(
                  context, Theme.of(context).primaryColor, 20, FontWeight.w900),
            ),
            gapH32,
            Expanded(
                child: Image.asset(
              filePath,
              fit: BoxFit.cover,
            )),
            gapH32,
            Text(
              content,
              style: myTextStyleMediumBold(context),
            ),
            gapH16
          ],
        ),
      ),
    );
  }
}

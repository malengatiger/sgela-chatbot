import 'package:carousel_slider/carousel_slider.dart';
import 'package:sgela_services/data/country.dart';
import 'package:sgela_services/data/sponsoree.dart';
import 'package:sgela_services/data/organization.dart';
import 'package:sgela_services/data/sgela_user.dart';
import 'package:edu_chatbot/ui/auth/user_sign_in.dart';
import 'package:edu_chatbot/ui/exam/subject_search.dart';
import 'package:edu_chatbot/ui/organization/organization_selector.dart';
import 'package:sgela_services/sgela_util/functions.dart';
import 'package:sgela_services/sgela_util/navigation_util.dart';
import 'package:sgela_services/sgela_util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../local_util/functions.dart';


class LandingPage extends StatefulWidget {
  const LandingPage({super.key,
    // required this.firestoreService,
    required this.hideButtons});

  final bool hideButtons;
  // final   FirestoreService firestoreService;

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
    pp('$mm ... getting cached data to decide what happens next ...');
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
        pp('$mm ... YEBO!!! returning Sponsoree. have to navigate to SubjectSearch: ${orgSponsoree!.toJson()} ...');
        //await widget.firestoreService.getOrganizationBrandings(orgSponsoree!.organizationId!, true);
        Future.delayed(const Duration(milliseconds: 200), (){
          NavigationUtils.navigateToPage(
              context: context, widget: const SubjectSearch());
        });
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
        NavigationUtils.navigateToPage(
            context: context, widget: const SubjectSearch());
      }
    }
  }

  _navigateToSignIn() async {
    pp('$mm _navigateToSignIn ...');
    var user = await NavigationUtils.navigateToPage(
        context: context, widget: const UserSignIn());
    pp('$mm _navigateToSignIn: returned from UserSignIn ...');
    if (user != null) {
      pp('$mm _navigateToSignIn: returned from UserSignIn, user is not null ...');
      _getData();
    }
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
                          Padding(
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
                          CarouselSlider(
                            items: [
                              GestureDetector(
                                onTap: () {
                                  pp('$mm page 1 tapped');
                                },
                                child: const InfoPage(
                                    filePath: 'assets/image10.webp',
                                    content: 'Ace the Test, Stress Less with AI!',
                                    title: 'Don\'t Worry, Be Happy!'),
                              ),
                              GestureDetector(
                                onTap: () {
                                  pp('$mm page 2 tapped');
                                },
                                child: const InfoPage(
                                    filePath: 'assets/image8.jpg',
                                    content: 'Say Goodbye to Exam Anxiety!',
                                    title: 'Use AI, less anxiety!'),
                              ),
                              GestureDetector(
                                onTap: () {
                                  pp('$mm page 3 tapped');
                                },
                                child: const InfoPage(
                                    filePath: 'assets/image7.jpg',
                                    content: 'Study Buddy: Your 24/7 Exam Coach!',
                                    title: 'Easy Does It!'),
                              ),
                              GestureDetector(
                                onTap: () {
                                  pp('$mm page 4 tapped');
                                },
                                child: const InfoPage(
                                    filePath: 'assets/image4.webp',
                                    content: 'Teacher\'s Pet in Your Pocket!',
                                    title: 'Always Here 24/7'),
                              ),
                            ],
                            options: CarouselOptions(
                                height: 560,
                                enlargeCenterPage: true,
                                onPageChanged: (index, ccr) {},
                                scrollPhysics: const PageScrollPhysics()),
                          ),
                        ],
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
            )));
  }
}

class InfoPage extends StatelessWidget {
  const InfoPage({super.key,
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
                  context, Theme
                  .of(context)
                  .primaryColor, 20, FontWeight.w900),
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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/ui/organization/org_logo_widget.dart';
import 'package:edu_chatbot/ui/organization/website_view.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:edu_chatbot/util/navigation_util.dart';
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

class OrganizationSplash extends StatefulWidget {
  const OrganizationSplash(
      {super.key, required this.branding, this.timeToDisappear});

  final Branding branding;
  final int? timeToDisappear;

  @override
  OrganizationSplashState createState() => OrganizationSplashState();
}

class OrganizationSplashState extends State<OrganizationSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _checkTime();
  }

  _checkTime() {
    if (widget.timeToDisappear != null) {
      Future.delayed(Duration(seconds: widget.timeToDisappear!), () {
        Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _navigateToWebsite() {
    if (widget.branding.organizationUrl != null &&
        widget.branding.organizationUrl!.isNotEmpty) {
      pp('branding url: ${widget.branding.organizationUrl}');
      NavigationUtils.navigateToPage(
          context: context,
          widget: WebsiteView(
            url: widget.branding.organizationUrl!,
            title: widget.branding.organizationName!,
          ));
    } else {
      NavigationUtils.navigateToPage(
          context: context,
          widget: WebsiteView(
            url: 'https://www.sgela-ai.tech',
            title: widget.branding.organizationName!,
          ));
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
      body: ScreenTypeLayout.builder(
        mobile: (_) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        widget.branding.tagLine == null ||
                                widget.branding.tagLine!.isEmpty
                            ? const Card(
                                elevation: 8,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: SizedBox(
                                      width: 400,
                                      child:
                                          Text('Good luck with your work!')),
                                ))
                            : Text(widget.branding.tagLine!),
                        TextButton(
                          onPressed: () {
                            _navigateToWebsite();
                          },
                          child: const Text('Go to Website'),
                        ),
                        gapH4,
                        Expanded(
                            child: CachedNetworkImage(
                          imageUrl: widget.branding.splashUrl!,
                          fit: BoxFit.cover,
                        )),
                        gapH16,
                      ],
                    ),
                  ),
                ),
              )
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

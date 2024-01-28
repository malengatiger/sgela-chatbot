import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_chatbot/data/branding.dart';
import 'package:edu_chatbot/ui/organization/org_logo_widget.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

class OrganizationSplash extends StatefulWidget {
  const OrganizationSplash({super.key, required this.branding, this.timeToDisappear});

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
      Future.delayed(Duration(seconds: widget.timeToDisappear!),(){
        Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(
      appBar: AppBar(
        title: OrgLogoWidget(branding: widget.branding,),
      ),
      body: ScreenTypeLayout.builder(
        mobile: (_){return  Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      gapH32,
                      Expanded(child: CachedNetworkImage(imageUrl: widget.branding.splashUrl!, fit: BoxFit.cover,)),
                      gapH16,
                      widget.branding.tagLine == null? gapW4: Text(widget.branding.tagLine!),
                    ],
                  ),
                ),
              ),
            )
          ],
        );},
        tablet: (_){return const Stack();},
        desktop: (_){return const Stack();},
      ),
    ));
  }
}

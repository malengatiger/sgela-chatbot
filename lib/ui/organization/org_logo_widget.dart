import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/branding.dart';
import '../../util/environment.dart';
import '../../util/functions.dart';

class OrgLogoWidget extends StatelessWidget {
  const OrgLogoWidget({super.key, this.branding, this.height, this.name, this.width, this.logoUrl});

  final Branding? branding;
  final double? height, width;
  final String? name;

  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    var mLogoUrl = ChatbotEnvironment.sgelaLogoUrl;
    var splashUrl = ChatbotEnvironment.sgelaSplashUrl;
    if (logoUrl != null) {
      mLogoUrl = logoUrl!;
    }
    if (branding != null) {
      if (branding!.logoUrl != null) {
        mLogoUrl = branding!.logoUrl!;
      }
      if (branding!.splashUrl != null) {
        splashUrl = branding!.splashUrl!;
      }
    }
    return SizedBox(
      height: height == null ? 36 : height!,
      // width: width == null? 400: width!,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: CachedNetworkImage(
              imageUrl: mLogoUrl,
              height: height == null ? 36 : height!,
              // width: height == null ? 64*4 : (height! * 4),
            ),
          ),
          gapW16,
          name == null
              ? Flexible(
            child: Text(
              branding == null
                  ? defaultName
                  : '${branding!.organizationName}',
              style: myTextStyle(context, Theme.of(context).primaryColor,
                  12, FontWeight.normal),
            ),
          )
              : Flexible(
            child: Text(
              name == null
                  ? defaultName
                  : name!,
              style: myTextStyle(context, Theme.of(context).primaryColor,
                  12, FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
  static const defaultName = 'SgelaAI Inc.';
}

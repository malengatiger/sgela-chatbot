import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_chatbot/data/organization.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:edu_chatbot/util/prefs.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../data/branding.dart';

class PoweredBy extends StatefulWidget {
  const PoweredBy({
    super.key,
    this.organization,
    required this.repository,
  });

  final Organization? organization;
  final Repository repository;

  @override
  State<PoweredBy> createState() => _PoweredByState();
}

class _PoweredByState extends State<PoweredBy> {
  static const String mm = '🍎🍎🍎 PoweredBy: ';

  Organization? sponsorOrganization;
  Branding? branding;
  bool busy = false;
  Prefs prefs = GetIt.instance<Prefs>();
  Repository repository = GetIt.instance<Repository>();
  @override
  void initState() {
    super.initState();
    _getOrganization();
  }

  Future<void> _getOrganization() async {
    sponsorOrganization = widget.organization;
    setState(() {
      busy = true;
    });
    try {
      sponsorOrganization = prefs.getOrganization();
      branding = prefs.getBrand();
    } catch (e,s) {
      pp(e);
      pp(s);
      if (mounted) {
        showErrorDialog(context, 'Unable to get sponsorOrganization ');
      }
    }
    setState(() {
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            gapW4,
             Text('Powered by', style: myTextStyleTiny(context),),
            gapW4,
            sponsorOrganization == null ? gapW4 : Text('${sponsorOrganization!.name}'),
            gapW8,
            branding == null
                ? gapW4
                : Card(
                    elevation: 8,
                    child: CachedNetworkImage(
                      height: 32,
                      imageUrl: branding!.logoUrl!,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

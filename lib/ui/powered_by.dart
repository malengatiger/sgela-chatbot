import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_chatbot/data/organization.dart';
import 'package:edu_chatbot/repositories/repository.dart';
import 'package:edu_chatbot/util/functions.dart';
import 'package:flutter/material.dart';

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

  Organization? org;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _getOrganization();
  }

  Future<void> _getOrganization() async {
    org = widget.organization;
    setState(() {
      busy = true;
    });
    try {
      org ??= await widget.repository.getSgelaOrganization();
      pp('$mm org: ${org!.toJson()}');
    } catch (e) {
      pp(e);
      if (mounted) {
        showErrorDialog(context, 'Unable to get Sgela org');
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
            const Text('Powered by'),
            gapW4,
            org == null ? gapW4 : Text('${org!.name}'),
            gapW32,
            org == null
                ? gapW4
                : Card(
                    elevation: 8,
                    child: CachedNetworkImage(
                      height: 32,
                      imageUrl: org!.logoUrl!,
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

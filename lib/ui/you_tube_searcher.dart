import 'package:badges/badges.dart' as bd;
import 'package:edu_chatbot/ui/busy_indicator.dart';
import 'package:edu_chatbot/ui/you_tube_gallery.dart';
import 'package:edu_chatbot/ui/you_tube_viewer.dart';
import 'package:edu_chatbot/util/environment.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/subject.dart';
import '../data/youtube_data.dart';
import '../services/you_tube_service.dart';
import '../util/dark_light_control.dart';
import '../util/functions.dart';
import '../util/navigation_util.dart';
import '../util/prefs.dart';
import 'color_gallery.dart';

class YouTubeSearcher extends StatefulWidget {
  const YouTubeSearcher(
      {super.key,
      required this.youTubeService,
      required this.subject,
      required this.prefs,
      required this.colorWatcher});

  final YouTubeService youTubeService;
  final Subject subject;
  final Prefs prefs;
  final ColorWatcher colorWatcher;

  @override
  YouTubeSearcherState createState() => YouTubeSearcherState();
}

class YouTubeSearcherState extends State<YouTubeSearcher> {
  List<YouTubeData> videos = [];
  TextEditingController textEditingController = TextEditingController();
  static const mm = '🍎🍎🍎🍎 YouTubeSearcher 🍐';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    pp('$mm ................ searchByTag YouTube ...');
    setState(() {
      busy = true;
    });
    try {
      videos = await widget.youTubeService.searchByTag(
          subjectId: widget.subject.id!,
          maxResults: ChatbotEnvironment.maxResults,
          tagType: 1);
      pp('$mm ... search YouTube found: ${videos.length} ...');
    } catch (e) {
      pp(e);
      if (mounted) {
        showErrorDialog(context, 'Error: $e');
      }
    }
    setState(() {
      busy = false;
    });
  }

  void _launchVideo(String videoUrl) async {
    pp('$mm .................. _launchVideo: $videoUrl ...');

    if (await canLaunchUrl(Uri.parse(videoUrl))) {
      await launchUrl(Uri.parse(videoUrl));
    } else {
      // If the YouTube app is not installed, open the video in a WebView
      if (mounted) {
        NavigationUtils.navigateToPage(
            context: context,
            widget: YouTubeViewer(
              youTubeVideoUrl: videoUrl,
            ));
      }
    }
  }

  bool showSearch = false;

  void _navigateToColorGallery() {
    NavigationUtils.navigateToPage(
        context: context,
        widget: ColorGallery(
            prefs: widget.prefs, colorWatcher: widget.colorWatcher));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            title: Text('YouTube Videos',
                style: myTextStyle(context, Theme.of(context).primaryColor, 16,
                    FontWeight.w600)),
            bottom: PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Text(
                  '${widget.subject.title}',
                  style: myTextStyleMediumBold(context),
                )),
            actions: [
              IconButton(
                  onPressed: () {
                    _navigateToColorGallery();
                  },
                  icon:  Icon(Icons.color_lens_outlined, color: Theme.of(context).primaryColor)),
              IconButton(
                  onPressed: () {
                    setState(() {
                      showSearch = !showSearch;
                    });
                  },
                  icon:  Icon(Icons.search, color: Theme.of(context).primaryColor)),
            ],
          ),
          body: Stack(
            children: [
              bd.Badge(
                position: bd.BadgePosition.topEnd(top:24, end: 12),
                badgeContent: Text(
                  '${videos.length}',
                  style:
                      myTextStyle(context, Colors.white, 16, FontWeight.normal),
                ),
                badgeStyle: const bd.BadgeStyle(
                  padding: EdgeInsets.all(12),
                  elevation: 16,
                ),
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        gapH16,
                        gapH16,
                        showSearch
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  controller: textEditingController,
                                  onChanged: (value) {
                                    pp('... search text: $value');
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Search',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed: () {
                                        _search();
                                      },
                                    ),
                                  ),
                                ),
                              )
                            : gapW8,
                        busy
                            ? const Expanded(
                                child: BusyIndicator(
                                  caption: 'Searching for videos ... please wait',
                                ),
                              )
                            : Expanded(
                                child: videos.isEmpty
                                    ? gapW8
                                    : YouTubeGallery(
                                        videos: videos,
                                        onTapped: (video) {
                                          _launchVideo(video.videoUrl!);
                                        }),
                              ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          )),
    );
  }
}

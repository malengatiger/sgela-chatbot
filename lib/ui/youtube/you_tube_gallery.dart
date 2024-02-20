import 'package:flutter/material.dart';
import 'package:sgela_services/data/youtube_data.dart';


class YouTubeGallery extends StatelessWidget {
  const YouTubeGallery(
      {super.key, required this.videos, required this.onTapped});

  final List<YouTubeData> videos;
  final Function(YouTubeData) onTapped;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 4, mainAxisSpacing: 4),
          itemCount: videos.length,
          itemBuilder: (_, index) {
            var video = videos.elementAt(index);
            return GestureDetector(
                onTap: () {
                  onTapped(video);
                },
                child: Image.network(
                  video.thumbnailMedium!,
                  fit: BoxFit.cover,
                ));
          }),
    );
  }
}

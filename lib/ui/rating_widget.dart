import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../util/functions.dart';

class GeminiRatingWidget extends StatelessWidget {
  const GeminiRatingWidget(
      {super.key, required this.onRating, required this.visible, this.color});

  final Function(double) onRating;
  final bool visible;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    pp('GeminiRating ... build, visible: $visible');
    var brightness = MediaQuery.of(context).platformBrightness;
    return visible
        ? Card(
            elevation: 12,
            // color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) =>  Icon(
                  Icons.star,
                  color: color == null? Theme.of(context).primaryColor: color!,
                ),
                onRatingUpdate: (rating) {
                  pp('🍎🍎🍎 onRatingUpdate: rating: 🍎$rating 🍎 calling onRating() ...');
                  Future.delayed(const Duration(milliseconds: 1000),(){
                    onRating(rating);

                  });
                },
              ),
            ),
          )
        : gapW8;
  }
}

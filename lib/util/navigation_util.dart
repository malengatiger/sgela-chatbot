import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class NavigationUtils {
  static Future navigateToPage({
    required BuildContext context,
    required Widget widget,
    PageTransitionType transitionType = PageTransitionType.scale,
    Duration transitionDuration = const Duration(milliseconds: 1000)
  }) async {
    var result = await Navigator.push(
      context,
      PageTransition(
        type: transitionType,
        duration: transitionDuration,
        alignment: Alignment.bottomLeft,
        child: widget,
      ),
    );
    return result;
  }
}

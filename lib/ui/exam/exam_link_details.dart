import 'package:flutter/material.dart';
import 'package:sgela_services/data/exam_link.dart';

import '../../local_util/functions.dart';

class ExamLinkDetails extends StatelessWidget {
  const ExamLinkDetails(
      {super.key, required this.examLink, required this.pageNumber});

  final ExamLink examLink;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: SizedBox(
        height: pageNumber == 0 ? 96 : 120,
        child: Padding(
          padding: const EdgeInsets.only(
              left: 20.0, right: 20.0, top: 8.0, bottom: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${examLink.documentTitle}',
                style: myTextStyleSmall(context),
              ),
              gapH8,
              Text(
                examLink.subject!.title!,
                style: myTextStyleSmallBoldPrimaryColor(context),
              ),
              gapH8,
              Text(
                '${examLink.title}',
                style: myTextStyleSmall(context),
              ),
              gapH8,
              pageNumber == 0
                  ? gapW4
                  : Text(
                'Page $pageNumber',
                style: myTextStyleSmallBoldPrimaryColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

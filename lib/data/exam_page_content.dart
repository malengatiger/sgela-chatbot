import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
part 'exam_page_content.g.dart';
@JsonSerializable()

class ExamPageContent {
  
  int? id, examLinkId, pageIndex;
  String? text, title, pageImageUrl;
  String? bytes;

  List<int>? uBytes;


  ExamPageContent(this.id, this.examLinkId, this.pageIndex, this.text,
      this.title, this.pageImageUrl, this.bytes, this.uBytes);

  factory ExamPageContent.fromJson(Map<String, dynamic> json) =>
      _$ExamPageContentFromJson(json);

  Map<String, dynamic> toJson() => _$ExamPageContentToJson(this);

}

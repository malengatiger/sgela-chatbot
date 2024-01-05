
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

part 'exam_page_image.g.dart';

@JsonSerializable()
class ExamPageImage {
  int? examLinkId;
  int? id;
  String? downloadUrl;

  List<int>? bytes;

  int? pageIndex;

  String? mimeType;


  ExamPageImage(this.examLinkId, this.id, this.downloadUrl, this.bytes,
      this.pageIndex, this.mimeType);

  factory ExamPageImage.fromJson(Map<String, dynamic> json) =>
      _$ExamPageImageFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = _$ExamPageImageToJson(this);

    return data;
  }}


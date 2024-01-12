import 'package:json_annotation/json_annotation.dart';

part 'exam_page_image.g.dart';

@JsonSerializable()
class ExamPageImage {
  int? examLinkId;
  int? id;

  List<int>? bytes;

  int? pageIndex;

  String? mimeType;

  ExamPageImage(
      {required this.examLinkId,
      required this.id,
      required this.bytes,
      required this.pageIndex,
      required this.mimeType});

  factory ExamPageImage.fromJson(Map<String, dynamic> json) =>
      _$ExamPageImageFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = _$ExamPageImageToJson(this);

    return data;
  }
}

import 'package:json_annotation/json_annotation.dart';

part 'exam_document.g.dart';

@JsonSerializable()
class ExamDocument {
  String? title;
  String? link;
  int? id;


  ExamDocument(this.title, this.link, this.id);

  factory ExamDocument.fromJson(Map<String, dynamic> json) =>
      _$ExamDocumentFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = _$ExamDocumentToJson(this);

    return data;
  }

}

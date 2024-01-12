import 'package:json_annotation/json_annotation.dart';

part 'subject_exam_link_aggregate.g.dart';

@JsonSerializable()
class SubjectExamLinkAggregate {
  int? subjectId;
  String? title;
  int? examLinks;

  SubjectExamLinkAggregate({required this.subjectId,
    required this.title, required this.examLinks});

  factory SubjectExamLinkAggregate.fromJson(Map<String, dynamic> json) =>
      _$SubjectExamLinkAggregateFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectExamLinkAggregateToJson(this);
}
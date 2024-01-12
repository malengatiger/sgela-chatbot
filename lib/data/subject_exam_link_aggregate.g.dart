// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_exam_link_aggregate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectExamLinkAggregate _$SubjectExamLinkAggregateFromJson(
        Map<String, dynamic> json) =>
    SubjectExamLinkAggregate(
      subjectId: json['subjectId'] as int?,
      title: json['title'] as String?,
      examLinks: json['examLinks'] as int?,
    );

Map<String, dynamic> _$SubjectExamLinkAggregateToJson(
        SubjectExamLinkAggregate instance) =>
    <String, dynamic>{
      'subjectId': instance.subjectId,
      'title': instance.title,
      'examLinks': instance.examLinks,
    };

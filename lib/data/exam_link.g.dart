// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExamLink _$ExamLinkFromJson(Map<String, dynamic> json) => ExamLink(
      json['title'] as String?,
      json['link'] as String?,
      json['id'] as int?,
      json['subject'] == null
          ? null
          : Subject.fromJson(json['subject'] as Map<String, dynamic>),
      json['examDocument'] == null
          ? null
          : ExamDocument.fromJson(json['examDocument'] as Map<String, dynamic>),
      json['pageImageZipUrl'] as String?,
      json['documentTitle'] as String?,
    );

Map<String, dynamic> _$ExamLinkToJson(ExamLink instance) => <String, dynamic>{
      'title': instance.title,
      'link': instance.link,
      'id': instance.id,
      'subject': instance.subject,
      'examDocument': instance.examDocument,
      'pageImageZipUrl': instance.pageImageZipUrl,
      'documentTitle': instance.documentTitle,
    };

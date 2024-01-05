// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExamLink _$ExamLinkFromJson(Map<String, dynamic> json) => ExamLink(
      json['title'] as String?,
      json['link'] as String?,
      json['id'] as int?,
      json['subjectTitle'] as String?,
      json['subjectId'] as int?,
      json['pageImageZipUrl'] as String?,
      json['documentTitle'] as String?,
    );

Map<String, dynamic> _$ExamLinkToJson(ExamLink instance) => <String, dynamic>{
      'title': instance.title,
      'link': instance.link,
      'id': instance.id,
      'subjectTitle': instance.subjectTitle,
      'subjectId': instance.subjectId,
      'pageImageZipUrl': instance.pageImageZipUrl,
      'documentTitle': instance.documentTitle,
    };

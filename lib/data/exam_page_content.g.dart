// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_page_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExamPageContent _$ExamPageContentFromJson(Map<String, dynamic> json) =>
    ExamPageContent(
      json['id'] as int?,
      json['examLinkId'] as int?,
      json['pageIndex'] as int?,
      json['text'] as String?,
      json['title'] as String?,
      json['pageImageUrl'] as String?,
      json['bytes'] as String?,
      (json['uBytes'] as List<dynamic>?)?.map((e) => e as int).toList(),
    );

Map<String, dynamic> _$ExamPageContentToJson(ExamPageContent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'examLinkId': instance.examLinkId,
      'pageIndex': instance.pageIndex,
      'text': instance.text,
      'title': instance.title,
      'pageImageUrl': instance.pageImageUrl,
      'bytes': instance.bytes,
      'uBytes': instance.uBytes,
    };

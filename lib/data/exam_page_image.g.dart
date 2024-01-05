// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_page_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExamPageImage _$ExamPageImageFromJson(Map<String, dynamic> json) =>
    ExamPageImage(
      json['examLinkId'] as int?,
      json['id'] as int?,
      json['downloadUrl'] as String?,
      (json['bytes'] as List<dynamic>?)?.map((e) => e as int).toList(),
      json['pageIndex'] as int?,
      json['mimeType'] as String?,
    );

Map<String, dynamic> _$ExamPageImageToJson(ExamPageImage instance) =>
    <String, dynamic>{
      'examLinkId': instance.examLinkId,
      'id': instance.id,
      'downloadUrl': instance.downloadUrl,
      'bytes': instance.bytes,
      'pageIndex': instance.pageIndex,
      'mimeType': instance.mimeType,
    };

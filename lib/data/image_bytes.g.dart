// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_bytes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageBytes _$ImageBytesFromJson(Map<String, dynamic> json) => ImageBytes(
      json['examLinkId'] as int?,
      json['id'] as int?,
      (json['bytes'] as List<dynamic>?)?.map((e) => e as int).toList(),
      json['imageIndex'] as int?,
    );

Map<String, dynamic> _$ImageBytesToJson(ImageBytes instance) =>
    <String, dynamic>{
      'examLinkId': instance.examLinkId,
      'id': instance.id,
      'bytes': instance.bytes,
      'imageIndex': instance.imageIndex,
    };

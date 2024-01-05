// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyContent _$MyContentFromJson(Map<String, dynamic> json) => MyContent(
      parts: (json['parts'] as List<dynamic>?)
          ?.map((e) => MyParts.fromJson(e as Map<String, dynamic>))
          .toList(),
      role: json['role'] as String?,
    );

Map<String, dynamic> _$MyContentToJson(MyContent instance) => <String, dynamic>{
      'parts': instance.parts,
      'role': instance.role,
    };

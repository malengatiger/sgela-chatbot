// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gemini_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyGeminiResponse _$MyGeminiResponseFromJson(Map<String, dynamic> json) =>
    MyGeminiResponse(
      (json['candidates'] as List<dynamic>?)
          ?.map((e) => MyCandidates.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['promptFeedback'] == null
          ? null
          : MyPromptFeedback.fromJson(
              json['promptFeedback'] as Map<String, dynamic>),
      json['tokensUsed'] as int?,
    );

Map<String, dynamic> _$MyGeminiResponseToJson(MyGeminiResponse instance) =>
    <String, dynamic>{
      'candidates': instance.candidates,
      'promptFeedback': instance.promptFeedback,
      'tokensUsed': instance.tokensUsed,
    };

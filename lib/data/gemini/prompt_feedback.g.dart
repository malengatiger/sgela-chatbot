// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prompt_feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyPromptFeedback _$MyPromptFeedbackFromJson(Map<String, dynamic> json) =>
    MyPromptFeedback(
      safetyRatings: (json['safetyRatings'] as List<dynamic>?)
          ?.map((e) => SafetyRatings.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MyPromptFeedbackToJson(MyPromptFeedback instance) =>
    <String, dynamic>{
      'safetyRatings': instance.safetyRatings,
    };

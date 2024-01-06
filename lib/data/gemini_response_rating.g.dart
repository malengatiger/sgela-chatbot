// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gemini_response_rating.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeminiResponseRating _$GeminiResponseRatingFromJson(
        Map<String, dynamic> json) =>
    GeminiResponseRating(
      rating: json['rating'] as int?,
      date: json['date'] as String?,
      id: json['id'] as int?,
      pageNumber: json['pageNumber'] as int?,
      tokensUsed: json['tokensUsed'] as int?,
      examLinkId: json['examLinkId'] as int?,
      responseText: json['responseText'] as String?,
      prompt: json['prompt'] as String?,
    );

Map<String, dynamic> _$GeminiResponseRatingToJson(
        GeminiResponseRating instance) =>
    <String, dynamic>{
      'rating': instance.rating,
      'date': instance.date,
      'id': instance.id,
      'pageNumber': instance.pageNumber,
      'examLinkId': instance.examLinkId,
      'responseText': instance.responseText,
      'prompt': instance.prompt,
      'tokensUsed': instance.tokensUsed,
    };

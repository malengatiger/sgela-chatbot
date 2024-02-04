import 'package:json_annotation/json_annotation.dart';

import 'exam_page_image.dart';

part 'gemini_response_rating.g.dart';

@JsonSerializable()
class GeminiResponseRating {
  int? rating;
  String? date;
  int? id;
  int? pageNumber;

  int? examLinkId;

  String? responseText;

  int? tokensUsed;

  GeminiResponseRating({required this.rating, required this.date,
    this.id, required this.pageNumber, required this.tokensUsed,
    required this.examLinkId, required this.responseText});

  factory GeminiResponseRating.fromJson(Map<String, dynamic> json) =>
      _$GeminiResponseRatingFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = _$GeminiResponseRatingToJson(this);

    return data;
  }}

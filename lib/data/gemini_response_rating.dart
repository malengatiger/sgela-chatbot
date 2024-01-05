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
  String? prompt;


  GeminiResponseRating({required this.rating, required this.date,
    this.id, required this.pageNumber,
    required this.examLinkId, required this.responseText, required this.prompt});

  factory GeminiResponseRating.fromJson(Map<String, dynamic> json) =>
      _$GeminiResponseRatingFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = _$GeminiResponseRatingToJson(this);

    return data;
  }}

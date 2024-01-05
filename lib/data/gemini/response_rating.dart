import 'package:json_annotation/json_annotation.dart';

part 'response_rating.g.dart';

@JsonSerializable()
class ResponseRating {
  int? examLinkId;
  int? rating;
  int? id;
  String? date;
  int? subjectId;
  String? subjectTitle;
  String? responseText;


  ResponseRating(this.examLinkId, this.rating, this.id, this.date,
      this.subjectId, this.subjectTitle, this.responseText);

  factory ResponseRating.fromJson(Map<String, dynamic> json) =>
      _$ResponseRatingFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = _$ResponseRatingToJson(this);

    return data;
  }}

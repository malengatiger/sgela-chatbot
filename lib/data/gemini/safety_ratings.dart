import 'package:json_annotation/json_annotation.dart';

part 'safety_ratings.g.dart';

@JsonSerializable()
class SafetyRatings {
  String? category;
  String? probability;

  SafetyRatings({this.category, this.probability});

  factory SafetyRatings.fromJson(Map<String, dynamic> json) =>
      _$SafetyRatingsFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = _$SafetyRatingsToJson(this);

    return data;
  }}


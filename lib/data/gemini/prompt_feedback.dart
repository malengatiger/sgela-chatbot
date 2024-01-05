import 'safety_ratings.dart';
import 'package:json_annotation/json_annotation.dart';

part 'prompt_feedback.g.dart';

@JsonSerializable()
class MyPromptFeedback {
  List<SafetyRatings>? safetyRatings;

  MyPromptFeedback({this.safetyRatings});

  factory MyPromptFeedback.fromJson(Map<String, dynamic> json) =>
      _$MyPromptFeedbackFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = _$MyPromptFeedbackToJson(this);

    return data;
  }}


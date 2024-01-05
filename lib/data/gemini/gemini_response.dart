
import 'package:json_annotation/json_annotation.dart';
import 'prompt_feedback.dart';
import 'candidates.dart';
part 'gemini_response.g.dart';

@JsonSerializable()
class MyGeminiResponse {
  List<MyCandidates>? candidates;
  MyPromptFeedback? promptFeedback;

  MyGeminiResponse({this.candidates, this.promptFeedback});

  factory MyGeminiResponse.fromJson(Map<String, dynamic> json) =>
      _$MyGeminiResponseFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = _$MyGeminiResponseToJson(this);

    return data;
  }}












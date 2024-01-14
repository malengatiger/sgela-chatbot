
import 'package:json_annotation/json_annotation.dart';
import 'prompt_feedback.dart';
import 'candidates.dart';
part 'gemini_response.g.dart';

@JsonSerializable()
class MyGeminiResponse {
  List<MyCandidates>? candidates;
  MyPromptFeedback? promptFeedback;
  int? tokensUsed;
  bool? responseIsOK;
  String? message;


  MyGeminiResponse(this.candidates, this.promptFeedback, this.tokensUsed,
      this.responseIsOK, this.message);

  factory MyGeminiResponse.fromJson(Map<String, dynamic> json) =>
      _$MyGeminiResponseFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = _$MyGeminiResponseToJson(this);

    return data;
  }}












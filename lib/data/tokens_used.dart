
import 'package:json_annotation/json_annotation.dart';

part 'tokens_used.g.dart';
@JsonSerializable()
/*
 {prompt_tokens: 610, completion_tokens: 354, total_tokens: 964}
 */
class TokensUsed {
  int? organizationId, sponsoreeId;
  String? date, sponsoreeName;
  String? organizationName, model;
  int? promptTokens, completionTokens, totalTokens;


  TokensUsed(
      this.organizationId,
      this.sponsoreeId,
      this.date,
      this.sponsoreeName,
      this.organizationName,
      this.promptTokens,
      this.completionTokens,
      this.model,
      this.totalTokens);

  factory TokensUsed.fromJson(Map<String, dynamic> json) =>
      _$TokensUsedFromJson(json);

  Map<String, dynamic> toJson() => _$TokensUsedToJson(this);
}

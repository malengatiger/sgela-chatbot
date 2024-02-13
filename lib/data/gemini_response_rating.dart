import 'package:json_annotation/json_annotation.dart';

part 'gemini_response_rating.g.dart';

@JsonSerializable()
class AIResponseRating {
  int? rating;
  String? date;
  int? id, subjectId, organizationId;
  int? numberOfPagesInQuery;

  int? sponsoreeId, userId;
  String? sponsoreeName, sponsoreeEmail, sponsoreeCellphone;
  int? examLinkId;
  String? examTitle, subject, aiModel;
  int? tokensUsed;

  AIResponseRating(
      {required this.rating,
      required this.date,
      required this.id,
      required this.subjectId,
      required this.organizationId,
      required this.numberOfPagesInQuery,
      required this.sponsoreeId,
      required this.userId,
      required this.sponsoreeName,
      required this.sponsoreeEmail,
      required this.sponsoreeCellphone,
      required this.examLinkId,
      required this.examTitle,
      required this.subject,
      required this.aiModel,
      required this.tokensUsed});

  factory AIResponseRating.fromJson(Map<String, dynamic> json) =>
      _$AIResponseRatingFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = _$AIResponseRatingToJson(this);

    return data;
  }
}

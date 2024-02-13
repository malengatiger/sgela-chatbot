import 'package:edu_chatbot/data/exam_link.dart';
import 'package:edu_chatbot/data/sponsoree.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sponsoree_activity.g.dart';

@JsonSerializable()
class SponsoreeActivity {
  int? organizationId, id;
  String? date;
  String? organizationName;
  int? totalTokens;
  int? elapsedTimeInSeconds;
  String? aiModel;
  int? sponsoreeId, userId;
  String? sponsoreeName, sponsoreeEmail, sponsoreeCellphone;
  int? examLinkId;
  String? examTitle, subject;
  int? subjectId;


  SponsoreeActivity({
      required this.organizationId,
      required this.id,
      required this.date,
      required this.organizationName,
      required this.totalTokens,
      required this.elapsedTimeInSeconds,
      required this.aiModel,
      required this.sponsoreeId,
      required this.userId,
      required this.sponsoreeName,
      required this.sponsoreeEmail,
      required this.sponsoreeCellphone,
      required this.examLinkId,
      required this.examTitle,
      required this.subjectId,
      required this.subject});

  factory SponsoreeActivity.fromJson(Map<String, dynamic> json) =>
      _$SponsoreeActivityFromJson(json);

  Map<String, dynamic> toJson() => _$SponsoreeActivityToJson(this);
}

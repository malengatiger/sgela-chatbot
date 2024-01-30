import 'package:edu_chatbot/data/sgela_user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sponsoree.g.dart';

@JsonSerializable()
class Sponsoree {
  int? organizationId, id;
  String? date;
  String? organizationName;
  bool? activeFlag;

  int? sgelaUserId;
  String? sgelaUserName;
  String? sgelaCellphone;
  String? sgelaEmail;
  String? sgelaFirebaseId;

  Sponsoree(
      {required this.organizationId,
      required this.id,
      required this.date,
      required this.organizationName,
      required this.activeFlag,
      required this.sgelaUserId,
      required this.sgelaUserName,
      required this.sgelaCellphone,
      required this.sgelaEmail,
      required this.sgelaFirebaseId});

  factory Sponsoree.fromJson(Map<String, dynamic> json) =>
      _$SponsoreeFromJson(json);

  Map<String, dynamic> toJson() => _$SponsoreeToJson(this);
}

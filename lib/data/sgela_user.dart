import 'package:json_annotation/json_annotation.dart';

part 'sgela_user.g.dart';

@JsonSerializable()
class SgelaUser {
  String? firstName, lastName, email, cellphone;
  String? date;
  int? id, countryId, cityId;
  String? countryName, cityName, firebaseUserId;
  String? institutionName;

  SgelaUser(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.cellphone,
      required this.date,
      required this.countryId,
      required this.cityId,
      required this.countryName,
      required this.cityName,
      this.firebaseUserId,
      this.institutionName});

  factory SgelaUser.fromJson(Map<String, dynamic> json) =>
      _$SgelaUserFromJson(json);

  Map<String, dynamic> toJson() => _$SgelaUserToJson(this);
}

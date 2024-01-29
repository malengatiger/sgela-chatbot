import 'package:json_annotation/json_annotation.dart';

part 'sgela_user.g.dart';
@JsonSerializable()
class SgelaUser {
  String? firstName, lastName, email, cellphone;
  String? date;
  int? countryId, cityId;
  String? countryName, cityName, firebaseUserId;
  String? institutionName;


  SgelaUser(
      this.firstName,
      this.lastName,
      this.email,
      this.cellphone,
      this.date,
      this.countryId,
      this.cityId,
      this.countryName,
      this.cityName, this.firebaseUserId,
      this.institutionName);

  factory SgelaUser.fromJson(Map<String, dynamic> json) =>
      _$SgelaUserFromJson(json);

  Map<String, dynamic> toJson() => _$SgelaUserToJson(this);
}

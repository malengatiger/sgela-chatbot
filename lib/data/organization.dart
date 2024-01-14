import 'package:edu_chatbot/data/country.dart';
import 'package:json_annotation/json_annotation.dart';

import 'city.dart';

part 'organization.g.dart';
@JsonSerializable()
class Organization {
  String? name, email, cellphone;
  int? id;
  Country? country;
  City? city;

  String? logoUrl, splashUrl;


  Organization(this.name, this.email, this.cellphone, this.id, this.country,
      this.city, this.logoUrl, this.splashUrl);

  factory Organization.fromJson(Map<String, dynamic> json) =>
      _$OrganizationFromJson(json);

  Map<String, dynamic> toJson() => _$OrganizationToJson(this);
}

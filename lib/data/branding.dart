
import 'package:json_annotation/json_annotation.dart';

import 'organization.dart';
part 'branding.g.dart';
@JsonSerializable()

class Branding {
  int? organizationId, id, splashTimeInSeconds, colorIndex;
  String? date;
  String? logoUrl, splashUrl, tagLine,
      organizationName, organizationUrl;
  bool? activeFlag;


  Branding({
    required this.organizationId,
    required this.id,
    required this.date,
    required this.logoUrl,
    required this.splashUrl,
    required this.tagLine,
    required this.organizationName,
    required this.organizationUrl,
    required this.splashTimeInSeconds,
    required this.colorIndex,
    required this.activeFlag});

  factory Branding.fromJson(Map<String, dynamic> json) =>
      _$BrandingFromJson(json);

  Map<String, dynamic> toJson() => _$BrandingToJson(this);
}

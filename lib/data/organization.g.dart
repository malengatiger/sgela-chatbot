// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Organization _$OrganizationFromJson(Map<String, dynamic> json) => Organization(
      json['name'] as String?,
      json['email'] as String?,
      json['cellphone'] as String?,
      json['id'] as int?,
      json['country'] == null
          ? null
          : Country.fromJson(json['country'] as Map<String, dynamic>),
      json['city'] == null
          ? null
          : City.fromJson(json['city'] as Map<String, dynamic>),
      json['logoUrl'] as String?,
      json['splashUrl'] as String?,
    );

Map<String, dynamic> _$OrganizationToJson(Organization instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'cellphone': instance.cellphone,
      'id': instance.id,
      'country': instance.country,
      'city': instance.city,
      'logoUrl': instance.logoUrl,
      'splashUrl': instance.splashUrl,
    };

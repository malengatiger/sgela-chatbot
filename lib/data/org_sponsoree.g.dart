// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'org_sponsoree.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrgSponsoree _$OrgSponsoreeFromJson(Map<String, dynamic> json) => OrgSponsoree(
      json['organizationId'] as int?,
      json['id'] as int?,
      json['date'] as String?,
      json['organizationName'] as String?,
      json['activeFlag'] as bool?,
      json['user'] == null
          ? null
          : SgelaUser.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OrgSponsoreeToJson(OrgSponsoree instance) =>
    <String, dynamic>{
      'organizationId': instance.organizationId,
      'id': instance.id,
      'date': instance.date,
      'organizationName': instance.organizationName,
      'activeFlag': instance.activeFlag,
      'user': instance.user,
    };

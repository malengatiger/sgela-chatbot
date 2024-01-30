// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sponsoree.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sponsoree _$SponsoreeFromJson(Map<String, dynamic> json) => Sponsoree(
      organizationId: json['organizationId'] as int?,
      id: json['id'] as int?,
      date: json['date'] as String?,
      organizationName: json['organizationName'] as String?,
      activeFlag: json['activeFlag'] as bool?,
      sgelaUserId: json['sgelaUserId'] as int?,
      sgelaUserName: json['sgelaUserName'] as String?,
      sgelaCellphone: json['sgelaCellphone'] as String?,
      sgelaEmail: json['sgelaEmail'] as String?,
      sgelaFirebaseId: json['sgelaFirebaseId'] as String?,
    );

Map<String, dynamic> _$SponsoreeToJson(Sponsoree instance) => <String, dynamic>{
      'organizationId': instance.organizationId,
      'id': instance.id,
      'date': instance.date,
      'organizationName': instance.organizationName,
      'activeFlag': instance.activeFlag,
      'sgelaUserId': instance.sgelaUserId,
      'sgelaUserName': instance.sgelaUserName,
      'sgelaCellphone': instance.sgelaCellphone,
      'sgelaEmail': instance.sgelaEmail,
      'sgelaFirebaseId': instance.sgelaFirebaseId,
    };

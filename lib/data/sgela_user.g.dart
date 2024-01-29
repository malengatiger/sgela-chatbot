// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sgela_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SgelaUser _$SgelaUserFromJson(Map<String, dynamic> json) => SgelaUser(
      json['firstName'] as String?,
      json['lastName'] as String?,
      json['email'] as String?,
      json['cellphone'] as String?,
      json['date'] as String?,
      json['countryId'] as int?,
      json['cityId'] as int?,
      json['countryName'] as String?,
      json['cityName'] as String?,
      json['firebaseUserId'] as String?,
      json['institutionName'] as String?,
    );

Map<String, dynamic> _$SgelaUserToJson(SgelaUser instance) => <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'cellphone': instance.cellphone,
      'date': instance.date,
      'countryId': instance.countryId,
      'cityId': instance.cityId,
      'countryName': instance.countryName,
      'cityName': instance.cityName,
      'firebaseUserId': instance.firebaseUserId,
      'institutionName': instance.institutionName,
    };

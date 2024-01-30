// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sgela_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SgelaUser _$SgelaUserFromJson(Map<String, dynamic> json) => SgelaUser(
      id: json['id'] as int?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      cellphone: json['cellphone'] as String?,
      date: json['date'] as String?,
      countryId: json['countryId'] as int?,
      cityId: json['cityId'] as int?,
      countryName: json['countryName'] as String?,
      cityName: json['cityName'] as String?,
      firebaseUserId: json['firebaseUserId'] as String?,
      institutionName: json['institutionName'] as String?,
    );

Map<String, dynamic> _$SgelaUserToJson(SgelaUser instance) => <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'cellphone': instance.cellphone,
      'date': instance.date,
      'id': instance.id,
      'countryId': instance.countryId,
      'cityId': instance.cityId,
      'countryName': instance.countryName,
      'cityName': instance.cityName,
      'firebaseUserId': instance.firebaseUserId,
      'institutionName': instance.institutionName,
    };

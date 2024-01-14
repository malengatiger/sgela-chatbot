// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Country _$CountryFromJson(Map<String, dynamic> json) => Country(
      json['id'] as int?,
      json['name'] as String?,
    )
      ..capital = json['capital'] as String?
      ..currencyName = json['currencyName'] as String?
      ..currencySymbol = json['currencySymbol'] as String?
      ..emoji = json['emoji'] as String?
      ..iso2 = json['iso2'] as String?
      ..iso3 = json['iso3'] as String?
      ..phoneCode = json['phoneCode'] as String?
      ..region = json['region'] as String?
      ..subregion = json['subregion'] as String?
      ..numericCode = json['numericCode'] as String?
      ..latitude = (json['latitude'] as num?)?.toDouble()
      ..longitude = (json['longitude'] as num?)?.toDouble();

Map<String, dynamic> _$CountryToJson(Country instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'capital': instance.capital,
      'currencyName': instance.currencyName,
      'currencySymbol': instance.currencySymbol,
      'emoji': instance.emoji,
      'iso2': instance.iso2,
      'iso3': instance.iso3,
      'phoneCode': instance.phoneCode,
      'region': instance.region,
      'subregion': instance.subregion,
      'numericCode': instance.numericCode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

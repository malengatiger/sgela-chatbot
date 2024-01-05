// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pricing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pricing _$PricingFromJson(Map<String, dynamic> json) => Pricing(
      (json['monthlyPrice'] as num?)?.toDouble(),
      (json['annualPrice'] as num?)?.toDouble(),
      json['currency'] as String?,
      json['date'] as String?,
      json['country'] == null
          ? null
          : Country.fromJson(json['country'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PricingToJson(Pricing instance) => <String, dynamic>{
      'monthlyPrice': instance.monthlyPrice,
      'annualPrice': instance.annualPrice,
      'currency': instance.currency,
      'date': instance.date,
      'country': instance.country,
    };

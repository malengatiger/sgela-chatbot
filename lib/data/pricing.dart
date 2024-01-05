import 'package:edu_chatbot/data/country.dart';
import 'package:json_annotation/json_annotation.dart';
part 'pricing.g.dart';
@JsonSerializable()

class Pricing {
  double? monthlyPrice, annualPrice;
  String? currency;
  String? date;
  Country? country;


  Pricing(this.monthlyPrice, this.annualPrice, this.currency, this.date,
      this.country);

  factory Pricing.fromJson(Map<String, dynamic> json) =>
      _$PricingFromJson(json);

  Map<String, dynamic> toJson() => _$PricingToJson(this);
}

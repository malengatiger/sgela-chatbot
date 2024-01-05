import 'package:edu_chatbot/data/country.dart';
import 'package:edu_chatbot/data/organization.dart';
import 'package:edu_chatbot/data/pricing.dart';
import 'package:edu_chatbot/data/user.dart';
import 'package:json_annotation/json_annotation.dart';
part 'subscription.g.dart';
@JsonSerializable()

class Subscription {
  Country? country;
  Organization? organization;
  User? user;
  String? date;
  Pricing? pricing;
  int? subscriptionType;
  bool? activeFlag;

  Subscription(this.country, this.organization, this.user, this.date,
      this.pricing, this.subscriptionType, this.activeFlag);

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);
}

import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';
@JsonSerializable()
class User {
  String? firstName, lastName, email, cellphone;
  String? date;

  User(this.firstName, this.lastName, this.email, this.cellphone, this.date);

  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

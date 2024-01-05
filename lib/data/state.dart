import 'package:json_annotation/json_annotation.dart';

import 'country.dart';
part 'state.g.dart';
@JsonSerializable()

class State {
  int? id;
  String? name;
  Country? country;

  State(this.id, this.country);

  factory State.fromJson(Map<String, dynamic> json) => _$StateFromJson(json);

  Map<String, dynamic> toJson() => _$StateToJson(this);
}

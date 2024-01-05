import 'package:json_annotation/json_annotation.dart';

part 'tag.g.dart';
@JsonSerializable()

class Tag {
  int? id;
  String? text;

  int? subjectId;


  Tag(this.id, this.text, this.subjectId);

  factory Tag.fromJson(Map<String, dynamic> json) =>
      _$TagFromJson(json);

  Map<String, dynamic> toJson() => _$TagToJson(this);
}


import 'package:json_annotation/json_annotation.dart';

part 'image_bytes.g.dart';

@JsonSerializable()
class ImageBytes {
  int? examLinkId;
  int? id;
  List<int>? bytes;
  int? imageIndex;


  ImageBytes(this.examLinkId, this.id, this.bytes, this.imageIndex);

  factory ImageBytes.fromJson(Map<String, dynamic> json) =>
      _$ImageBytesFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = _$ImageBytesToJson(this);

    return data;
  }}


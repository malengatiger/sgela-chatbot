import 'package:json_annotation/json_annotation.dart';
part 'youtube_data.g.dart';
@JsonSerializable()

class YouTubeData {
  int? id;
  String? title, description, channelId, videoId, playlistId;
  String? videoUrl, channelUrl, playlistUrl;
  String? thumbnailHigh, thumbnailMedium, thumbnailDefault;
  int? subjectId;


//10711116875
  YouTubeData(
      this.id,
      this.title,
      this.description,
      this.channelId,
      this.videoId,
      this.playlistId,
      this.videoUrl,
      this.channelUrl,
      this.playlistUrl,
      this.thumbnailHigh,
      this.thumbnailMedium,
      this.thumbnailDefault,
      this.subjectId);

  factory YouTubeData.fromJson(Map<String, dynamic> json) =>
      _$YouTubeDataFromJson(json);

  Map<String, dynamic> toJson() => _$YouTubeDataToJson(this);

  static const String VIDEO = "https://www.youtube.com/watch?v=";
  static const String CHANNEL = "https://www.youtube.com/channel/";
  static const String PLAYLIST = "https://www.youtube.com/playlist?list=";
}


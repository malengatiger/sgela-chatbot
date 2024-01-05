// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YouTubeData _$YouTubeDataFromJson(Map<String, dynamic> json) => YouTubeData(
      json['id'] as int?,
      json['title'] as String?,
      json['description'] as String?,
      json['channelId'] as String?,
      json['videoId'] as String?,
      json['playlistId'] as String?,
      json['videoUrl'] as String?,
      json['channelUrl'] as String?,
      json['playlistUrl'] as String?,
      json['thumbnailHigh'] as String?,
      json['thumbnailMedium'] as String?,
      json['thumbnailDefault'] as String?,
      json['subjectId'] as int?,
    );

Map<String, dynamic> _$YouTubeDataToJson(YouTubeData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'channelId': instance.channelId,
      'videoId': instance.videoId,
      'playlistId': instance.playlistId,
      'videoUrl': instance.videoUrl,
      'channelUrl': instance.channelUrl,
      'playlistUrl': instance.playlistUrl,
      'thumbnailHigh': instance.thumbnailHigh,
      'thumbnailMedium': instance.thumbnailMedium,
      'thumbnailDefault': instance.thumbnailDefault,
      'subjectId': instance.subjectId,
    };

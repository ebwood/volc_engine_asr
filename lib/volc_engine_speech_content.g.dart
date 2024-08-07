// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volc_engine_speech_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VolcSpeechContent _$VolcSpeechContentFromJson(Map<String, dynamic> json) =>
    VolcSpeechContent(
      type: $enumDecode(_$VolcSpeechContentTypeEnumMap, json['type']),
      text: json['text'] as String? ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
      isRecording: json['isRecording'] as bool? ?? true,
    );

Map<String, dynamic> _$VolcSpeechContentToJson(VolcSpeechContent instance) =>
    <String, dynamic>{
      'type': _$VolcSpeechContentTypeEnumMap[instance.type]!,
      'text': instance.text,
      'duration': instance.duration,
      'volume': instance.volume,
      'isRecording': instance.isRecording,
    };

const _$VolcSpeechContentTypeEnumMap = {
  VolcSpeechContentType.volume: 0,
  VolcSpeechContentType.text: 1,
  VolcSpeechContentType.recordStatus: 2,
};

import 'package:json_annotation/json_annotation.dart';

part 'volc_engine_speech_content.g.dart';

@JsonSerializable()
class VolcSpeechContent {
  VolcSpeechContent({
    required this.type,
    this.text = '',
    this.duration = 0,
    this.volume = 0.0,
    this.isRecording = true,
  });
  final VolcSpeechContentType type;
  final String text;
  final int duration;
  final double volume;
  final bool isRecording;

  factory VolcSpeechContent.fromJson(Map<String, dynamic> json) =>
      _$VolcSpeechContentFromJson(json);
  Map<String, dynamic> toJson() => _$VolcSpeechContentToJson(this);
}

enum VolcSpeechContentType {
  @JsonValue(0)
  volume,
  @JsonValue(1)
  text,
  @JsonValue(2)
  recordStatus
}

import 'package:json_annotation/json_annotation.dart';

part 'volc_engine_init_param.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class VolcEngineInitParam {
  VolcEngineInitParam({
    required this.userId,
    required this.deviceId,
    required this.debug,
    String? debugDir,
    required this.appVersion,
    required this.appId,
    required String token,
    required this.websocketAddress,
    required this.websocketUri,
    required this.websocketCluster,
  })  : // token = 'Bearer;$token',
        // 只有在调试模式才保存调试日志
        debugDir = debug ? debugDir : null;
  final String userId;
  final String deviceId;
  final bool debug;
  final String? debugDir;
  final String appVersion;
  final String appId;
  final String token;
  final String websocketAddress;
  final String websocketUri;
  final String websocketCluster;

  factory VolcEngineInitParam.fromJson(Map<String, dynamic> json) =>
      _$VolcEngineInitParamFromJson(json);
  Map<String, dynamic> toJson() => _$VolcEngineInitParamToJson(this);
}

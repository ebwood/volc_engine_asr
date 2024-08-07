// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volc_engine_init_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VolcEngineInitParam _$VolcEngineInitParamFromJson(Map<String, dynamic> json) =>
    VolcEngineInitParam(
      userId: json['user_id'] as String,
      deviceId: json['device_id'] as String,
      debug: json['debug'] as bool,
      debugDir: json['debug_dir'] as String?,
      appVersion: json['app_version'] as String,
      appId: json['app_id'] as String,
      token: json['token'] as String,
      websocketAddress: json['websocket_address'] as String,
      websocketUri: json['websocket_uri'] as String,
      websocketCluster: json['websocket_cluster'] as String,
    );

Map<String, dynamic> _$VolcEngineInitParamToJson(
        VolcEngineInitParam instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'device_id': instance.deviceId,
      'debug': instance.debug,
      'debug_dir': instance.debugDir,
      'app_version': instance.appVersion,
      'app_id': instance.appId,
      'token': instance.token,
      'websocket_address': instance.websocketAddress,
      'websocket_uri': instance.websocketUri,
      'websocket_cluster': instance.websocketCluster,
    };

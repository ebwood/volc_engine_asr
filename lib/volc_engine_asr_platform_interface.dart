import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:volc_engine_asr/volc_engine_asr.dart';
import 'package:volc_engine_asr/volc_engine_init_param.dart';
import 'package:volc_engine_asr/volc_engine_speech_content.dart';

import 'volc_engine_asr_method_channel.dart';

abstract class VolcEngineAsrPlatform extends PlatformInterface {
  /// Constructs a VolcEngineAsrPlatform.
  VolcEngineAsrPlatform() : super(token: _token);

  static final Object _token = Object();

  static VolcEngineAsrPlatform _instance = MethodChannelVolcEngineAsr();

  /// The default instance of [VolcEngineAsrPlatform] to use.
  ///
  /// Defaults to [MethodChannelVolcEngineAsr].
  static VolcEngineAsrPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VolcEngineAsrPlatform] when
  /// they register themselves.
  static set instance(VolcEngineAsrPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> init(VolcEngineInitParam params) async {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future startRecord({bool autoStop = false, String? recordDir}) async {
    throw UnimplementedError('startRecord() has not been implemented.');
  }

  Future stopRecord() async {
    throw UnimplementedError('stopRecord() has not been implemented.');
  }

  Future destroy() async {
    throw UnimplementedError('destroy() has not been implemented.');
  }

  Stream<VolcSpeechContent?> get speechStream;
  Stream<RecordContentType> get textStream;
  Stream<double> get volumeStream;
  Stream<RecordStatusType> get recordStatusStream;
}

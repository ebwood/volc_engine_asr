import 'package:flutter_test/flutter_test.dart';
import 'package:volc_engine_asr/volc_engine_asr.dart';
import 'package:volc_engine_asr/volc_engine_asr_platform_interface.dart';
import 'package:volc_engine_asr/volc_engine_asr_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:volc_engine_asr/volc_engine_init_param.dart';
import 'package:volc_engine_asr/volc_engine_speech_content.dart';

class MockVolcEngineAsrPlatform
    with MockPlatformInterfaceMixin
    implements VolcEngineAsrPlatform {
  @override
  Future destroy() async {}

  @override
  Future<bool> init(VolcEngineInitParam params) async {
    return true;
  }

  @override
  Stream<VolcSpeechContent> get speechStream =>
      Stream<VolcSpeechContent>.fromIterable([]);

  @override
  Future stopRecord() async {}

  @override
  Stream<RecordContentType> get textStream => Stream<RecordContentType>.fromIterable([]);

  @override
  Stream<double> get volumeStream => Stream<double>.fromIterable([]);

  @override
  Future startRecord({bool autoStop = false, String? recordDir}) async {}

  @override
  Stream<RecordStatusType> get recordStatusStream => Stream.fromIterable([]);
}

void main() {
  final VolcEngineAsrPlatform initialPlatform = VolcEngineAsrPlatform.instance;

  test('$MethodChannelVolcEngineAsr is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVolcEngineAsr>());
  });

  test('getPlatformVersion', () async {
    VolcEngineAsr volcEngineAsrPlugin = VolcEngineAsr();
    MockVolcEngineAsrPlatform fakePlatform = MockVolcEngineAsrPlatform();
    VolcEngineAsrPlatform.instance = fakePlatform;
  });
}

import 'package:volc_engine_asr/volc_engine_init_param.dart';
import 'package:volc_engine_asr/volc_engine_speech_content.dart';

import 'volc_engine_asr_platform_interface.dart';

typedef RecordStatusType = ({bool isRecording, String? recordFile});
typedef RecordContentType = ({String text, int duration});

class VolcEngineAsr {
  Future<bool> init(VolcEngineInitParam params) {
    return VolcEngineAsrPlatform.instance.init(params);
  }

  Future startRecord({bool autoStop = false}) {
    return VolcEngineAsrPlatform.instance.startRecord(autoStop: autoStop);
  }

  Future stopRecord() {
    return VolcEngineAsrPlatform.instance.stopRecord();
  }

  Future destroy() {
    return VolcEngineAsrPlatform.instance.destroy();
  }

  Stream<VolcSpeechContent?> get speechStream =>
      VolcEngineAsrPlatform.instance.speechStream;
  Stream<RecordContentType> get textAndDurationStream =>
      VolcEngineAsrPlatform.instance.textAndDurationStream;
  Stream<double> get volumeStream =>
      VolcEngineAsrPlatform.instance.volumeStream;
  Stream<RecordStatusType> get statusAndFileStream =>
      VolcEngineAsrPlatform.instance.statusAndFileStream;
  String? get recordFile => VolcEngineAsrPlatform.instance.recordFile;
}

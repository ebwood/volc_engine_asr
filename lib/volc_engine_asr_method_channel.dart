import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:volc_engine_asr/volc_engine_asr.dart';
import 'package:volc_engine_asr/volc_engine_init_param.dart';
import 'package:volc_engine_asr/volc_engine_speech_content.dart';
import 'package:collection/collection.dart';

import 'volc_engine_asr_platform_interface.dart';

/// An implementation of [VolcEngineAsrPlatform] that uses method channels.
class MethodChannelVolcEngineAsr extends VolcEngineAsrPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('volc_engine_asr');

  @visibleForTesting
  final eventChannel = const EventChannel('volc_engine_asr_speech');

  @override
  late final Stream<VolcSpeechContent?> speechStream;

  String? _recordFileDir;

  MethodChannelVolcEngineAsr() {
    speechStream = eventChannel.receiveBroadcastStream().map((data) {
      VolcSpeechContent? content;
      try {
        content = VolcSpeechContent.fromJson(jsonDecode(data));
      } catch (e) {
        print('数据解析失败: $e');
      }
      return content;
    });
  }

  @override
  Future<bool> init(VolcEngineInitParam params) async {
    // 删除上一次的录音文件
    // String recordDir =
    //     await getTemporaryDirectory().then((value) => '${value.path}/asr');
    // if (Directory(recordDir).existsSync()) {
    //   Directory(recordDir).deleteSync(recursive: false);
    // }

    try {
      final initResult =
          await methodChannel.invokeMethod('init', params.toJson());
      print("asr引擎初始化结果: $initResult");
      return true;
    } catch (e) {
      print('asr引擎初始化失败: $e');
      return false;
    }
  }

  @override
  Future startRecord({bool autoStop = false, String? recordDir}) async {
    recordDir ??= await getTemporaryDirectory()
        .then((value) => '${value.path}/asr/${const Uuid().v4()}');

    _recordFileDir = recordDir;
    Directory dir = Directory(recordDir!);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    print("开始录音: $recordDir");
    try {
      await methodChannel.invokeMethod(
          'startRecord', {'auto_stop': autoStop, 'record_dir': recordDir});
    } catch (e) {
      print('asr引擎开始录音失败: $e');
    }
  }

  @override
  Future stopRecord() async {
    try {
      await methodChannel.invokeMethod('stopRecord');
    } catch (e) {
      print('asr引擎结束录音失败: $e');
    }
  }

  @override
  Future destroy() async {
    try {
      await methodChannel.invokeMethod('destroy');
    } catch (e) {
      print('asr引擎销毁失败: $e');
    }
  }

  @override
  Stream<RecordContentType> get textAndDurationStream => speechStream
      .where((e) => e != null && e.type == VolcSpeechContentType.text)
      .cast<VolcSpeechContent>()
      .map((e) => (text: e.text, duration: e.duration));

  @override
  Stream<double> get volumeStream => speechStream
      .where((e) => e != null && e.type == VolcSpeechContentType.volume)
      .cast<VolcSpeechContent>()
      .map((e) => e.volume);

  @override
  Stream<RecordStatusType> get statusAndFileStream => speechStream
          .where(
              (e) => e != null && e.type == VolcSpeechContentType.recordStatus)
          .cast<VolcSpeechContent>()
          .map((e) {
        String? path = recordFile;
        return (isRecording: e.isRecording, recordFile: path);
      });

  @override
  String? get recordFile {
    if (_recordFileDir == null) {
      return null;
    }
    Directory dir = Directory(_recordFileDir!);
    if (!dir.existsSync()) {
      return null;
    }
    final result = dir.listSync().firstOrNull?.path;
    return result;
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:volc_engine_asr/volc_engine_asr.dart';
import 'package:volc_engine_asr/volc_engine_init_param.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _volcEngineAsrPlugin = VolcEngineAsr();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String filePath =
        await getApplicationCacheDirectory().then((value) => value.path);
    print('filePath: $filePath');
    _volcEngineAsrPlugin.init(VolcEngineInitParam(
        userId: '5977913899',
        deviceId: 'device_android',
        debug: !kReleaseMode,
        debugDir: filePath,
        appVersion: '1.0.0',
        appId: dotenv.get("ASR_APP_ID"),
        token: dotenv.get("ASR_TOKEN"),
        websocketAddress: dotenv.get("ASR_WEBSOCKET_ADDRESS"),
        websocketUri: dotenv.get("ASR_WEBSOCKET_URI"),
        websocketCluster: dotenv.get("ASR_WEBSOCKET_CLUSTER")));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                onPressed: () async {
                  if (await Permission.microphone.request().isGranted) {
                    _volcEngineAsrPlugin.startRecord(autoStop: false);
                  }
                },
                icon: const Icon(Icons.start)),
            IconButton(
                onPressed: () async {
                  await _volcEngineAsrPlugin.stopRecord();
                },
                icon: const Icon(Icons.stop)),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                StreamBuilder<RecordContentType>(
                  stream: _volcEngineAsrPlugin.textAndDurationStream,
                  builder: (context, snapshot) {
                    final value = snapshot.data;
                    return Text(
                        '内容: ${value?.text ?? ''}, 时长: ${value?.duration ?? 0}');
                  },
                ),
                StreamBuilder<double>(
                  stream: _volcEngineAsrPlugin.volumeStream,
                  builder: (context, snapshot) {
                    return Text('音量: ${snapshot.data ?? ''}');
                  },
                ),
                StreamBuilder<RecordStatusType>(
                  stream: _volcEngineAsrPlugin.statusAndFileStream,
                  builder: (context, snapshot) {
                    String? path = snapshot.data?.recordFile;

                    if (path == null || !File(path).existsSync()) {
                      path = null;
                    }
                    return Text(
                        '是否录音中: ${snapshot.data ?? false}\n文件路径: $path');
                  },
                ),
              ],
            ))
          ],
        ),
      ),
    );
  }
}

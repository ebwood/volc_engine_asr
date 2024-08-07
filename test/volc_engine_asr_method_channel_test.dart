import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volc_engine_asr/volc_engine_asr_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelVolcEngineAsr platform = MethodChannelVolcEngineAsr();
  const MethodChannel channel = MethodChannel('volc_engine_asr');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

}

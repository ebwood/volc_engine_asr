import Flutter
import UIKit
import SpeechEngineAsrToB

struct AudioRecognitionResult: Codable {
    let audioInfo: AudioInfo
    let result: RecognitionResult
    
    enum CodingKeys: String, CodingKey {
        case audioInfo = "audio_info"
        case result
    }
    
    func finish() -> Bool {
        let duration = audioInfo.duration
        if let lastUtterance = result.utterances.last(where: { $0.definite }) {
            let lastUtteranceTime = lastUtterance.endTime
            let lastUtteranceInterval = duration - lastUtteranceTime;
            return lastUtteranceInterval > 1000
        }
        return false
    }
}

struct AudioInfo: Codable {
    let duration: Int
}

struct RecognitionResult: Codable {
    let text: String
    let utterances: [Utterance]
}

struct Utterance: Codable {
    let definite: Bool
    let endTime: Int
    let startTime: Int
    let text: String
    let words: [Word]?
    
    enum CodingKeys: String, CodingKey {
        case definite
        case endTime = "end_time"
        case startTime = "start_time"
        case text
        case words
    }
}

struct Word: Codable {
    let endTime: Int
    let startTime: Int
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case endTime = "end_time"
        case startTime = "start_time"
        case text
    }
}

public class VolcEngineAsrPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, SpeechEngineDelegate {
    
    private var eventSink: FlutterEventSink?
    private var speechEngine: SpeechEngine?
    private var engineStarted: Bool = false
    private var finishTalkingTimestamp: Int64 = -1
    private var autoStop: Bool = false
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        SpeechEngine.prepareEnvironment()
        
        let channel = FlutterMethodChannel(name: "volc_engine_asr", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "volc_engine_asr_speech", binaryMessenger: registrar.messenger())
        let instance = VolcEngineAsrPlugin()
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            initEngine(params: call.arguments as! [String: Any], result: result)
        case "startRecord":
            autoStop = (call.arguments as! [String: Any])["auto_stop"] as! Bool? == true
            let recordDir = (call.arguments as! [String: Any])["record_dir"] as! String?
            startRecord(autoStop: autoStop, recordDir: recordDir, result: result)
        case "stopRecord":
            stopRecord(result: result)
        case "destroy":
            destroySpeechEngine()
            result("Engine is destroyed successfully")
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    // 初始化引擎
    private func initEngine(params: [String: Any], result: FlutterResult) {
        if (speechEngine != nil) {
            result("Engine is already created")
            return;
        }
        let uid: String = params["user_id"] as! String
        let deviceId: String = params["device_id"] as! String
        let appVersion: String = params["app_version"] as! String
        let isDebug: Bool = params["debug"] as! Bool? == true
        let debugDir: String? = params["debug_dir"] as? String
        let appId: String = params["app_id"] as! String
        let token: String = params["token"] as! String
        let websocketAddress =
        params["websocket_address"] as! String
        let websocketUri = params["websocket_uri"] as! String
        let websocketCluster =
        params["websocket_cluster"] as! String
        
        print("初始化参数: \(params)")
        
        speechEngine = SpeechEngine()
        let engine: SpeechEngine = speechEngine!
        let createResult = engine.createEngine(with: self)
        if (!createResult) {
            destroySpeechEngine()
            result(FlutterError(code: "initEngine", message: "fail", details: "fail"))
            return
        }
        
        engine.setStringParam(SE_ASR_ENGINE, forKey: SE_PARAMS_KEY_ENGINE_NAME_STRING)
        engine.setStringParam(uid, forKey: SE_PARAMS_KEY_UID_STRING)
        engine.setStringParam(deviceId, forKey: SE_PARAMS_KEY_DEVICE_ID_STRING)
        engine.setStringParam(appVersion, forKey: "app_version")
        
        engine.setStringParam(isDebug ? SE_LOG_LEVEL_DEBUG : SE_LOG_LEVEL_WARN, forKey: SE_PARAMS_KEY_LOG_LEVEL_STRING)
        
        if (debugDir != nil){
            engine.setStringParam(debugDir!, forKey: SE_PARAMS_KEY_DEBUG_PATH_STRING)
        }
        
        //【必须配置】鉴权相关：AppID
        engine.setStringParam(appId, forKey: SE_PARAMS_KEY_APP_ID_STRING)
        //【必须配置】鉴权相关：Token
        engine.setStringParam(token, forKey: SE_PARAMS_KEY_APP_TOKEN_STRING)
        //【必须配置】识别服务ADDRESS
        engine.setStringParam(
            websocketAddress,
            forKey: SE_PARAMS_KEY_ASR_ADDRESS_STRING
        )
        //【必须配置】识别服务URI
        engine.setStringParam(
            websocketUri,
            forKey: SE_PARAMS_KEY_ASR_URI_STRING
        )
        //【必须配置】识别服务CLUSTER
        engine.setStringParam(
            websocketCluster,
            forKey: SE_PARAMS_KEY_ASR_CLUSTER_STRING
        )
        
        //【必需配置】识别服务资源信息ResourceId，参考大模型流式语音识别API--鉴权
        engine.setStringParam(
            "volc.bigasr.sauc.duration",
            forKey: SE_PARAMS_KEY_RESOURCE_ID_STRING
        )
        //【必需配置】协议类型，BigAsr协议需设置为Seed
        engine.setIntParam(Int(SEProtocolTypeSeed.rawValue), forKey: SE_PARAMS_KEY_PROTOCOL_TYPE_INT)
        
        //【可选配置】建连超时时间，建议使用默认值
        engine.setIntParam(12000, forKey: SE_PARAMS_KEY_ASR_CONN_TIMEOUT_INT)
        //【可选配置】数据接收超时时间，建议使用默认值
        engine.setIntParam(8000, forKey: SE_PARAMS_KEY_ASR_RECV_TIMEOUT_INT)
        //【可选配置】请求断连后是否尝试重连，默认0不重连
        engine.setIntParam(0, forKey: SE_PARAMS_KEY_ASR_MAX_RETRY_TIMES_INT)
        
        engine.setStringParam(SE_RECORDER_TYPE_RECORDER, forKey:
                                SE_PARAMS_KEY_RECORDER_TYPE_STRING)
        
        //【可选配置】是否开启顺滑(DDC)
        engine.setBoolParam(true, forKey: SE_PARAMS_KEY_ASR_ENABLE_DDC_BOOL)
        //【可选配置】是否开启文字转数字(ITN)
        //                    engine.setBoolParam(false, forKey: SE_PARAMS_KEY_ASR_ENABLE_ITN_BOOL)
        //【可选配置】是否开启标点
        engine.setBoolParam(true, forKey: SE_PARAMS_KEY_ASR_SHOW_NLU_PUNC_BOOL)
        //【可选配置】设置识别语种
        //        engine.setStringParam("en-US", forKey: SE_PARAMS_KEY_ASR_LANGUAGE_STRING)
        //【可选配置】是否启用云端自动判停
        engine.setBoolParam(false, forKey: SE_PARAMS_KEY_ASR_AUTO_STOP_BOOL)
        //【可选配置】是否隐藏句尾标点
        engine.setBoolParam(false, forKey: SE_PARAMS_KEY_ASR_DISABLE_END_PUNC_BOOL)
        
        //【可选配置】控制识别结果返回的形式，全量返回或增量返回，默认为全量
        engine.setStringParam(
            SE_ASR_RESULT_TYPE_FULL,
            forKey: SE_PARAMS_KEY_ASR_RESULT_TYPE_STRING
        )
        
        //【可选配置】设置VAD头部静音时长，用户多久没说话视为空音频，即静音检测时长
        engine.setIntParam(1000, forKey: SE_PARAMS_KEY_ASR_VAD_START_SILENCE_TIME_INT)
        //【可选配置】设置VAD尾部静音时长，用户说话后停顿多久视为说话结束，即自动判停时长
        engine.setIntParam(500, forKey: SE_PARAMS_KEY_ASR_VAD_END_SILENCE_TIME_INT);
        //【可选配置】设置VAD模式，用于定制VAD场景，默认为空
        //        engine.setStringParam("", forKey: SE_PARAMS_KEY_ASR_VAD_MODE_STRING);
        //        //【可选配置】用户音频输入最大时长，仅一句话识别场景生效，单位毫秒，默认为 60000ms.
        //        engine.setIntParam(60000, forKey: SE_PARAMS_KEY_VAD_MAX_SPEECH_DURATION_INT);
        //【可选配置】最大录音时长，默认60000ms，如果使用场景超过60s请修改该值，-1为不限制录音时长
        engine.setIntParam(60000, forKey: SE_PARAMS_KEY_VAD_MAX_SPEECH_DURATION_INT)
        
        // 大模型语音识别模拟自动判停，传入判停时间字段
        engine.setStringParam("{\"vad_segment_duration\":800}", forKey: SE_PARAMS_KEY_ASR_REQ_PARAMS_STRING)
        
        
        //【可选配置】控制是否返回录音音量，在 APP 需要显示音频波形时可以启用
        engine.setBoolParam(
            true, forKey: SE_PARAMS_KEY_ENABLE_GET_VOLUME_BOOL)
        
        //【可选配置】是否需要返回录音音量
        engine.setBoolParam(
            true,
            forKey: SE_PARAMS_KEY_ENABLE_GET_VOLUME_BOOL
        )
        
        let ret = engine.initEngine()
        if (ret != SENoError) {
            let errMessage = "Init Engine Fail: $ret"
            print("engine init result: \(errMessage)")
            destroySpeechEngine()
            result(FlutterError(code: "\(ret)", message: errMessage, details: errMessage))
            return
        }
        
        result("Init engine success")
    }
    
    private func destroySpeechEngine() {
        if (speechEngine != nil) {
            speechEngine!.send(SEDirectiveSyncStopEngine, data: "")
            speechEngine!.destroy()
            speechEngine = nil
        }
    }
    
    // 开始录音
    private func startRecord(autoStop: Bool, recordDir: String?, result: FlutterResult) {
        if (speechEngine == nil) {
            result(FlutterError(code: "startRecord", message: "fail", details: "fail"))
            return
        }
        
        let engine = speechEngine!
        // 录音文件地址
        if (recordDir != nil) {
            engine.setStringParam(recordDir!, forKey: SE_PARAMS_KEY_ASR_REC_PATH_STRING)
        }
        engine.setBoolParam(autoStop, forKey: SE_PARAMS_KEY_ASR_AUTO_STOP_BOOL)
        var ret = engine.send(SEDirectiveSyncStopEngine, data: "")
        if (ret != SENoError) {
            print("send directive syncStop failed: \(ret)")
            result(FlutterError(code: "startRecord fail", message: "fail", details: "fail"))
            return
        }
        ret = engine.send(SEDirectiveStartEngine, data: "")
        if (ret == SERecCheckEnvironmentFailed) {
            print("please check your record audio permission")
            result(FlutterError(code: "startRecord fail", message: "please check your record audio permission", details: "please check your record audio permission"))
            return
        } else if (ret != SENoError) {
            print("send directive failed: \(ret)")
            result(FlutterError(code: "startRecord fail", message: "send directive failed: \(ret)", details: "send directive failed: \(ret)"))
            return
        }
        print("start recording")
        result("startRecord successfully")
    }
    
    // 结束录音
    private func stopRecord(result: FlutterResult) {
        finishTalkingTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
        if (speechEngine == nil) {
            result(FlutterError(code: "stopEngine fail", message: "fail", details: "fail"))
            return
        }
        
        let engine = speechEngine!
        engine.send(SEDirectiveFinishTalking, data: "")
        result("stopRecord successfully")
    }
    
    public func onMessage(with type: SEMessageType, andData data: Data) {
        switch type {
        case SEEngineStart:
            // Callback: 引擎启动成功回调
            print("Callback: 引擎启动成功");
            speechStart()
        case SEEngineStop:
            // Callback: 引擎关闭回调
            print("Callback: 引擎关闭");
            speechStop()
        case SEEngineError:
            // Callback: 错误信息回调
            print("Callback: 错误信息: %@", data);
            speechError(data: data)
        case SEConnectionConnected:
            print("Callback: 建连成功");
            break;
        case SEAsrPartialResult:
            // Callback: ASR 当前请求的部分结果回调
            print("Callback: ASR 当前请求的部分结果");
            speechAsrResult(data: data, isFinal: false)
        case SEFinalResult:
            // Callback: ASR 当前请求最终结果回调
            print("Callback: ASR 当前请求最终结果");
            speechAsrResult(data: data, isFinal: true)
        case SEVolumeLevel:
            // Callback: 录音音量回调
            print("Callback: 录音音量");
            let volume = Double(String(data: data, encoding: .utf8) ?? "0.0") ?? 0.0
            DispatchQueue.main.async { [weak self] in
                self?.eventSink?(VolcEngineSpeechContent.volume(volume: volume).toJson())
            }
            break;
        default:
            break;
        }
    }
    
    private func speechStart() {
        engineStarted = true
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(VolcEngineSpeechContent.recordStatus(isRecording: true).toJson())
        }
    }
    
    private func speechStop() {
        if !engineStarted {
            return
        }
        engineStarted = false
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(VolcEngineSpeechContent.recordStatus(isRecording: false).toJson())
        }
    }
    
    private func speechError(data: Data) {
        do {
            // 使用 JSONSerialization 反序列化数据
            if let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print(jsonDict)
                if (jsonDict.keys.contains("err_code") && jsonDict.keys.contains("err_msg")) {
                    //                    stopEngine()
                }
            }
        } catch {
            print("Error deserializing JSON: \(error)")
        }
    }
    
    private func stopEngine() {
        if (speechEngine == nil) {
            return
        }
        speechEngine!.send(SEDirectiveStopEngine, data: "")
    }
    
    private func speechAsrResult(data: Data, isFinal: Bool) {
        DispatchQueue.main.async { [weak self] in
            do {
                // 解析 JSON 数据
                let model = try JSONDecoder().decode(AudioRecognitionResult.self, from: data)
                let duration: Int = model.audioInfo.duration
                let text = model.result.text
                
                print("Text: \(text), duration: \(duration)")
                if (!text.isEmpty) {
                    self?.eventSink?(VolcEngineSpeechContent.text(text: text, duration: duration).toJson())
                    if self?.autoStop == true, model.finish() {
                        self?.speechStop()
                    }
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
}

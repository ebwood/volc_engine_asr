package com.wood.volc_engine_asr

import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Environment
import android.util.Log

import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import com.bytedance.speech.speechengine.SpeechEngine
import com.bytedance.speech.speechengine.SpeechEngineDefines
import com.bytedance.speech.speechengine.SpeechEngineGenerator

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONException
import org.json.JSONObject
import java.io.File

data class AudioRecognitionResult(
    @SerializedName("audio_info") val audioInfo: AudioInfo,
    val result: RecognitionResult
) {
    companion object {
        fun parse(jsonString: String): AudioRecognitionResult? {
            return try {
                Gson().fromJson(jsonString, AudioRecognitionResult::class.java)
            } catch (e: Exception) {
                println("Error parsing JSON: ${e.message}")
                null
            }
        }
    }
}

data class AudioInfo(
    val duration: Int
)

data class RecognitionResult(
    val text: String,
    val utterances: List<Utterance>
)

data class Utterance(
    val definite: Boolean,
    @SerializedName("end_time") val endTime: Int,
    @SerializedName("start_time") val startTime: Int,
    val text: String,
    val words: List<Word>?
)

data class Word(
    @SerializedName("end_time") val endTime: Int,
    @SerializedName("start_time") val startTime: Int,
    val text: String
)

/** VolcEngineAsrPlugin */
class VolcEngineAsrPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler,
    ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    companion object {
        const val TAG = "VolcEngineAsrPlugin"
    }

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var speechEngine: SpeechEngine? = null
    private lateinit var applicationContext: Context
    private var activity: Activity? = null

    //    private lateinit var streamRecorder: SpeechStreamRecorder
    private var mEngineStarted: Boolean = false

    // Statistics
    private var mFinishTalkingTimestamp: Long = -1

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext

        SpeechEngineGenerator.PrepareEnvironment(
            flutterPluginBinding.applicationContext,
            flutterPluginBinding.applicationContext as Application
        )


        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "volc_engine_asr")
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "volc_engine_asr_speech")

        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        destroySpeechEngine()
        channel.setMethodCallHandler(null)
    }

    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "init" -> {
                init(call.arguments as Map<String, Any?>, result)
            }

            "startRecord" -> {
                val autoStop = (call.arguments as Map<String, Any?>)["auto_stop"] as Boolean?
                val recordDir =
                    (call.arguments as Map<String, Any?>)["record_dir"] as String? //?: getDebugPath()
                startRecord(autoStop == true, recordDir, result)
            }

            "stopRecord" -> {
                stopRecord(result)
            }

            "destroy" -> {
                destroySpeechEngine()
                result.success("Engine is destroyed successfully")
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?
    ) {
        Log.i(TAG, "EventChannel onListen")
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        Log.i(TAG, "EventChannel onCancel")
    }


    // 初始化
    private fun init(params: Map<String, Any?>, result: Result) {
        if (speechEngine != null) {
            result.success("Engine is already created")
            return
        }
        val uid: String = params["user_id"] as String
        val deviceId: String = params["device_id"] as String
        val appVersion: String = params["app_version"] as String
        val isDebug: Boolean = params["debug"] as Boolean? == true
        val debugDir: String? = params["debug_dir"] as String? //?: getDebugPath()
        val appId: String = params["app_id"] as String
        val token: String = params["token"] as String
        val websocketAddress =
            params["websocket_address"] as String
        val websocketUri = params["websocket_uri"] as String
        val websocketCluster =
            params["websocket_cluster"] as String

        Log.i("init params", params.toString())

        speechEngine = SpeechEngineGenerator.getInstance()

        val engine: SpeechEngine = speechEngine!!
        engine.createEngine()

        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_ENGINE_NAME_STRING,
            SpeechEngineDefines.ASR_ENGINE
        )

        engine.setOptionString(SpeechEngineDefines.PARAMS_KEY_UID_STRING, uid)
        engine.setOptionString(SpeechEngineDefines.PARAMS_KEY_DEVICE_ID_STRING, deviceId)
        engine.setOptionString(SpeechEngineDefines.PARAMS_KEY_APP_VERSION_STRING, appVersion)
        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_LOG_LEVEL_STRING,
            if (isDebug) SpeechEngineDefines.LOG_LEVEL_TRACE else SpeechEngineDefines.LOG_LEVEL_WARN
        )

        if (debugDir != null)
            engine.setOptionString(SpeechEngineDefines.PARAMS_KEY_DEBUG_PATH_STRING, debugDir)
        // 录音文件地址
//        engine.setOptionString(SpeechEngineDefines.PARAMS_KEY_ASR_REC_PATH_STRING, debugDir)

        //【必须配置】鉴权相关：AppID
        engine.setOptionString(SpeechEngineDefines.PARAMS_KEY_APP_ID_STRING, appId)
        //【必须配置】鉴权相关：Token
        engine.setOptionString(SpeechEngineDefines.PARAMS_KEY_APP_TOKEN_STRING, token)
        //【必须配置】识别服务ADDRESS
        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_ASR_ADDRESS_STRING,
            websocketAddress
        )
        //【必须配置】识别服务URI
        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_ASR_URI_STRING,
            websocketUri
        )
        //【必须配置】识别服务CLUSTER
        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_ASR_CLUSTER_STRING,
            websocketCluster
        )
        //【必需配置】识别服务资源信息ResourceId，参考大模型流式语音识别API--鉴权
        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_RESOURCE_ID_STRING,
            "volc.bigasr.sauc.duration"
        );
        //【必需配置】协议类型，大模型流式识别协议需设置为Seed，
        engine.setOptionInt(
            SpeechEngineDefines.PARAMS_KEY_PROTOCOL_TYPE_INT,
            SpeechEngineDefines.PROTOCOL_TYPE_SEED
        );

        //【可选配置】建连超时时间，建议使用默认值
        engine.setOptionInt(SpeechEngineDefines.PARAMS_KEY_ASR_CONN_TIMEOUT_INT, 12000)
        //【可选配置】数据接收超时时间，建议使用默认值
        engine.setOptionInt(SpeechEngineDefines.PARAMS_KEY_ASR_RECV_TIMEOUT_INT, 8000)
        //【可选配置】请求断连后是否尝试重连，默认0不重连
        engine.setOptionInt(SpeechEngineDefines.PARAMS_KEY_ASR_MAX_RETRY_TIMES_INT, 0)

        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_RECORDER_TYPE_STRING,
            SpeechEngineDefines.RECORDER_TYPE_RECORDER
        )

        //【可选配置】是否开启顺滑(DDC)
        engine.setOptionBoolean(SpeechEngineDefines.PARAMS_KEY_ASR_ENABLE_DDC_BOOL, true)
        //【可选配置】是否开启文字转数字(ITN)
//        engine.setOptionBoolean(SpeechEngineDefines.PARAMS_KEY_ASR_ENABLE_ITN_BOOL, false)
        //【可选配置】是否开启标点
        engine.setOptionBoolean(SpeechEngineDefines.PARAMS_KEY_ASR_SHOW_NLU_PUNC_BOOL, true)
        //【可选配置】设置识别语种
//        engine.setOptionString(SpeechEngineDefines.PARAMS_KEY_ASR_LANGUAGE_STRING, "en-US")
        //【可选配置】是否启用云端自动判停
        engine.setOptionBoolean(SpeechEngineDefines.PARAMS_KEY_ASR_AUTO_STOP_BOOL, false)
        //【可选配置】是否隐藏句尾标点
        engine.setOptionBoolean(SpeechEngineDefines.PARAMS_KEY_ASR_DISABLE_END_PUNC_BOOL, false)

        //【可选配置】控制识别结果返回的形式，全量返回或增量返回，默认为全量
        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_ASR_RESULT_TYPE_STRING,
            SpeechEngineDefines.ASR_RESULT_TYPE_FULL
        )

        //【可选配置】设置VAD头部静音时长，用户多久没说话视为空音频，即静音检测时长
        engine.setOptionInt(SpeechEngineDefines.PARAMS_KEY_ASR_VAD_START_SILENCE_TIME_INT, 1000)
        //【可选配置】设置VAD尾部静音时长，用户说话后停顿多久视为说话结束，即自动判停时长
        engine.setOptionInt(SpeechEngineDefines.PARAMS_KEY_ASR_VAD_END_SILENCE_TIME_INT, 500);
        //【可选配置】设置VAD模式，用于定制VAD场景，默认为空
//        engine.setOptionString(SpeechEngineDefines.PARAMS_KEY_ASR_VAD_MODE_STRING, "");
//        //【可选配置】用户音频输入最大时长，仅一句话识别场景生效，单位毫秒，默认为 60000ms.
//        engine.setOptionInt(SpeechEngineDefines.PARAMS_KEY_VAD_MAX_SPEECH_DURATION_INT, 60000);
        //【可选配置】最大录音时长，默认60000ms，如果使用场景超过60s请修改该值，-1为不限制录音时长
        engine.setOptionInt(SpeechEngineDefines.PARAMS_KEY_VAD_MAX_SPEECH_DURATION_INT, 60000)


        //【可选配置】控制是否返回录音音量，在 APP 需要显示音频波形时可以启用
        engine.setOptionBoolean(SpeechEngineDefines.PARAMS_KEY_ENABLE_GET_VOLUME_BOOL, true)

        //【可选配置】是否需要返回录音音量
        engine.setOptionBoolean(
            SpeechEngineDefines.PARAMS_KEY_ENABLE_GET_VOLUME_BOOL,
            true
        )

        engine.setOptionString(
            SpeechEngineDefines.PARAMS_KEY_ASR_REQ_PARAMS_STRING,
            "{\"vad_segment_duration\":800}"
        )

        val ret = engine.initEngine()

        if (ret != SpeechEngineDefines.ERR_NO_ERROR) {
            val errMessage = "Init Engine Fail: $ret"
            Log.e("engine init result", errMessage)
            destroySpeechEngine()
            result.error("$ret", errMessage, errMessage)
            return
        }

        engine.setListener(object : SpeechEngine.SpeechListener {
            override fun onSpeechMessage(type: Int, data: ByteArray?, len: Int) {
                this@VolcEngineAsrPlugin.onSpeechMessage(type, data, len)
            }
        })

        Log.i("engine init result", "success")
        result.success("Init Engine Success")
//        streamRecorder = SpeechStreamRecorder()
//        streamRecorder.SetSpeechEngine(engine)
    }

    private fun startRecord(autoStop: Boolean, recordDir: String?, result: Result) {
        if (speechEngine == null) {
            result.error("startRecord", "fail", "fail")
            return
        }
        val engine: SpeechEngine = speechEngine!!
        // 录音文件地址
        if (recordDir != null)
            engine.setOptionString(SpeechEngineDefines.PARAMS_KEY_ASR_REC_PATH_STRING, recordDir)

        engine.setOptionBoolean(SpeechEngineDefines.PARAMS_KEY_ASR_AUTO_STOP_BOOL, autoStop)
        var ret = engine.sendDirective(SpeechEngineDefines.DIRECTIVE_SYNC_STOP_ENGINE, "")
        if (ret != SpeechEngineDefines.ERR_NO_ERROR) {
            Log.e(TAG, "send directive syncStop failed: $ret")
            result.error(TAG, "startRecord fail", "fail")
        } else {
            ret = engine.sendDirective(SpeechEngineDefines.DIRECTIVE_START_ENGINE, "")
            if (ret == SpeechEngineDefines.ERR_REC_CHECK_ENVIRONMENT_FAILED) {
                Log.i(TAG, "please check your record audio permission")
            } else if (ret != SpeechEngineDefines.ERR_NO_ERROR) {
                Log.e(TAG, "send directive failed, $ret")
            } else {
                Log.i(TAG, "start recording")
            }
            result.success("startRecord successfully")
        }
    }

    private fun stopRecord(result: Result) {
        mFinishTalkingTimestamp = System.currentTimeMillis()

        if (speechEngine == null) {
            result.error("stopRecord", "fail", "fail")
            return
        }

        val engine = speechEngine!!
        engine.sendDirective(SpeechEngineDefines.DIRECTIVE_FINISH_TALKING, "")
        result.success("stopRecord successfully")
    }


    private fun onSpeechMessage(type: Int, data: ByteArray?, len: Int) {
        val stdData = String(data ?: ByteArray(0))
        Log.i(TAG, "返回数据: $type, 内容: $stdData")
        when (type) {
            SpeechEngineDefines.MESSAGE_TYPE_ENGINE_START -> {
                // Callback: 引擎启动成功回调
                Log.i(TAG, "Callback: 引擎启动成功: data: $stdData")
                speechStart()
            }

            SpeechEngineDefines.MESSAGE_TYPE_ENGINE_STOP -> {
                // Callback: 引擎关闭回调
                Log.i(TAG, "Callback: 引擎关闭: data: $stdData")
                speechStop(stdData)
            }

            SpeechEngineDefines.MESSAGE_TYPE_ENGINE_ERROR -> {
                // Callback: 错误信息回调
                Log.e(TAG, "Callback: 错误信息: $stdData")
                speechError(stdData)
            }

            SpeechEngineDefines.MESSAGE_TYPE_CONNECTION_CONNECTED -> {
                Log.i(TAG, "Callback: 建连成功: data: $stdData")
            }

            SpeechEngineDefines.MESSAGE_TYPE_PARTIAL_RESULT -> {
                // Callback: ASR 当前请求的部分结果回调
                Log.d(TAG, "Callback: ASR 当前请求的部分结果\n$stdData")
                speechAsrResult(stdData, false)
            }

            SpeechEngineDefines.MESSAGE_TYPE_FINAL_RESULT -> {
                // Callback: ASR 当前请求最终结果回调
                Log.i(TAG, "Callback: ASR 当前请求最终结果: $stdData")
                speechAsrResult(stdData, true)
            }

            SpeechEngineDefines.MESSAGE_TYPE_VOLUME_LEVEL -> {
                // Callback: 录音音量回调
                Log.d(TAG, "Callback: 录音音量: $stdData")
                // EventChannel要运行在主线程
                activity?.runOnUiThread {
                    eventSink?.success(
                        VolcEngineSpeechContent.volume(
                            stdData.toDoubleOrNull() ?: .0
                        ).toJson()
                    )
                }
            }

            SpeechEngineDefines.MESSAGE_TYPE_ASR_AUDIO_DATA -> {
                Log.d(TAG, "录音文件数据: $stdData")
            }

            SpeechEngineDefines.MESSAGE_TYPE_ASR_ALL_AUDIO_DATA -> {
                Log.d(TAG, "录音文件所有数据: $stdData")
            }

            else -> {}
        }
    }

    private fun destroySpeechEngine() {
        if (speechEngine != null) {
            speechEngine!!.sendDirective(SpeechEngineDefines.DIRECTIVE_SYNC_STOP_ENGINE, "")
            speechEngine!!.destroyEngine()
            speechEngine = null
        }
    }

    private fun getDebugPath(): String {
        val state = Environment.getExternalStorageState()
        if (Environment.MEDIA_MOUNTED == state) {
            Log.d(TAG, "External storage can be read and write.")
        } else {
            Log.e(TAG, "External storage can't write.")
            return ""
        }
        var debugDir: File? = applicationContext.getExternalFilesDir(null)
        if (debugDir == null) {
            return ""
        }
        if (!debugDir.exists()) {
            if (debugDir.mkdirs()) {
                Log.d(TAG, "Create debug path successfully.")
            } else {
                Log.e(TAG, "Failed to create debug path.")
                return ""
            }
        }
        return debugDir.getAbsolutePath()
    }

    private fun speechStart() {
        mEngineStarted = true
        activity?.runOnUiThread {
            eventSink?.success(VolcEngineSpeechContent.recordStatus(true).toJson())
        }
    }

    private fun speechStop(data: String) {
        mEngineStarted = false
        activity?.runOnUiThread {
            eventSink?.success(VolcEngineSpeechContent.recordStatus(false).toJson())
        }
    }

    private fun speechAsrResult(data: String, isFinal: Boolean) {
        try {
            AudioRecognitionResult.parse(data)?.let { result ->
                var text = result.result.text
                if (text.isEmpty()) {
                    return
                }
                var duration = result.audioInfo.duration
                // EventChannel要运行在主线程
                activity?.runOnUiThread {
                    eventSink?.success(VolcEngineSpeechContent.text(text, duration).toJson())
                }

                Log.i(TAG, "当前录音结果: $text")
            }
        } catch (e: JSONException) {
            e.printStackTrace()
        }
    }

    private fun speechError(data: String) {
        try {
            val reader = JSONObject(data)
            if (!reader.has("err_code") || !reader.has("err_msg")) {
                return
            }

            stopEngine()
        } catch (e: JSONException) {
            e.printStackTrace()
        }
    }

    private fun stopEngine() {
        if (speechEngine == null) {
            return
        }
        speechEngine!!.sendDirective(SpeechEngineDefines.DIRECTIVE_STOP_ENGINE, "")
    }


}

package com.wood.volc_engine_asr

import com.google.gson.Gson

enum class VolcEngineSpeechContentType {
    VOLUME, TEXT, RECORD_STATUS
}

private val gson = Gson()

data class VolcEngineSpeechContent(
    val type: VolcEngineSpeechContentType,
    val volume: Double = 0.0,
    val text: String = "",
    val duration: Int = 0,
    val isRecording: Boolean = true,
) {

    fun toJson(): String = gson.toJson(mapOf(
        "type" to type.ordinal,
        "volume" to volume,
        "text" to text,
        "duration" to duration,
        "isRecording" to isRecording
    ))

    companion object {
        fun volume(volume: Double): VolcEngineSpeechContent {
            return VolcEngineSpeechContent(VolcEngineSpeechContentType.VOLUME, volume)
        }

        fun text(text: String, duration: Int): VolcEngineSpeechContent {
            return VolcEngineSpeechContent(VolcEngineSpeechContentType.TEXT, text = text, duration = duration)
        }

        fun recordStatus(isRecording: Boolean): VolcEngineSpeechContent {
            return VolcEngineSpeechContent(VolcEngineSpeechContentType.RECORD_STATUS, isRecording = isRecording)
        }
    }
}

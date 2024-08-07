package com.wood.volc_engine_asr

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encodeToString
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json

// Mark the enum as @Serializable
@Serializable
enum class VolcEngineSpeechContentType {
    VOLUME, TEXT, RECORD_STATUS
}

// Create a custom serializer for VolcEngineSpeechContentType
object VolcEngineSpeechContentTypeSerializer : KSerializer<VolcEngineSpeechContentType> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("VolcEngineSpeechContentType", PrimitiveKind.INT)

    override fun serialize(encoder: Encoder, value: VolcEngineSpeechContentType) {
        val intValue = when (value) {
            VolcEngineSpeechContentType.VOLUME -> 0
            VolcEngineSpeechContentType.TEXT -> 1
            VolcEngineSpeechContentType.RECORD_STATUS -> 2
        }
        encoder.encodeInt(intValue)
    }

    override fun deserialize(decoder: Decoder): VolcEngineSpeechContentType {
        return when (val intValue = decoder.decodeInt()) {
            0 -> VolcEngineSpeechContentType.VOLUME
            1 -> VolcEngineSpeechContentType.TEXT
            2 -> VolcEngineSpeechContentType.RECORD_STATUS
            else -> throw IllegalArgumentException("Unknown VolcEngineSpeechContentType value: $intValue")
        }
    }
}

@Serializable
data class VolcEngineSpeechContent(
    @Serializable(with = VolcEngineSpeechContentTypeSerializer::class)
    val type: VolcEngineSpeechContentType,
    val volume: Double = 0.0,
    val text: String = "",
    val duration: Int = 0,
    val isRecording: Boolean = true,
) {

    fun toJson(): String = Json.encodeToString(this)

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

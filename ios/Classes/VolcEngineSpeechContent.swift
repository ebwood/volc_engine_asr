//
//  VolcEngineSpeechContent.swift
//  volc_engine_asr
//
//  Created by cplin on 2024/8/6.
//

import Foundation

enum VolcEngineSpeechContentType: Int, Codable {
    case volume = 0
    case text = 1
    case recordStatus = 2
}

struct VolcEngineSpeechContent: Codable {
    let type: VolcEngineSpeechContentType
    let volume: Double
    let text: String
    let duration: Int
    let isRecording: Bool
    
    init(type: VolcEngineSpeechContentType, volume: Double = 0.0, text: String = "", duration: Int = 0, isRecording: Bool) {
        self.type = type
        self.volume = volume
        self.text = text
        self.duration = duration
        self.isRecording = isRecording
    }
    
    func toJson() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let jsonData = try? encoder.encode(self) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }
    
    static func volume(volume: Double) -> VolcEngineSpeechContent {
        return VolcEngineSpeechContent(type: .volume, volume: volume, isRecording: true)
    }
    
    static func text(text: String, duration: Int) -> VolcEngineSpeechContent {
        return VolcEngineSpeechContent(type: .text, text: text, duration: duration, isRecording: true)
    }
    
    static func recordStatus(isRecording: Bool) -> VolcEngineSpeechContent {
        return VolcEngineSpeechContent(type: .recordStatus, isRecording: isRecording)
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case volume
        case text
        case duration
        case isRecording
    }
}

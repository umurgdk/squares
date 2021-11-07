//
//  WaveformGenerator.swift
//  Squares
//
//  Created by Umur Gedik on 6.11.2021.
//

import Foundation
import AVFoundation
import Accelerate

enum WaveformError: String, Error {
    case audioFileHasNoTracks
}

actor WaveformGenerator: ObservableObject {
    public func waveform(from buffer: AVAudioPCMBuffer, targetLength: Int) async throws -> [Float] {
        guard var data = buffer.toFloatChannelData()?.first else {
            throw WaveformError.audioFileHasNoTracks
        }
        
        let dataLength = vDSP_Length(data.count)
        
        vDSP_vabs(data, 1, &data, 1, dataLength)
        
        let decimationFactor = Int(floor(Float(dataLength) / Float(targetLength)))
        let filterLength = vDSP_Length(decimationFactor)
        let filter = [Float](repeating: 1 / Float(filterLength), count: Int(filterLength))
        
        let outputLength = vDSP_Length(targetLength)
        var output = [Float](repeating: 0, count: targetLength)
        
        vDSP_desamp(data, decimationFactor, filter, &output, outputLength, filterLength)
        
        var max: Float = 0
        vDSP_maxv(output, 1, &max, outputLength)
        vDSP_vsdiv(output, 1, &max, &output, 1, outputLength)
        return output
    }
}

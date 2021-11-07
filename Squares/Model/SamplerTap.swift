//
//  SamplerTap.swift
//  Squares
//
//  Created by Umur Gedik on 7.11.2021.
//

import AVFoundation
import AudioKit

@MainActor
protocol SamplerTapDelegate: AnyObject {
    func samplerDidStopPlayingSample(id: Sample.ID)
}

@MainActor
class SamplerTap: BaseTap {
    public let sampleID: Sample.ID
    public weak var delegate: SamplerTapDelegate?
    public init(input: Node, sampleID: Sample.ID) {
        self.sampleID = sampleID
        super.init(input, bufferSize: 64)
    }
    
    private var isSilent = true {
        didSet {
            guard isSilent != oldValue else { return }
            if isSilent {
                delegate?.samplerDidStopPlayingSample(id: sampleID)
            }
        }
    }
    
    override func doHandleTapBlock(buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        Task {
            await MainActor.run { isSilent = buffer.isSilent }
        }
    }
}

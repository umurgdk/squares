//
//  DrumMachine.swift
//  Squares
//
//  Created by Umur Gedik on 6.11.2021.
//

import Foundation
import AVFoundation
import AppKit
import AudioKit

struct GridSize {
    let columns: Int
    let rows: Int
    
    static let macbookPro13 = GridSize(columns: 4, rows: 3)
    var positions: [GridPoisition] { (0..<rows).flatMap { row in (0..<columns).map { col in GridPoisition(column: col, row: row) }} }
}

struct GridPoisition {
    let column: Int
    let row: Int
}

@MainActor
class DrumMachine: ObservableObject, SamplerTapDelegate {
    @Published public private(set) var slots: [[SampleSlot]]
    @Published public private(set) var nowPlaying: [Sample.ID: TimeInterval] = [:]
    
    private let waveformGenerator = WaveformGenerator()
    private let audioEngine = AudioEngine()
    private let mixer = Mixer()
    private var samplerTaps: [Sample.ID: SamplerTap] = [:]
    
    public let size: GridSize
    public init(size: GridSize = .macbookPro13) {
        self.size = size
        slots = Array(repeating: Array(repeating: SampleSlot.empty, count: size.columns), count: size.rows)
        
        audioEngine.output = mixer
        try! audioEngine.start()
    }
    
    public func windowStatusDidChange(isActive: Bool) {
        if isActive {
            print("starting audio engine")
            try! audioEngine.start()
        } else {
            print("stopping audio engine")
            audioEngine.stop()
        }
    }
    
    public func playSample(at position: GridPoisition) {
        if case let .ready(sample) = slots[position.row][position.column] {
            sample.sampler.play()
            nowPlaying[sample.id] = Date.now.timeIntervalSince1970
        }
    }
    
    public func loadAudio(url: URL, at position: GridPoisition) {
        let slot = slots[position.row][position.column]
        if case let .ready(sample) = slot {
            mixer.removeInput(sample.sampler)
            samplerTaps[sample.id]?.dispose()
            samplerTaps.removeValue(forKey: sample.id)
        }
        
        Task {
            do {
                let sampler = AppleSampler(file: nil)
                let audioFile = try AVAudioFile(forReading: url)
                try sampler.loadAudioFile(audioFile)
                mixer.addInput(sampler)
                
                let fileName = url.deletingPathExtension().pathComponents.last ?? ""
                var sample = Sample(sampler: sampler, duration: audioFile.duration, name: fileName.uppercased())
                updateSlot(.ready(sample), at: position)
                
                let tap = SamplerTap(input: sampler, sampleID: sample.id)
                tap.delegate = self
                samplerTaps[sample.id] = tap
                tap.start()
                
                // TODO: Waveform is huge, needs to be downsampled and normalized
                if let buffer = audioFile.toAVAudioPCMBuffer() {
                    let waveform = try await waveformGenerator.waveform(from: buffer, targetLength: 32)
                    sample.waveform = .ready(waveform)
                    updateSlot(.ready(sample), at: position)
                }
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }
    
    private func updateSlot(_ slot: SampleSlot, at position: GridPoisition) {
        slots[position.row][position.column] = slot
    }
    
    private func sampleWithID(_ id: Sample.ID) -> Sample? {
        for slot in slots.flatMap({ $0 }) {
            if case let .ready(sample) = slot, sample.id == id {
                return sample
            }
        }
        
        return nil
    }
    
    func samplerDidStopPlayingSample(id: Sample.ID) {
        nowPlaying.removeValue(forKey: id)
        if let sample = sampleWithID(id) {
            print("Sample[\(sample.name)] did stop playing")
        }
    }
}

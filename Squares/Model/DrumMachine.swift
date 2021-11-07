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
import Combine

struct NowPlaying {
    let sampleID: Sample.ID
    let isPlaying: Bool
}

@MainActor
class DrumMachine: ObservableObject, SamplerTapDelegate {
    public let grid: SlotGrid
    public var slotChangePublisher: AnyPublisher<GridPosition, Never> { grid.slotChangePublisher }
    
    public var nowPlayingPublisher: AnyPublisher<NowPlaying, Never> { nowPlayingSignal.eraseToAnyPublisher() }
    private let nowPlayingSignal = PassthroughSubject<NowPlaying, Never>()
                                        
    private var samplePlayStartTimes: [Sample.ID: TimeInterval] = [:]
    private let waveformGenerator = WaveformGenerator()
    private let audioEngine = AudioEngine()
    private let mixer = Mixer()
    
    public init(size: GridSize = .macbookPro13) {
        grid = SlotGrid(size: size)
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
    
    public func currentPlayProgress(at position: GridPosition) -> Double? {
        guard
            let sample = grid.sample(at: position),
            let startTime = samplePlayStartTimes[sample.id]
        else { return nil }
        
        let currentTime = Date.now.timeIntervalSince1970 - startTime
        let progress = currentTime / sample.duration
        return progress > 1 ? nil : progress
    }
    
    public func playSample(at position: GridPosition) {
        if let sample = grid.sample(at: position) {
            sample.sampler.play()
            samplePlayStartTimes[sample.id] = Date.now.timeIntervalSince1970
            nowPlayingSignal.send(NowPlaying(sampleID: sample.id, isPlaying: true))
        }
    }
    
    public func loadAudio(urls: [URL], at position: GridPosition = .zero) {
        var positions = grid.size.validPositions.startingFrom(position)
        for url in urls {
            guard let position = positions.next() else { return }
            loadAudio(url: url, at: position)
        }
    }
    
    public func loadAudio(url: URL, at position: GridPosition) {
        if let sample = grid.sample(at: position) {
            mixer.removeInput(sample.sampler)
            samplePlayStartTimes.removeValue(forKey: sample.id)
        }
        
        Task {
            do {
                let sampler = AppleSampler(file: nil)
                let audioFile = try AVAudioFile(forReading: url)
                try sampler.loadAudioFile(audioFile)
                mixer.addInput(sampler)
                
                let fileName = url.deletingPathExtension().pathComponents.last ?? ""
                var sample = Sample(sampler: sampler, duration: audioFile.duration, name: fileName.uppercased())
                grid.setSlot(.ready(sample), at: position)
                
                // TODO: Waveform is huge, needs to be downsampled and normalized
                if let buffer = audioFile.toAVAudioPCMBuffer() {
                    let waveform = try await waveformGenerator.waveform(from: buffer, targetLength: 32)
                    sample.waveform = .ready(waveform)
                    grid.setSlot(.ready(sample), at: position)
                }
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }
    
    func samplerDidStopPlayingSample(id: Sample.ID) {
        nowPlayingSignal.send(NowPlaying(sampleID: id, isPlaying: false))
        samplePlayStartTimes.removeValue(forKey: id)
        if let sample = grid.sampleBy(id: id) {
            print("Sample[\(sample.name)] did stop playing")
        }
    }
}

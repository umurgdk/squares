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
class DrumMachine: ObservableObject {
    @Published public private(set) var audios: [[Sample]]
    @Published public private(set) var nowPlaying: [Sample.ID: TimeInterval] = [:]
    
    private let waveformGenerator = WaveformGenerator()
    private let audioEngine = AudioEngine()
    private let mixer = Mixer()
    
    public let size: GridSize
    public init(size: GridSize = .macbookPro13) {
        self.size = size
        audios = (0..<size.rows).map { _ in (0..<size.columns).map { _ in Sample() } }
        
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
    
    public func play(_ audio: Sample) {
        guard case let .ready(player) = audio.state else { return }
        nowPlaying[audio.id] = Date.now.timeIntervalSince1970
        player.play()
    }
    
    public func removePlaying(_ audio: Sample) {
        nowPlaying.removeValue(forKey: audio.id)
        guard case let .ready(player) = audio.state else { return }
        player.seek(time: 0)
    }
    
    public func loadAudio(url: URL, at position: GridPoisition) {
        let audio = audios[position.row][position.column]
        if case let .ready(playerNode) = audio.state {
            mixer.removeInput(playerNode)
        }
        
        Task {
            do {
                var audio = audio
                let playerNode = AudioPlayer()
                try playerNode.load(url: url, buffered: true)
                mixer.addInput(playerNode)
                
                let fileName = url.deletingPathExtension().pathComponents.last ?? ""
                
                audio.state = .ready(playerNode)
                audio.name = fileName.uppercased()
                updateAudio(audio, at: position)
                
                playerNode.completionHandler = { [weak self, audio] in
                    DispatchQueue.main.async { [weak self, audio] in self?.removePlaying(audio)}
                }
                
                // TODO: Waveform is huge, needs to be downsampled and normalized
                if let buffer = playerNode.buffer {
                    let waveform = try await waveformGenerator.waveform(from: buffer, targetLength: 32)
                    audio.waveform = .ready(waveform)
                    updateAudio(audio, at: position)
                }
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }
    
    private func updateAudio(_ audio: Sample, at position: GridPoisition) {
        audios[position.row][position.column] = audio
    }
}


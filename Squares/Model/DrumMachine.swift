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
class DrumMachine: ObservableObject {
    @Published public private(set) var isRecording = false
    
    public let grid: SlotGrid
    public var slotChangePublisher: AnyPublisher<GridPosition, Never> { grid.slotChangePublisher }
    
    private let nowPlayingSignal = PassthroughSubject<NowPlaying, Never>()
                                        
    private var samplePlayStartTimes: [Sample.ID: TimeInterval] = [:]
    private let waveformGenerator = WaveformGenerator()
    private let audioEngine = AudioEngine()
    private let mixer = Mixer()
    
    private var recorder: NodeRecorder? {
        didSet { isRecording = recorder != nil }
    }
    
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
    
    public func nowPlayingPublisher(for sampleID: Sample.ID?) -> AnyPublisher<NowPlaying, Never> {
        guard let sampleID = sampleID else {
            return [].publisher.eraseToAnyPublisher()
        }
        
        return nowPlayingSignal.filter { $0.sampleID == sampleID }.eraseToAnyPublisher()
    }
    
    public func currentPlayProgress(of sampleID: Sample.ID) -> Double? {
        guard
            let sample = grid.sampleBy(id: sampleID),
            let startTime = samplePlayStartTimes[sample.id]
        else { return nil }
        
        let currentTime = Date.now.timeIntervalSince1970 - startTime
        if currentTime > sample.duration {
            return nil
        }
        
        return currentTime / sample.duration
    }
    
    public func playSample(at position: GridPosition) {
        if let sample = grid.sample(at: position) {
            sample.sampler.play()
            samplePlayStartTimes[sample.id] = Date.now.timeIntervalSince1970
            nowPlayingSignal.send(NowPlaying(sampleID: sample.id, isPlaying: true))
        }
    }
    
    public func startRecording() {
        do {
            let format = AVAudioFormat(commonFormat: .pcmFormatFloat64, sampleRate: 44100, channels: 2, interleaved: true)!
            let recordingDirectory = FileManager.default.temporaryDirectory
            let recordingURL = recordingDirectory.appendingPathComponent("recording.caf")
            let audioFile = try AVAudioFile(forWriting: recordingURL, settings: format.settings)
            let recorder = try NodeRecorder(node: mixer, file: audioFile)
            try recorder.reset()
            try recorder.record()
            self.recorder = recorder
        } catch {
            NSAlert(error: error).runModal()
        }
    }
    
    public func stopRecording() {
        guard let recorder = recorder else { return }

        recorder.stop()
        self.recorder = nil
        guard let file = recorder.audioFile else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["caf"]
        guard savePanel.runModal() == .OK, let url = savePanel.url else { return }
        do {
            try FileManager.default.moveItem(at: file.url, to: url)
        } catch {
            NSAlert(error: error).runModal()
        }
    }
    
    public func loadAudio(urls: [URL], at position: GridPosition = .zero) {
        var positions = grid.size.validPositions.startingFrom(position)
        for url in urls {
            guard let position = positions.next() else { return }
            
            loadAudio(url: url, at: position)
        }
    }
    
    private func loadAudioFilesInside(directory directoryURL: URL, at position: GridPosition) {
        var positions = grid.size.validPositions.startingFrom(position)
        
        do {
            let filePaths = try FileManager.default.contentsOfDirectory(atPath: directoryURL.path)
            for filePath in filePaths {
                let ext = (filePath as NSString).pathExtension
                guard let uti = UTType(filenameExtension: ext) else { continue }
                
                if uti.conforms(to: .audio) {
                    guard let position = positions.next() else { return }
                    loadAudio(url: URL(fileURLWithPath: filePath, relativeTo: directoryURL), at: position)
                }
            }
        } catch {
            NSAlert(error: error).runModal()
        }
    }
    
    public func loadAudio(url: URL, at position: GridPosition) {
        var isDirectory: ObjCBool = .init(false)
        
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return }
        if isDirectory.boolValue {
            return loadAudioFilesInside(directory: url, at: position)
        }
        
        if let sample = grid.sample(at: position) {
            mixer.removeInput(sample.sampler)
            samplePlayStartTimes.removeValue(forKey: sample.id)
        }
        
        grid.setSlot(.empty, at: position)
        
        Task {
            do {
                let sampler = AppleSampler(file: nil)
                let audioFile = try AVAudioFile(forReading: url)
                try sampler.loadAudioFile(audioFile)
                mixer.addInput(sampler)
                
                let fileName = url.deletingPathExtension().pathComponents.last ?? ""
                var sample = Sample(sampler: sampler, duration: audioFile.duration, name: fileName.uppercased())
                grid.setSample(sample, at: position)
                
                // TODO: Waveform is huge, needs to be downsampled and normalized
                if let buffer = audioFile.toAVAudioPCMBuffer() {
                    let waveform = try await waveformGenerator.waveform(from: buffer, targetLength: 32)
                    sample.waveform = .ready(waveform)
                    grid.setSample(sample, at: position)
                }
            } catch {
                DispatchQueue.main.async { NSAlert(error: error).runModal() }
            }
        }
    }
}

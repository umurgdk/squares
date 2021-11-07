//
//  SquarePad.swift
//  Squares
//
//  Created by Umur Gedik on 6.11.2021.
//

import UniformTypeIdentifiers
import SwiftUI
import AudioKitUI

struct SquarePad: View {
    @ObservedObject var drumMachine: DrumMachine
    let position: GridPosition
    
    @State private var slot: SampleSlot
    @State private var sample: Sample?
    @State private var isDropTarget = false
    @State private var playProgress: Double? = nil
    
    var isEmpty: Bool {
        if case .empty = slot { return true }
        return false
    }
    
    init(drumMachine: DrumMachine, position: GridPosition) {
        self.position = position
        self._drumMachine = ObservedObject(initialValue: drumMachine)
        self._slot = State(initialValue: drumMachine.grid.slot(at: position))
        self._sample = State(initialValue: drumMachine.grid.sample(at: position))
    }
    
    func sampleView(_ sample: Sample) -> some View {
        Group {
            HStack {
                Text(sample.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding([.horizontal, .vertical], 8)
            }
            
            WaveformView(waveform: sample.waveform)
                .padding(EdgeInsets(top: 32, leading: 8, bottom: 16, trailing: 8))
        }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            SquareBackground(isEmpty: isEmpty, isDropTarget: isDropTarget, playProgress: playProgress)
            switch slot {
            case .empty:
                EmptyView()
            case .loading:
                ProgressView().controlSize(.small)
            case .ready:
                if let sample = sample {
                    sampleView(sample)
                }
            }
        }
        .onOptionalDrag(sample) { sample in
            NSItemProvider(object: TransferrableSampleID(sampleID: sample.id))
        } preview: {
            self.opacity(0.5)
        }
        .onDrop(of: [.fileURL, Sample.uti], isTargeted: $isDropTarget) { itemProviders in
            Task {
                if let sampleIDProvider = itemProviders.first(where: { $0.hasItemConformingToTypeIdentifier(Sample.uti.identifier) }) {
                    guard
                        let sampleID = await [sampleIDProvider].resolveSampleIDs().first,
                        let draggedSamplePosition = drumMachine.grid.position(of: sampleID)
                    else { return }
                    
                    drumMachine.grid.swapSlots(position, draggedSamplePosition)
                    return
                }
                
                let urls = await itemProviders.resolveFileURLs()
                drumMachine.loadAudio(urls: urls, at: position)
            }
            
            return true
        }
        .onReceive(drumMachine.nowPlayingPublisher(for: sample?.id)) { status in
            guard let sample = sample else { return }

            if status.isPlaying {
                playProgress = drumMachine.currentPlayProgress(of: sample.id)
                let currentTime = sample.duration * (playProgress ?? 0)
                let remainingTime = sample.duration - currentTime
                withAnimation(Animation.linear(duration: remainingTime)) {
                    playProgress = 1
                }
            }
        }
        .onReceive(drumMachine.slotChangePublisher) { changedPosition in
            guard changedPosition == position else { return }
            slot = drumMachine.grid.slot(at: position)
            sample = drumMachine.grid.sample(at: position)
        }
    }
}

extension ShapeStyle where Self == Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

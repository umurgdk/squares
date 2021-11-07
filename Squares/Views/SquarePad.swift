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
    @State private var isDropTarget = false
    @State private var timer = Timer.publish(every: 0.1, on: .current, in: .common).autoconnect()
    @State private var playProgress: Double? = nil
    
    var isEmpty: Bool {
        if case .empty = slot { return true }
        return false
    }
    
    init(drumMachine: DrumMachine, position: GridPosition) {
        self._drumMachine = ObservedObject(initialValue: drumMachine)
        self.position = position
        self._slot = State(initialValue: drumMachine.grid.slot(at: position))
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            SquareBackground(isEmpty: isEmpty, isDropTarget: isDropTarget, playProgress: playProgress)
            switch slot {
            case .empty:
                EmptyView()
            case .loading:
                ProgressView().controlSize(.small)
            case .ready(let sample):
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
        .onDrop(of: [.fileURL], isTargeted: $isDropTarget) { itemProviders in
            Task {
                let urls = await itemProviders.resolveFileURLs()
                drumMachine.loadAudio(urls: urls, at: position)
            }
            
            return true
        }
        .onReceive(drumMachine.nowPlayingPublisher) { status in
            guard status.sampleID == drumMachine.grid.sample(at: position)?.id else { return }
            
            if status.isPlaying {
                playProgress = drumMachine.currentPlayProgress(at: position)
                timer = Timer.publish(every: 0.1, on: .current, in: .common).autoconnect()
            } else {
                timer.upstream.connect().cancel()
            }
        }
        .onReceive(drumMachine.slotChangePublisher) { changedPosition in
            guard changedPosition == position else { return }
            slot = drumMachine.grid.slot(at: position)
        }
        .onReceive(timer) { _ in
            if let progress = drumMachine.currentPlayProgress(at: position) {
                withAnimation { playProgress = progress }
            } else {
                playProgress = nil
                timer.upstream.connect().cancel()
            }
        }
        .onAppear { timer.upstream.connect().cancel() }
    }
}

//
//  SquarePad.swift
//  Squares
//
//  Created by Umur Gedik on 6.11.2021.
//

import SwiftUI
import AudioKitUI

struct SquarePad: View  {
    @ObservedObject var drumMachine: DrumMachine
    let position: GridPoisition
    let audio: Audio
    
    @State var isDropTarget = false
    @State var timer = Timer.publish(every: 0.1, on: .current, in: .common).autoconnect()
    @State var playTime: Double? = nil
    var playProgress: Double? {
        guard
            case let .ready(player) = audio.state,
            let playTime = playTime
        else {
            return nil
        }

        return min(playTime, player.duration) / player.duration
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            SquareBackground(isDropTarget: isDropTarget, playProgress: playProgress)
            HStack {
                Text(audio.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding([.horizontal, .vertical], 8)
            }
            switch audio.state {
            case .empty:
                EmptyView()
            case .loading:
                ProgressView().controlSize(.small)
            case .ready(let player):
                switch audio.waveform {
                case .empty:
                    EmptyView()
                case .generating:
                    ProgressView().controlSize(.small)
                case .ready(let waveform):
                    WaveformShape(waveform: waveform)
                        .padding(EdgeInsets(top: 32, leading: 8, bottom: 16, trailing: 8))
                }
            }
        }
        .onDrop(of: [.audio, .fileURL], isTargeted: $isDropTarget) { itemProvider in
            guard let itemProvider = itemProvider.first else { return false }
            _ = itemProvider.loadObject(ofClass: URL.self) { reading, error in
                if let error = error {
                    NSAlert(error: error).runModal()
                    return
                }
                
                guard let url = reading else { return }
                drumMachine.loadAudio(url: url, at: position)
            }
            
            return true
        }
        .onChange(of: drumMachine.nowPlaying[audio.id]) { isPlayingAt in
            if isPlayingAt == nil {
                playTime = nil
                self.timer.upstream.connect().cancel()
            } else {
                playTime = 0
                self.timer = Timer.publish(every: 0.1, on: .current, in: .common).autoconnect()
            }
        }
        .onReceive(timer) { _ in
            withAnimation {
                playTime = playTime.map { $0 + 0.1 } ?? 0
            }
        }
        .onAppear { timer.upstream.connect().cancel() }
    }
}

struct SquareBackground: View {
    let isDropTarget: Bool
    let playProgress: Double?
    
    @ViewBuilder var flash: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.primary.opacity(1 - (playProgress ?? 1)))
    }
    
    var body: some View {
        GeometryReader { geom in
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: NSColor.windowBackgroundColor))
                .shadow(color: Color(white: 0).opacity(0.15), radius: 2, x: 0, y: 1)
                .overlay(flash)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isDropTarget ? Color.blue : Color.black,
                                lineWidth: isDropTarget ? 3 : 1)
                        .opacity(isDropTarget ? 1 : 0.1)
                )
            }
    }
}

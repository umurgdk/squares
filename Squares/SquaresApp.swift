//
//  SquaresApp.swift
//  Squares
//
//  Created by Umur Gedik on 6.11.2021.
//

import SwiftUI
import Combine

@main @MainActor
struct SquaresApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var drumMachine = DrumMachine()
    @State var isTrackpadEnabled = false
    @State var isEmpty = true
    
    var isEmptyPublisher: AnyPublisher<Bool, Never> {
        drumMachine.grid.$numberOfSamples
            .map { $0 == 0 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    @ViewBuilder
    var emptyView: some View {
        if isEmpty {
            Text("Please drag audio samples")
                .font(.title)
                .foregroundColor(.secondary)
                .padding(32)
                .background(Color(nsColor: .controlBackgroundColor))
        } else {
            EmptyView()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(drumMachine: drumMachine, trackPadEnabled: isTrackpadEnabled)
                .overlay(emptyView)
                .toolbar {
                    ToolbarItem(placement: .status) {
                        Toggle(isOn: $isTrackpadEnabled) {
                            Label("Trackpad Enabled", systemImage: "rectangle.and.hand.point.up.left")
                                .foregroundColor(isTrackpadEnabled ? .accentColor : .secondary)
                        }
                    }
                    
                    ToolbarItem(placement: .status) {
                        Button {
                            if drumMachine.isRecording {
                                isTrackpadEnabled = false
                                drumMachine.stopRecording()
                            } else {
                                isTrackpadEnabled = true
                                drumMachine.startRecording()
                            }
                        } label: {
                            Label(drumMachine.isRecording ? "Stop Recording" : "Start Recording",
                                  systemImage: drumMachine.isRecording ? "stop.circle" : "record.circle")
                                .foregroundColor(.red)
                        }
                    }
                }
                .onReceive(isEmptyPublisher) { isEmpty in
                    withAnimation {
                        self.isEmpty = isEmpty
                    }
                }
        }
        .onChange(of: scenePhase) { newValue in
            drumMachine.windowStatusDidChange(isActive: newValue == .active)
        }
    }
}


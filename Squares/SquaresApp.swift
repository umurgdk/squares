//
//  SquaresApp.swift
//  Squares
//
//  Created by Umur Gedik on 6.11.2021.
//

import SwiftUI

@main @MainActor
struct SquaresApp: App {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var drumMachine = DrumMachine()
    @State var isTrackpadEnabled = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(drumMachine: drumMachine, trackPadEnabled: isTrackpadEnabled)
                .toolbar {
                    ToolbarItem(placement: .status) {
                        Toggle(isOn: $isTrackpadEnabled) {
                            Label("Trackpad Enabled", systemImage: "rectangle.and.hand.point.up.left")
                                .foregroundColor(isTrackpadEnabled ? .accentColor : .secondary)
                        }
                    }
                }
        }
        .onChange(of: scenePhase) { newValue in
            drumMachine.windowStatusDidChange(isActive: newValue == .active)
        }
    }
}

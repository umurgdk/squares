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
    
    var body: some Scene {
        WindowGroup {
            ContentView(drumMachine: drumMachine)
        }
        .onChange(of: scenePhase) { newValue in
            drumMachine.windowStatusDidChange(isActive: newValue == .active)
        }
    }
}

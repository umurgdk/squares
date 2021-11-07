//
//  DrumMachine+Environment.swift
//  Squares
//
//  Created by Umur Gedik on 6.11.2021.
//

import SwiftUI

fileprivate struct DrumMachineKey: EnvironmentKey {
    @MainActor static let defaultValue = DrumMachine()
}

extension EnvironmentValues {
    var drumMachine: DrumMachine {
        get { self[DrumMachineKey.self] }
        set { self[DrumMachineKey.self] = newValue }
    }
}

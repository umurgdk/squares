//
//  Sample.swift
//  Squares
//
//  Created by Umur Gedik on 6.11.2021.
//

import Foundation
import AudioKit

struct Sample: Identifiable {
    let id: UUID = UUID()
    let sampler: AppleSampler
    let duration: TimeInterval
    var name: String = ""
    var waveform: Waveform = .empty
    
    enum Waveform { case empty, generating, ready([Float]) }
}

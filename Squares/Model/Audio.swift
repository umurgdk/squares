//
//  Audio.swift
//  Squares
//
//  Created by Umur Gedik on 6.11.2021.
//

import Foundation
import AudioKit

struct Audio: Identifiable {
    let id: UUID = UUID()
    var name: String = ""
    var state: State = .empty
    var waveform: Waveform = .empty
    
    enum State { case empty, loading(URL), ready(AudioPlayer) }
    enum Waveform { case empty, generating, ready([Float]) }
}

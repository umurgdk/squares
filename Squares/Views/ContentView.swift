//
//  ContentView.swift
//  Squares
//
//  Created by Umur Gedik on 6.11.2021.
//

import SwiftUI

struct ContentView: View {
    @StateObject var drumMachine: DrumMachine
    public let trackPadEnabled: Bool
    
    var body: some View {
        GeometryReader { geom in
            VStack(spacing: 8) {
                ForEach(0..<drumMachine.size.rows) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<drumMachine.size.columns) { col in
                            SquarePad(drumMachine: drumMachine,
                                      position: GridPoisition(column: col, row: row),
                                      slot: drumMachine.slots[row][col])
                        }
                    }
                }
            }
            .padding()
            .overlay(
                TouchInterceptor { touch in
                    guard trackPadEnabled else { return }
                    let y = (1 - touch.normalizedPosition.y)
                    let x = touch.normalizedPosition.x
                    
                    let row = Int(floor(y * CGFloat(drumMachine.size.rows)))
                    let col = Int(floor(x * CGFloat(drumMachine.size.columns)))
                    drumMachine.playSample(at: GridPoisition(column: col, row: row))
                } onTouchUp: { touch in
                }
            )
        }
    }
}

@MainActor
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let drumMachine = DrumMachine()
        return Group {
            SquarePad(drumMachine: drumMachine, position: GridPoisition(column: 0, row: 0   ), slot: .empty)
                .padding()
                .frame(width: 100, height: 100, alignment: .center)
            ContentView(drumMachine: DrumMachine(), trackPadEnabled: false)
                .frame(width: 400, height: 270, alignment: .center)
        }
    }
}

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
    
    var size: GridSize { drumMachine.grid.size }
    
    var body: some View {
        GeometryReader { geom in
            VStack(spacing: 8) {
                ForEach(0..<size.rows) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<size.columns) { col in
                            SquarePad(drumMachine: drumMachine,
                                      position: GridPosition(column: col, row: row))
                        }
                    }
                }
            }
            .padding()
            .overlay(trackPadOverlay)
        }.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    var trackPadOverlay: some View {
        if trackPadEnabled {
            TouchInterceptor { touch in
                guard trackPadEnabled else { return }
                let y = (1 - touch.normalizedPosition.y)
                let x = touch.normalizedPosition.x
                
                let row = Int(floor(y * CGFloat(size.rows)))
                let col = Int(floor(x * CGFloat(size.columns)))
                drumMachine.playSample(at: .init(column: col, row: row))
            } onTouchUp: { touch in
            }
        } else {
            EmptyView()
        }
    }
}

@MainActor
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let drumMachine = DrumMachine()
        return Group {
            SquarePad(drumMachine: drumMachine, position: GridPosition(column: 0, row: 0))
                .padding()
                .frame(width: 100, height: 100, alignment: .center)
            ContentView(drumMachine: DrumMachine(), trackPadEnabled: false)
                .frame(width: 400, height: 270, alignment: .center)
        }
    }
}

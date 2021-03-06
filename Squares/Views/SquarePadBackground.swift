//
//  SquarePadBackground.swift
//  Squares
//
//  Created by Umur Gedik on 7.11.2021.
//

import SwiftUI

struct SquareBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    let isEmpty: Bool
    let isDropTarget: Bool
    let playProgress: Double?
    
    @ViewBuilder var flash: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.primary.opacity(1 - (playProgress ?? 1)))
    }
    
    var emptyStrokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: isDropTarget ? 3 : 1,
                    lineCap: .butt,
                    lineJoin: .round,
                    miterLimit: 1,
                    dash: isDropTarget ? [] : [4],
                    dashPhase: isDropTarget ? 0 : 4)
    }
    
    var nonEmptyStrokeColor: Color {
        if isDropTarget { return .blue }
        return Color.primary.opacity(0.1)
    }
    
    var fillColor: Color {
        if isDropTarget || !isEmpty {
            if colorScheme == .light {
                return .white
            } else {
                return .black
            }
        }
        
        return .clear
    }
    
    @ViewBuilder
    var body: some View {
        if isEmpty {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isDropTarget ? Color.blue : Color.primary.opacity(0.1), style: emptyStrokeStyle)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(fillColor)
                        .opacity(isDropTarget ? 1 : 0)
                )
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(fillColor)
                .shadow(color: Color.black.opacity(colorScheme == .light ? 0.15 : 0.35),
                        radius: colorScheme == .light ? 2 : 2.5,
                        x: 0,
                        y: colorScheme == .light ? 1 : 2)
                .overlay(flash)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(nonEmptyStrokeColor, lineWidth: isDropTarget ? 3 : 1)
                )
        }
    }
}

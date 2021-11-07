//
//  OptionalDrag.swift
//  Squares
//
//  Created by Umur Gedik on 7.11.2021.
//

import Foundation
import SwiftUI

struct OptionalDrag<T, P: View>: ViewModifier {
    let optionalValue: T?
    let data: (T) -> NSItemProvider
    let preview: () -> P
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if let value = optionalValue {
            content.onDrag({ data(value) }, preview: preview)
        } else {
            content
        }
    }
}

extension View {
    func onOptionalDrag<T, P: View>(_ value: T?, data: @escaping (T) -> NSItemProvider, @ViewBuilder preview: @escaping () -> P) -> some View {
        self.modifier(OptionalDrag(optionalValue: value, data: data, preview: preview))
    }
}

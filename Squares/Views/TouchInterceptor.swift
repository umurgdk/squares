//
//  TouchInterceptor.swift
//  Squares
//
//  Created by Umur Gedik on 7.11.2021.
//

import SwiftUI
import AppKit

protocol TouchInterceptorDelegate: AnyObject {
    func didTouchDown(_ touch: NSTouch)
    func didTouchUp(_ touch: NSTouch)
}

class TouchInterceptorNSView: NSView {
    weak var delegate: TouchInterceptorDelegate?
    convenience init() {
        self.init(frame: .zero)
        allowedTouchTypes = [.indirect]
        wantsRestingTouches = true
    }
    
    override func touchesBegan(with event: NSEvent) {
        super.touchesBegan(with: event)
        let touches = event.touches(matching: .began, in: nil)
        touches.forEach { delegate?.didTouchDown($0) }
    }
    
    override func touchesEnded(with event: NSEvent) {
        super.touchesEnded(with: event)
        let touches = event.touches(matching: .ended, in: nil)
        touches.forEach { delegate?.didTouchUp($0) }
    }
}

struct TouchInterceptor: NSViewRepresentable {
    let onTouchDown: (NSTouch) -> Void
    let onTouchUp: (NSTouch) -> Void
    
    func makeNSView(context: Context) -> TouchInterceptorNSView {
        let nsView = TouchInterceptorNSView()
        nsView.delegate = context.coordinator
        return nsView
    }
    
    func updateNSView(_ nsView: TouchInterceptorNSView, context: Context) {
        context.coordinator.parent = self
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: TouchInterceptorDelegate {
        var parent: TouchInterceptor
        init(_ parent: TouchInterceptor) {
            self.parent = parent
        }
        
        func didTouchDown(_ touch: NSTouch) {
            parent.onTouchDown(touch)
        }
        
        func didTouchUp(_ touch: NSTouch) {
            parent.onTouchUp(touch)
        }
    }
}

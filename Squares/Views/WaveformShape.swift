//
//  WaveformView.swift
//  Squares
//
//  Created by Umur Gedik on 6.11.2021.
//

import SwiftUI
import AudioKitUI

struct WaveformShape: Shape {
    let waveform: [Float]
    
    func path(in rect: CGRect) -> Path {
        Path { p in
            for index in waveform.indices {
                let barRect = self.barRect(at: index, in: rect)
                p.addRoundedRect(in: barRect, cornerSize: cornerSize(for: barRect))
            }
        }
    }
    
    var spacing: CGFloat = 2
    
    private func cornerSize(for rect: CGRect) -> CGSize {
        let radius = rect.width < rect.height ? rect.width / 2 : rect.height / 2
        return CGSize(width: radius, height: radius)
    }
    
    private func barRect(at index: Int, in bounds: CGRect) -> CGRect {
        let size = barSize(at: index, in: bounds)
        let origin = barOrigin(at: index, in: bounds, size: size)
        return CGRect(origin: origin, size: size)
    }
    
    private func barOrigin(at index: Int, in bounds: CGRect, size: CGSize) -> CGPoint {
        let index = CGFloat(index)
        let left = size.width * index + spacing * index
        let top = bounds.height / 2 - size.height / 2
        return CGPoint(x: left, y: top)
    }
    
    private func barSize(at index: Int, in bounds: CGRect) -> CGSize {
        let count = CGFloat(waveform.count)
        let sample = CGFloat(waveform[index])
        let totalSpacing = spacing * (count - 1)
        let width = (bounds.width - totalSpacing) / count
        let height = max(bounds.height * sample, 1)
        return CGSize(width: width, height: height)
    }
}

struct WaveformView: NSViewRepresentable {
    let waveform: [Float]
    
    func makeNSView(context: Context) -> NativeView {
        let view = NativeView(waveform: waveform)
        return view
    }
    
    func updateNSView(_ nsView: NativeView, context: Context) {
        nsView.waveform = waveform
    }
    
    class NativeView: NSView {
        var waveform: [Float] = [] {
            didSet { waveformLayer.table = waveform }
        }
        
        var waveformLayer = WaveformLayer(table: [], fillColor: .white, strokeColor: .white, isMirrored: true)
        
        convenience init(waveform: [Float]) {
            self.init()
            self.waveform = waveform
            wantsLayer = true
            waveformLayer.drawsAsynchronously = false
            waveformLayer.table = waveform
            layer?.addSublayer(waveformLayer)
        }
        
        override func layout() {
            super.layout()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            waveformLayer.frame = bounds
            CATransaction.commit()
        }
    }
}

struct WaveformView_Previews: PreviewProvider {
    static var previews: some View {
        WaveformView(waveform: [10.3, 4.8,0.6,0.4,0.3,0.1,0.04,0])
            .frame(width: 100, height: 100, alignment: .center)
    }
}

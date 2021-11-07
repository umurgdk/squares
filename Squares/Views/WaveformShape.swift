//
//  WaveformView.swift
//  Squares
//
//  Created by Umur Gedik on 6.11.2021.
//

import SwiftUI
import AudioKitUI

struct WaveformView: View {
    let waveform: Sample.Waveform
    var body: some View {
        switch waveform {
        case .empty:
            EmptyView()
        case .generating:
            ProgressView().controlSize(.small)
        case .ready(let dataPoints):
            WaveformShape(waveform: dataPoints)
        }
    }
}

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

struct WaveformView_Previews: PreviewProvider {
    static var previews: some View {
        WaveformView(waveform: .ready([10.3, 4.8,0.6,0.4,0.3,0.1,0.04,0]))
            .frame(width: 100, height: 100, alignment: .center)
    }
}

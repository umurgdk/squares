//
//  Grid.swift
//  Squares
//
//  Created by Umur Gedik on 7.11.2021.
//

import Foundation
import Combine

struct GridSize {
    let columns: Int
    let rows: Int
    
    static let macbookPro13 = GridSize(columns: 4, rows: 3)
    var validPositions: GridPositionEnumerator { GridPositionEnumerator(size: self) }
}

struct GridPosition: Equatable {
    var column: Int
    var row: Int
    
    static var zero: Self { .init(column: 0, row: 0) }
}

struct GridPositionEnumerator: Sequence, IteratorProtocol {
    public let size: GridSize
    private var row: Int
    private var column: Int
    
    init(size: GridSize, starting: GridPosition = .zero) {
        self.size = size
        row = starting.row
        column = starting.column
    }
    
    func startingFrom(_ position: GridPosition) -> Self {
        .init(size: size, starting: position)
    }
    
    mutating func next() -> GridPosition? {
        guard row < size.rows, column < size.columns else { return nil }
        
        let position = GridPosition(column: column, row: row)
        
        column += 1
        if column >= size.columns {
            column = 0
            row += 1
        }
        
        return position
    }
}

class SlotGrid: ObservableObject {
    public var slotChangePublisher: AnyPublisher<GridPosition, Never> { slotChangeSignal.eraseToAnyPublisher() }
    private let slotChangeSignal = PassthroughSubject<GridPosition, Never>()
    
    @Published var numberOfSamples = 0
    
    public let size: GridSize
    private var slots: [[SampleSlot]]
    private var samples: [Sample.ID: Sample] = [:] {
        didSet { numberOfSamples = samples.count }
    }
    
    public init(size: GridSize = .macbookPro13) {
        self.size = size
        self.slots = Array(repeating: Array(repeating: SampleSlot.empty, count: size.columns), count: size.rows)
    }
    
    @inline(__always)
    public func slot(at position: GridPosition) -> SampleSlot {
        slots[position.row][position.column]
    }
    
    @inline(__always)
    public func setSlot(_ slot: SampleSlot, at position: GridPosition) {
        slots[position.row][position.column] = slot
        slotChangeSignal.send(position)
    }
    
    @inline(__always)
    public func setSample(_ sample: Sample, at position: GridPosition) {
        samples[sample.id] = sample
        setSlot(.ready(sample.id), at: position)
    }
    
    @inline(__always)
    public func swapSlots(_ lhs: GridPosition, _ rhs: GridPosition) {
        let leftSlot = slot(at: lhs)
        let rightSlot = slot(at: rhs)
        
        setSlot(rightSlot, at: lhs)
        setSlot(leftSlot, at: rhs)
    }
    
    @inline(__always)
    public func sample(at position: GridPosition) -> Sample? {
        if case let .ready(sampleID) = slot(at: position) {
            return samples[sampleID]
        }
        
        return nil
    }
    
    @inline(__always)
    public func sampleBy(id sampleID: Sample.ID) -> Sample? {
        samples[sampleID]
    }
    
    public func position(of sampleID: Sample.ID) -> GridPosition? {
        for position in size.validPositions {
            if let sample = sample(at: position), sample.id == sampleID {
                return position
            }
        }
        
        return nil
    }
}

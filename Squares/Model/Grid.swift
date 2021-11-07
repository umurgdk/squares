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
    private var slots: [[SampleSlot]]
    private let slotChangeSignal = PassthroughSubject<GridPosition, Never>()
    public var slotChangePublisher: AnyPublisher<GridPosition, Never> { slotChangeSignal.eraseToAnyPublisher() }
    
    public let size: GridSize
    public init(size: GridSize = .macbookPro13) {
        self.size = size
        self.slots = Array(repeating: Array(repeating: SampleSlot.empty, count: size.columns), count: size.rows)
    }
    
    public func slot(at position: GridPosition) -> SampleSlot {
        slots[position.row][position.column]
    }
    
    public func setSlot(_ slot: SampleSlot, at position: GridPosition) {
        slots[position.row][position.column] = slot
        slotChangeSignal.send(position)
    }
    
    public func sample(at position: GridPosition) -> Sample? {
        if case let .ready(sample) = slot(at: position) {
            return sample
        }
        
        return nil
    }
    
    public func sampleBy(id sampleID: Sample.ID) -> Sample? {
        for position in size.validPositions {
            if let sample = sample(at: position) {
                return sample
            }
        }
        
        return nil
    }
}

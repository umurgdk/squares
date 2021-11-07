//
//  Sample.swift
//  Squares
//
//  Created by Umur Gedik on 6.11.2021.
//

import Foundation
import AudioKit
import UniformTypeIdentifiers

struct Sample: Identifiable {
    static let uti = UTType("io.umurgdk.squares.sampleID") ?? .data
    
    let id: UUID = UUID()
    let sampler: AppleSampler
    let duration: TimeInterval
    var name: String = ""
    var waveform: Waveform = .empty
    
    enum Waveform { case empty, generating, ready([Float]) }
}

final class TransferrableSampleID: NSObject, NSItemProviderWriting, NSItemProviderReading, Codable {
    public let sampleID: Sample.ID
    public init(sampleID: Sample.ID) {
        self.sampleID = sampleID
    }
    
    static var writableTypeIdentifiersForItemProvider: [String] { [Sample.uti.identifier] }
    static var readableTypeIdentifiersForItemProvider: [String] { [Sample.uti.identifier] }
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        
        let progress = Progress(totalUnitCount: 1)
        progress.completedUnitCount = 1
        
        do {
            let data = try JSONEncoder().encode(sampleID)
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        
        return progress
    }
    
    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> TransferrableSampleID {
        let sampleID = try JSONDecoder().decode(Sample.ID.self, from: data)
        return TransferrableSampleID(sampleID: sampleID)
    }
}

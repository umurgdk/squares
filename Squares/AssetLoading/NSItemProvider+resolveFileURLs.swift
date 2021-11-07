//
//  NSItemProvider+resolveFileURLs.swift
//  Squares
//
//  Created by Umur Gedik on 7.11.2021.
//

import UniformTypeIdentifiers
import Foundation

fileprivate struct Mal: Codable {
    let root: UUID
}
            

extension Array where Element == NSItemProvider {
    func resolveSampleIDs() async -> [Sample.ID] {
        await resolve { itemProvider in
            await withCheckedContinuation { continuation in
                itemProvider.loadObject(ofClass: TransferrableSampleID.self) { itemReading, error in
                    guard error == nil, let transferrableSampleID = itemReading as? TransferrableSampleID  else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    continuation.resume(returning: transferrableSampleID.sampleID)
                }
            }
        }
    }
    
    func resolveFileURLs() async -> [URL] {
        await resolve { itemProvider in
            let data = try? await itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) as? Data
            return data.flatMap { URL(dataRepresentation: $0, relativeTo: nil) }
        }
    }
    
    private func resolve<T>(_ task: @escaping (NSItemProvider) async -> T?) async -> [T] {
        return await withTaskGroup(of: T?.self) { group in
            var values: [T] = []
            for itemProvider in self {
                group.addTask { await task(itemProvider) }
            }
            
            for await value in group {
                if let url = value {
                    values.append(url)
                }
            }
            
            return values
        }
    }
}

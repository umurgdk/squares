//
//  NSItemProvider+resolveFileURLs.swift
//  Squares
//
//  Created by Umur Gedik on 7.11.2021.
//

import UniformTypeIdentifiers
import Foundation

extension Array where Element == NSItemProvider {
    func resolveFileURLs() async -> [URL] {
        return await withTaskGroup(of: URL?.self) { group in
            var urls: [URL] = []
            
            for itemProvider in self {
                group.addTask {
                    let data = try? await itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) as? Data
                    return data.flatMap { data in URL(dataRepresentation: data, relativeTo: nil) }
                }
            }
            
            for await url in group {
                if let url = url {
                    urls.append(url)
                }
            }
            
            return urls
        }
    }
}

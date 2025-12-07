//
//  ModelContainer.swift
//  mojisampler
//
//  Created by mizznoff on 2025/11/10.
//

import Foundation
import SwiftData

public extension ModelContainer {
    static let shared: ModelContainer = {
        do {
            let isStoredInMemoryOnly: Bool
            #if DEBUG
                isStoredInMemoryOnly = false
            #else
                // TODO: 準備が整ったら false にする
                isStoredInMemoryOnly = true
            #endif
            return try .init(for: AnalyzedImage.self, Word.self, Tag.self, configurations: ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly))
        } catch {
            fatalError("Failed to init modelContainer: \(error)")
        }
    }()
}

//
//  Tag.swift
//  mojisampler
//
//  Created by Tsubasa YABUKI on 2025/11/13.
//

import Foundation
import SwiftData

@Model
public final class Tag: Identifiable, @unchecked Sendable {
    @Attribute(.unique) public private(set) var id: UUID
    public private(set) var text: String
    @Relationship(deleteRule: .nullify, inverse: \Word.tags) public var words: [Word]

    public init(id: UUID = .init(), text: String, words: [Word] = []) {
        self.id = id
        self.text = text
        self.words = words
    }
}

public extension Tag {
    #if DEBUG
        static var mockTags: [Tag] {
            [
                Tag(text: "道頓堀"),
                Tag(text: "あたたかい"),
                Tag(text: "独特"),
                Tag(text: "看板"),
                Tag(text: "あのひとへ"),
                Tag(text: "手書き"),
            ]
        }
    #endif
}

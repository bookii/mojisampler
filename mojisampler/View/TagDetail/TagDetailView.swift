//
//  TagDetailView.swift
//  mojisampler
//
//  Created by mizznoff on 2025/12/09.
//

import SwiftData
import SwiftUI

public struct TagDetailView: View {
    private enum Destination: Hashable {
        case textEditor(tag: Tag)
        case wordDetail(_ word: Word)
    }

    private let tag: Tag
    private var words: [Word]
    @Environment(\.modelContext) private var modelContext
    @Binding private var path: NavigationPath

    public init(path: Binding<NavigationPath>, tag: Tag) {
        _path = path
        self.tag = tag
        words = tag.words
    }

    public var body: some View {
        Group {
            if words.isEmpty {
                Text("ワードはありません")
            } else {
                ScrollView {
                    WordsFlowLayoutView(words)
                        .onSelectWord { word in
                            path.append(Destination.wordDetail(word))
                        }
                }
            }
        }
        .padding(16)
        .navigationTitle("#\(tag.text)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Destination.self) { destination in
            switch destination {
            case let .wordDetail(word):
                WordDetailView(path: $path, word: word)
            case let .textEditor(tag):
                TextEditorView(path: $path, tag: tag)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("", systemImage: "square.and.pencil") {
                    path.append(Destination.textEditor(tag: tag))
                }
            }
        }
    }
}

#if DEBUG
    #Preview {
        NavigationRootView { path in
            TagDetailView(path: path, tag: Tag.mockTags.first!)
        }
    }
#endif

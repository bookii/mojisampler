//
//  WordsScrollFlowView.swift
//  mojisampler
//
//  Created by mizznoff on 2025/11/06.
//

import SwiftUI

public struct WordsFlowLayoutView: View {
    private var words: [Word]
    private var onLastWordAppearAction: (() -> Void)?
    private var onSelectWordAction: ((Word) -> Void)?
    private var onDeleteWordAction: ((Word) -> Void)?

    public init(_ words: [Word]) {
        self.words = words
    }

    public var body: some View {
        HStack(spacing: 0) {
            FlowLayout(alignment: .topLeading, spacing: 8) {
                ForEach(words) { word in
                    if let uiImage = UIImage(data: word.imageData) {
                        Button {
                            onSelectWordAction?(word)
                        } label: {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 66)
                                .onAppear {
                                    if word.id == words.last?.id {
                                        onLastWordAppearAction?()
                                    }
                                }
                        }
                        .contextMenu {
                            if let onDeleteWordAction {
                                Button("削除", role: .destructive) {
                                    onDeleteWordAction(word)
                                }
                            }
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - ViewModifier

    public func onLastWordAppear(perform onLastWordAppearAction: @escaping () -> Void) -> Self {
        var view = self
        view.onLastWordAppearAction = onLastWordAppearAction
        return view
    }

    public func onSelectWord(perform onSelectWordAction: @escaping (Word) -> Void) -> Self {
        var view = self
        view.onSelectWordAction = onSelectWordAction
        return view
    }

    public func onDeleteWord(perform onDeleteWordAction: @escaping (Word) -> Void) -> Self {
        var view = self
        view.onDeleteWordAction = onDeleteWordAction
        return view
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var words = [Word]()
        @Previewable @State var text = ""
        ScrollView {
            VStack {
                WordsFlowLayoutView(words)
                    .onLastWordAppear {
                        text = "Last word appeared"
                    }
                    .onSelectWord { word in
                        text = "\(word.text) selected"
                    }
                    .onDeleteWord { word in
                        words.removeAll { $0.id == word.id }
                    }
                    .frame(maxWidth: .infinity)
                Text(text)
            }
            .padding(16)
        }
        .task {
            words = await AnalyzedImage.mockAnalyzedImage().words
        }
    }
#endif

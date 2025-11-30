//
//  WordsScrollFlowView.swift
//  mojisampler
//
//  Created by mizznoff on 2025/11/06.
//

import SwiftUI

public struct WordsScrollFlowView: View {
    private var words: [Word]
    private var onLastWordAppearAction: (() -> Void)?
    private var onSelectWord: ((Word) -> Void)?

    public init(words: [Word]) {
        self.words = words
    }

    public var body: some View {
        ScrollView {
            FlowLayout(alignment: .topLeading, spacing: 8) {
                ForEach(words) { word in
                    if let uiImage = UIImage(data: word.imageData) {
                        Button {
                            onSelectWord?(word)
                        } label: {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 66)
                                .onAppear {
                                    guard word.id == words.last?.id else {
                                        return
                                    }
                                    // TODO: 2回目以降に読み込まない不具合の修正
                                    onLastWordAppearAction?()
                                }
                        }
                    }
                }
            }
        }
    }

    // MARK: - ViewModifier

    public func onLastWordAppear(perform onLastWordAppearAction: @escaping () -> Void) -> Self {
        var view = self
        view.onLastWordAppearAction = onLastWordAppearAction
        return view
    }

    public func onSelectWord(perform onSelectWord: @escaping (Word) -> Void) -> Self {
        var view = self
        view.onSelectWord = onSelectWord
        return view
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var words = [Word]()
        @Previewable @State var text = ""
        VStack {
            WordsScrollFlowView(words: words)
                .onLastWordAppear {
                    text = "Last word appeared"
                }
                .task {
                    words = await AnalyzedImage.mockAnalyzedImage().words
                }
            Text(text)
        }
    }
#endif

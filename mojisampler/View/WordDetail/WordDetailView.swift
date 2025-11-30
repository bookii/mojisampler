//
//  WordDetailView.swift
//  mojisampler
//
//  Created by Tsubasa YABUKI on 2025/11/30.
//

import SwiftUI

public struct WordDetailView: View {
    @Binding private var path: NavigationPath
    private let word: Word

    public init(path: Binding<NavigationPath>, word: Word) {
        _path = path
        self.word = word
    }

    public var body: some View {
        if let uiImage = UIImage(data: word.imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(height: 66)
                .onAppear {
                    // DEBUG
                    for tag in word.tags {
                        print(tag.text)
                    }
                }
        }
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var word: Word?
        NavigationRootView { path in
            if let word {
                WordDetailView(path: path, word: word)
            }
        }
        .task {
            word = await Word.mockWords().first!
        }
    }
#endif

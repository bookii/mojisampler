//
//  WordDetailView.swift
//  mojisampler
//
//  Created by Tsubasa YABUKI on 2025/11/30.
//

import SwiftData
import SwiftUI

public struct WordDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var imageMaxHeight: CGFloat?
    @State private var error: Error?
    @State private var isErrorAlertPresented: Bool = false
    @Binding private var path: NavigationPath
    private let word: Word

    public init(path: Binding<NavigationPath>, word: Word) {
        _path = path
        self.word = word
    }

    public var body: some View {
        VStack(spacing: 16) {
            if let uiImage = UIImage(data: word.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: uiImage.isPortrait ? imageMaxHeight : nil)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("タグ")
                    .font(.headline)
                ScrollView {
                    TagsFlowLayoutView(word.tags)
                        .onDeleteTag { deletedTag in
                            word.tags.removeAll { $0.id == deletedTag.id }
                        }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { width in
                imageMaxHeight = width
            }
        }
        .padding(.horizontal, 16)
        .navigationTitle(word.text)
        .alert(error?.localizedDescription ?? "Unknown error", isPresented: $isErrorAlertPresented) {
            Button("OK") {
                self.error = nil
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    do {
                        modelContext.delete(word)
                        try modelContext.save()
                        dismiss()
                    } catch {
                        self.error = error
                        isErrorAlertPresented = true
                    }
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }
}

private extension UIImage {
    var isPortrait: Bool {
        size.width < size.height
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var word: Word?
        NavigationRootView { path in
            if let word {
                WordDetailView(path: path, word: word)
                    .padding(.leading, 16)
            }
        }
        .task {
            word = await Word.mockWords().first!
        }
    }
#endif

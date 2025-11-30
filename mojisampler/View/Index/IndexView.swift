//
//  IndexView.swift
//  mojisampler
//
//  Created by mizznoff on 2025/10/27.
//

import PhotosUI
import SwiftData
import SwiftUI

public struct IndexView: View {
    private enum Destination: Hashable {
        case extractor(uiImage: UIImage)
        case textEditor
        case wordDetail(_ word: Word)
    }

    // DEBUG
    @Query private var tags: [Tag]

    @Query private var analyzedImages: [AnalyzedImage]
    @State private var pickerItem: PhotosPickerItem?
    @Binding private var path: NavigationPath

    public init(path: Binding<NavigationPath>) {
        _path = path
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text("集めた文字数: \(String(countCharacters()))")
                .font(.system(size: 24))
            WordsScrollFlowView(words: analyzedImages.flatMap(\.words))
                .onSelectWord { word in
                    path.append(Destination.wordDetail(word))
                }
        }
        .onChange(of: pickerItem) {
            guard let pickerItem else {
                return
            }
            pickerItem.loadTransferable(type: Data.self) { result in
                Task { @MainActor in
                    if pickerItem == self.pickerItem,
                       case let .success(data) = result,
                       let uiImage = data.flatMap({ UIImage(data: $0) })
                    {
                        self.path.append(Destination.extractor(uiImage: uiImage))
                    }
                }
            }
        }
        .navigationDestination(for: Destination.self) { destination in
            switch destination {
            case let .extractor(uiImage):
                ExtractorView(path: $path, uiImage: uiImage)
            case .textEditor:
                TextEditorView(path: $path)
            case let .wordDetail(word):
                WordDetailView(path: $path, word: word)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    path.append(Destination.textEditor)
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("", systemImage: "plus")
                }
            }
        }
    }

    private func countCharacters() -> Int {
        return analyzedImages.flatMap(\.words).reduce(0) { sum, word in
            sum + word.text.count
        }
    }
}

#if DEBUG
    #Preview {
        NavigationRootView { path in
            IndexView(path: path)
                .environment(\.analyzerService, MockAnalyzerService.shared)
                .modelContainer(ModelContainer.shared)
                .task {
                    await ModelContainer.shared.mainContext.insert(AnalyzedImage.mockAnalyzedImage())
                }
        }
    }
#endif

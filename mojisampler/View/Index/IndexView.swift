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
        case wordDetail(_ word: Word)
        case tagDetail(_ tag: Tag)
    }

    fileprivate enum TabType: Hashable {
        case words
        case tags
        case stats
    }

    @Binding private var path: NavigationPath
    @Query private var tags: [Tag]
    @Query private var analyzedImages: [AnalyzedImage]
    @State private var selectedTab: TabType = .words
    @State private var pickerItem: PhotosPickerItem?

    public init(path: Binding<NavigationPath>) {
        _path = path
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: TabType.words) {
                wordsView
            } label: {
                Image(systemName: "photo")
            }
            Tab(value: TabType.tags) {
                tagsView
            } label: {
                Image(systemName: "tag")
            }
            Tab(value: TabType.stats) {
                statsView
            } label: {
                Image(systemName: "chart.bar.xaxis")
            }
        }
        .padding(.horizontal, 16)
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
        .navigationTitle(selectedTab.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Destination.self) { destination in
            switch destination {
            case let .extractor(uiImage):
                ExtractorView(path: $path, uiImage: uiImage)
            case let .wordDetail(word):
                WordDetailView(path: $path, word: word)
            case let .tagDetail(tag):
                TagDetailView(path: $path, tag: tag)
            }
        }
        .toolbar {
            switch selectedTab {
            case .words:
                ToolbarItem(placement: .primaryAction) {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("", systemImage: "plus")
                    }
                }
            case .tags:
                ToolbarItem(placement: .primaryAction) {
                    Button("", systemImage: "plus") {}
                }
            case .stats:
                ToolbarItem {
                    EmptyView()
                }
            }
        }
    }

    private var wordsView: some View {
        ScrollView {
            WordsFlowLayoutView(analyzedImages.flatMap(\.words))
                .onSelectWord { word in
                    path.append(Destination.wordDetail(word))
                }
        }
    }

    private var tagsView: some View {
        ScrollView {
            TagsFlowLayoutView(tags)
                .onSelectTag { tag in
                    path.append(Destination.tagDetail(tag))
                }
        }
    }

    private var statsView: some View {
        Text("集めた文字数: \(String(countCharacters()))")
            .font(.system(size: 24))
    }

    private func countCharacters() -> Int {
        return analyzedImages.flatMap(\.words).reduce(0) { sum, word in
            sum + word.text.count
        }
    }
}

private extension IndexView.TabType {
    var title: String {
        switch self {
        case .words:
            "ワード一覧"
        case .tags:
            "タグ一覧"
        case .stats:
            "統計"
        }
    }
}

#if DEBUG
    #Preview {
        @Previewable let modelContext = ModelContainer.shared.mainContext
        NavigationRootView { path in
            IndexView(path: path)
                .environment(\.analyzerService, MockAnalyzerService.shared)
                .modelContainer(ModelContainer.shared)
                .task {
                    for tag in Tag.mockTags {
                        modelContext.insert(tag)
                    }
                    await modelContext.insert(AnalyzedImage.mockAnalyzedImage())
                }
        }
    }
#endif

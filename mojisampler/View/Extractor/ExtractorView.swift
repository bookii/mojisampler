//
//  ExtractorView.swift
//  mojisampler
//
//  Created by mizznoff on 2025/10/30.
//

import Foundation
import SwiftData
import SwiftUI
import UIKit

public struct ExtractorView: View {
    private let uiImage: UIImage
    @Environment(\.analyzerService) private var analyzerService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding private var path: NavigationPath
    @State private var analyzedImage: AnalyzedImage?
    @State private var error: Error?
    @State private var isErrorAlertPresented: Bool = false
    @State private var viewWidth: CGFloat = 0
    @State private var tagSearchWord: String = ""
    @State private var selectedTags: [Tag] = []
    @Query private var allTags: [Tag]
    private var suggestedTags: [Tag] {
        guard !tagSearchWord.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }
        return allTags.filter { allTag in !selectedTags.contains(where: { $0.text == allTag.text }) }
            .filter { $0.text.localizedStandardContains(tagSearchWord) }
            .prefix(5)
            .map(\.self)
    }

    public init(path: Binding<NavigationPath>, uiImage: UIImage) {
        _path = path
        self.uiImage = uiImage
    }

    public var body: some View {
        Group {
            if let analyzedImage {
                mainView(analyzedImage: analyzedImage)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("文字のサンプリング")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !suggestedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestedTags) { tag in
                            Button {
                                selectedTags.append(tag)
                                tagSearchWord = ""
                            } label: {
                                tagView(tag)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .scrollClipDisabled()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") {
                    guard let analyzedImage else {
                        return
                    }
                    for word in analyzedImage.words {
                        word.tags = selectedTags
                        modelContext.insert(word)
                    }
                    modelContext.insert(analyzedImage)
                    for tag in selectedTags {
                        modelContext.insert(tag)
                    }
                    do {
                        try modelContext.save()
                        dismiss()
                    } catch {
                        self.error = error
                        isErrorAlertPresented = true
                    }
                }
                .disabled(selectedTags.isEmpty)
            }
            ToolbarItem(placement: .bottomBar) {
                TextField("タグを入力", text: $tagSearchWord)
                    .padding(.leading, 16)
            }
            ToolbarItem(placement: .bottomBar) {
                Button("", systemImage: "plus", role: .none) {
                    selectedTags.append(.init(text: tagSearchWord))
                    tagSearchWord = ""
                }
                .disabled(tagSearchWord.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .alert(error?.localizedDescription ?? "Unknown error", isPresented: $isErrorAlertPresented) {
            Button("OK") {
                self.error = nil
            }
        }
        .task {
            do {
                analyzedImage = try await analyzerService.analyzeImage(uiImage)
            } catch {
                self.error = error
            }
        }
    }

    private func mainView(analyzedImage: AnalyzedImage) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(selectedTags) { tag in
                        Menu {
                            Button("削除", role: .destructive) {
                                selectedTags.removeAll(where: { $0.id == tag.id })
                            }
                        } label: {
                            tagView(tag)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollClipDisabled()
            ScrollView {
                WordsFlowLayoutView(data: .init(words: analyzedImage.words))
                    .onGeometryChange(for: CGFloat.self, of: \.size.width) { width in
                        viewWidth = width
                    }
                    .padding(.horizontal, 16)
            }
        }
    }

    private func tagView(_ tag: Tag) -> some View {
        Text("#\(tag.text)")
            .font(.body)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(in: Capsule())
            .backgroundStyle(Color.blue)
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var uiImage: UIImage? = nil
        NavigationRootView { path in
            if let uiImage {
                ExtractorView(path: path, uiImage: uiImage)
            }
        }
        .environment(\.analyzerService, MockAnalyzerService.shared)
        .task {
            uiImage = await UIImage.mockImage()
        }
    }
#endif

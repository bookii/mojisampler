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
    @Environment(\.analyzerService) private var analyzerService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding private var path: NavigationPath
    @State private var analyzedImage: AnalyzedImage?
    @State private var error: Error?
    @State private var isErrorAlertPresented: Bool = false
    @State private var viewWidth: CGFloat = 0
    @State private var tagSearchWord: String = ""
    @State private var tags: [Tag] = []
    private let uiImage: UIImage

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") {
                    guard let analyzedImage else {
                        return
                    }
                    for word in analyzedImage.words {
                        word.tags = tags
                        modelContext.insert(word)
                    }
                    modelContext.insert(analyzedImage)
                    for tag in tags {
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
                .disabled(tags.isEmpty)
            }
            ToolbarItem(placement: .bottomBar) {
                TextField("タグを入力", text: $tagSearchWord)
                    .padding(.leading, 16)
            }
            ToolbarItem(placement: .bottomBar) {
                Button("", systemImage: "plus", role: .none) {
                    tags.append(.init(text: tagSearchWord))
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
                    ForEach(tags) { tag in
                        tagView(tag)
                    }
                }
            }
            ScrollView {
                WordsFlowLayoutView(analyzedImage.words)
                    .onGeometryChange(for: CGFloat.self, of: \.size.width) { width in
                        viewWidth = width
                    }
            }
        }
        .padding(.horizontal, 16)
    }

    private func tagView(_ tag: Tag) -> some View {
        Menu {
            Button("削除", role: .destructive) {
                tags.removeAll(where: { $0.id == tag.id })
            }
        } label: {
            Text("#\(tag.text)")
                .font(.body)
        }
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

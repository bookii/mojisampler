//
//  TextEditorView.swift
//  mojisampler
//
//  Created by mizznoff on 2025/11/03.
//

import Photos
import SwiftData
import SwiftUI

public struct TextEditorView: View {
    public enum Error: LocalizedError {
        case photoLibraryUnavailable
    }

    fileprivate enum WordPickerTab: String, CaseIterable, Identifiable {
        case basedOnTag
        case others

        var id: String {
            rawValue
        }
    }

    private let tag: Tag
    @Environment(\.dismiss) private var dismiss
    @Binding private var path: NavigationPath
    @State private var viewModel = ImageConvertiveTextViewModel()
    @State private var selectedWordPickerTab: WordPickerTab = .basedOnTag
    @State private var savedImage: UIImage?
    @State private var isSaveCompletionAlertPresented: Bool = false
    @State private var isShareSheetPresented: Bool = false
    @State private var error: Swift.Error?
    @State private var isErrorAlertPresented: Bool = false

    public init(path: Binding<NavigationPath>, tag: Tag) {
        _path = path
        self.tag = tag
    }

    public var body: some View {
        VStack(spacing: 16) {
            textView
            wordPickerTabView
        }
        .padding(16)
        .frame(maxHeight: .infinity)
        .background {
            Color.gray
                .ignoresSafeArea()
        }
        .task {
            selectedWordPickerTab = selectedWordPickerTab
        }
        .navigationTitle("テキストの作成")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.render()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
            }
        }
        .alert("テキスト画像を保存しました", isPresented: $isSaveCompletionAlertPresented) {
            Button("共有する") {
                isShareSheetPresented = true
            }
            Button("閉じる") {
                dismiss()
            }
        }
        .alert(error?.localizedDescription ?? "Unknown error", isPresented: $isErrorAlertPresented) {
            Button("OK") {
                self.error = nil
            }
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let savedImage {
                ShareImageActivityView(uiImage: savedImage)
            }
        }
        .onChange(of: selectedWordPickerTab) { _, newValue in
            viewModel.setEditable(newValue == .others)
        }
    }

    private var textView: some View {
        ImageConvertiveTextView(viewModel: viewModel)
            .onRenderImage { uiImage in
                Task {
                    do {
                        try await saveImage(uiImage)
                        await MainActor.run {
                            self.savedImage = uiImage
                            self.isSaveCompletionAlertPresented = true
                        }
                    } catch {
                        await MainActor.run {
                            self.error = error
                            self.isErrorAlertPresented = true
                        }
                    }
                }
            }
            .onReceiveError { error in
                self.error = error
                isErrorAlertPresented = true
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var wordPickerTabView: some View {
        Picker("", selection: $selectedWordPickerTab) {
            ForEach(WordPickerTab.allCases) { wordPickerTab in
                Text(wordPickerTab.title)
                    .tag(wordPickerTab)
            }
        }
        .pickerStyle(.segmented)
    }

    private var wordPicker: some View {
        EmptyView()
    }

    // MARK: - ViewModifier

    private nonisolated func saveImage(_ uiImage: UIImage) async throws {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized:
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
            }
        case .notDetermined:
            if await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized {
                try await saveImage(uiImage)
            } else {
                throw Error.photoLibraryUnavailable
            }
        default:
            throw Error.photoLibraryUnavailable
        }
    }
}

private extension TextEditorView.WordPickerTab {
    var title: String {
        switch self {
        case .basedOnTag:
            "タグ"
        case .others:
            "その他"
        }
    }
}

#if DEBUG
    #Preview {
        NavigationRootView { path in
            TextEditorView(path: path, tag: Tag.mockTags.first!)
        }
    }
#endif

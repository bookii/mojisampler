//
//  TagScrollFlowView.swift
//  mojisampler
//
//  Created by mizznoff on 2025/12/07.
//

import SwiftUI

public struct TagsFlowLayoutView: View {
    private let tags: [Tag]
    private var onLastTagAppearAction: (() -> Void)?
    private var onSelectTagAction: ((Tag) -> Void)?
    private var onDeleteTagAction: ((Tag) -> Void)?

    public init(_ tags: [Tag]) {
        self.tags = tags
    }

    public var body: some View {
        HStack(spacing: 0) {
            FlowLayout(alignment: .topLeading, spacing: 8) {
                ForEach(tags) { tag in
                    Button {
                        onSelectTagAction?(tag)
                    } label: {
                        Text("#\(tag.text)")
                            .font(.body)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(in: Capsule())
                            .backgroundStyle(Color.blue)
                    }
                    .onAppear {
                        if tags.last?.id == tag.id {
                            onLastTagAppearAction?()
                        }
                    }
                    .contextMenu {
                        if let onDeleteTagAction {
                            Button("削除", role: .destructive) {
                                onDeleteTagAction(tag)
                            }
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - ViewModifier

    public func onLastTagAppear(perform onLastTagAppearAction: @escaping () -> Void) -> Self {
        var view = self
        view.onLastTagAppearAction = onLastTagAppearAction
        return view
    }

    public func onSelectTag(perform onSelectTagAction: @escaping (Tag) -> Void) -> Self {
        var view = self
        view.onSelectTagAction = onSelectTagAction
        return view
    }

    public func onDeleteTag(perform onDeleteTagAction: @escaping (Tag) -> Void) -> Self {
        var view = self
        view.onDeleteTagAction = onDeleteTagAction
        return view
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var tags = [Tag]()
        @Previewable @State var text = ""
        ScrollView {
            VStack {
                TagsFlowLayoutView(tags)
                    .onLastTagAppear {
                        text = "Last word appeared"
                    }
                    .onSelectTag { tag in
                        text = "#\(tag.text) selected"
                    }
                    .onDeleteTag { tag in
                        tags.removeAll { $0.id == tag.id }
                    }
                    .frame(maxWidth: .infinity)
                Text(text)
            }
            .padding(16)
        }
        .task {
            tags = Tag.mockTags
        }
    }
#endif

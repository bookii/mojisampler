//
//  ImageConvertiveTextView.swift
//  mojisampler
//
//  Created by mizznoff on 2025/11/03.
//

import Foundation
import SwiftUI
import UIKit

@Observable
public final class ImageConvertiveTextViewModel {
    fileprivate enum Command {
        case replace(markedText: String, uiImage: UIImage)
        case render
    }

    fileprivate var isFirstResponder: Bool = false
    fileprivate var command: Command?
    fileprivate var isEditable: Bool = false

    public func replace(markedText: String, with uiImage: UIImage) {
        command = .replace(markedText: markedText, uiImage: uiImage)
    }

    public func render() {
        command = .render
    }

    public func setEditable(_ isEditable: Bool) {
        self.isEditable = isEditable
    }
}

public struct ImageConvertiveTextView: UIViewRepresentable {
    private let textView = UITextView()
    @Bindable private var viewModel: ImageConvertiveTextViewModel
    fileprivate var onReceiveErrorAction: ((Error) -> Void)?
    private var onRenderImageAction: ((UIImage) -> Void)?

    public init(viewModel: ImageConvertiveTextViewModel) {
        self.viewModel = viewModel
    }

    public func makeUIView(context: Context) -> UITextView {
        textView.font = .systemFont(ofSize: 24)
        textView.delegate = context.coordinator
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.textContainerInset = .init(top: 8, left: 8, bottom: 8, right: 8)

        let width = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.width ?? 0
        let toolbarFrame = CGRect(x: 0, y: 0, width: width, height: 44)
        let toolbar = UIToolbar(frame: toolbarFrame)
        let collectionView = HorizontalWordCollectionView(frame: toolbarFrame)
        toolbar.addSubview(collectionView)
        textView.inputAccessoryView = toolbar
        textView.isEditable = viewModel.isEditable
        viewModel.isFirstResponder = viewModel.isEditable

        context.coordinator.textView = textView
        context.coordinator.collectionView = collectionView

        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        Task { @MainActor in
            if uiView.isEditable != viewModel.isEditable {
                uiView.isEditable = viewModel.isEditable
                viewModel.isFirstResponder = viewModel.isEditable
            }
            if viewModel.isFirstResponder, !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            } else if !viewModel.isFirstResponder, uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }

        if let command = viewModel.command {
            defer {
                Task { @MainActor in
                    viewModel.command = nil
                }
            }
            switch command {
            case let .replace(markedText, uiImage):
                guard let attributedText = textView.attributedText else {
                    return
                }
                let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
                let fullText = mutableAttributedText.string
                guard let range = fullText.range(of: markedText, options: .backwards) else {
                    return
                }

                let nsRange = NSRange(range, in: fullText)
                let attachment = NSTextAttachment()
                attachment.image = uiImage

                let imageSize = uiImage.size
                let height: CGFloat = 32
                let scale = height / imageSize.height
                attachment.bounds = CGRect(x: 0, y: -8, width: imageSize.width * scale, height: height)

                let imageAttributedString = NSAttributedString(attachment: attachment)
                mutableAttributedText.replaceCharacters(in: nsRange, with: imageAttributedString)

                textView.attributedText = mutableAttributedText
                textView.font = .systemFont(ofSize: 24)
            case .render:
                if let uiImage = context.coordinator.render() {
                    onRenderImageAction?(uiImage)
                }
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject {
        fileprivate weak var textView: UITextView?
        fileprivate weak var collectionView: HorizontalWordCollectionView? {
            didSet {
                collectionView?.horizontalWordCollectionViewDelegate = self
            }
        }

        private let parent: ImageConvertiveTextView

        fileprivate init(_ parent: ImageConvertiveTextView) {
            self.parent = parent
            super.init()
        }

        fileprivate func render() -> UIImage? {
            guard let textView else {
                return nil
            }
            let selectedTextRange = textView.selectedTextRange
            textView.selectedTextRange = nil
            let width = textView.bounds.width
            let height = textView.sizeThatFits(.init(width: width, height: .greatestFiniteMagnitude)).height
            let render = UIGraphicsImageRenderer(size: .init(width: width, height: height))
            let image = render.image { context in
                textView.layer.render(in: context.cgContext)
                textView.selectedTextRange = selectedTextRange
            }
            return image
        }
    }

    // MARK: - ViewModifier

    public func onRenderImage(perform action: @escaping (UIImage) -> Void) -> Self {
        var view = self
        view.onRenderImageAction = action
        return view
    }

    public func onReceiveError(perform action: @escaping (Error) -> Void) -> Self {
        var view = self
        view.onReceiveErrorAction = action
        return view
    }

    // MARK: - Methods

    public func replace(markedText: String, in attributedText: NSAttributedString, with uiImage: UIImage) -> NSAttributedString? {
        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
        let fullText = mutableAttributedText.string
        guard let range = fullText.range(of: markedText, options: .backwards) else {
            return nil
        }

        let nsRange = NSRange(range, in: fullText)
        let attachment = NSTextAttachment()
        attachment.image = uiImage

        let imageSize = uiImage.size
        let height: CGFloat = 32
        let scale = height / imageSize.height
        attachment.bounds = CGRect(x: 0, y: -8, width: imageSize.width * scale, height: height)

        let imageAttributedString = NSAttributedString(attachment: attachment)
        mutableAttributedText.replaceCharacters(in: nsRange, with: imageAttributedString)

        return mutableAttributedText
    }
}

extension ImageConvertiveTextView.Coordinator: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        collectionView?.fullAttributedText = textView.attributedText
        if let markedTextRange = textView.markedTextRange, let markedText = textView.text(in: markedTextRange) {
            collectionView?.markedText = markedText
        }
    }

    public func textViewDidBeginEditing(_: UITextView) {
        parent.viewModel.isFirstResponder = true
    }

    public func textViewDidEndEditing(_: UITextView) {
        parent.viewModel.isFirstResponder = false
    }
}

extension ImageConvertiveTextView.Coordinator: HorizontalWordCollectionViewDelegate {
    public func horizontalWordCollectionView(_: HorizontalWordCollectionView, shouldReplace markedText: String, with uiImage: UIImage) {
        parent.viewModel.replace(markedText: markedText, with: uiImage)
    }

    public func horizontalWordCollectionView(_: HorizontalWordCollectionView, didReceive error: Error) {
        parent.onReceiveErrorAction?(error)
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var viewModel = ImageConvertiveTextViewModel()

        ImageConvertiveTextView(viewModel: viewModel)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(16)
            .background {
                Color.gray
                    .ignoresSafeArea()
            }
    }
#endif

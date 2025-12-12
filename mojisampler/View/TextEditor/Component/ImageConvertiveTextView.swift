//
//  ImageConvertiveTextView.swift
//  mojisampler
//
//  Created by mizznoff on 2025/12/12.
//

import Foundation
import SwiftUI
import UIKit

public class ImageConvertiveTextView: UITextView {
    public enum InputMode {
        case basedOnTag(words: [Word])
        case others
    }

    public var inputMode: InputMode = .others {
        didSet {
            Task { @MainActor in
                UIView.performWithoutAnimation {
                    switch (oldValue, inputMode) {
                    case let (.others, .basedOnTag(words)):
                        inputView = wordsFlowLayoutViewHostingController.view
                        inputAccessoryView = nil
                        data.words = words
                        resignFirstResponder()
                        becomeFirstResponder()
                    case (.basedOnTag, .others):
                        inputView = nil
                        inputAccessoryView = wordsToolbar
                        data.words = []
                        resignFirstResponder()
                        becomeFirstResponder()
                    default:
                        break
                    }
                }
            }
        }
    }

    private let fontSize: CGFloat = 28
    private let data = WordsFlowLayoutView.Data()
    private let wordsCollectionView: HorizontalWordCollectionView
    private let wordsToolbar: UIToolbar
    private var wordsFlowLayoutViewHostingController: UIHostingController<WordsFlowLayoutScrollView>

    public init() {
        let width = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.width ?? 0
        let toolbarFrame = CGRect(x: 0, y: 0, width: width, height: 52)
        let toolbar = UIToolbar(frame: toolbarFrame)
        wordsCollectionView = HorizontalWordCollectionView(frame: .init(x: toolbarFrame.origin.x + 16,
                                                                        y: toolbarFrame.origin.y,
                                                                        width: toolbarFrame.width - 32,
                                                                        height: toolbarFrame.height - 8))
        toolbar.addSubview(wordsCollectionView)
        wordsToolbar = toolbar

        let hostingController = UIHostingController(rootView: WordsFlowLayoutScrollView(data: data))

        let screenSize: CGSize = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.size ?? .zero
        hostingController.view.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height * 0.3)
        hostingController.view.backgroundColor = .clear
        wordsFlowLayoutViewHostingController = hostingController

        super.init(frame: .zero, textContainer: nil)

        font = .systemFont(ofSize: fontSize)
        isEditable = true
        delegate = self
        wordsCollectionView.horizontalWordCollectionViewDelegate = self

        hostingController.rootView = hostingController.rootView
            .onSelectWord { [weak self] word in
                guard let uiImage = UIImage(data: word.imageData) else {
                    return
                }
                self?.insert(uiImage: uiImage)
            }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func replace(markedText: String, with uiImage: UIImage) {
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

        attributedText = mutableAttributedText
        font = .systemFont(ofSize: fontSize)
    }

    public func insert(uiImage: UIImage) {
        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)

        let attachment = NSTextAttachment()
        attachment.image = uiImage

        let imageSize = uiImage.size
        let height: CGFloat = 32
        let scale = height / imageSize.height
        attachment.bounds = CGRect(x: 0, y: -8, width: imageSize.width * scale, height: height)

        let imageAttributedString = NSAttributedString(attachment: attachment)
        mutableAttributedText.insert(imageAttributedString, at: selectedRanges.first!.location)
        attributedText = mutableAttributedText
        font = .systemFont(ofSize: fontSize)
    }

    public func render() -> UIImage {
        let selectedTextRange = selectedTextRange
        self.selectedTextRange = nil
        let width = bounds.width
        let height = sizeThatFits(.init(width: bounds.width, height: .greatestFiniteMagnitude)).height
        let render = UIGraphicsImageRenderer(size: .init(width: width, height: height))
        let image = render.image { context in
            layer.render(in: context.cgContext)
            self.selectedTextRange = selectedTextRange
        }
        return image
    }
}

extension ImageConvertiveTextView: HorizontalWordCollectionViewDelegate {
    public func horizontalWordCollectionView(_: HorizontalWordCollectionView, shouldReplace markedText: String, with uiImage: UIImage) {
        replace(markedText: markedText, with: uiImage)
    }

    public func horizontalWordCollectionView(_: HorizontalWordCollectionView, didReceive _: Error) {
        // TODO: エラーの伝播
    }
}

private struct WordsFlowLayoutScrollView: View {
    private var data: WordsFlowLayoutView.Data
    private var onSelectWordAction: ((Word) -> Void)?

    fileprivate init(data: WordsFlowLayoutView.Data) {
        self.data = data
    }

    fileprivate var body: some View {
        ScrollView {
            WordsFlowLayoutView(data: data)
                .onSelectWord { word in
                    onSelectWordAction?(word)
                }
                .padding(16)
        }
        .background(Color(.systemBackground))
        .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 24, topTrailing: 24)))
    }

    fileprivate func onSelectWord(perform onSelectWordAction: @escaping (Word) -> Void) -> Self {
        var view = self
        view.onSelectWordAction = onSelectWordAction
        return view
    }
}

extension ImageConvertiveTextView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        wordsCollectionView.fullAttributedText = textView.attributedText
        if let markedTextRange = textView.markedTextRange, let markedText = textView.text(in: markedTextRange) {
            wordsCollectionView.markedText = markedText
        }
    }
}

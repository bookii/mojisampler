//
//  ImageConvertiveTextViewRepresentable.swift
//  mojisampler
//
//  Created by mizznoff on 2025/11/03.
//

import Foundation
import SwiftUI

public struct ImageConvertiveTextViewRepresentable: UIViewRepresentable {
    public typealias InputMode = ImageConvertiveTextView.InputMode

    @Observable
    public class Data {
        public var inputMode: InputMode
        public var shouldRender: Bool

        public init(inputMode: InputMode = .others, shouldRender: Bool = false) {
            self.inputMode = inputMode
            self.shouldRender = shouldRender
        }
    }

    private let textView = ImageConvertiveTextView()
    @Binding private var data: Data
    private var onRenderImageAction: ((UIImage) -> Void)?

    public init(data: Binding<Data>) {
        _data = data
    }

    public func makeUIView(context _: Context) -> ImageConvertiveTextView {
        return textView
    }

    public func updateUIView(_ uiView: ImageConvertiveTextView, context _: Context) {
        uiView.inputMode = data.inputMode

        if data.shouldRender {
            if let onRenderImageAction {
                onRenderImageAction(uiView.render())
            }
            data.shouldRender = false
        }
    }

    // MARK: - ViewModifier

    public func onRenderImage(perform action: @escaping (UIImage) -> Void) -> Self {
        var view = self
        view.onRenderImageAction = action
        return view
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var data = ImageConvertiveTextViewRepresentable.Data()
        ImageConvertiveTextViewRepresentable(data: $data)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(16)
            .background {
                Color.gray
                    .ignoresSafeArea()
            }
    }
#endif

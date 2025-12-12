//
//  HorizontalWordCollectionView.swift
//  mojisampler
//
//  Created by mizznoff on 2025/11/06.
//

import Foundation
import SwiftData
import UIKit

@MainActor
public protocol HorizontalWordCollectionViewDelegate: AnyObject {
    func horizontalWordCollectionView(_ collectionView: HorizontalWordCollectionView, shouldReplace markedText: String, with uiImage: UIImage)
    func horizontalWordCollectionView(_ collectionView: HorizontalWordCollectionView, didReceive error: Error)
}

public final class HorizontalWordCollectionView: UICollectionView {
    // MARK: - Properties

    public weak var horizontalWordCollectionViewDelegate: HorizontalWordCollectionViewDelegate?

    public var fullAttributedText: NSAttributedString = .init(string: "")
    public var markedText: String = "" {
        didSet {
            updateCandidateWords()
        }
    }

    fileprivate let cellIdentifier = "HorizontalWordCollectionViewCell"
    private var candidateWords: [Word] = []

    // MARK: - Lifecycle

    public init(frame: CGRect) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 4
        flowLayout.sectionInset = .init(top: 0, left: 8, bottom: 0, right: 8)
        super.init(frame: frame, collectionViewLayout: flowLayout)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        register(HorizontalWordCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        dataSource = self
        delegate = self

        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        backgroundColor = .systemBackground
        layer.cornerRadius = 8
        contentInsetAdjustmentBehavior = .never
    }

    // MARK: - Methods

    private func updateCandidateWords() {
        if markedText.isEmpty {
            candidateWords = []
            reloadData()
            return
        }
        do {
            var descriptor = FetchDescriptor<Word>(
                predicate: #Predicate { $0.text.starts(with: markedText) },
                sortBy: [.init(\.text, order: .reverse)]
            )
            descriptor.fetchLimit = 10
            candidateWords = try ModelContainer.shared.mainContext.fetch(descriptor)
        } catch {
            candidateWords = []
            horizontalWordCollectionViewDelegate?.horizontalWordCollectionView(self, didReceive: error)
        }
        reloadData()
    }
}

// MARK: - HorizontalWordCollectionView (UICollectionViewDelegateFlowLayout)

extension HorizontalWordCollectionView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let height = collectionView.bounds.height
        // TODO: width を flexible にする
        return CGSize(width: height, height: height)
    }
}

// MARK: - HorizontalWordCollectionView (UICollectionViewDataSource)

extension HorizontalWordCollectionView: UICollectionViewDataSource {
    public func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        candidateWords.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? HorizontalWordCollectionViewCell else {
            fatalError("Failed to cast cell")
        }
        let candidateWord = candidateWords[indexPath.row]
        cell.id = candidateWord.id
        cell.image = UIImage(data: candidateWord.imageData)
        return cell
    }
}

// MARK: - HorizontalWordCollectionView (UICollectionViewDelegate)

extension HorizontalWordCollectionView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !markedText.isEmpty,
              candidateWords.indices.contains(indexPath.row),
              let uiImage = UIImage(data: candidateWords[indexPath.row].imageData)
        else {
            return
        }
        horizontalWordCollectionViewDelegate?.horizontalWordCollectionView(self, shouldReplace: markedText, with: uiImage)
        candidateWords = []
        collectionView.reloadData()
    }
}

//
//  FlowLayout.swift
//  mojisampler
//
//  Created by mizznoff on 2025/11/05.
//

import SwiftUI

// ref: https://github.com/apple/sample-food-truck/blob/main/App/General/FlowLayout.swift
public struct FlowLayout: Layout {
    private let alignment: Alignment
    private let spacing: CGFloat?

    public init(alignment: Alignment = .center, spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width,
                                subviews: subviews,
                                alignment: alignment,
                                spacing: spacing)
        return result.bounds
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width,
                                subviews: subviews,
                                alignment: alignment,
                                spacing: spacing)
        for row in result.rows {
            let rowXOffset = (bounds.width - row.frame.width) * alignment.horizontal.percent()
            for index in row.range {
                let xPos = rowXOffset + row.frame.minX + row.xOffsets[index - row.range.lowerBound] + bounds.minX
                let rowYAlignment = (row.frame.height - subviews[index].sizeThatFits(.unspecified).height) * alignment.vertical.percent()
                let yPos = row.frame.minY + rowYAlignment + bounds.minY
                subviews[index].place(at: CGPoint(x: xPos, y: yPos), anchor: .topLeading, proposal: .unspecified)
            }
        }
    }

    private struct FlowResult {
        var bounds = CGSize.zero
        var rows = [Row]()

        struct Row {
            var range: Range<Int>
            var xOffsets: [Double]
            var frame: CGRect
        }

        init(in maxPossibleWidth: Double, subviews: Subviews, alignment _: Alignment, spacing: CGFloat?) {
            var itemsInRow = 0
            var remainingWidth = maxPossibleWidth.isFinite ? maxPossibleWidth : .greatestFiniteMagnitude
            var rowMinY = 0.0
            var rowHeight = 0.0
            var xOffsets: [Double] = []
            for (index, subview) in zip(subviews.indices, subviews) {
                let idealSize = subview.sizeThatFits(.unspecified)
                if index != 0, widthInRow(index: index, idealWidth: idealSize.width) > remainingWidth {
                    // Finish the current row without this subview.
                    finalizeRow(index: max(index - 1, 0), idealSize: idealSize)
                }
                addToRow(index: index, idealSize: idealSize)

                if index == subviews.endIndex - 1 {
                    // Finish this row; it's either full or on the last view anyway.
                    finalizeRow(index: index, idealSize: idealSize)
                }
            }

            func spacingBefore(index: Int) -> Double {
                guard itemsInRow > 0 else {
                    return 0
                }
                return spacing ?? subviews[index - 1].spacing.distance(to: subviews[index].spacing, along: .horizontal)
            }

            func widthInRow(index: Int, idealWidth: Double) -> Double {
                idealWidth + spacingBefore(index: index)
            }

            func addToRow(index: Int, idealSize: CGSize) {
                let width = widthInRow(index: index, idealWidth: idealSize.width)

                xOffsets.append(maxPossibleWidth - remainingWidth + spacingBefore(index: index))
                // Allocate width to this item (and spacing).
                remainingWidth -= width
                // Ensure the row height is as tall as the tallest item.
                rowHeight = max(rowHeight, idealSize.height)
                // Can fit in this row, add it.
                itemsInRow += 1
            }

            func finalizeRow(index: Int, idealSize _: CGSize) {
                let rowWidth = maxPossibleWidth - remainingWidth
                rows.append(Row(range: index - max(itemsInRow - 1, 0) ..< index + 1,
                                xOffsets: xOffsets,
                                frame: CGRect(x: 0, y: rowMinY, width: rowWidth, height: rowHeight)))
                bounds.width = max(bounds.width, rowWidth)
                let ySpacing = spacing ?? ViewSpacing().distance(to: ViewSpacing(), along: .vertical)
                bounds.height += rowHeight + ySpacing
                rowMinY += rowHeight + ySpacing
                itemsInRow = 0
                rowHeight = 0
                xOffsets.removeAll()
                remainingWidth = maxPossibleWidth
            }
        }
    }
}

private extension HorizontalAlignment {
    nonisolated func percent() -> Double {
        switch self {
        case .leading: 0
        case .trailing: 1
        default: 0.5
        }
    }
}

private extension VerticalAlignment {
    nonisolated func percent() -> Double {
        switch self {
        case .top: 0
        case .bottom: 1
        default: 0.5
        }
    }
}

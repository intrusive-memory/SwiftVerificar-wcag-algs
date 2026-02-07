import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// A vector graphics content chunk extracted from a PDF document.
///
/// Represents complex vector art composed of a collection of line segments
/// (paths/lines). `LineArtChunk` is used to detect visual structures such as
/// decorative borders, diagrams, flowcharts, and other non-text graphical
/// elements that may require alternative text for accessibility.
///
/// The overall bounding box encompasses all constituent lines.
///
/// `LineArtChunk` conforms to `ContentChunk`, making it interoperable with
/// other content types in the content analysis pipeline.
///
/// - Note: Ported from veraPDF-wcag-algs `LineArtChunk` Java class.
public struct LineArtChunk: ContentChunk, Sendable, Hashable, Codable {

    // MARK: - ContentChunk Conformance

    /// The bounding box of this line art chunk, encompassing all lines.
    public let boundingBox: BoundingBox

    // MARK: - Line Art Properties

    /// The individual line segments that compose this vector graphic.
    public let lines: [LineChunk]

    // MARK: - Accessibility Properties

    /// The alternative text for this line art, if provided.
    ///
    /// In accessible PDFs, meaningful graphics should have alt text
    /// describing their content.
    public let altText: String?

    /// The actual text replacement for this line art, if provided.
    public let actualText: String?

    // MARK: - Initialization

    /// Creates a new line art chunk with explicit bounding box.
    ///
    /// - Parameters:
    ///   - boundingBox: The spatial location and page of this line art.
    ///   - lines: The line segments composing the vector graphic.
    ///   - altText: The alternative text, if any.
    ///   - actualText: The actual text replacement, if any.
    public init(
        boundingBox: BoundingBox,
        lines: [LineChunk],
        altText: String? = nil,
        actualText: String? = nil
    ) {
        self.boundingBox = boundingBox
        self.lines = lines
        self.altText = altText
        self.actualText = actualText
    }

    /// Creates a new line art chunk, automatically computing the bounding
    /// box from the constituent line segments.
    ///
    /// All lines must be on the same page. If the lines array is empty,
    /// the bounding box defaults to a zero-sized box at the origin on page 0.
    ///
    /// - Parameters:
    ///   - lines: The line segments composing the vector graphic.
    ///   - altText: The alternative text, if any.
    ///   - actualText: The actual text replacement, if any.
    public init(
        lines: [LineChunk],
        altText: String? = nil,
        actualText: String? = nil
    ) {
        self.lines = lines
        self.altText = altText
        self.actualText = actualText

        if let first = lines.first {
            let combined = lines.dropFirst().reduce(first.boundingBox) { result, line in
                result.union(with: line.boundingBox) ?? result
            }
            self.boundingBox = combined
        } else {
            self.boundingBox = BoundingBox(pageIndex: 0, rect: .zero)
        }
    }

    // MARK: - Computed Properties

    /// Whether this line art has any form of alternative text.
    ///
    /// Per WCAG 2.1 Success Criterion 1.1.1, meaningful non-text content
    /// must have a text alternative.
    public var hasAlternativeText: Bool {
        (altText != nil && altText?.isEmpty == false)
            || (actualText != nil && actualText?.isEmpty == false)
    }

    /// The number of line segments in this vector graphic.
    public var lineCount: Int {
        lines.count
    }

    /// Whether this line art chunk contains no lines.
    public var isEmpty: Bool {
        lines.isEmpty
    }

    /// The total length of all line segments combined.
    public var totalLength: CGFloat {
        lines.reduce(0) { $0 + $1.length }
    }

    /// The horizontal line segments in this line art.
    public var horizontalLines: [LineChunk] {
        lines.filter(\.isHorizontal)
    }

    /// The vertical line segments in this line art.
    public var verticalLines: [LineChunk] {
        lines.filter(\.isVertical)
    }

    /// Whether this line art appears to be a grid or table-like structure.
    ///
    /// A simple heuristic: the art contains at least 2 horizontal and
    /// 2 vertical lines.
    public var appearsGridLike: Bool {
        horizontalLines.count >= 2 && verticalLines.count >= 2
    }

    /// The best available text description for this line art.
    ///
    /// Prefers `altText` over `actualText`. Returns `nil` if neither is available.
    public var textDescription: String? {
        if let alt = altText, !alt.isEmpty {
            return alt
        }
        if let actual = actualText, !actual.isEmpty {
            return actual
        }
        return nil
    }

    /// The total area covered by the bounding box of this line art.
    public var area: CGFloat {
        boundingBox.area
    }
}

import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// A block of text lines, representing a paragraph-like unit.
///
/// A `TextBlock` groups multiple `TextLine` values into a coherent block
/// of text, typically corresponding to a paragraph or other block-level
/// text element in the document. The `text` computed property joins all
/// line texts with newline separators.
///
/// - Note: Ported from veraPDF-wcag-algs `TextBlock` Java class.
public struct TextBlock: ContentChunk, Sendable, Hashable {

    // MARK: - ContentChunk Conformance

    /// The bounding box of this text block, covering all contained lines.
    public let boundingBox: BoundingBox

    // MARK: - Properties

    /// The text lines that compose this block, in reading order.
    public let lines: [TextLine]

    // MARK: - Initialization

    /// Creates a new text block from lines.
    ///
    /// - Parameters:
    ///   - boundingBox: The bounding box covering all lines in this block.
    ///   - lines: The text lines composing this block, in reading order.
    public init(boundingBox: BoundingBox, lines: [TextLine]) {
        self.boundingBox = boundingBox
        self.lines = lines
    }

    // MARK: - Computed Properties

    /// The concatenated text content of all lines, joined by newlines.
    public var text: String {
        lines.map(\.text).joined(separator: "\n")
    }

    /// The total number of lines in this block.
    public var lineCount: Int {
        lines.count
    }

    /// The total number of text chunks across all lines.
    public var totalChunkCount: Int {
        lines.reduce(0) { $0 + $1.chunkCount }
    }

    /// Whether this block has no text content.
    public var isEmpty: Bool {
        lines.isEmpty || text.isEmpty
    }

    /// All text chunks from all lines in this block, in reading order.
    public var allChunks: [TextChunk] {
        lines.flatMap(\.chunks)
    }
}

// MARK: - Codable

extension TextBlock: Codable {

    enum CodingKeys: String, CodingKey {
        case boundingBox
        case lines
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.boundingBox = try container.decode(BoundingBox.self, forKey: .boundingBox)
        self.lines = try container.decode([TextLine].self, forKey: .lines)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(lines, forKey: .lines)
    }
}

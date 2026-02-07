import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// A column of text blocks.
///
/// Represents a vertical column of text on a PDF page, composed of
/// one or more `TextBlock` values. Columns are used to model multi-column
/// page layouts where text flows top-to-bottom within a column before
/// continuing to the next column.
///
/// - Note: Ported from veraPDF-wcag-algs `TextColumn` Java class.
public struct TextColumn: ContentChunk, Sendable, Hashable {

    // MARK: - ContentChunk Conformance

    /// The bounding box of this text column, covering all contained blocks.
    public let boundingBox: BoundingBox

    // MARK: - Properties

    /// The text blocks that compose this column, in reading order.
    public let blocks: [TextBlock]

    // MARK: - Initialization

    /// Creates a new text column from blocks.
    ///
    /// - Parameters:
    ///   - boundingBox: The bounding box covering all blocks in this column.
    ///   - blocks: The text blocks composing this column, in reading order.
    public init(boundingBox: BoundingBox, blocks: [TextBlock]) {
        self.boundingBox = boundingBox
        self.blocks = blocks
    }

    // MARK: - Computed Properties

    /// The concatenated text content of all blocks, joined by double newlines.
    public var text: String {
        blocks.map(\.text).joined(separator: "\n\n")
    }

    /// The total number of blocks in this column.
    public var blockCount: Int {
        blocks.count
    }

    /// The total number of lines across all blocks in this column.
    public var totalLineCount: Int {
        blocks.reduce(0) { $0 + $1.lineCount }
    }

    /// The total number of text chunks across all blocks and lines.
    public var totalChunkCount: Int {
        blocks.reduce(0) { $0 + $1.totalChunkCount }
    }

    /// Whether this column has no text content.
    public var isEmpty: Bool {
        blocks.isEmpty || text.isEmpty
    }

    /// All text lines from all blocks in this column, in reading order.
    public var allLines: [TextLine] {
        blocks.flatMap(\.lines)
    }

    /// All text chunks from all blocks and lines in this column, in reading order.
    public var allChunks: [TextChunk] {
        blocks.flatMap(\.allChunks)
    }
}

// MARK: - Codable

extension TextColumn: Codable {

    enum CodingKeys: String, CodingKey {
        case boundingBox
        case blocks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.boundingBox = try container.decode(BoundingBox.self, forKey: .boundingBox)
        self.blocks = try container.decode([TextBlock].self, forKey: .blocks)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(blocks, forKey: .blocks)
    }
}

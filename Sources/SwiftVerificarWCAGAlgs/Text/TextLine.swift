import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// A line of text content composed of one or more text chunks.
///
/// Represents a horizontal line of text on a PDF page. A line contains
/// one or more `TextChunk` values, each potentially with different
/// font properties and colors. The `text` computed property concatenates
/// all chunk values.
///
/// Lines track whether they are the start or end of a logical text block,
/// which is useful for paragraph detection and reading order analysis.
///
/// - Note: Ported from veraPDF-wcag-algs `TextLine` Java class.
public struct TextLine: ContentChunk, Sendable, Hashable {

    // MARK: - ContentChunk Conformance

    /// The bounding box of this text line, covering all contained chunks.
    public let boundingBox: BoundingBox

    // MARK: - Properties

    /// The text chunks that compose this line, in reading order.
    public let chunks: [TextChunk]

    /// Whether this is the first line of a logical text block.
    public let isLineStart: Bool

    /// Whether this is the last line of a logical text block.
    public let isLineEnd: Bool

    // MARK: - Initialization

    /// Creates a new text line from chunks and position flags.
    ///
    /// - Parameters:
    ///   - boundingBox: The bounding box covering all chunks in this line.
    ///   - chunks: The text chunks composing this line, in reading order.
    ///   - isLineStart: Whether this is the first line of a block.
    ///   - isLineEnd: Whether this is the last line of a block.
    public init(
        boundingBox: BoundingBox,
        chunks: [TextChunk],
        isLineStart: Bool = false,
        isLineEnd: Bool = false
    ) {
        self.boundingBox = boundingBox
        self.chunks = chunks
        self.isLineStart = isLineStart
        self.isLineEnd = isLineEnd
    }

    // MARK: - Computed Properties

    /// The concatenated text content of all chunks in this line.
    public var text: String {
        chunks.map(\.value).joined()
    }

    /// The number of chunks in this line.
    public var chunkCount: Int {
        chunks.count
    }

    /// Whether this line has no text content.
    public var isEmpty: Bool {
        chunks.isEmpty || text.isEmpty
    }
}

// MARK: - Codable

extension TextLine: Codable {

    enum CodingKeys: String, CodingKey {
        case boundingBox
        case chunks
        case isLineStart
        case isLineEnd
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.boundingBox = try container.decode(BoundingBox.self, forKey: .boundingBox)
        self.chunks = try container.decode([TextChunk].self, forKey: .chunks)
        self.isLineStart = try container.decode(Bool.self, forKey: .isLineStart)
        self.isLineEnd = try container.decode(Bool.self, forKey: .isLineEnd)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(chunks, forKey: .chunks)
        try container.encode(isLineStart, forKey: .isLineStart)
        try container.encode(isLineEnd, forKey: .isLineEnd)
    }
}

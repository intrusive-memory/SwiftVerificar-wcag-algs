import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// A generic content node for text-based semantic elements.
///
/// `ContentNode` is the workhorse struct for representing most semantic
/// elements in a PDF structure tree, including paragraphs, headings, spans,
/// block quotes, captions, and other text-containing elements.
///
/// ## Consolidation
///
/// This struct consolidates 15+ Java semantic node subclasses:
/// - `SemanticTextNode`, `SemanticSpan`, `SemanticParagraph`
/// - `SemanticHeading`, `SemanticH1`-`SemanticH6`
/// - `SemanticBlockQuote`, `SemanticCaption`, `SemanticCode`
/// - `SemanticSection`, `SemanticDiv`, `SemanticDocument`
/// - And other text-containing structure elements
///
/// The `type` property (a `SemanticType` enum case) discriminates between
/// these different semantic roles.
///
/// ## Text Content
///
/// The `textBlocks` array contains the actual text content as `TextBlock`
/// instances, preserving the line and paragraph structure for accessibility
/// analysis such as contrast checking and reading order validation.
///
/// ## Typography
///
/// The `dominantFontSize`, `dominantFontWeight`, and `dominantColor`
/// properties represent the most common typographic attributes in the
/// node's content, used for detecting large text and contrast requirements.
///
/// - Note: Ported from multiple veraPDF-wcag-algs Java classes.
public struct ContentNode: SemanticNode, Sendable, Hashable {

    // MARK: - SemanticNode Conformance

    /// The unique identifier for this node.
    public let id: UUID

    /// The semantic type of this node.
    ///
    /// Determines the role this content plays in the document structure.
    /// Common values include `.paragraph`, `.heading`, `.h1`-`.h6`,
    /// `.span`, `.blockQuote`, `.caption`, `.code`, etc.
    public let type: SemanticType

    /// The bounding box of this node, if it has a spatial location.
    public let boundingBox: BoundingBox?

    /// The child nodes of this node, in document order.
    public let children: [any SemanticNode]

    /// The attributes dictionary from the PDF structure element.
    public let attributes: AttributesDictionary

    /// The depth of this node in the structure tree.
    public let depth: Int

    /// Error codes detected during validation of this node.
    public var errorCodes: Set<SemanticErrorCode>

    // MARK: - Content Properties

    /// The text blocks containing the actual text content of this node.
    ///
    /// Preserves the paragraph and line structure for accessibility
    /// analysis.
    public let textBlocks: [TextBlock]

    /// The dominant (most common) font size in the content.
    ///
    /// Used to determine if the text qualifies as "large text" per
    /// WCAG contrast requirements.
    public let dominantFontSize: CGFloat?

    /// The dominant (most common) font weight in the content.
    ///
    /// Used along with font size to determine large text status
    /// (14pt bold is equivalent to 18pt regular).
    public let dominantFontWeight: CGFloat?

    /// The dominant (most common) text color in the content.
    ///
    /// Used for contrast ratio calculations.
    public let dominantColor: CGColor?

    // MARK: - Initialization

    /// Creates a new content node with all properties.
    ///
    /// - Parameters:
    ///   - id: The unique identifier (defaults to a new UUID).
    ///   - type: The semantic type of this node.
    ///   - boundingBox: The spatial location, if any.
    ///   - children: The child nodes.
    ///   - attributes: The PDF structure element attributes.
    ///   - depth: The depth in the structure tree.
    ///   - errorCodes: Initial error codes (defaults to empty).
    ///   - textBlocks: The text content blocks.
    ///   - dominantFontSize: The dominant font size.
    ///   - dominantFontWeight: The dominant font weight.
    ///   - dominantColor: The dominant text color.
    public init(
        id: UUID = UUID(),
        type: SemanticType,
        boundingBox: BoundingBox? = nil,
        children: [any SemanticNode] = [],
        attributes: AttributesDictionary = [:],
        depth: Int = 0,
        errorCodes: Set<SemanticErrorCode> = [],
        textBlocks: [TextBlock] = [],
        dominantFontSize: CGFloat? = nil,
        dominantFontWeight: CGFloat? = nil,
        dominantColor: CGColor? = nil
    ) {
        self.id = id
        self.type = type
        self.boundingBox = boundingBox
        self.children = children
        self.attributes = attributes
        self.depth = depth
        self.errorCodes = errorCodes
        self.textBlocks = textBlocks
        self.dominantFontSize = dominantFontSize
        self.dominantFontWeight = dominantFontWeight
        self.dominantColor = dominantColor
    }

    /// Creates a simple content node with minimal properties.
    ///
    /// - Parameters:
    ///   - type: The semantic type of this node.
    ///   - depth: The depth in the structure tree.
    public init(type: SemanticType, depth: Int = 0) {
        self.init(
            id: UUID(),
            type: type,
            boundingBox: nil,
            children: [],
            attributes: [:],
            depth: depth,
            errorCodes: [],
            textBlocks: [],
            dominantFontSize: nil,
            dominantFontWeight: nil,
            dominantColor: nil
        )
    }

    // MARK: - Computed Properties

    /// The concatenated text content of all text blocks.
    public var text: String {
        textBlocks.map(\.text).joined(separator: "\n\n")
    }

    /// Whether this node has any text content.
    public var hasTextContent: Bool {
        !textBlocks.isEmpty && !text.isEmpty
    }

    /// The total number of text blocks.
    public var textBlockCount: Int {
        textBlocks.count
    }

    /// The total number of text lines across all blocks.
    public var totalLineCount: Int {
        textBlocks.reduce(0) { $0 + $1.lineCount }
    }

    /// The total number of text chunks across all blocks and lines.
    public var totalChunkCount: Int {
        textBlocks.reduce(0) { $0 + $1.totalChunkCount }
    }

    /// Whether the dominant font qualifies as "large text" per WCAG.
    ///
    /// Large text is defined as 18pt or larger, or 14pt bold or larger.
    /// Large text has reduced contrast requirements (3:1 vs 4.5:1 for AA).
    public var isLargeText: Bool {
        guard let fontSize = dominantFontSize else { return false }

        // 18pt or larger is always large text
        if fontSize >= 18 {
            return true
        }

        // 14pt bold or larger is large text
        if fontSize >= 14, let weight = dominantFontWeight, weight >= 700 {
            return true
        }

        return false
    }

    /// The text type classification for WCAG contrast requirements.
    public var textType: TextType {
        isLargeText ? .large : .regular
    }

    /// Whether this is a heading node (H, H1-H6).
    public var isHeading: Bool {
        type.isHeading
    }

    /// The heading level if this is a specific heading (H1-H6).
    public var headingLevel: Int? {
        type.headingLevel
    }

    // MARK: - Factory Methods

    /// Creates a document root node.
    ///
    /// - Parameters:
    ///   - children: The top-level children of the document.
    ///   - attributes: The document attributes.
    /// - Returns: A content node with type `.document`.
    public static func document(
        children: [any SemanticNode] = [],
        attributes: AttributesDictionary = [:]
    ) -> ContentNode {
        ContentNode(
            type: .document,
            boundingBox: nil,
            children: children,
            attributes: attributes,
            depth: 0
        )
    }

    /// Creates a paragraph node.
    ///
    /// - Parameters:
    ///   - boundingBox: The spatial location.
    ///   - textBlocks: The text content.
    ///   - depth: The depth in the structure tree.
    ///   - attributes: The paragraph attributes.
    /// - Returns: A content node with type `.paragraph`.
    public static func paragraph(
        boundingBox: BoundingBox? = nil,
        textBlocks: [TextBlock] = [],
        depth: Int = 1,
        attributes: AttributesDictionary = [:]
    ) -> ContentNode {
        ContentNode(
            type: .paragraph,
            boundingBox: boundingBox,
            children: [],
            attributes: attributes,
            depth: depth,
            textBlocks: textBlocks
        )
    }

    /// Creates a heading node at the specified level.
    ///
    /// - Parameters:
    ///   - level: The heading level (1-6). Values outside this range
    ///            result in a generic `.heading` type.
    ///   - boundingBox: The spatial location.
    ///   - textBlocks: The heading text content.
    ///   - depth: The depth in the structure tree.
    ///   - attributes: The heading attributes.
    /// - Returns: A content node with the appropriate heading type.
    public static func heading(
        level: Int,
        boundingBox: BoundingBox? = nil,
        textBlocks: [TextBlock] = [],
        depth: Int = 1,
        attributes: AttributesDictionary = [:]
    ) -> ContentNode {
        let type: SemanticType
        switch level {
        case 1: type = .h1
        case 2: type = .h2
        case 3: type = .h3
        case 4: type = .h4
        case 5: type = .h5
        case 6: type = .h6
        default: type = .heading
        }

        return ContentNode(
            type: type,
            boundingBox: boundingBox,
            children: [],
            attributes: attributes,
            depth: depth,
            textBlocks: textBlocks
        )
    }

    /// Creates a span node.
    ///
    /// - Parameters:
    ///   - boundingBox: The spatial location.
    ///   - textBlocks: The span text content.
    ///   - depth: The depth in the structure tree.
    ///   - attributes: The span attributes.
    /// - Returns: A content node with type `.span`.
    public static func span(
        boundingBox: BoundingBox? = nil,
        textBlocks: [TextBlock] = [],
        depth: Int = 2,
        attributes: AttributesDictionary = [:]
    ) -> ContentNode {
        ContentNode(
            type: .span,
            boundingBox: boundingBox,
            children: [],
            attributes: attributes,
            depth: depth,
            textBlocks: textBlocks
        )
    }

    /// Creates a caption node.
    ///
    /// - Parameters:
    ///   - boundingBox: The spatial location.
    ///   - textBlocks: The caption text content.
    ///   - depth: The depth in the structure tree.
    ///   - attributes: The caption attributes.
    /// - Returns: A content node with type `.caption`.
    public static func caption(
        boundingBox: BoundingBox? = nil,
        textBlocks: [TextBlock] = [],
        depth: Int = 2,
        attributes: AttributesDictionary = [:]
    ) -> ContentNode {
        ContentNode(
            type: .caption,
            boundingBox: boundingBox,
            children: [],
            attributes: attributes,
            depth: depth,
            textBlocks: textBlocks
        )
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Equatable

    public static func == (lhs: ContentNode, rhs: ContentNode) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable

extension ContentNode: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case boundingBox
        case attributes
        case depth
        case errorCodes
        case textBlocks
        case dominantFontSize
        case dominantFontWeight
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.type = try container.decode(SemanticType.self, forKey: .type)
        self.boundingBox = try container.decodeIfPresent(BoundingBox.self, forKey: .boundingBox)
        self.attributes = try container.decode(AttributesDictionary.self, forKey: .attributes)
        self.depth = try container.decode(Int.self, forKey: .depth)
        self.errorCodes = try container.decode(Set<SemanticErrorCode>.self, forKey: .errorCodes)
        self.textBlocks = try container.decode([TextBlock].self, forKey: .textBlocks)
        self.dominantFontSize = try container.decodeIfPresent(CGFloat.self, forKey: .dominantFontSize)
        self.dominantFontWeight = try container.decodeIfPresent(CGFloat.self, forKey: .dominantFontWeight)
        // Children and dominantColor are not encoded (children would be recursive,
        // CGColor is not Codable)
        self.children = []
        self.dominantColor = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(boundingBox, forKey: .boundingBox)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(depth, forKey: .depth)
        try container.encode(errorCodes, forKey: .errorCodes)
        try container.encode(textBlocks, forKey: .textBlocks)
        try container.encodeIfPresent(dominantFontSize, forKey: .dominantFontSize)
        try container.encodeIfPresent(dominantFontWeight, forKey: .dominantFontWeight)
        // Children and dominantColor are not encoded
    }
}

// MARK: - CustomStringConvertible

extension ContentNode: CustomStringConvertible {

    public var description: String {
        let indent = String(repeating: "  ", count: depth)
        let textPreview = text.prefix(50).replacingOccurrences(of: "\n", with: " ")
        let truncated = text.count > 50 ? "..." : ""
        return "\(indent)<\(type.rawValue)>\(textPreview)\(truncated)</\(type.rawValue)>"
    }
}

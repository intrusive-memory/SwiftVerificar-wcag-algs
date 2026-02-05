import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// A semantic node representing a figure or illustration in the document.
///
/// `FigureNode` is specialized for non-text content that typically requires
/// alternative text for accessibility. It tracks image chunks and line art
/// chunks that compose the visual content, along with accessibility
/// attributes like `Alt` and `ActualText`.
///
/// ## WCAG Requirements
///
/// Per WCAG 2.1 Success Criterion 1.1.1 (Non-text Content), all figures
/// must have text alternatives that serve the equivalent purpose, unless
/// they are purely decorative (in which case they should be marked as
/// artifacts, not figures).
///
/// ## Content Types
///
/// A figure may contain:
/// - **Images**: Raster graphics (`ImageChunk`)
/// - **Line Art**: Vector graphics (`LineArtChunk`)
/// - **Nested Content**: Text captions or other elements as children
///
/// ## Caption Association
///
/// Figures often have associated captions. The `caption` computed property
/// searches children for a caption node. Proper caption association is
/// a PDF/UA requirement.
///
/// - Note: Ported from veraPDF-wcag-algs `SemanticFigure` Java class.
public struct FigureNode: SemanticNode, Sendable, Hashable {

    // MARK: - SemanticNode Conformance

    /// The unique identifier for this node.
    public let id: UUID

    /// The semantic type is always `.figure` for FigureNode.
    public var type: SemanticType { .figure }

    /// The bounding box of this figure.
    public let boundingBox: BoundingBox?

    /// The child nodes (may include captions and other nested content).
    public let children: [any SemanticNode]

    /// The attributes dictionary from the PDF structure element.
    public let attributes: AttributesDictionary

    /// The depth of this node in the structure tree.
    public let depth: Int

    /// Error codes detected during validation.
    public var errorCodes: Set<SemanticErrorCode>

    // MARK: - Figure-Specific Properties

    /// The image chunks contained in this figure.
    public let imageChunks: [ImageChunk]

    /// The line art chunks contained in this figure.
    public let lineArtChunks: [LineArtChunk]

    // MARK: - Initialization

    /// Creates a new figure node with all properties.
    ///
    /// - Parameters:
    ///   - id: The unique identifier (defaults to a new UUID).
    ///   - boundingBox: The spatial location, if any.
    ///   - children: The child nodes (e.g., captions).
    ///   - attributes: The PDF structure element attributes.
    ///   - depth: The depth in the structure tree.
    ///   - errorCodes: Initial error codes (defaults to empty).
    ///   - imageChunks: The image content.
    ///   - lineArtChunks: The line art content.
    public init(
        id: UUID = UUID(),
        boundingBox: BoundingBox? = nil,
        children: [any SemanticNode] = [],
        attributes: AttributesDictionary = [:],
        depth: Int = 1,
        errorCodes: Set<SemanticErrorCode> = [],
        imageChunks: [ImageChunk] = [],
        lineArtChunks: [LineArtChunk] = []
    ) {
        self.id = id
        self.boundingBox = boundingBox
        self.children = children
        self.attributes = attributes
        self.depth = depth
        self.errorCodes = errorCodes
        self.imageChunks = imageChunks
        self.lineArtChunks = lineArtChunks
    }

    /// Creates a figure node with a single image.
    ///
    /// - Parameters:
    ///   - image: The image chunk for this figure.
    ///   - depth: The depth in the structure tree.
    ///   - attributes: The figure attributes (include Alt for accessibility).
    /// - Returns: A figure node containing the image.
    public init(
        image: ImageChunk,
        depth: Int = 1,
        attributes: AttributesDictionary = [:]
    ) {
        self.init(
            boundingBox: image.boundingBox,
            attributes: attributes,
            depth: depth,
            imageChunks: [image]
        )
    }

    /// Creates a figure node with line art.
    ///
    /// - Parameters:
    ///   - lineArt: The line art chunk for this figure.
    ///   - depth: The depth in the structure tree.
    ///   - attributes: The figure attributes.
    /// - Returns: A figure node containing the line art.
    public init(
        lineArt: LineArtChunk,
        depth: Int = 1,
        attributes: AttributesDictionary = [:]
    ) {
        self.init(
            boundingBox: lineArt.boundingBox,
            attributes: attributes,
            depth: depth,
            lineArtChunks: [lineArt]
        )
    }

    // MARK: - Computed Properties

    /// Whether this figure has any visual content (images or line art).
    public var hasVisualContent: Bool {
        !imageChunks.isEmpty || !lineArtChunks.isEmpty
    }

    /// The total number of images in this figure.
    public var imageCount: Int {
        imageChunks.count
    }

    /// The total number of line art elements in this figure.
    public var lineArtCount: Int {
        lineArtChunks.count
    }

    /// The total number of visual elements (images + line art).
    public var visualElementCount: Int {
        imageCount + lineArtCount
    }

    /// Whether this figure has alternative text (Alt or ActualText attribute).
    ///
    /// This is a critical WCAG requirement for non-decorative figures.
    public var hasAltText: Bool {
        hasTextAlternative
    }

    /// Whether this figure appears to be purely decorative.
    ///
    /// A figure is considered decorative if it lacks alt text, has no
    /// functional purpose, and has no visual content. Figures with images
    /// or line art that lack alt text are NOT decorative - they need
    /// alternative text. Decorative figures should ideally be marked
    /// as artifacts rather than figures.
    public var appearsDecorative: Bool {
        !hasAltText && children.isEmpty && !hasVisualContent
    }

    /// The caption node associated with this figure, if any.
    ///
    /// Searches the direct children for a caption element.
    public var caption: ContentNode? {
        for child in children {
            if let content = child as? ContentNode, content.type == .caption {
                return content
            }
        }
        return nil
    }

    /// Whether this figure has an associated caption.
    public var hasCaption: Bool {
        caption != nil
    }

    /// The text content of the caption, if present.
    public var captionText: String? {
        caption?.text
    }

    /// The combined bounding box of all visual elements.
    ///
    /// If the figure has an explicit bounding box, that is returned.
    /// Otherwise, this computes the union of all image and line art
    /// bounding boxes.
    public var computedBoundingBox: BoundingBox? {
        if let explicit = boundingBox {
            return explicit
        }

        var boxes: [BoundingBox] = []
        boxes.append(contentsOf: imageChunks.map(\.boundingBox))
        boxes.append(contentsOf: lineArtChunks.map(\.boundingBox))

        guard let first = boxes.first else { return nil }

        return boxes.dropFirst().reduce(first) { result, box in
            result.union(with: box) ?? result
        }
    }

    /// The total pixel count of all images in this figure.
    public var totalPixelCount: Int {
        imageChunks.reduce(0) { $0 + $1.pixelCount }
    }

    /// Whether any image in this figure has alternative text.
    public var anyImageHasAltText: Bool {
        imageChunks.contains { $0.hasAlternativeText }
    }

    /// Whether any line art in this figure has alternative text.
    public var anyLineArtHasAltText: Bool {
        lineArtChunks.contains { $0.hasAlternativeText }
    }

    /// The best available description for this figure.
    ///
    /// Priority: figure's own alt text > caption text > image alt text
    public var bestDescription: String? {
        // First check figure's own alt text
        if let alt = textDescription {
            return alt
        }

        // Then check caption
        if let captionText = captionText, !captionText.isEmpty {
            return captionText
        }

        // Finally check images
        for image in imageChunks {
            if let desc = image.textDescription {
                return desc
            }
        }

        // Check line art
        for lineArt in lineArtChunks {
            if let desc = lineArt.textDescription {
                return desc
            }
        }

        return nil
    }

    // MARK: - Validation Helpers

    /// Validates accessibility requirements for this figure.
    ///
    /// Checks for missing alt text and other WCAG violations.
    ///
    /// - Returns: A set of error codes for any issues found.
    public func validateAccessibility() -> Set<SemanticErrorCode> {
        var errors = Set<SemanticErrorCode>()

        // Check for missing alt text
        if !hasAltText && !appearsDecorative {
            errors.insert(.figureMissingAltText)
        }

        // Check caption association (if there's a caption, it should be
        // a direct child)
        // This is handled in higher-level validation

        return errors
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Equatable

    public static func == (lhs: FigureNode, rhs: FigureNode) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable

extension FigureNode: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case boundingBox
        case attributes
        case depth
        case errorCodes
        case imageChunks
        case lineArtChunks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.boundingBox = try container.decodeIfPresent(BoundingBox.self, forKey: .boundingBox)
        self.attributes = try container.decode(AttributesDictionary.self, forKey: .attributes)
        self.depth = try container.decode(Int.self, forKey: .depth)
        self.errorCodes = try container.decode(Set<SemanticErrorCode>.self, forKey: .errorCodes)
        self.imageChunks = try container.decode([ImageChunk].self, forKey: .imageChunks)
        self.lineArtChunks = try container.decode([LineArtChunk].self, forKey: .lineArtChunks)
        // Children are not encoded
        self.children = []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(boundingBox, forKey: .boundingBox)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(depth, forKey: .depth)
        try container.encode(errorCodes, forKey: .errorCodes)
        try container.encode(imageChunks, forKey: .imageChunks)
        try container.encode(lineArtChunks, forKey: .lineArtChunks)
    }
}

// MARK: - CustomStringConvertible

extension FigureNode: CustomStringConvertible {

    public var description: String {
        let indent = String(repeating: "  ", count: depth)
        let content: String
        if !imageChunks.isEmpty {
            content = "\(imageCount) image(s)"
        } else if !lineArtChunks.isEmpty {
            content = "\(lineArtCount) line art"
        } else {
            content = "empty"
        }
        let alt = hasAltText ? " [has alt]" : ""
        return "\(indent)<Figure>\(content)\(alt)</Figure>"
    }
}

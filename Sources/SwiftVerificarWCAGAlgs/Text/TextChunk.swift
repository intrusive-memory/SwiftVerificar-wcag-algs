import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Text content chunk with full styling information.
///
/// Represents a discrete piece of text content extracted from a PDF document,
/// including font properties, color information, and spatial positioning.
/// This is the fundamental text unit used in WCAG accessibility analysis,
/// particularly for contrast ratio checking.
///
/// A `TextChunk` carries all the information needed to determine:
/// - Whether the text is "large" (for WCAG contrast thresholds)
/// - Whether it is bold or italic
/// - What the contrast ratio is between text and background
///
/// - Note: Ported from veraPDF-wcag-algs `TextChunk` and `TextInfoChunk` Java classes,
///   consolidated into a single value type.
public struct TextChunk: ContentChunk, Sendable, Hashable {

    // MARK: - ContentChunk Conformance

    /// The bounding box of this text chunk, specifying its location and page.
    public let boundingBox: BoundingBox

    // MARK: - Text Content

    /// The string value of this text chunk.
    public let value: String

    /// The positions of individual symbols/glyphs within this chunk.
    public let symbolPositions: [CGPoint]

    // MARK: - Font Properties

    /// The name of the font used for this text.
    public let fontName: String

    /// The font size in points.
    public let fontSize: CGFloat

    /// The font weight (CSS-style numeric weight, e.g. 400 for normal, 700 for bold).
    public let fontWeight: CGFloat

    /// The italic angle of the font in degrees.
    ///
    /// A non-zero value typically indicates an italic or oblique font.
    public let italicAngle: CGFloat

    // MARK: - Color Properties

    /// The foreground (text) color.
    public let textColor: CGColor

    /// The background color behind the text, if determinable.
    public let backgroundColor: CGColor?

    /// The computed contrast ratio between text color and background color.
    ///
    /// This value is `nil` if the background color could not be determined.
    public let contrastRatio: CGFloat?

    // MARK: - Formatting Properties

    /// Whether this text is underlined.
    public let isUnderlined: Bool

    /// The baseline offset of this text.
    public let baseline: CGFloat

    /// The visual slant angle of the glyphs in degrees.
    ///
    /// A value greater than 10 degrees indicates visually italic text,
    /// even if the font metadata does not report an italic angle.
    public let slantDegree: CGFloat

    // MARK: - Initialization

    /// Creates a new text chunk with all styling information.
    ///
    /// - Parameters:
    ///   - boundingBox: The spatial location and page of this text.
    ///   - value: The string content.
    ///   - fontName: The name of the font.
    ///   - fontSize: The font size in points.
    ///   - fontWeight: The font weight (CSS-style numeric).
    ///   - italicAngle: The italic angle of the font in degrees.
    ///   - textColor: The foreground color.
    ///   - backgroundColor: The background color, if known.
    ///   - contrastRatio: The contrast ratio, if computed.
    ///   - isUnderlined: Whether the text is underlined.
    ///   - baseline: The baseline offset.
    ///   - slantDegree: The visual slant angle in degrees.
    ///   - symbolPositions: The positions of individual glyphs.
    public init(
        boundingBox: BoundingBox,
        value: String,
        fontName: String,
        fontSize: CGFloat,
        fontWeight: CGFloat,
        italicAngle: CGFloat,
        textColor: CGColor,
        backgroundColor: CGColor? = nil,
        contrastRatio: CGFloat? = nil,
        isUnderlined: Bool = false,
        baseline: CGFloat = 0,
        slantDegree: CGFloat = 0,
        symbolPositions: [CGPoint] = []
    ) {
        self.boundingBox = boundingBox
        self.value = value
        self.fontName = fontName
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.italicAngle = italicAngle
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.contrastRatio = contrastRatio
        self.isUnderlined = isUnderlined
        self.baseline = baseline
        self.slantDegree = slantDegree
        self.symbolPositions = symbolPositions
    }

    // MARK: - Computed Properties

    /// Whether this text is italic, based on font italic angle or visual slant.
    ///
    /// Text is considered italic if:
    /// - The font's `italicAngle` is non-zero, OR
    /// - The visual `slantDegree` exceeds 10 degrees.
    public var isItalic: Bool {
        abs(italicAngle) > 0 || slantDegree > 10
    }

    /// Whether this text is bold, based on font weight.
    ///
    /// Text is considered bold if `fontWeight` is 600 or greater
    /// (corresponding to CSS "SemiBold" and above).
    public var isBold: Bool {
        fontWeight >= 600
    }

    /// The WCAG text type classification for contrast requirements.
    ///
    /// Per WCAG 2.1:
    /// - Font size >= 18pt is "large text"
    /// - Font size >= 14pt AND bold is "large text"
    /// - Otherwise it is "regular text"
    public var textType: TextType {
        if fontSize >= 18 {
            return .large
        }
        if fontSize >= 14 && isBold {
            return .large
        }
        return .regular
    }

    // MARK: - Hashable

    public static func == (lhs: TextChunk, rhs: TextChunk) -> Bool {
        lhs.boundingBox == rhs.boundingBox
            && lhs.value == rhs.value
            && lhs.fontName == rhs.fontName
            && lhs.fontSize == rhs.fontSize
            && lhs.fontWeight == rhs.fontWeight
            && lhs.italicAngle == rhs.italicAngle
            && lhs.isUnderlined == rhs.isUnderlined
            && lhs.baseline == rhs.baseline
            && lhs.slantDegree == rhs.slantDegree
            && lhs.symbolPositions == rhs.symbolPositions
            && lhs.contrastRatio == rhs.contrastRatio
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(boundingBox)
        hasher.combine(value)
        hasher.combine(fontName)
        hasher.combine(fontSize)
        hasher.combine(fontWeight)
        hasher.combine(italicAngle)
        hasher.combine(isUnderlined)
        hasher.combine(baseline)
        hasher.combine(slantDegree)
    }
}

// MARK: - Codable

extension TextChunk: Codable {

    enum CodingKeys: String, CodingKey {
        case boundingBox
        case value
        case fontName
        case fontSize
        case fontWeight
        case italicAngle
        case textColorComponents
        case backgroundColorComponents
        case contrastRatio
        case isUnderlined
        case baseline
        case slantDegree
        case symbolPositionXs
        case symbolPositionYs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.boundingBox = try container.decode(BoundingBox.self, forKey: .boundingBox)
        self.value = try container.decode(String.self, forKey: .value)
        self.fontName = try container.decode(String.self, forKey: .fontName)
        self.fontSize = try container.decode(CGFloat.self, forKey: .fontSize)
        self.fontWeight = try container.decode(CGFloat.self, forKey: .fontWeight)
        self.italicAngle = try container.decode(CGFloat.self, forKey: .italicAngle)
        self.isUnderlined = try container.decode(Bool.self, forKey: .isUnderlined)
        self.baseline = try container.decode(CGFloat.self, forKey: .baseline)
        self.slantDegree = try container.decode(CGFloat.self, forKey: .slantDegree)
        self.contrastRatio = try container.decodeIfPresent(CGFloat.self, forKey: .contrastRatio)

        // Decode CGColor from sRGB components
        let textComponents = try container.decode([CGFloat].self, forKey: .textColorComponents)
        self.textColor = TextChunk.cgColorFromComponents(textComponents)

        if let bgComponents = try container.decodeIfPresent([CGFloat].self, forKey: .backgroundColorComponents) {
            self.backgroundColor = TextChunk.cgColorFromComponents(bgComponents)
        } else {
            self.backgroundColor = nil
        }

        // Decode symbol positions from parallel arrays
        let xs = try container.decode([CGFloat].self, forKey: .symbolPositionXs)
        let ys = try container.decode([CGFloat].self, forKey: .symbolPositionYs)
        self.symbolPositions = zip(xs, ys).map { CGPoint(x: $0, y: $1) }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(value, forKey: .value)
        try container.encode(fontName, forKey: .fontName)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(fontWeight, forKey: .fontWeight)
        try container.encode(italicAngle, forKey: .italicAngle)
        try container.encode(isUnderlined, forKey: .isUnderlined)
        try container.encode(baseline, forKey: .baseline)
        try container.encode(slantDegree, forKey: .slantDegree)
        try container.encodeIfPresent(contrastRatio, forKey: .contrastRatio)

        // Encode CGColor as sRGB components
        try container.encode(TextChunk.componentsFromCGColor(textColor), forKey: .textColorComponents)
        if let bg = backgroundColor {
            try container.encode(TextChunk.componentsFromCGColor(bg), forKey: .backgroundColorComponents)
        }

        // Encode symbol positions as parallel arrays
        try container.encode(symbolPositions.map(\.x), forKey: .symbolPositionXs)
        try container.encode(symbolPositions.map(\.y), forKey: .symbolPositionYs)
    }

    // MARK: - CGColor Codable Helpers

    /// Extracts sRGB components from a CGColor for serialization.
    static func componentsFromCGColor(_ color: CGColor) -> [CGFloat] {
        guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = color.converted(to: srgb, intent: .defaultIntent, options: nil),
              let components = converted.components else {
            // Fallback: return as-is
            return color.components ?? [0, 0, 0, 1]
        }
        return Array(components)
    }

    /// Creates a CGColor from sRGB components.
    static func cgColorFromComponents(_ components: [CGFloat]) -> CGColor {
        guard let srgb = CGColorSpace(name: CGColorSpace.sRGB) else {
            // Fallback to generic RGB
            return CGColor(red: components.first ?? 0,
                           green: components.count > 1 ? components[1] : 0,
                           blue: components.count > 2 ? components[2] : 0,
                           alpha: components.count > 3 ? components[3] : 1)
        }
        return CGColor(colorSpace: srgb, components: components)
            ?? CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    }
}

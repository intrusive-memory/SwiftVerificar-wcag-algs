import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Extracts text content from semantic nodes for accessibility analysis.
///
/// `TextExtractor` provides utilities for gathering text content from semantic
/// nodes in various formats, including plain text, formatted text with styling
/// information, and text statistics for WCAG compliance checking.
///
/// ## Use Cases
///
/// - Extract all text content from a document for indexing or searching
/// - Gather text for reading order validation
/// - Analyze text properties (font size, weight, color) for contrast checking
/// - Compute dominant typography attributes for heading detection
/// - Generate text summaries for alt text validation
///
/// ## Example
///
/// ```swift
/// let extractor = TextExtractor()
/// let node = ContentNode.paragraph(textBlocks: [...])
///
/// // Extract plain text
/// let text = extractor.extractPlainText(from: node)
///
/// // Extract with statistics
/// let stats = extractor.extractTextStatistics(from: node)
/// print("Average font size: \(stats.averageFontSize)")
/// print("Dominant color: \(stats.dominantColor)")
/// ```
///
/// - Note: Ported from veraPDF-wcag-algs text extraction utilities.
public struct TextExtractor: Sendable, Hashable, Codable {

    // MARK: - Configuration

    /// Whether to preserve formatting information during extraction.
    public let preserveFormatting: Bool

    /// Whether to include whitespace normalization.
    public let normalizeWhitespace: Bool

    // MARK: - Initialization

    /// Creates a new text extractor with the specified options.
    ///
    /// - Parameters:
    ///   - preserveFormatting: Whether to preserve line breaks and paragraph structure.
    ///   - normalizeWhitespace: Whether to collapse consecutive whitespace.
    public init(
        preserveFormatting: Bool = true,
        normalizeWhitespace: Bool = false
    ) {
        self.preserveFormatting = preserveFormatting
        self.normalizeWhitespace = normalizeWhitespace
    }

    // MARK: - Plain Text Extraction

    /// Extracts plain text content from a semantic node.
    ///
    /// This recursively visits the node and all its children, gathering text content
    /// in document order.
    ///
    /// - Parameter node: The semantic node to extract text from.
    /// - Returns: The concatenated text content.
    public func extractPlainText(from node: any SemanticNode) -> String {
        var text = ""

        // Extract text from this node
        if let contentNode = node as? ContentNode {
            let nodeText = contentNode.text
            if !nodeText.isEmpty {
                text.append(nodeText)
            }
        }

        // Extract text from children
        for child in node.children {
            let childText = extractPlainText(from: child)
            if !childText.isEmpty {
                if !text.isEmpty && preserveFormatting {
                    text.append("\n")
                }
                text.append(childText)
            }
        }

        if normalizeWhitespace {
            text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return text
    }

    /// Extracts all text chunks from a semantic node.
    ///
    /// This returns the raw text chunks with all styling information intact,
    /// useful for contrast analysis and typography checks.
    ///
    /// - Parameter node: The semantic node to extract chunks from.
    /// - Returns: An array of all text chunks in document order.
    public func extractTextChunks(from node: any SemanticNode) -> [TextChunk] {
        var chunks: [TextChunk] = []

        // Extract chunks from this node
        if let contentNode = node as? ContentNode {
            for block in contentNode.textBlocks {
                for line in block.lines {
                    chunks.append(contentsOf: line.chunks)
                }
            }
        }

        // Extract chunks from children
        for child in node.children {
            chunks.append(contentsOf: extractTextChunks(from: child))
        }

        return chunks
    }

    // MARK: - Text Statistics

    /// Extracts comprehensive text statistics from a semantic node.
    ///
    /// This computes aggregate statistics useful for accessibility analysis,
    /// including font properties, color distribution, and content metrics.
    ///
    /// - Parameter node: The semantic node to analyze.
    /// - Returns: Text statistics for the node and its descendants.
    public func extractTextStatistics(from node: any SemanticNode) -> TextStatistics {
        let chunks = extractTextChunks(from: node)

        guard !chunks.isEmpty else {
            return TextStatistics.empty
        }

        // Collect font sizes and weights
        let fontSizes = chunks.map(\.fontSize)
        let fontWeights = chunks.map(\.fontWeight)

        // Count font families
        var fontFamilies: [String: Int] = [:]
        for chunk in chunks {
            fontFamilies[chunk.fontName, default: 0] += 1
        }

        // Count colors (convert to hex for grouping)
        var colors: [String: (CGColor, Int)] = [:]
        for chunk in chunks {
            let hex = colorToHex(chunk.textColor)
            if let existing = colors[hex] {
                colors[hex] = (existing.0, existing.1 + 1)
            } else {
                colors[hex] = (chunk.textColor, 1)
            }
        }

        // Compute statistics
        let averageFontSize = fontSizes.reduce(0.0, +) / CGFloat(fontSizes.count)
        let averageFontWeight = fontWeights.reduce(0.0, +) / CGFloat(fontWeights.count)

        let minFontSize = fontSizes.min() ?? 0
        let maxFontSize = fontSizes.max() ?? 0

        let dominantFontFamily = fontFamilies.max(by: { $0.value < $1.value })?.key
        let dominantColor = colors.max(by: { $0.value.1 < $1.value.1 })?.value.0

        let totalCharacters = chunks.reduce(0) { $0 + $1.value.count }
        let totalWords = chunks.reduce(0) { count, chunk in
            count + chunk.value.split(separator: " ").count
        }

        // Count formatting variations
        let boldCount = chunks.filter(\.isBold).count
        let italicCount = chunks.filter(\.isItalic).count
        let underlinedCount = chunks.filter(\.isUnderlined).count

        return TextStatistics(
            totalChunks: chunks.count,
            totalCharacters: totalCharacters,
            totalWords: totalWords,
            averageFontSize: averageFontSize,
            minFontSize: minFontSize,
            maxFontSize: maxFontSize,
            averageFontWeight: averageFontWeight,
            dominantFontFamily: dominantFontFamily,
            dominantColor: dominantColor,
            uniqueFontFamilies: Set(chunks.map(\.fontName)),
            uniqueFontSizes: Set(fontSizes),
            boldCount: boldCount,
            italicCount: italicCount,
            underlinedCount: underlinedCount
        )
    }

    /// Computes the dominant (most frequent) font size in a node's text content.
    ///
    /// - Parameter node: The semantic node to analyze.
    /// - Returns: The most common font size, or `nil` if the node has no text.
    public func dominantFontSize(in node: any SemanticNode) -> CGFloat? {
        let chunks = extractTextChunks(from: node)
        guard !chunks.isEmpty else { return nil }

        var sizeCounts: [CGFloat: Int] = [:]
        for chunk in chunks {
            sizeCounts[chunk.fontSize, default: 0] += chunk.value.count
        }

        return sizeCounts.max(by: { $0.value < $1.value })?.key
    }

    /// Computes the dominant (most frequent) font weight in a node's text content.
    ///
    /// - Parameter node: The semantic node to analyze.
    /// - Returns: The most common font weight, or `nil` if the node has no text.
    public func dominantFontWeight(in node: any SemanticNode) -> CGFloat? {
        let chunks = extractTextChunks(from: node)
        guard !chunks.isEmpty else { return nil }

        var weightCounts: [CGFloat: Int] = [:]
        for chunk in chunks {
            weightCounts[chunk.fontWeight, default: 0] += chunk.value.count
        }

        return weightCounts.max(by: { $0.value < $1.value })?.key
    }

    /// Computes the dominant (most frequent) text color in a node's text content.
    ///
    /// - Parameter node: The semantic node to analyze.
    /// - Returns: The most common text color, or `nil` if the node has no text.
    public func dominantColor(in node: any SemanticNode) -> CGColor? {
        let chunks = extractTextChunks(from: node)
        guard !chunks.isEmpty else { return nil }

        var colorCounts: [String: (CGColor, Int)] = [:]
        for chunk in chunks {
            let hex = colorToHex(chunk.textColor)
            if let existing = colorCounts[hex] {
                colorCounts[hex] = (existing.0, existing.1 + chunk.value.count)
            } else {
                colorCounts[hex] = (chunk.textColor, chunk.value.count)
            }
        }

        return colorCounts.max(by: { $0.value.1 < $1.value.1 })?.value.0
    }

    // MARK: - Text Lines and Blocks

    /// Extracts all text lines from a semantic node, preserving line structure.
    ///
    /// - Parameter node: The semantic node to extract lines from.
    /// - Returns: An array of all text lines in document order.
    public func extractTextLines(from node: any SemanticNode) -> [TextLine] {
        var lines: [TextLine] = []

        if let contentNode = node as? ContentNode {
            for block in contentNode.textBlocks {
                lines.append(contentsOf: block.lines)
            }
        }

        for child in node.children {
            lines.append(contentsOf: extractTextLines(from: child))
        }

        return lines
    }

    /// Extracts all text blocks from a semantic node, preserving block structure.
    ///
    /// - Parameter node: The semantic node to extract blocks from.
    /// - Returns: An array of all text blocks in document order.
    public func extractTextBlocks(from node: any SemanticNode) -> [TextBlock] {
        var blocks: [TextBlock] = []

        if let contentNode = node as? ContentNode {
            blocks.append(contentsOf: contentNode.textBlocks)
        }

        for child in node.children {
            blocks.append(contentsOf: extractTextBlocks(from: child))
        }

        return blocks
    }

    // MARK: - Helper Methods

    /// Converts a CGColor to a hex string for grouping/comparison.
    private func colorToHex(_ color: CGColor) -> String {
        guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = color.converted(to: srgb, intent: .defaultIntent, options: nil),
              let components = converted.components,
              components.count >= 3 else {
            return "#000000"
        }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Text Statistics

/// Comprehensive statistics about text content in a semantic node.
public struct TextStatistics: Sendable, Hashable, Codable {

    /// The total number of text chunks.
    public let totalChunks: Int

    /// The total number of characters across all chunks.
    public let totalCharacters: Int

    /// The total number of words (whitespace-delimited).
    public let totalWords: Int

    /// The average font size across all chunks.
    public let averageFontSize: CGFloat

    /// The minimum font size found.
    public let minFontSize: CGFloat

    /// The maximum font size found.
    public let maxFontSize: CGFloat

    /// The average font weight across all chunks.
    public let averageFontWeight: CGFloat

    /// The most frequently used font family.
    public let dominantFontFamily: String?

    /// The dominant text color (stored as sRGB components).
    public let dominantColorComponents: [CGFloat]?

    /// The set of unique font families used.
    public let uniqueFontFamilies: Set<String>

    /// The set of unique font sizes used.
    public let uniqueFontSizes: Set<CGFloat>

    /// The number of bold chunks.
    public let boldCount: Int

    /// The number of italic chunks.
    public let italicCount: Int

    /// The number of underlined chunks.
    public let underlinedCount: Int

    /// The dominant text color as a CGColor.
    public var dominantColor: CGColor? {
        guard let components = dominantColorComponents else { return nil }
        return ColorContrastCalculator.cgColorFromComponents(components)
    }

    /// Creates text statistics with all properties.
    internal init(
        totalChunks: Int,
        totalCharacters: Int,
        totalWords: Int,
        averageFontSize: CGFloat,
        minFontSize: CGFloat,
        maxFontSize: CGFloat,
        averageFontWeight: CGFloat,
        dominantFontFamily: String?,
        dominantColor: CGColor?,
        uniqueFontFamilies: Set<String>,
        uniqueFontSizes: Set<CGFloat>,
        boldCount: Int,
        italicCount: Int,
        underlinedCount: Int
    ) {
        self.totalChunks = totalChunks
        self.totalCharacters = totalCharacters
        self.totalWords = totalWords
        self.averageFontSize = averageFontSize
        self.minFontSize = minFontSize
        self.maxFontSize = maxFontSize
        self.averageFontWeight = averageFontWeight
        self.dominantFontFamily = dominantFontFamily
        self.dominantColorComponents = dominantColor.map {
            ColorContrastCalculator.componentsFromCGColor($0)
        }
        self.uniqueFontFamilies = uniqueFontFamilies
        self.uniqueFontSizes = uniqueFontSizes
        self.boldCount = boldCount
        self.italicCount = italicCount
        self.underlinedCount = underlinedCount
    }

    /// Empty statistics for nodes with no text content.
    public static let empty = TextStatistics(
        totalChunks: 0,
        totalCharacters: 0,
        totalWords: 0,
        averageFontSize: 0,
        minFontSize: 0,
        maxFontSize: 0,
        averageFontWeight: 0,
        dominantFontFamily: nil,
        dominantColor: nil,
        uniqueFontFamilies: [],
        uniqueFontSizes: [],
        boldCount: 0,
        italicCount: 0,
        underlinedCount: 0
    )

    /// Whether the dominant font qualifies as "large text" per WCAG.
    public var isLargeText: Bool {
        if averageFontSize >= 18 {
            return true
        }
        if averageFontSize >= 14 && averageFontWeight >= 700 {
            return true
        }
        return false
    }

    /// The text type classification for WCAG contrast requirements.
    public var textType: TextType {
        isLargeText ? .large : .regular
    }
}

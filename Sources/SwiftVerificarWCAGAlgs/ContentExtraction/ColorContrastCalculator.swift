import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// WCAG 2.1 contrast ratio calculator implementing the official luminance and contrast formulas.
///
/// This struct provides precise color contrast calculations according to the WCAG 2.1
/// specification, which is critical for accessibility compliance. The contrast ratio
/// determines whether text is readable against its background.
///
/// ## WCAG Conformance Levels
///
/// - **Level AA** (Standard):
///   - Regular text (< 18pt, or < 14pt bold): minimum 4.5:1
///   - Large text (≥ 18pt, or ≥ 14pt bold): minimum 3.0:1
///
/// - **Level AAA** (Enhanced):
///   - Regular text: minimum 7.0:1
///   - Large text: minimum 4.5:1
///
/// ## References
///
/// - [WCAG 2.1 Contrast (Minimum)](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html) — Success Criterion 1.4.3
/// - [WCAG 2.1 Contrast (Enhanced)](https://www.w3.org/WAI/WCAG21/Understanding/contrast-enhanced.html) — Success Criterion 1.4.6
/// - [WCAG 2.1 Relative Luminance](https://www.w3.org/TR/WCAG21/#dfn-relative-luminance) — Technical definition
///
/// ## Example
///
/// ```swift
/// let calculator = ColorContrastCalculator()
/// let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
/// let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
///
/// let ratio = calculator.contrastRatio(foreground: black, background: white)
/// // ratio ≈ 21.0 (perfect contrast)
///
/// let passes = calculator.meetsRequirement(
///     ratio: ratio,
///     textType: .regular,
///     level: .aa
/// )
/// // passes == true (21.0 > 4.5)
/// ```
///
/// - Note: Ported from veraPDF-wcag-algs `ContrastRatioChecker` Java class.
public struct ColorContrastCalculator: Sendable, Hashable, Codable {

    // MARK: - Initialization

    /// Creates a new contrast calculator.
    public init() {}

    // MARK: - Public API

    /// Calculates the contrast ratio between two colors.
    ///
    /// The contrast ratio is defined by WCAG 2.1 as:
    /// ```
    /// (L1 + 0.05) / (L2 + 0.05)
    /// ```
    /// where L1 is the relative luminance of the lighter color and L2 is the
    /// relative luminance of the darker color.
    ///
    /// - Parameters:
    ///   - foreground: The foreground (text) color.
    ///   - background: The background color.
    /// - Returns: The contrast ratio, a value between 1.0 (no contrast) and 21.0 (maximum contrast).
    public func contrastRatio(foreground: CGColor, background: CGColor) -> CGFloat {
        let l1 = relativeLuminance(of: foreground)
        let l2 = relativeLuminance(of: background)

        let lighter = max(l1, l2)
        let darker = min(l1, l2)

        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Calculates the relative luminance of a color per WCAG 2.1.
    ///
    /// Relative luminance is defined as:
    /// ```
    /// L = 0.2126 * R + 0.7152 * G + 0.0722 * B
    /// ```
    /// where R, G, and B are the normalized sRGB components.
    ///
    /// Each component is normalized by:
    /// - If `c ≤ 0.03928`: `c / 12.92`
    /// - Otherwise: `((c + 0.055) / 1.055) ^ 2.4`
    ///
    /// - Parameter color: The color to analyze (must be convertible to sRGB).
    /// - Returns: The relative luminance, a value between 0.0 (black) and 1.0 (white).
    ///
    /// - Note: Colors are automatically converted to sRGB color space before calculation.
    public func relativeLuminance(of color: CGColor) -> CGFloat {
        guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = color.converted(to: srgb, intent: .defaultIntent, options: nil),
              let components = converted.components,
              components.count >= 3 else {
            // Fallback: treat as black if conversion fails
            return 0
        }

        let r = normalizeColorComponent(components[0])
        let g = normalizeColorComponent(components[1])
        let b = normalizeColorComponent(components[2])

        // WCAG 2.1 luminance formula
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Checks if a contrast ratio meets the WCAG requirement for the given text type and level.
    ///
    /// - Parameters:
    ///   - ratio: The contrast ratio to check.
    ///   - textType: The type of text (regular, large, or logo).
    ///   - level: The WCAG conformance level (AA or AAA).
    /// - Returns: `true` if the ratio meets or exceeds the requirement, `false` otherwise.
    public func meetsRequirement(
        ratio: CGFloat,
        textType: TextType,
        level: WCAGLevel
    ) -> Bool {
        let required = requiredRatio(for: textType, level: level)
        return ratio >= required
    }

    /// Returns the minimum contrast ratio required for the given text type and conformance level.
    ///
    /// - Parameters:
    ///   - textType: The type of text (regular, large, or logo).
    ///   - level: The WCAG conformance level (AA or AAA).
    /// - Returns: The minimum required contrast ratio.
    public func requiredRatio(for textType: TextType, level: WCAGLevel) -> CGFloat {
        switch (textType, level) {
        case (.logo, _):
            return 1.0  // No requirement for logo/brand text
        case (.large, .aa):
            return 3.0  // Large text AA: 3:1
        case (.large, .aaa):
            return 4.5  // Large text AAA: 4.5:1
        case (.regular, .aa):
            return 4.5  // Regular text AA: 4.5:1
        case (.regular, .aaa):
            return 7.0  // Regular text AAA: 7:1
        }
    }

    /// Analyzes a text chunk's contrast and returns the conformance result.
    ///
    /// - Parameters:
    ///   - chunk: The text chunk to analyze (must have both textColor and backgroundColor).
    ///   - level: The WCAG conformance level to check against.
    /// - Returns: A contrast analysis result, or `nil` if the chunk lacks background color.
    public func analyzeTextChunk(
        _ chunk: TextChunk,
        level: WCAGLevel = .aa
    ) -> ContrastAnalysisResult? {
        guard let backgroundColor = chunk.backgroundColor else {
            return nil
        }

        let ratio = contrastRatio(foreground: chunk.textColor, background: backgroundColor)
        let passes = meetsRequirement(ratio: ratio, textType: chunk.textType, level: level)

        return ContrastAnalysisResult(
            foregroundColor: chunk.textColor,
            backgroundColor: backgroundColor,
            ratio: ratio,
            textType: chunk.textType,
            level: level,
            passes: passes
        )
    }

    // MARK: - Private Helpers

    /// Normalizes an sRGB color component for luminance calculation.
    ///
    /// Per WCAG 2.1, each component must be linearized before applying the
    /// luminance formula.
    ///
    /// - Parameter c: The sRGB component value (0.0 to 1.0).
    /// - Returns: The normalized (linearized) component value.
    private func normalizeColorComponent(_ c: CGFloat) -> CGFloat {
        if c <= 0.03928 {
            return c / 12.92
        } else {
            return pow((c + 0.055) / 1.055, 2.4)
        }
    }
}

// MARK: - Supporting Types

/// WCAG conformance levels for contrast requirements.
public enum WCAGLevel: String, Sendable, Hashable, Codable, CaseIterable {
    /// Level AA (standard): 4.5:1 for regular text, 3:1 for large text.
    case aa = "AA"

    /// Level AAA (enhanced): 7:1 for regular text, 4.5:1 for large text.
    case aaa = "AAA"
}

/// Result of a contrast analysis for a text chunk.
public struct ContrastAnalysisResult: Sendable, Hashable, Codable {

    /// The foreground (text) color analyzed.
    public let foregroundColorComponents: [CGFloat]

    /// The background color analyzed.
    public let backgroundColorComponents: [CGFloat]

    /// The calculated contrast ratio.
    public let ratio: CGFloat

    /// The text type classification.
    public let textType: TextType

    /// The WCAG level checked against.
    public let level: WCAGLevel

    /// Whether the contrast ratio meets the requirement.
    public let passes: Bool

    /// The minimum required ratio for this text type and level.
    public var requiredRatio: CGFloat {
        ColorContrastCalculator().requiredRatio(for: textType, level: level)
    }

    /// How much the ratio exceeds (or falls short of) the requirement.
    ///
    /// A positive value indicates the ratio exceeds the requirement.
    /// A negative value indicates the ratio falls short.
    public var margin: CGFloat {
        ratio - requiredRatio
    }

    /// The foreground color as a CGColor.
    public var foregroundColor: CGColor {
        ColorContrastCalculator.cgColorFromComponents(foregroundColorComponents)
    }

    /// The background color as a CGColor.
    public var backgroundColor: CGColor {
        ColorContrastCalculator.cgColorFromComponents(backgroundColorComponents)
    }

    /// Creates a new contrast analysis result.
    ///
    /// - Parameters:
    ///   - foregroundColor: The foreground color.
    ///   - backgroundColor: The background color.
    ///   - ratio: The calculated contrast ratio.
    ///   - textType: The text type classification.
    ///   - level: The WCAG level checked.
    ///   - passes: Whether the ratio meets the requirement.
    internal init(
        foregroundColor: CGColor,
        backgroundColor: CGColor,
        ratio: CGFloat,
        textType: TextType,
        level: WCAGLevel,
        passes: Bool
    ) {
        self.foregroundColorComponents = ColorContrastCalculator.componentsFromCGColor(foregroundColor)
        self.backgroundColorComponents = ColorContrastCalculator.componentsFromCGColor(backgroundColor)
        self.ratio = ratio
        self.textType = textType
        self.level = level
        self.passes = passes
    }
}

// MARK: - CGColor Conversion Helpers

extension ColorContrastCalculator {

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

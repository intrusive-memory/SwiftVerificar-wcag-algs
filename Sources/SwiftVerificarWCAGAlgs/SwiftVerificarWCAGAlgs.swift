import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// SwiftVerificarWCAGAlgs - WCAG accessibility algorithms for SwiftVerificar
///
/// Swift port of veraPDF-wcag-algs providing accessibility validation algorithms
/// including contrast ratio calculation and structure tree validation.
///
/// - SeeAlso: [veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs)
public struct SwiftVerificarWCAGAlgs {

    /// The current version of the library
    public static let version = "0.1.0"

    /// Creates a new instance of SwiftVerificarWCAGAlgs
    public init() {}
}

// MARK: - Contrast Ratio Calculator

/// WCAG contrast ratio calculator
public struct ContrastRatioCalculator: Sendable {

    public init() {}

    /// Calculate the contrast ratio between two colors
    /// - Parameters:
    ///   - foreground: Foreground color (RGB, 0-1 range)
    ///   - background: Background color (RGB, 0-1 range)
    /// - Returns: Contrast ratio (1:1 to 21:1)
    public func contrastRatio(
        foreground: (r: Double, g: Double, b: Double),
        background: (r: Double, g: Double, b: Double)
    ) -> Double {
        let l1 = relativeLuminance(r: foreground.r, g: foreground.g, b: foreground.b)
        let l2 = relativeLuminance(r: background.r, g: background.g, b: background.b)

        let lighter = max(l1, l2)
        let darker = min(l1, l2)

        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Calculate the relative luminance of a color
    /// - Parameters:
    ///   - r: Red component (0-1)
    ///   - g: Green component (0-1)
    ///   - b: Blue component (0-1)
    /// - Returns: Relative luminance (0-1)
    public func relativeLuminance(r: Double, g: Double, b: Double) -> Double {
        let rLinear = linearize(r)
        let gLinear = linearize(g)
        let bLinear = linearize(b)

        return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear
    }

    /// Convert sRGB component to linear RGB
    private func linearize(_ value: Double) -> Double {
        if value <= 0.04045 {
            return value / 12.92
        } else {
            return pow((value + 0.055) / 1.055, 2.4)
        }
    }

    /// Check if contrast ratio meets WCAG AA for normal text
    /// - Parameter ratio: Contrast ratio
    /// - Returns: True if ratio >= 4.5:1
    public func meetsWCAGAA(ratio: Double) -> Bool {
        ratio >= 4.5
    }

    /// Check if contrast ratio meets WCAG AA for large text
    /// - Parameter ratio: Contrast ratio
    /// - Returns: True if ratio >= 3:1
    public func meetsWCAGAALargeText(ratio: Double) -> Bool {
        ratio >= 3.0
    }

    /// Check if contrast ratio meets WCAG AAA for normal text
    /// - Parameter ratio: Contrast ratio
    /// - Returns: True if ratio >= 7:1
    public func meetsWCAGAAA(ratio: Double) -> Bool {
        ratio >= 7.0
    }

    /// Check if contrast ratio meets WCAG AAA for large text
    /// - Parameter ratio: Contrast ratio
    /// - Returns: True if ratio >= 4.5:1
    public func meetsWCAGAAALargeText(ratio: Double) -> Bool {
        ratio >= 4.5
    }
}

// MARK: - Structure Tree Validator

/// Validates PDF structure tree for accessibility compliance
public struct StructureTreeValidator: Sendable {

    public init() {}

    /// Validate heading hierarchy
    /// - Parameter headingLevels: Array of heading levels in document order
    /// - Returns: Array of validation issues
    public func validateHeadingHierarchy(headingLevels: [Int]) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []

        // Check for skipped heading levels
        var previousLevel = 0
        for (index, level) in headingLevels.enumerated() {
            if level > previousLevel + 1 && previousLevel > 0 {
                issues.append(AccessibilityIssue(
                    type: .skippedHeadingLevel,
                    message: "Heading level skipped from H\(previousLevel) to H\(level)",
                    location: "Heading \(index + 1)"
                ))
            }
            previousLevel = level
        }

        // Check if first heading is H1
        if let first = headingLevels.first, first != 1 {
            issues.append(AccessibilityIssue(
                type: .missingH1,
                message: "Document should start with H1, found H\(first)",
                location: "First heading"
            ))
        }

        return issues
    }
}

// MARK: - Accessibility Issues

/// An accessibility issue found during validation
public struct AccessibilityIssue: Sendable, Identifiable {
    public let id = UUID()
    public let type: AccessibilityIssueType
    public let message: String
    public let location: String?

    public init(type: AccessibilityIssueType, message: String, location: String? = nil) {
        self.type = type
        self.message = message
        self.location = location
    }
}

/// Types of accessibility issues
public enum AccessibilityIssueType: String, Sendable {
    // Contrast issues
    case insufficientContrast = "INSUFFICIENT_CONTRAST"

    // Structure issues
    case skippedHeadingLevel = "SKIPPED_HEADING_LEVEL"
    case missingH1 = "MISSING_H1"
    case improperNesting = "IMPROPER_NESTING"

    // Alt text issues
    case missingAltText = "MISSING_ALT_TEXT"
    case decorativeNotMarked = "DECORATIVE_NOT_MARKED"

    // Table issues
    case missingTableHeaders = "MISSING_TABLE_HEADERS"
    case missingTableScope = "MISSING_TABLE_SCOPE"

    // Link issues
    case ambiguousLinkText = "AMBIGUOUS_LINK_TEXT"
    case brokenLink = "BROKEN_LINK"

    // Language issues
    case missingLanguage = "MISSING_LANGUAGE"
    case incorrectLanguage = "INCORRECT_LANGUAGE"
}

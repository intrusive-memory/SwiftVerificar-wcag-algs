import Foundation

/// Text formatting classification.
///
/// Represents the vertical positioning of text relative to the baseline,
/// indicating whether text is rendered as normal inline text, subscript
/// (below the baseline), or superscript (above the baseline).
///
/// - Note: Ported from veraPDF-wcag-algs `TextFormat` Java enum.
public enum TextFormat: String, CaseIterable, Sendable, Codable {

    /// Normal text rendered at the baseline.
    case normal

    /// Subscript text rendered below the baseline.
    case `subscript`

    /// Superscript text rendered above the baseline.
    case superscript
}

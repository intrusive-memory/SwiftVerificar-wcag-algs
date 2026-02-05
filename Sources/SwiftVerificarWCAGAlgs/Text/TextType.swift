import Foundation

/// Text size classification for WCAG contrast requirements.
///
/// WCAG 2.1 defines different contrast ratio thresholds depending on
/// text size. Large text (at least 18pt, or at least 14pt bold) has
/// a lower required contrast ratio than regular text. Logo or brand
/// text has no contrast requirement.
///
/// - Note: Ported from veraPDF-wcag-algs text type classification logic.
///   See WCAG 2.1 Success Criterion 1.4.3 (Contrast Minimum) and 1.4.6
///   (Contrast Enhanced).
public enum TextType: String, CaseIterable, Sendable, Codable {

    /// Normal text requiring a 4.5:1 contrast ratio at WCAG AA level.
    case regular

    /// Large text (18pt+, or 14pt+ bold) requiring a 3.0:1 contrast ratio at WCAG AA level.
    case large

    /// Logo or brand text with no contrast requirement.
    case logo

    // MARK: - Contrast Requirements

    /// The minimum contrast ratio required for WCAG AA compliance.
    public var minimumContrastRatioAA: CGFloat {
        switch self {
        case .regular:
            return 4.5
        case .large:
            return 3.0
        case .logo:
            return 1.0
        }
    }

    /// The minimum contrast ratio required for WCAG AAA compliance.
    public var minimumContrastRatioAAA: CGFloat {
        switch self {
        case .regular:
            return 7.0
        case .large:
            return 4.5
        case .logo:
            return 1.0
        }
    }
}

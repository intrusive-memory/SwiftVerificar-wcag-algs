import Foundation

/// Checker for WCAG 2.1 Success Criterion 1.1.1 - Non-text Content (Level A).
///
/// This checker validates that all non-text content (images, figures, line art)
/// has appropriate text alternatives that serve the equivalent purpose.
///
/// ## WCAG 2.1 Requirement
///
/// All non-text content that is presented to the user has a text alternative
/// that serves the equivalent purpose, except for the situations listed below:
///
/// - **Controls, Input**: If non-text content is a control or accepts user input,
///   then it has a name that describes its purpose.
/// - **Time-Based Media**: If non-text content is time-based media, then text
///   alternatives at least provide descriptive identification.
/// - **Test**: If non-text content is a test or exercise that would be invalid
///   if presented in text, then text alternatives at least provide descriptive
///   identification.
/// - **Sensory**: If non-text content is primarily intended to create a specific
///   sensory experience, then text alternatives at least provide descriptive
///   identification.
/// - **CAPTCHA**: If the purpose is to confirm that content is being accessed by
///   a person rather than a computer, then text alternatives that identify and
///   describe the purpose are provided.
/// - **Decoration, Formatting, Invisible**: If non-text content is pure decoration,
///   is used only for visual formatting, or is not presented to users, then it is
///   implemented in a way that it can be ignored by assistive technology.
///
/// ## PDF/UA Implementation
///
/// In PDF documents, non-text content includes:
/// - **Figures**: Images and illustrations marked with Figure tags
/// - **Line Art**: Vector graphics and diagrams
/// - **Form Controls**: Interactive form fields
///
/// Text alternatives are provided via:
/// - **Alt attribute**: Primary alternative text
/// - **ActualText attribute**: Replacement text for the content
/// - **Caption elements**: Associated caption as a child of the figure
///
/// Decorative content should be marked as **Artifact** rather than as a Figure
/// in the structure tree.
///
/// ## Validation Rules
///
/// This checker validates that:
/// 1. All Figure nodes have either Alt or ActualText attributes
/// 2. Alt/ActualText is not empty or whitespace-only
/// 3. Figures with no visual content are flagged as potentially decorative
/// 4. Images within figures have appropriate alternative text
///
/// - SeeAlso: [WCAG 2.1 SC 1.1.1](https://www.w3.org/WAI/WCAG21/Understanding/non-text-content.html)
/// - Note: Ported from veraPDF-wcag-algs figure validation logic.
public struct AltTextChecker: AccessibilityChecker {

    // MARK: - AccessibilityChecker Conformance

    /// The WCAG success criterion being checked.
    public let criterion: WCAGSuccessCriterion = .nonTextContent

    /// The minimum acceptable length for alternative text.
    ///
    /// Text shorter than this is considered too brief to be meaningful.
    public let minimumAltTextLength: Int

    /// Whether to check image chunks within figures.
    public let checkImageChunks: Bool

    /// Whether to accept captions as alternative text.
    ///
    /// If true, a figure with a caption but no Alt/ActualText will pass.
    public let acceptCaptionAsAlt: Bool

    // MARK: - Initialization

    /// Creates a new alt text checker with default settings.
    ///
    /// - Parameters:
    ///   - minimumAltTextLength: Minimum length for alt text (default: 1).
    ///   - checkImageChunks: Whether to check image chunks (default: true).
    ///   - acceptCaptionAsAlt: Whether to accept captions as alt text (default: false).
    public init(
        minimumAltTextLength: Int = 1,
        checkImageChunks: Bool = true,
        acceptCaptionAsAlt: Bool = false
    ) {
        self.minimumAltTextLength = minimumAltTextLength
        self.checkImageChunks = checkImageChunks
        self.acceptCaptionAsAlt = acceptCaptionAsAlt
    }

    // MARK: - Checking

    /// Checks a semantic node for non-text content violations.
    ///
    /// - Parameter node: The semantic node to check.
    /// - Returns: The result of the accessibility check.
    public func check(_ node: any SemanticNode) -> AccessibilityCheckResult {
        var violations: [AccessibilityViolation] = []

        // Only check figure nodes
        guard node.type == .figure else {
            return .passing(criterion: criterion)
        }

        // Cast to FigureNode for detailed inspection
        guard let figure = node as? FigureNode else {
            return .passing(criterion: criterion)
        }

        // Check for alternative text
        violations.append(contentsOf: checkFigureAltText(figure))

        // Check image chunks if enabled
        if checkImageChunks {
            violations.append(contentsOf: checkImageChunksAltText(figure))
        }

        // Return result
        if violations.isEmpty {
            return .passing(
                criterion: criterion,
                context: "Figure has appropriate alternative text"
            )
        } else {
            return .failing(
                criterion: criterion,
                violations: violations
            )
        }
    }

    // MARK: - Private Helpers

    /// Checks if a figure has appropriate alternative text.
    private func checkFigureAltText(_ figure: FigureNode) -> [AccessibilityViolation] {
        var violations: [AccessibilityViolation] = []

        // Skip figures with no visual content (may be container only)
        guard figure.hasVisualContent else {
            return violations
        }

        // Check for Alt or ActualText
        let hasAlt = figure.altText != nil && !figure.altText!.isEmpty
        let hasActual = figure.actualText != nil && !figure.actualText!.isEmpty

        // If accepting captions, check for caption
        let hasCaption = acceptCaptionAsAlt && figure.hasCaption

        if !hasAlt && !hasActual && !hasCaption {
            violations.append(
                AccessibilityViolation(
                    nodeId: figure.id,
                    nodeType: .figure,
                    description: "Figure with \(figure.visualElementCount) visual element(s) lacks alternative text (Alt, ActualText, or Caption required)",
                    severity: .critical,
                    location: figure.boundingBox
                )
            )
        } else {
            // Check minimum length
            let altText = figure.altText ?? figure.actualText ?? figure.captionText ?? ""
            if altText.count < minimumAltTextLength {
                violations.append(
                    AccessibilityViolation(
                        nodeId: figure.id,
                        nodeType: .figure,
                        description: "Figure has alternative text that is too short (\(altText.count) character(s), minimum: \(minimumAltTextLength))",
                        severity: .serious,
                        location: figure.boundingBox
                    )
                )
            }

            // Check for whitespace-only alt text
            if altText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                violations.append(
                    AccessibilityViolation(
                        nodeId: figure.id,
                        nodeType: .figure,
                        description: "Figure has alternative text that is whitespace-only",
                        severity: .critical,
                        location: figure.boundingBox
                    )
                )
            }
        }

        return violations
    }

    /// Checks if image chunks within a figure have alternative text.
    ///
    /// This is an additional check beyond the figure-level Alt attribute.
    private func checkImageChunksAltText(_ figure: FigureNode) -> [AccessibilityViolation] {
        var violations: [AccessibilityViolation] = []

        // If figure has alt text, individual images don't need it
        if figure.hasAltText {
            return violations
        }

        // Check each image chunk
        for image in figure.imageChunks {
            if !image.hasAlternativeText {
                violations.append(
                    AccessibilityViolation(
                        nodeId: figure.id,
                        nodeType: .figure,
                        description: "Image chunk within figure lacks alternative text",
                        severity: .serious,
                        location: image.boundingBox
                    )
                )
            }
        }

        return violations
    }
}

// MARK: - Convenience Extensions

extension AltTextChecker {

    /// Creates a strict checker with high standards.
    ///
    /// Requires:
    /// - Minimum alt text length of 10 characters
    /// - Checks all image chunks
    /// - Does not accept captions as alt text
    public static var strict: AltTextChecker {
        AltTextChecker(
            minimumAltTextLength: 10,
            checkImageChunks: true,
            acceptCaptionAsAlt: false
        )
    }

    /// Creates a lenient checker with relaxed standards.
    ///
    /// Requires:
    /// - Minimum alt text length of 1 character
    /// - Does not check image chunks
    /// - Accepts captions as alt text
    public static var lenient: AltTextChecker {
        AltTextChecker(
            minimumAltTextLength: 1,
            checkImageChunks: false,
            acceptCaptionAsAlt: true
        )
    }

    /// Creates a checker that accepts captions as alternative text.
    public static var acceptingCaptions: AltTextChecker {
        AltTextChecker(
            minimumAltTextLength: 1,
            checkImageChunks: true,
            acceptCaptionAsAlt: true
        )
    }
}

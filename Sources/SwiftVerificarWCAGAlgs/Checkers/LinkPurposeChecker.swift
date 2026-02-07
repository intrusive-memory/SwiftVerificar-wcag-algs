import Foundation

/// Checker for WCAG 2.1 Success Criterion 2.4.4 - Link Purpose (In Context) (Level A).
///
/// This checker validates that the purpose of each link can be determined from
/// the link text alone or from the link text together with its programmatically
/// determined link context.
///
/// ## WCAG 2.1 Requirement
///
/// The purpose of each link can be determined from the link text alone or from
/// the link text together with its programmatically determined link context,
/// except where the purpose of the link would be ambiguous to users in general.
///
/// ## PDF/UA Implementation
///
/// In PDF documents, links are represented as:
/// - **Link structure elements**: Tagged with the `Link` tag
/// - **Annotations**: Link annotations with `/Subtype /Link`
///
/// Link context includes:
/// - The link text itself (text content of the Link element)
/// - Alternative text (Alt or ActualText attributes)
/// - The containing paragraph, list item, or heading
/// - Adjacent text in the same sentence
/// - Table cells (for links in tables)
///
/// ## Validation Rules
///
/// This checker validates that:
/// 1. Link elements are not empty (have text content or Alt)
/// 2. Link text is not generic or ambiguous (e.g., "click here", "more")
/// 3. Link text provides meaningful description of destination
/// 4. Multiple links with same text lead to same destination (or have distinct context)
///
/// ## Common Violations
///
/// - Links with text like "click here", "read more", "here", "link"
/// - Empty links with no text or alternative
/// - Multiple different destinations with identical link text
/// - Links with only punctuation or special characters
///
/// - SeeAlso: [WCAG 2.1 SC 2.4.4](https://www.w3.org/WAI/WCAG21/Understanding/link-purpose-in-context.html)
/// - Note: Ported from veraPDF-wcag-algs link validation logic.
public struct LinkPurposeChecker: AccessibilityChecker {

    // MARK: - AccessibilityChecker Conformance

    /// The WCAG success criterion being checked.
    public let criterion: WCAGSuccessCriterion = .linkPurpose

    /// The minimum acceptable length for link text.
    public let minimumLinkTextLength: Int

    /// Whether to check for generic link text.
    public let checkForGenericText: Bool

    /// Generic link text patterns that should be flagged.
    ///
    /// Common patterns like "click here", "read more", etc.
    public let genericPatterns: Set<String>

    /// Whether to require distinct text for different destinations.
    public let requireDistinctText: Bool

    // MARK: - Initialization

    /// Creates a new link purpose checker with default settings.
    ///
    /// - Parameters:
    ///   - minimumLinkTextLength: Minimum acceptable link text length (default: 1).
    ///   - checkForGenericText: Whether to flag generic link text (default: true).
    ///   - genericPatterns: Custom generic patterns (uses defaults if nil).
    ///   - requireDistinctText: Whether different destinations need distinct text (default: false).
    public init(
        minimumLinkTextLength: Int = 1,
        checkForGenericText: Bool = true,
        genericPatterns: Set<String>? = nil,
        requireDistinctText: Bool = false
    ) {
        self.minimumLinkTextLength = minimumLinkTextLength
        self.checkForGenericText = checkForGenericText
        self.genericPatterns = genericPatterns ?? Self.defaultGenericPatterns
        self.requireDistinctText = requireDistinctText
    }

    // MARK: - Checking

    /// Checks a semantic node for link purpose violations.
    ///
    /// - Parameter node: The semantic node to check.
    /// - Returns: The result of the accessibility check.
    public func check(_ node: any SemanticNode) -> AccessibilityCheckResult {
        var violations: [AccessibilityViolation] = []

        // Only check link nodes
        guard node.type == .link else {
            return .passing(criterion: criterion)
        }

        // Check link text
        violations.append(contentsOf: checkLinkText(node))

        // Check for generic text
        if checkForGenericText {
            violations.append(contentsOf: checkGenericText(node))
        }

        if violations.isEmpty {
            return .passing(
                criterion: criterion,
                context: "Link has clear purpose"
            )
        } else {
            return .failing(
                criterion: criterion,
                violations: violations
            )
        }
    }

    /// Checks multiple nodes and validates distinct link text for different destinations.
    public func check(_ nodes: [any SemanticNode]) -> AccessibilityCheckResult {
        var violations: [AccessibilityViolation] = []

        // Check each link individually
        let linkNodes = nodes.filter { $0.type == .link }
        for node in linkNodes {
            let result = check(node)
            violations.append(contentsOf: result.violations)
        }

        // Check for duplicate link text if enabled
        if requireDistinctText && linkNodes.count > 1 {
            violations.append(contentsOf: checkDistinctLinkText(linkNodes))
        }

        if violations.isEmpty {
            return .passing(
                criterion: criterion,
                context: "Checked \(linkNodes.count) link(s)"
            )
        } else {
            return .failing(
                criterion: criterion,
                violations: violations,
                context: "Found \(violations.count) violation(s) in \(linkNodes.count) link(s)"
            )
        }
    }

    // MARK: - Private Helpers

    /// Checks if a link has meaningful text.
    private func checkLinkText(_ node: any SemanticNode) -> [AccessibilityViolation] {
        var violations: [AccessibilityViolation] = []

        // Get link text from node
        let linkText = extractLinkText(node)

        // Check for empty link text
        if linkText.isEmpty {
            violations.append(
                AccessibilityViolation(
                    nodeId: node.id,
                    nodeType: .link,
                    description: "Link has no text content or alternative text",
                    severity: .critical,
                    location: node.boundingBox
                )
            )
            return violations
        }

        // Check minimum length
        if linkText.count < minimumLinkTextLength {
            violations.append(
                AccessibilityViolation(
                    nodeId: node.id,
                    nodeType: .link,
                    description: "Link text is too short (\(linkText.count) character(s), minimum: \(minimumLinkTextLength))",
                    severity: .serious,
                    location: node.boundingBox
                )
            )
        }

        // Check for whitespace-only
        if linkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            violations.append(
                AccessibilityViolation(
                    nodeId: node.id,
                    nodeType: .link,
                    description: "Link text is whitespace-only",
                    severity: .critical,
                    location: node.boundingBox
                )
            )
        }

        // Check for punctuation-only
        let alphanumericSet = CharacterSet.alphanumerics
        if linkText.unicodeScalars.allSatisfy({ !alphanumericSet.contains($0) }) {
            violations.append(
                AccessibilityViolation(
                    nodeId: node.id,
                    nodeType: .link,
                    description: "Link text contains only punctuation or special characters",
                    severity: .serious,
                    location: node.boundingBox
                )
            )
        }

        return violations
    }

    /// Checks if link text is generic or ambiguous.
    private func checkGenericText(_ node: any SemanticNode) -> [AccessibilityViolation] {
        var violations: [AccessibilityViolation] = []

        let linkText = extractLinkText(node)
        let normalized = linkText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if genericPatterns.contains(normalized) {
            violations.append(
                AccessibilityViolation(
                    nodeId: node.id,
                    nodeType: .link,
                    description: "Link uses generic text '\(linkText)' that does not describe the destination",
                    severity: .serious,
                    location: node.boundingBox
                )
            )
        }

        return violations
    }

    /// Checks for duplicate link text pointing to different destinations.
    private func checkDistinctLinkText(_ links: [any SemanticNode]) -> [AccessibilityViolation] {
        var violations: [AccessibilityViolation] = []

        // Group links by their text
        var textToLinks: [String: [any SemanticNode]] = [:]
        for link in links {
            let text = extractLinkText(link)
            if !text.isEmpty {
                textToLinks[text, default: []].append(link)
            }
        }

        // Find duplicate texts
        for (text, linksWithText) in textToLinks where linksWithText.count > 1 {
            // This is a potential issue - multiple links with same text
            // In reality, we'd need to check if they point to different destinations
            // For now, we flag it as a moderate issue
            for link in linksWithText {
                violations.append(
                    AccessibilityViolation(
                        nodeId: link.id,
                        nodeType: .link,
                        description: "Multiple links (\(linksWithText.count)) share the same text '\(text)' - ensure they lead to the same destination or have distinct context",
                        severity: .moderate,
                        location: link.boundingBox
                    )
                )
            }
        }

        return violations
    }

    /// Extracts the effective link text from a node.
    ///
    /// Prefers: Alt > ActualText > Title > own text content > children text content
    private func extractLinkText(_ node: any SemanticNode) -> String {
        // Check for Alt text
        if let alt = node.altText, !alt.isEmpty {
            return alt
        }

        // Check for ActualText
        if let actual = node.actualText, !actual.isEmpty {
            return actual
        }

        // Check for Title
        if let title = node.title, !title.isEmpty {
            return title
        }

        // Extract text from this node's own text blocks (ContentNode)
        if let content = node as? ContentNode, !content.text.isEmpty {
            return content.text
        }

        // If node has children, try to extract text from them
        var texts: [String] = []
        for child in node.children {
            let childText = extractLinkText(child)
            if !childText.isEmpty {
                texts.append(childText)
            }
        }

        return texts.joined(separator: " ")
    }

    // MARK: - Default Generic Patterns

    /// Default set of generic link text patterns.
    private static let defaultGenericPatterns: Set<String> = [
        // English
        "here", "click here", "click", "link", "read more", "more",
        "continue", "next", "previous", "back", "go", "details",
        "info", "information", "learn more", "find out more",
        "see more", "view", "view more", "read", "download",

        // Common abbreviations
        "...", ">>", "<<", ">", "<",

        // Short uninformative phrases
        "this", "that", "this page", "this site", "this link",
        "page", "site", "article", "document", "pdf"
    ]
}

// MARK: - Convenience Extensions

extension LinkPurposeChecker {

    /// Creates a strict checker with high standards.
    ///
    /// Requires:
    /// - Minimum link text of 5 characters
    /// - Checks for generic text
    /// - Requires distinct text for different destinations
    public static var strict: LinkPurposeChecker {
        LinkPurposeChecker(
            minimumLinkTextLength: 5,
            checkForGenericText: true,
            genericPatterns: nil,
            requireDistinctText: true
        )
    }

    /// Creates a lenient checker with relaxed standards.
    ///
    /// Requires:
    /// - Minimum link text of 1 character
    /// - Does not check for generic text
    /// - Does not require distinct text
    public static var lenient: LinkPurposeChecker {
        LinkPurposeChecker(
            minimumLinkTextLength: 1,
            checkForGenericText: false,
            genericPatterns: nil,
            requireDistinctText: false
        )
    }

    /// Creates a checker with custom generic patterns.
    ///
    /// - Parameter patterns: Custom set of generic patterns to detect.
    /// - Returns: A link purpose checker with custom patterns.
    public static func withCustomPatterns(_ patterns: Set<String>) -> LinkPurposeChecker {
        LinkPurposeChecker(
            minimumLinkTextLength: 1,
            checkForGenericText: true,
            genericPatterns: patterns,
            requireDistinctText: false
        )
    }
}

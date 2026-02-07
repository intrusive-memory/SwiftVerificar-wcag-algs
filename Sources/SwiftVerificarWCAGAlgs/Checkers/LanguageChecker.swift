import Foundation

/// Checker for WCAG 2.1 Success Criterion 3.1.1 - Language of Page (Level A).
///
/// This checker validates that the default human language of each document
/// can be programmatically determined.
///
/// ## WCAG 2.1 Requirement
///
/// The default human language of each Web page can be programmatically determined.
///
/// ## PDF/UA Implementation
///
/// In PDF documents, the language is specified via the `Lang` entry in:
/// - The document catalog (for document-level language)
/// - Structure elements (for element-level language)
///
/// The `Lang` entry should contain a language code conforming to BCP 47
/// (e.g., "en", "en-US", "fr", "es-MX").
///
/// ## Validation Rules
///
/// This checker validates that:
/// 1. The document root has a `Lang` attribute
/// 2. The language code is not empty
/// 3. The language code appears to be valid (basic format check)
/// 4. Optionally, validates that the language code conforms to BCP 47
///
/// ## Language Code Format
///
/// Valid language codes follow BCP 47 (RFC 5646):
/// - Primary language tag: 2-3 letters (e.g., "en", "fra")
/// - Optional region subtag: 2 letters or 3 digits (e.g., "US", "419")
/// - Optional script subtag: 4 letters (e.g., "Latn")
/// - Examples: "en", "en-US", "zh-Hans", "es-419", "fr-CA"
///
/// - SeeAlso: [WCAG 2.1 SC 3.1.1](https://www.w3.org/WAI/WCAG21/Understanding/language-of-page.html)
/// - SeeAlso: [BCP 47](https://tools.ietf.org/html/bcp47)
/// - Note: Ported from veraPDF-wcag-algs language validation logic.
public struct LanguageChecker: AccessibilityChecker {

    // MARK: - AccessibilityChecker Conformance

    /// The WCAG success criterion being checked.
    public let criterion: WCAGSuccessCriterion = .languageOfPage

    /// Whether to perform strict BCP 47 validation.
    ///
    /// If true, validates language codes against BCP 47 format.
    /// If false, only checks for non-empty language attribute.
    public let strictValidation: Bool

    /// Whether to check all nodes for language attributes.
    ///
    /// If true, checks all nodes (useful for SC 3.1.2 Language of Parts).
    /// If false, only checks document root.
    public let checkAllNodes: Bool

    // MARK: - Initialization

    /// Creates a new language checker with default settings.
    ///
    /// - Parameters:
    ///   - strictValidation: Whether to perform strict BCP 47 validation (default: true).
    ///   - checkAllNodes: Whether to check all nodes (default: false).
    public init(
        strictValidation: Bool = true,
        checkAllNodes: Bool = false
    ) {
        self.strictValidation = strictValidation
        self.checkAllNodes = checkAllNodes
    }

    // MARK: - Checking

    /// Checks a semantic node for language violations.
    ///
    /// - Parameter node: The semantic node to check.
    /// - Returns: The result of the accessibility check.
    public func check(_ node: any SemanticNode) -> AccessibilityCheckResult {
        var violations: [AccessibilityViolation] = []

        // If checking only document root
        if !checkAllNodes {
            // Only check document nodes
            guard node.type == .document else {
                return .passing(criterion: criterion)
            }

            violations.append(contentsOf: checkNodeLanguage(node))
        } else {
            // Check all nodes that might have language
            if shouldCheckNode(node) {
                violations.append(contentsOf: checkNodeLanguage(node))
            }
        }

        if violations.isEmpty {
            return .passing(
                criterion: criterion,
                context: "Language attribute is valid"
            )
        } else {
            return .failing(
                criterion: criterion,
                violations: violations
            )
        }
    }

    // MARK: - Private Helpers

    /// Determines if a node should be checked for language.
    private func shouldCheckNode(_ node: any SemanticNode) -> Bool {
        // Always check document root
        if node.type == .document {
            return true
        }

        // If checking all nodes, check content-bearing nodes
        if checkAllNodes {
            switch node.type {
            case .paragraph, .heading, .h1, .h2, .h3, .h4, .h5, .h6,
                 .span, .blockQuote, .caption, .listItem:
                return true
            default:
                return false
            }
        }

        return false
    }

    /// Checks if a node has a valid language attribute.
    private func checkNodeLanguage(_ node: any SemanticNode) -> [AccessibilityViolation] {
        var violations: [AccessibilityViolation] = []

        // Get language attribute
        guard let language = node.language else {
            // Document root must have language
            if node.type == .document {
                violations.append(
                    AccessibilityViolation(
                        nodeId: node.id,
                        nodeType: node.type,
                        description: "Document lacks language attribute (Lang entry required)",
                        severity: .critical,
                        location: node.boundingBox
                    )
                )
            } else if checkAllNodes {
                // Other nodes may lack language if they inherit from parent
                // This is not necessarily a violation for non-document nodes
            }
            return violations
        }

        // Check for empty language
        let trimmed = language.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            violations.append(
                AccessibilityViolation(
                    nodeId: node.id,
                    nodeType: node.type,
                    description: "Language attribute is empty or whitespace-only",
                    severity: .critical,
                    location: node.boundingBox
                )
            )
            return violations
        }

        // Perform strict validation if enabled
        if strictValidation {
            if let error = validateLanguageCode(trimmed) {
                violations.append(
                    AccessibilityViolation(
                        nodeId: node.id,
                        nodeType: node.type,
                        description: "Invalid language code '\(trimmed)': \(error)",
                        severity: .serious,
                        location: node.boundingBox
                    )
                )
            }
        }

        return violations
    }

    /// Validates a language code against BCP 47 format.
    ///
    /// - Parameter code: The language code to validate.
    /// - Returns: An error message if invalid, nil if valid.
    private func validateLanguageCode(_ code: String) -> String? {
        // Basic BCP 47 format: language[-script][-region][-variant]
        // Language: 2-3 letters
        // Script: 4 letters (optional)
        // Region: 2 letters or 3 digits (optional)
        // Variant: 5-8 alphanumeric or 4 starting with digit (optional)

        let parts = code.split(separator: "-").map(String.init)

        guard !parts.isEmpty else {
            return "Language code is empty"
        }

        // Check primary language tag
        let language = parts[0]
        if language.count < 2 || language.count > 3 {
            return "Primary language tag must be 2-3 letters (e.g., 'en', 'fra')"
        }

        if !language.allSatisfy({ $0.isLetter }) {
            return "Primary language tag must contain only letters"
        }

        // If only language tag, it's valid
        if parts.count == 1 {
            return nil
        }

        // Check subsequent subtags
        for i in 1..<parts.count {
            let subtag = parts[i]

            // Check for script (4 letters)
            if subtag.count == 4 && subtag.allSatisfy({ $0.isLetter }) {
                continue
            }

            // Check for region (2 letters or 3 digits)
            if subtag.count == 2 && subtag.allSatisfy({ $0.isLetter || $0.isNumber }) {
                continue
            }

            if subtag.count == 3 && subtag.allSatisfy({ $0.isNumber }) {
                continue
            }

            // Check for variant (5-8 alphanumeric or 4 starting with digit)
            if subtag.count >= 5 && subtag.count <= 8 && subtag.allSatisfy({ $0.isLetter || $0.isNumber }) {
                continue
            }

            if subtag.count == 4, let first = subtag.first, first.isNumber {
                continue
            }

            return "Invalid subtag '\(subtag)' in language code"
        }

        return nil
    }
}

// MARK: - Convenience Extensions

extension LanguageChecker {

    /// Creates a checker that only validates document-level language (3.1.1).
    public static var documentOnly: LanguageChecker {
        LanguageChecker(strictValidation: true, checkAllNodes: false)
    }

    /// Creates a checker that validates all element languages (3.1.2).
    public static var allElements: LanguageChecker {
        LanguageChecker(strictValidation: true, checkAllNodes: true)
    }

    /// Creates a lenient checker that only checks for non-empty language.
    public static var lenient: LanguageChecker {
        LanguageChecker(strictValidation: false, checkAllNodes: false)
    }
}

// MARK: - Common Language Codes

extension LanguageChecker {

    /// Common ISO 639-1 language codes.
    public static let commonLanguages: Set<String> = [
        "en", "es", "fr", "de", "it", "pt", "nl", "ru", "zh", "ja",
        "ko", "ar", "hi", "pl", "sv", "da", "no", "fi", "cs", "el",
        "he", "tr", "id", "th", "vi", "ro", "hu", "uk", "bg", "hr",
        "sr", "sk", "sl", "et", "lv", "lt", "is", "ga", "mt", "cy"
    ]

    /// Checks if a language code is a common language.
    ///
    /// - Parameter code: The language code to check.
    /// - Returns: True if the code is in the common languages set.
    public static func isCommonLanguage(_ code: String) -> Bool {
        let primary = code.split(separator: "-").first.map(String.init) ?? ""
        return commonLanguages.contains(primary.lowercased())
    }
}

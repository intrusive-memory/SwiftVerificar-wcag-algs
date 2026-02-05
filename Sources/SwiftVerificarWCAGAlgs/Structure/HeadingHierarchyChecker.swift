import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Result of heading hierarchy validation.
///
/// Contains findings from analyzing the heading structure of a PDF
/// document for WCAG compliance.
///
/// - Note: WCAG 1.3.1 (Info and Relationships) and 2.4.6 (Headings and Labels)
///   require proper heading hierarchy and meaningful heading text.
public struct HeadingHierarchyValidationResult: Sendable, Equatable {

    /// Issues detected during heading hierarchy validation.
    public let issues: [HeadingHierarchyIssue]

    /// The total number of heading nodes found.
    public let totalHeadingCount: Int

    /// The distribution of headings by level.
    public let headingsByLevel: [Int: Int]

    /// Whether the heading hierarchy is valid.
    public var isValid: Bool {
        issues.isEmpty
    }

    /// Issues grouped by type.
    public var issuesByType: [HeadingHierarchyIssue.IssueType: [HeadingHierarchyIssue]] {
        Dictionary(grouping: issues) { $0.type }
    }

    /// The number of critical issues found.
    public var criticalIssueCount: Int {
        issues.filter { $0.severity == .critical }.count
    }

    /// The maximum heading level found.
    public var maxHeadingLevel: Int {
        headingsByLevel.keys.max() ?? 0
    }

    /// Whether the document has exactly one H1.
    public var hasSingleH1: Bool {
        headingsByLevel[1] == 1
    }

    /// Creates a new heading hierarchy validation result.
    ///
    /// - Parameters:
    ///   - issues: The validation issues found.
    ///   - totalHeadingCount: The total number of headings.
    ///   - headingsByLevel: Count of headings at each level.
    public init(
        issues: [HeadingHierarchyIssue],
        totalHeadingCount: Int,
        headingsByLevel: [Int: Int]
    ) {
        self.issues = issues
        self.totalHeadingCount = totalHeadingCount
        self.headingsByLevel = headingsByLevel
    }
}

/// An issue found during heading hierarchy validation.
///
/// Records problems with heading structure that may affect navigation
/// and document understanding.
public struct HeadingHierarchyIssue: Sendable, Equatable, Identifiable {

    /// Severity level of the heading hierarchy issue.
    public enum Severity: String, Sendable, Equatable, CaseIterable {
        /// Critical issue that significantly impacts accessibility.
        case critical

        /// Warning about potential heading problems.
        case warning

        /// Informational note about headings.
        case info
    }

    /// The type of heading hierarchy issue.
    public enum IssueType: String, Sendable, Equatable, CaseIterable {
        /// Heading level was skipped (e.g., H1 to H3).
        case levelSkipped

        /// Multiple H1 headings found.
        case multipleH1

        /// Heading is empty (no text content).
        case emptyHeading

        /// First heading is not H1.
        case firstHeadingNotH1

        /// Heading level increases by more than one.
        case levelIncreaseExcessive

        /// Heading text is not meaningful.
        case nonMeaningfulText

        /// Heading appears out of logical order.
        case logicalOrderViolation
    }

    /// Unique identifier for this issue instance.
    public let id: UUID

    /// The type of issue.
    public let type: IssueType

    /// The severity of the issue.
    public let severity: Severity

    /// The ID of the heading node with the issue.
    public let nodeId: UUID

    /// The heading level (1-6).
    public let headingLevel: Int

    /// A human-readable description of the issue.
    public let message: String

    /// The page index where the issue occurred.
    public let pageIndex: Int?

    /// Additional context about the issue.
    public let context: [String: String]

    /// Creates a new heading hierarchy issue.
    ///
    /// - Parameters:
    ///   - type: The type of issue.
    ///   - severity: The severity level.
    ///   - nodeId: The affected heading node ID.
    ///   - headingLevel: The heading level.
    ///   - message: A description of the issue.
    ///   - pageIndex: The page where the issue occurred.
    ///   - context: Additional contextual information.
    public init(
        type: IssueType,
        severity: Severity,
        nodeId: UUID,
        headingLevel: Int,
        message: String,
        pageIndex: Int? = nil,
        context: [String: String] = [:]
    ) {
        self.id = UUID()
        self.type = type
        self.severity = severity
        self.nodeId = nodeId
        self.headingLevel = headingLevel
        self.message = message
        self.pageIndex = pageIndex
        self.context = context
    }
}

/// Validates the heading hierarchy of a PDF document's structure tree.
///
/// The `HeadingHierarchyChecker` ensures that headings follow proper
/// hierarchical structure according to WCAG guidelines:
///
/// ## Validation Rules
///
/// - **Single H1**: Document should have exactly one H1 heading
/// - **No skipped levels**: Heading levels should not be skipped
///   (e.g., H1 -> H2 -> H4 is invalid)
/// - **Proper nesting**: Heading levels should increase by at most one
/// - **Non-empty headings**: Headings must contain text or text alternatives
/// - **Meaningful text**: Heading text should be descriptive
/// - **Logical order**: Headings should follow document flow
///
/// ## Example Usage
///
/// ```swift
/// let checker = HeadingHierarchyChecker()
/// let result = checker.validate(rootNode)
///
/// if result.isValid {
///     print("Heading hierarchy is valid")
///     print("Found \(result.totalHeadingCount) headings")
/// } else {
///     print("Found \(result.issues.count) heading issues:")
///     for issue in result.issues {
///         print("- H\(issue.headingLevel): \(issue.message)")
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// `HeadingHierarchyChecker` is `Sendable` and can be used concurrently.
///
/// - Note: Ported from veraPDF-wcag-algs heading validation concepts.
public struct HeadingHierarchyChecker: Sendable {

    /// Options for heading hierarchy validation.
    public struct Options: Sendable, Equatable {

        /// Whether to require exactly one H1.
        public let requireSingleH1: Bool

        /// Whether to check for skipped heading levels.
        public let checkSkippedLevels: Bool

        /// Whether to check for empty headings.
        public let checkEmptyHeadings: Bool

        /// Whether to validate heading text meaningfulness.
        public let validateHeadingText: Bool

        /// Whether to check that first heading is H1.
        public let requireFirstH1: Bool

        /// Maximum allowed heading level (typically 6).
        public let maxHeadingLevel: Int

        /// Minimum heading text length for meaningfulness check.
        public let minHeadingTextLength: Int

        /// Creates default heading hierarchy validation options.
        public init(
            requireSingleH1: Bool = true,
            checkSkippedLevels: Bool = true,
            checkEmptyHeadings: Bool = true,
            validateHeadingText: Bool = true,
            requireFirstH1: Bool = true,
            maxHeadingLevel: Int = 6,
            minHeadingTextLength: Int = 1
        ) {
            self.requireSingleH1 = requireSingleH1
            self.checkSkippedLevels = checkSkippedLevels
            self.checkEmptyHeadings = checkEmptyHeadings
            self.validateHeadingText = validateHeadingText
            self.requireFirstH1 = requireFirstH1
            self.maxHeadingLevel = maxHeadingLevel
            self.minHeadingTextLength = minHeadingTextLength
        }

        /// All validation checks enabled.
        public static let all = Options()

        /// Basic validation (skipped levels and empty headings only).
        public static let basic = Options(
            requireSingleH1: false,
            checkSkippedLevels: true,
            checkEmptyHeadings: true,
            validateHeadingText: false,
            requireFirstH1: false
        )

        /// Strict validation with all checks.
        public static let strict = Options()
    }

    /// Validation options.
    public let options: Options

    /// Creates a new checker with the specified options.
    ///
    /// - Parameter options: Validation configuration options.
    public init(options: Options = .all) {
        self.options = options
    }

    /// Validates the heading hierarchy of a structure tree.
    ///
    /// - Parameter root: The root node of the structure tree.
    /// - Returns: The validation result containing any issues found.
    public func validate(_ root: any SemanticNode) -> HeadingHierarchyValidationResult {
        // Collect all heading nodes
        let headings = collectHeadings(root)

        var issues: [HeadingHierarchyIssue] = []
        var levelCounts: [Int: Int] = [:]

        // Count headings by level
        for heading in headings {
            let level = extractHeadingLevel(heading.node)
            levelCounts[level, default: 0] += 1
        }

        // Check for multiple H1s
        if options.requireSingleH1 {
            if let h1Count = levelCounts[1], h1Count > 1 {
                // Find all H1 nodes and report issues
                for heading in headings where extractHeadingLevel(heading.node) == 1 {
                    issues.append(HeadingHierarchyIssue(
                        type: .multipleH1,
                        severity: .critical,
                        nodeId: heading.node.id,
                        headingLevel: 1,
                        message: "Document contains multiple H1 headings (found \(h1Count))",
                        pageIndex: heading.node.pageIndex,
                        context: ["h1Count": "\(h1Count)"]
                    ))
                }
            } else if levelCounts[1] == nil {
                // No H1 found
                if let firstHeading = headings.first {
                    let level = extractHeadingLevel(firstHeading.node)
                    issues.append(HeadingHierarchyIssue(
                        type: .firstHeadingNotH1,
                        severity: .critical,
                        nodeId: firstHeading.node.id,
                        headingLevel: level,
                        message: "Document has no H1 heading",
                        pageIndex: firstHeading.node.pageIndex
                    ))
                }
            }
        }

        // Check first heading is H1
        if options.requireFirstH1, let firstHeading = headings.first {
            let level = extractHeadingLevel(firstHeading.node)
            if level != 1 {
                issues.append(HeadingHierarchyIssue(
                    type: .firstHeadingNotH1,
                    severity: .warning,
                    nodeId: firstHeading.node.id,
                    headingLevel: level,
                    message: "First heading is H\(level), should be H1",
                    pageIndex: firstHeading.node.pageIndex,
                    context: ["actualLevel": "\(level)"]
                ))
            }
        }

        // Check each heading
        var previousLevel: Int?

        for heading in headings {
            let level = extractHeadingLevel(heading.node)

            // Check for empty headings
            if options.checkEmptyHeadings {
                if let emptyIssue = checkEmptyHeading(heading.node, level: level) {
                    issues.append(emptyIssue)
                }
            }

            // Check heading text meaningfulness
            if options.validateHeadingText {
                if let textIssue = checkHeadingText(heading.node, level: level) {
                    issues.append(textIssue)
                }
            }

            // Check for skipped levels
            if options.checkSkippedLevels, let prevLevel = previousLevel {
                if level > prevLevel + 1 {
                    issues.append(HeadingHierarchyIssue(
                        type: .levelSkipped,
                        severity: .critical,
                        nodeId: heading.node.id,
                        headingLevel: level,
                        message: "Heading level skipped from H\(prevLevel) to H\(level)",
                        pageIndex: heading.node.pageIndex,
                        context: [
                            "previousLevel": "\(prevLevel)",
                            "currentLevel": "\(level)",
                            "skippedLevels": "\(level - prevLevel - 1)"
                        ]
                    ))
                }
            }

            // Check max level
            if level > options.maxHeadingLevel {
                issues.append(HeadingHierarchyIssue(
                    type: .levelIncreaseExcessive,
                    severity: .warning,
                    nodeId: heading.node.id,
                    headingLevel: level,
                    message: "Heading level H\(level) exceeds maximum of H\(options.maxHeadingLevel)",
                    pageIndex: heading.node.pageIndex,
                    context: [
                        "actualLevel": "\(level)",
                        "maxLevel": "\(options.maxHeadingLevel)"
                    ]
                ))
            }

            previousLevel = level
        }

        return HeadingHierarchyValidationResult(
            issues: issues,
            totalHeadingCount: headings.count,
            headingsByLevel: levelCounts
        )
    }

    // MARK: - Private Helper Methods

    private func collectHeadings(
        _ root: any SemanticNode
    ) -> [(node: any SemanticNode, depth: Int)] {
        var result: [(node: any SemanticNode, depth: Int)] = []

        func collect(_ node: any SemanticNode, depth: Int) {
            if isHeadingType(node.type) {
                result.append((node, depth))
            }

            for child in node.children {
                collect(child, depth: depth + 1)
            }
        }

        collect(root, depth: 0)
        return result
    }

    private func isHeadingType(_ type: SemanticType) -> Bool {
        switch type {
        case .heading, .h1, .h2, .h3, .h4, .h5, .h6:
            return true
        default:
            return false
        }
    }

    private func extractHeadingLevel(_ node: any SemanticNode) -> Int {
        switch node.type {
        case .h1: return 1
        case .h2: return 2
        case .h3: return 3
        case .h4: return 4
        case .h5: return 5
        case .h6: return 6
        case .heading:
            // Try to extract from attributes or default to 1
            if let levelAttr = node.attributes["Level"]?.intValue {
                return levelAttr
            }
            return 1
        default:
            return 0
        }
    }

    private func checkEmptyHeading(
        _ node: any SemanticNode,
        level: Int
    ) -> HeadingHierarchyIssue? {
        // Check if heading has content
        let hasContent = node.hasChildren || node.hasTextAlternative

        if !hasContent {
            return HeadingHierarchyIssue(
                type: .emptyHeading,
                severity: .critical,
                nodeId: node.id,
                headingLevel: level,
                message: "Heading H\(level) is empty",
                pageIndex: node.pageIndex
            )
        }

        return nil
    }

    private func checkHeadingText(
        _ node: any SemanticNode,
        level: Int
    ) -> HeadingHierarchyIssue? {
        // Get text from node
        let text = node.textDescription ?? ""
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check minimum length
        if trimmed.count < options.minHeadingTextLength {
            return HeadingHierarchyIssue(
                type: .nonMeaningfulText,
                severity: .warning,
                nodeId: node.id,
                headingLevel: level,
                message: "Heading H\(level) text is too short to be meaningful",
                pageIndex: node.pageIndex,
                context: [
                    "textLength": "\(trimmed.count)",
                    "minLength": "\(options.minHeadingTextLength)"
                ]
            )
        }

        // Check for non-meaningful patterns
        let lowercased = trimmed.lowercased()
        let nonMeaningfulPatterns = [
            "heading", "title", "section", "chapter",
            "untitled", "new heading", "click here"
        ]

        if nonMeaningfulPatterns.contains(where: { lowercased == $0 }) {
            return HeadingHierarchyIssue(
                type: .nonMeaningfulText,
                severity: .warning,
                nodeId: node.id,
                headingLevel: level,
                message: "Heading H\(level) text '\(trimmed)' is not meaningful",
                pageIndex: node.pageIndex,
                context: ["headingText": trimmed]
            )
        }

        return nil
    }
}

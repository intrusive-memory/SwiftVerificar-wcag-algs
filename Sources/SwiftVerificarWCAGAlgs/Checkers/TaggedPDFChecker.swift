import Foundation

/// Validates that a PDF document meets tagged PDF requirements.
///
/// Tagged PDF is a fundamental requirement of PDF/UA. This checker
/// validates that:
/// - The document has a proper structure tree
/// - All content is contained within structure elements
/// - The structure tree is not empty
/// - Required structure elements are present
///
/// ## PDF/UA Requirements
///
/// - **7.1**: The document shall be tagged
/// - All semantic structure shall be indicated by tags
/// - The logical structure shall be provided via structure elements
///
/// ## Usage
///
/// ```swift
/// let checker = TaggedPDFChecker()
/// let result = checker.check(documentRootNode)
/// if !result.passed {
///     for violation in result.violations {
///         print(violation.description)
///     }
/// }
/// ```
///
/// - Note: Ported from veraPDF-wcag-algs tagged PDF validation logic.
public struct TaggedPDFChecker: PDFUAChecker {

    /// The PDF/UA requirement validated by this checker.
    public let requirement: PDFUARequirement = .documentMustBeTagged

    /// Minimum number of structure elements expected in a valid tagged PDF.
    public let minimumStructureElements: Int

    /// Whether to check for presence of document root element.
    public let requireDocumentRoot: Bool

    /// Whether to check that all content is tagged.
    public let requireAllContentTagged: Bool

    /// Creates a new tagged PDF checker.
    ///
    /// - Parameters:
    ///   - minimumStructureElements: Minimum structure elements expected (default: 1).
    ///   - requireDocumentRoot: Whether document root is required (default: true).
    ///   - requireAllContentTagged: Whether all content must be tagged (default: true).
    public init(
        minimumStructureElements: Int = 1,
        requireDocumentRoot: Bool = true,
        requireAllContentTagged: Bool = true
    ) {
        self.minimumStructureElements = minimumStructureElements
        self.requireDocumentRoot = requireDocumentRoot
        self.requireAllContentTagged = requireAllContentTagged
    }

    /// Checks if a semantic node represents a properly tagged PDF document.
    ///
    /// - Parameter node: The root semantic node to check.
    /// - Returns: A check result indicating whether the document is properly tagged.
    public func check(_ node: any SemanticNode) -> PDFUACheckResult {
        var violations: [PDFUAViolation] = []

        // Check 1: Document must have a structure tree root
        if requireDocumentRoot && node.type != .document {
            violations.append(
                PDFUAViolation(
                    nodeId: node.id,
                    nodeType: node.type,
                    description: "Document root must be of type 'Document', found '\(node.type.rawValue)'",
                    severity: .error,
                    location: node.boundingBox
                )
            )
        }

        // Check 2: Document must not be empty
        if node.children.isEmpty {
            violations.append(
                PDFUAViolation(
                    nodeId: node.id,
                    nodeType: node.type,
                    description: "Document structure tree is empty - no tagged content found",
                    severity: .error,
                    location: node.boundingBox
                )
            )
        }

        // Check 3: Count all structure elements
        let elementCount = countStructureElements(node)
        if elementCount < minimumStructureElements {
            violations.append(
                PDFUAViolation(
                    nodeId: node.id,
                    nodeType: node.type,
                    description: "Document has only \(elementCount) structure element(s), minimum required is \(minimumStructureElements)",
                    severity: .error,
                    location: node.boundingBox
                )
            )
        }

        // Check 4: All structure elements must have valid types
        let invalidElements = findInvalidElements(node)
        for element in invalidElements {
            violations.append(
                PDFUAViolation(
                    nodeId: element.id,
                    nodeType: element.type,
                    description: "Structure element has invalid or unrecognized type: '\(element.type.rawValue)'",
                    severity: .warning,
                    location: element.boundingBox
                )
            )
        }

        // Check 5: Detect untagged content (if required)
        if requireAllContentTagged {
            let untaggedContent = findUntaggedContent(node)
            for content in untaggedContent {
                violations.append(
                    PDFUAViolation(
                        nodeId: content.id,
                        nodeType: content.type,
                        description: "Content appears to be untagged or in an artifact element",
                        severity: .warning,
                        location: content.boundingBox
                    )
                )
            }
        }

        // Check 6: Validate required structure elements
        if !hasRequiredElements(node) {
            violations.append(
                PDFUAViolation(
                    nodeId: node.id,
                    nodeType: node.type,
                    description: "Document missing required structure elements (no content blocks found)",
                    severity: .error,
                    location: node.boundingBox
                )
            )
        }

        // Return result
        if violations.isEmpty {
            return .passing(
                requirement: requirement,
                context: "Document is properly tagged with \(elementCount) structure element(s)"
            )
        } else {
            return .failing(
                requirement: requirement,
                violations: violations,
                context: "Found \(violations.count) tagging violation(s)"
            )
        }
    }

    // MARK: - Private Helper Methods

    /// Counts all structure elements in the tree.
    private func countStructureElements(_ node: any SemanticNode) -> Int {
        var count = 1 // Count this node

        for child in node.children {
            count += countStructureElements(child)
        }

        return count
    }

    /// Finds elements with invalid or unrecognized types.
    private func findInvalidElements(_ node: any SemanticNode) -> [any SemanticNode] {
        var invalid: [any SemanticNode] = []

        // Check if this node has a recognized type
        // In practice, SemanticType enum contains all valid types,
        // but we can check for empty or unusual configurations
        if node.children.isEmpty && node.boundingBox == nil && node.type != .document {
            // Empty element with no content and no bounding box is suspicious
            invalid.append(node)
        }

        // Recursively check children
        for child in node.children {
            invalid.append(contentsOf: findInvalidElements(child))
        }

        return invalid
    }

    /// Finds content that appears to be untagged.
    private func findUntaggedContent(_ node: any SemanticNode) -> [any SemanticNode] {
        var untagged: [any SemanticNode] = []

        // Check if this node is marked as an artifact
        if node.type == .artifact {
            untagged.append(node)
        }

        // Check for nodes with error codes indicating missing content
        if node.errorCodes.contains(.emptyElement) {
            untagged.append(node)
        }

        // Recursively check children
        for child in node.children {
            untagged.append(contentsOf: findUntaggedContent(child))
        }

        return untagged
    }

    /// Checks if document has required structure elements.
    private func hasRequiredElements(_ node: any SemanticNode) -> Bool {
        // A tagged document must have at least some content elements
        // Look for paragraphs, headings, figures, tables, lists, etc.
        let contentTypes: Set<SemanticType> = [
            .paragraph, .heading, .h1, .h2, .h3, .h4, .h5, .h6,
            .figure, .table, .list, .div, .blockQuote
        ]

        return containsAnyType(node, types: contentTypes)
    }

    /// Checks if tree contains any of the specified types.
    private func containsAnyType(_ node: any SemanticNode, types: Set<SemanticType>) -> Bool {
        if types.contains(node.type) {
            return true
        }

        for child in node.children {
            if containsAnyType(child, types: types) {
                return true
            }
        }

        return false
    }
}

// MARK: - Convenience Initializers

extension TaggedPDFChecker {

    /// Creates a strict tagged PDF checker with all validations enabled.
    public static var strict: TaggedPDFChecker {
        TaggedPDFChecker(
            minimumStructureElements: 1,
            requireDocumentRoot: true,
            requireAllContentTagged: true
        )
    }

    /// Creates a lenient tagged PDF checker with relaxed requirements.
    public static var lenient: TaggedPDFChecker {
        TaggedPDFChecker(
            minimumStructureElements: 1,
            requireDocumentRoot: false,
            requireAllContentTagged: false
        )
    }

    /// Creates a basic tagged PDF checker that only checks for structure tree existence.
    public static var basic: TaggedPDFChecker {
        TaggedPDFChecker(
            minimumStructureElements: 1,
            requireDocumentRoot: false,
            requireAllContentTagged: false
        )
    }
}

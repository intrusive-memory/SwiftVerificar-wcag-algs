import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Result of structure tree analysis.
///
/// Contains validation findings from analyzing the structure tree
/// of a PDF document for WCAG compliance.
///
/// - Note: Ported from veraPDF-wcag-algs structure validation concepts.
public struct StructureTreeAnalysisResult: Sendable, Equatable {

    /// All errors detected during analysis.
    public let errors: [StructureTreeError]

    /// The total number of nodes analyzed.
    public let totalNodeCount: Int

    /// The maximum depth of the tree.
    public let maxDepth: Int

    /// Whether the structure tree is valid.
    public var isValid: Bool {
        errors.isEmpty
    }

    /// Errors grouped by type.
    public var errorsByType: [SemanticErrorCode: [StructureTreeError]] {
        Dictionary(grouping: errors) { $0.code }
    }

    /// The number of unique error codes found.
    public var errorCodeCount: Int {
        Set(errors.map(\.code)).count
    }

    /// Creates a new analysis result.
    ///
    /// - Parameters:
    ///   - errors: The validation errors found.
    ///   - totalNodeCount: The total number of nodes analyzed.
    ///   - maxDepth: The maximum depth of the tree.
    public init(
        errors: [StructureTreeError],
        totalNodeCount: Int,
        maxDepth: Int
    ) {
        self.errors = errors
        self.totalNodeCount = totalNodeCount
        self.maxDepth = maxDepth
    }
}

/// An error found during structure tree analysis.
///
/// Records the specific validation failure, affected node, and
/// contextual information for reporting.
public struct StructureTreeError: Sendable, Equatable, Identifiable {

    /// Unique identifier for this error instance.
    public let id: UUID

    /// The error code indicating the type of issue.
    public let code: SemanticErrorCode

    /// The ID of the node where the error was found.
    public let nodeId: UUID

    /// The semantic type of the node with the error.
    public let nodeType: SemanticType

    /// A human-readable description of the error.
    public let message: String

    /// The page index where the error occurred, if applicable.
    public let pageIndex: Int?

    /// Additional context about the error.
    public let context: [String: String]

    /// Creates a new structure tree error.
    ///
    /// - Parameters:
    ///   - code: The error code.
    ///   - nodeId: The ID of the affected node.
    ///   - nodeType: The type of the affected node.
    ///   - message: A description of the error.
    ///   - pageIndex: The page where the error occurred.
    ///   - context: Additional contextual information.
    public init(
        code: SemanticErrorCode,
        nodeId: UUID,
        nodeType: SemanticType,
        message: String,
        pageIndex: Int? = nil,
        context: [String: String] = [:]
    ) {
        self.id = UUID()
        self.code = code
        self.nodeId = nodeId
        self.nodeType = nodeType
        self.message = message
        self.pageIndex = pageIndex
        self.context = context
    }
}

/// Analyzes the structure tree of a PDF document for WCAG compliance.
///
/// The `StructureTreeAnalyzer` performs comprehensive validation of the
/// logical structure tree, checking for accessibility issues such as:
///
/// - Invalid nesting of elements
/// - Missing required children
/// - Inappropriate parent-child relationships
/// - Missing or invalid attributes
/// - Empty structural elements
/// - Duplicate IDs
///
/// ## Example Usage
///
/// ```swift
/// let analyzer = StructureTreeAnalyzer()
/// let result = analyzer.analyze(rootNode)
///
/// if result.isValid {
///     print("Structure tree is valid")
/// } else {
///     print("Found \(result.errors.count) errors")
///     for error in result.errors {
///         print("- \(error.message)")
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// `StructureTreeAnalyzer` is `Sendable` and can be used concurrently.
/// All analysis operations are pure functions with no shared mutable state.
///
/// - Note: Ported from veraPDF-wcag-algs structure tree validation logic.
public struct StructureTreeAnalyzer: Sendable {

    /// Options for structure tree analysis.
    public struct Options: Sendable, Equatable {

        /// Whether to validate nesting relationships.
        public let validateNesting: Bool

        /// Whether to validate required children.
        public let validateRequiredChildren: Bool

        /// Whether to validate attributes.
        public let validateAttributes: Bool

        /// Whether to check for empty elements.
        public let checkEmptyElements: Bool

        /// Whether to check for duplicate IDs.
        public let checkDuplicateIds: Bool

        /// Maximum allowed tree depth (0 = unlimited).
        public let maxDepth: Int

        /// Creates default analysis options.
        public init(
            validateNesting: Bool = true,
            validateRequiredChildren: Bool = true,
            validateAttributes: Bool = true,
            checkEmptyElements: Bool = true,
            checkDuplicateIds: Bool = true,
            maxDepth: Int = 0
        ) {
            self.validateNesting = validateNesting
            self.validateRequiredChildren = validateRequiredChildren
            self.validateAttributes = validateAttributes
            self.checkEmptyElements = checkEmptyElements
            self.checkDuplicateIds = checkDuplicateIds
            self.maxDepth = maxDepth
        }

        /// All validations enabled.
        public static let all = Options()

        /// Only nesting validation enabled.
        public static let nestingOnly = Options(
            validateNesting: true,
            validateRequiredChildren: false,
            validateAttributes: false,
            checkEmptyElements: false,
            checkDuplicateIds: false
        )

        /// Only attribute validation enabled.
        public static let attributesOnly = Options(
            validateNesting: false,
            validateRequiredChildren: false,
            validateAttributes: true,
            checkEmptyElements: false,
            checkDuplicateIds: false
        )
    }

    /// Analysis options.
    public let options: Options

    /// Creates a new analyzer with the specified options.
    ///
    /// - Parameter options: Analysis configuration options.
    public init(options: Options = .all) {
        self.options = options
    }

    /// Analyzes a structure tree starting from the given root node.
    ///
    /// - Parameter root: The root node of the structure tree.
    /// - Returns: The analysis result containing any errors found.
    public func analyze(_ root: any SemanticNode) -> StructureTreeAnalysisResult {
        var errors: [StructureTreeError] = []
        var seenIds: Set<UUID> = []
        var nodeCount = 0
        var maxDepthSeen = 0

        analyzeNode(
            root,
            errors: &errors,
            seenIds: &seenIds,
            nodeCount: &nodeCount,
            maxDepth: &maxDepthSeen
        )

        return StructureTreeAnalysisResult(
            errors: errors,
            totalNodeCount: nodeCount,
            maxDepth: maxDepthSeen
        )
    }

    // MARK: - Private Analysis Methods

    private func analyzeNode(
        _ node: any SemanticNode,
        errors: inout [StructureTreeError],
        seenIds: inout Set<UUID>,
        nodeCount: inout Int,
        maxDepth: inout Int
    ) {
        nodeCount += 1
        maxDepth = max(maxDepth, node.depth)

        // Check max depth
        if options.maxDepth > 0 && node.depth > options.maxDepth {
            errors.append(StructureTreeError(
                code: .invalidNesting,
                nodeId: node.id,
                nodeType: node.type,
                message: "Node exceeds maximum depth of \(options.maxDepth)",
                pageIndex: node.pageIndex,
                context: ["depth": "\(node.depth)", "maxDepth": "\(options.maxDepth)"]
            ))
        }

        // Check for duplicate IDs
        if options.checkDuplicateIds {
            if seenIds.contains(node.id) {
                errors.append(StructureTreeError(
                    code: .duplicateId,
                    nodeId: node.id,
                    nodeType: node.type,
                    message: "Duplicate node ID detected",
                    pageIndex: node.pageIndex
                ))
            } else {
                seenIds.insert(node.id)
            }
        }

        // Check for empty elements
        if options.checkEmptyElements {
            if let emptyError = checkEmptyElement(node) {
                errors.append(emptyError)
            }
        }

        // Validate nesting
        if options.validateNesting {
            errors.append(contentsOf: validateNesting(node))
        }

        // Validate required children
        if options.validateRequiredChildren {
            errors.append(contentsOf: validateRequiredChildren(node))
        }

        // Validate attributes
        if options.validateAttributes {
            errors.append(contentsOf: validateAttributes(node))
        }

        // Recursively analyze children
        for child in node.children {
            analyzeNode(
                child,
                errors: &errors,
                seenIds: &seenIds,
                nodeCount: &nodeCount,
                maxDepth: &maxDepth
            )
        }
    }

    private func checkEmptyElement(_ node: any SemanticNode) -> StructureTreeError? {
        // Skip certain types that are allowed to be empty
        let allowedEmptyTypes: Set<SemanticType> = [
            .artifact, .documentHeader, .documentFooter, .note,
            .document, .part, .article, .section, .div  // Structural containers can be empty
        ]

        if allowedEmptyTypes.contains(node.type) {
            return nil
        }

        // Check if node has content
        let hasContent = node.hasChildren || node.hasTextAlternative

        if !hasContent {
            return StructureTreeError(
                code: .emptyElement,
                nodeId: node.id,
                nodeType: node.type,
                message: "Element is empty (no children or text alternative)",
                pageIndex: node.pageIndex
            )
        }

        return nil
    }

    private func validateNesting(_ node: any SemanticNode) -> [StructureTreeError] {
        var errors: [StructureTreeError] = []

        // Validate child types based on parent type
        for child in node.children {
            if !isValidChildType(child.type, forParent: node.type) {
                errors.append(StructureTreeError(
                    code: .unexpectedChild,
                    nodeId: child.id,
                    nodeType: child.type,
                    message: "Invalid child type '\(child.type.rawValue)' for parent '\(node.type.rawValue)'",
                    pageIndex: child.pageIndex,
                    context: [
                        "parentType": node.type.rawValue,
                        "childType": child.type.rawValue
                    ]
                ))
            }
        }

        return errors
    }

    private func isValidChildType(
        _ childType: SemanticType,
        forParent parentType: SemanticType
    ) -> Bool {
        switch parentType {
        case .document:
            // Document can contain most structure types
            return childType != .listLabel && childType != .listBody

        case .list:
            // Lists must contain list items
            return childType == .listItem

        case .listItem:
            // List items must contain label and body
            return childType == .listLabel || childType == .listBody || childType == .list

        case .table:
            // Tables must contain rows or thead/tbody/tfoot
            return childType == .tableRow
                || childType == .tableHead
                || childType == .tableBody
                || childType == .tableFoot

        case .tableRow:
            // Table rows must contain cells (TD or TH)
            return childType == .tableCell || childType == .tableHeader

        case .tableHead, .tableBody, .tableFoot:
            // Table sections must contain rows
            return childType == .tableRow

        case .toc:
            // TOC must contain TOCI items
            return childType == .tocItem

        default:
            // Most other types can have flexible children
            return true
        }
    }

    private func validateRequiredChildren(_ node: any SemanticNode) -> [StructureTreeError] {
        var errors: [StructureTreeError] = []

        switch node.type {
        case .listItem:
            // List items should have at least a body
            let hasBody = node.children.contains { $0.type == .listBody }
            if !hasBody {
                errors.append(StructureTreeError(
                    code: .missingRequiredChild,
                    nodeId: node.id,
                    nodeType: node.type,
                    message: "List item missing required LBody child",
                    pageIndex: node.pageIndex,
                    context: ["missingChild": "LBody"]
                ))
            }

        case .table:
            // Tables should have at least one row
            if node.children.isEmpty {
                errors.append(StructureTreeError(
                    code: .missingRequiredChild,
                    nodeId: node.id,
                    nodeType: node.type,
                    message: "Table has no rows",
                    pageIndex: node.pageIndex,
                    context: ["missingChild": "TR"]
                ))
            }

        case .tableRow:
            // Table rows should have at least one cell
            if node.children.isEmpty {
                errors.append(StructureTreeError(
                    code: .missingRequiredChild,
                    nodeId: node.id,
                    nodeType: node.type,
                    message: "Table row has no cells",
                    pageIndex: node.pageIndex,
                    context: ["missingChild": "TD or TH"]
                ))
            }

        default:
            break
        }

        return errors
    }

    private func validateAttributes(_ node: any SemanticNode) -> [StructureTreeError] {
        var errors: [StructureTreeError] = []

        // Validate required attributes for specific types
        switch node.type {
        case .figure:
            // Figures should have Alt or ActualText
            if !node.hasTextAlternative {
                errors.append(StructureTreeError(
                    code: .missingAttribute,
                    nodeId: node.id,
                    nodeType: node.type,
                    message: "Figure missing Alt or ActualText attribute",
                    pageIndex: node.pageIndex,
                    context: ["requiredAttribute": "Alt or ActualText"]
                ))
            }

        case .link:
            // Links should have meaningful content or Alt text
            if !node.hasChildren && !node.hasTextAlternative {
                errors.append(StructureTreeError(
                    code: .missingAttribute,
                    nodeId: node.id,
                    nodeType: node.type,
                    message: "Link has no content or Alt text",
                    pageIndex: node.pageIndex,
                    context: ["requiredAttribute": "Alt or content"]
                ))
            }

        default:
            break
        }

        return errors
    }
}

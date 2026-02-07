import Foundation

/// The result of a PDF/UA compliance check.
///
/// Contains information about whether the check passed, the specific
/// PDF/UA requirement, and any violations found.
public struct PDFUACheckResult: Sendable, Equatable {

    /// The PDF/UA requirement being checked.
    public let requirement: PDFUARequirement

    /// Whether the check passed (no violations found).
    public let passed: Bool

    /// The violations found during the check.
    public let violations: [PDFUAViolation]

    /// Additional context about the check.
    public let context: String?

    /// Creates a new PDF/UA check result.
    ///
    /// - Parameters:
    ///   - requirement: The PDF/UA requirement being checked.
    ///   - passed: Whether the check passed.
    ///   - violations: The violations found (defaults to empty).
    ///   - context: Additional context (optional).
    public init(
        requirement: PDFUARequirement,
        passed: Bool,
        violations: [PDFUAViolation] = [],
        context: String? = nil
    ) {
        self.requirement = requirement
        self.passed = passed
        self.violations = violations
        self.context = context
    }

    /// Creates a passing result with no violations.
    ///
    /// - Parameter requirement: The PDF/UA requirement being checked.
    /// - Returns: A passing check result.
    public static func passing(
        requirement: PDFUARequirement,
        context: String? = nil
    ) -> PDFUACheckResult {
        PDFUACheckResult(
            requirement: requirement,
            passed: true,
            violations: [],
            context: context
        )
    }

    /// Creates a failing result with violations.
    ///
    /// - Parameters:
    ///   - requirement: The PDF/UA requirement being checked.
    ///   - violations: The violations found.
    ///   - context: Additional context (optional).
    /// - Returns: A failing check result.
    public static func failing(
        requirement: PDFUARequirement,
        violations: [PDFUAViolation],
        context: String? = nil
    ) -> PDFUACheckResult {
        PDFUACheckResult(
            requirement: requirement,
            passed: false,
            violations: violations,
            context: context
        )
    }
}

/// A specific violation of a PDF/UA requirement.
public struct PDFUAViolation: Sendable, Equatable, Identifiable {

    /// Unique identifier for this violation.
    public let id: UUID

    /// The node where the violation occurred, if applicable.
    public let nodeId: UUID?

    /// The type of semantic node where the violation occurred, if applicable.
    public let nodeType: SemanticType?

    /// A human-readable description of the violation.
    public let description: String

    /// The severity of the violation.
    public let severity: PDFUASeverity

    /// The location of the violation, if available.
    public let location: BoundingBox?

    /// Creates a new PDF/UA violation.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID).
    ///   - nodeId: The ID of the node where the violation occurred (optional).
    ///   - nodeType: The type of semantic node (optional).
    ///   - description: Human-readable description.
    ///   - severity: The severity level.
    ///   - location: The spatial location (optional).
    public init(
        id: UUID = UUID(),
        nodeId: UUID? = nil,
        nodeType: SemanticType? = nil,
        description: String,
        severity: PDFUASeverity,
        location: BoundingBox? = nil
    ) {
        self.id = id
        self.nodeId = nodeId
        self.nodeType = nodeType
        self.description = description
        self.severity = severity
        self.location = location
    }
}

/// The severity level of a PDF/UA violation.
public enum PDFUASeverity: String, Sendable, Codable, CaseIterable {
    /// Critical violation that makes the PDF non-compliant.
    case error

    /// Serious violation that should be fixed.
    case warning

    /// Minor issue or best practice recommendation.
    case info
}

/// PDF/UA requirements that can be checked.
public enum PDFUARequirement: String, Sendable, Codable, CaseIterable {

    // MARK: - Structure Requirements

    /// Document must be tagged (7.1)
    case documentMustBeTagged = "7.1"

    /// All structure elements must have appropriate role mapping (7.2)
    case structureElementsNeedRoleMapping = "7.2"

    /// Structure tree must be logically ordered (7.3)
    case logicalReadingOrder = "7.3"

    // MARK: - Table Requirements

    /// Tables must have headers (7.5)
    case tablesMustHaveHeaders = "7.5"

    /// Table structure must be regular (no gaps/overlaps) (7.5)
    case tableStructureMustBeRegular = "7.5.1"

    /// Table cells must be properly associated with headers (7.5.2)
    case tableCellHeaderAssociation = "7.5.2"

    // MARK: - List Requirements

    /// List items must have labels (7.6)
    case listItemsMustHaveLabels = "7.6"

    /// List structure must be proper (7.6.1)
    case listStructureMustBeProper = "7.6.1"

    // MARK: - Content Requirements

    /// Non-text content must have alternative descriptions (7.18)
    case alternativeDescriptions = "7.18"

    /// Actual text must be provided for artifacts and abbreviations (7.18.1)
    case actualTextRequired = "7.18.1"

    /// The category of this requirement.
    public var category: PDFUACategory {
        switch self {
        case .documentMustBeTagged, .structureElementsNeedRoleMapping, .logicalReadingOrder:
            return .structure
        case .tablesMustHaveHeaders, .tableStructureMustBeRegular, .tableCellHeaderAssociation:
            return .tables
        case .listItemsMustHaveLabels, .listStructureMustBeProper:
            return .lists
        case .alternativeDescriptions, .actualTextRequired:
            return .content
        }
    }

    /// A human-readable name for this requirement.
    public var name: String {
        switch self {
        case .documentMustBeTagged:
            return "Document Must Be Tagged"
        case .structureElementsNeedRoleMapping:
            return "Structure Elements Need Role Mapping"
        case .logicalReadingOrder:
            return "Logical Reading Order"
        case .tablesMustHaveHeaders:
            return "Tables Must Have Headers"
        case .tableStructureMustBeRegular:
            return "Table Structure Must Be Regular"
        case .tableCellHeaderAssociation:
            return "Table Cell Header Association"
        case .listItemsMustHaveLabels:
            return "List Items Must Have Labels"
        case .listStructureMustBeProper:
            return "List Structure Must Be Proper"
        case .alternativeDescriptions:
            return "Alternative Descriptions"
        case .actualTextRequired:
            return "Actual Text Required"
        }
    }
}

/// PDF/UA requirement categories.
public enum PDFUACategory: String, Sendable, Codable, CaseIterable {
    /// Structure and tagging requirements.
    case structure = "Structure"

    /// Table accessibility requirements.
    case tables = "Tables"

    /// List accessibility requirements.
    case lists = "Lists"

    /// Content and alternative description requirements.
    case content = "Content"
}

/// Protocol for all PDF/UA checkers.
///
/// PDF/UA checkers validate specific PDF/UA requirements against
/// semantic nodes or document-level properties.
///
/// ## Implementation Guide
///
/// Conforming types should:
/// 1. Specify which `PDFUARequirement` they check
/// 2. Implement `check(_:)` to validate a semantic node or document
/// 3. Return detailed violations for any issues found
/// 4. Be stateless and thread-safe (Sendable)
///
/// ## Example
///
/// ```swift
/// struct TaggedPDFChecker: PDFUAChecker {
///     let requirement: PDFUARequirement = .documentMustBeTagged
///
///     func check(_ node: any SemanticNode) -> PDFUACheckResult {
///         // Check if document has proper tagging...
///     }
/// }
/// ```
public protocol PDFUAChecker: Sendable {

    /// The PDF/UA requirement this checker validates.
    var requirement: PDFUARequirement { get }

    /// Checks a semantic node for violations of the PDF/UA requirement.
    ///
    /// - Parameter node: The semantic node to check.
    /// - Returns: The result of the PDF/UA check.
    func check(_ node: any SemanticNode) -> PDFUACheckResult

    /// Checks multiple semantic nodes.
    ///
    /// Default implementation checks each node individually and
    /// aggregates the results.
    ///
    /// - Parameter nodes: The semantic nodes to check.
    /// - Returns: An aggregated check result.
    func check(_ nodes: [any SemanticNode]) -> PDFUACheckResult
}

// MARK: - Default Implementation

extension PDFUAChecker {

    /// Default implementation that checks multiple nodes.
    public func check(_ nodes: [any SemanticNode]) -> PDFUACheckResult {
        var allViolations: [PDFUAViolation] = []

        for node in nodes {
            let result = check(node)
            allViolations.append(contentsOf: result.violations)
        }

        // Only fail if there are error-severity violations
        let hasErrorViolations = allViolations.contains { $0.severity == .error }
        if hasErrorViolations {
            return .failing(
                requirement: requirement,
                violations: allViolations,
                context: "Found \(allViolations.count) violation(s) in \(nodes.count) node(s)"
            )
        } else if allViolations.isEmpty {
            return .passing(
                requirement: requirement,
                context: "Checked \(nodes.count) node(s)"
            )
        } else {
            // Only warnings/info -- still passing
            return PDFUACheckResult(
                requirement: requirement,
                passed: true,
                violations: allViolations,
                context: "Checked \(nodes.count) node(s) (\(allViolations.count) informational note(s))"
            )
        }
    }
}

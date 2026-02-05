import Foundation

/// The result of an accessibility check.
///
/// Contains information about whether the check passed, the specific
/// WCAG success criterion, and any violations found.
public struct AccessibilityCheckResult: Sendable, Equatable {

    /// The WCAG success criterion being checked.
    public let criterion: WCAGSuccessCriterion

    /// Whether the check passed (no violations found).
    public let passed: Bool

    /// The violations found during the check.
    public let violations: [AccessibilityViolation]

    /// Additional context about the check.
    public let context: String?

    /// Creates a new accessibility check result.
    ///
    /// - Parameters:
    ///   - criterion: The WCAG success criterion being checked.
    ///   - passed: Whether the check passed.
    ///   - violations: The violations found (defaults to empty).
    ///   - context: Additional context (optional).
    public init(
        criterion: WCAGSuccessCriterion,
        passed: Bool,
        violations: [AccessibilityViolation] = [],
        context: String? = nil
    ) {
        self.criterion = criterion
        self.passed = passed
        self.violations = violations
        self.context = context
    }

    /// Creates a passing result with no violations.
    ///
    /// - Parameter criterion: The WCAG success criterion being checked.
    /// - Returns: A passing check result.
    public static func passing(
        criterion: WCAGSuccessCriterion,
        context: String? = nil
    ) -> AccessibilityCheckResult {
        AccessibilityCheckResult(
            criterion: criterion,
            passed: true,
            violations: [],
            context: context
        )
    }

    /// Creates a failing result with violations.
    ///
    /// - Parameters:
    ///   - criterion: The WCAG success criterion being checked.
    ///   - violations: The violations found.
    ///   - context: Additional context (optional).
    /// - Returns: A failing check result.
    public static func failing(
        criterion: WCAGSuccessCriterion,
        violations: [AccessibilityViolation],
        context: String? = nil
    ) -> AccessibilityCheckResult {
        AccessibilityCheckResult(
            criterion: criterion,
            passed: false,
            violations: violations,
            context: context
        )
    }
}

/// A specific violation of a WCAG success criterion.
public struct AccessibilityViolation: Sendable, Equatable, Identifiable {

    /// Unique identifier for this violation.
    public let id: UUID

    /// The node where the violation occurred.
    public let nodeId: UUID

    /// The type of semantic node where the violation occurred.
    public let nodeType: SemanticType

    /// A human-readable description of the violation.
    public let description: String

    /// The severity of the violation.
    public let severity: ViolationSeverity

    /// The location of the violation, if available.
    public let location: BoundingBox?

    /// Creates a new accessibility violation.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID).
    ///   - nodeId: The ID of the node where the violation occurred.
    ///   - nodeType: The type of semantic node.
    ///   - description: Human-readable description.
    ///   - severity: The severity level.
    ///   - location: The spatial location (optional).
    public init(
        id: UUID = UUID(),
        nodeId: UUID,
        nodeType: SemanticType,
        description: String,
        severity: ViolationSeverity,
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

/// The severity level of an accessibility violation.
public enum ViolationSeverity: String, Sendable, Codable, CaseIterable {
    /// Critical violation that makes content inaccessible.
    case critical

    /// Serious violation that significantly impacts accessibility.
    case serious

    /// Moderate violation that may impact some users.
    case moderate

    /// Minor violation or best practice recommendation.
    case minor
}

/// WCAG 2.1 Success Criteria that can be checked.
public enum WCAGSuccessCriterion: String, Sendable, Codable, CaseIterable {

    // MARK: - Perceivable (1.x)

    /// 1.1.1 Non-text Content (Level A)
    case nonTextContent = "1.1.1"

    /// 1.3.1 Info and Relationships (Level A)
    case infoAndRelationships = "1.3.1"

    /// 1.4.3 Contrast (Minimum) (Level AA)
    case contrastMinimum = "1.4.3"

    /// 1.4.6 Contrast (Enhanced) (Level AAA)
    case contrastEnhanced = "1.4.6"

    // MARK: - Operable (2.x)

    /// 2.4.1 Bypass Blocks (Level A)
    case bypassBlocks = "2.4.1"

    /// 2.4.2 Page Titled (Level A)
    case pageTitled = "2.4.2"

    /// 2.4.4 Link Purpose (In Context) (Level A)
    case linkPurpose = "2.4.4"

    /// 2.4.6 Headings and Labels (Level AA)
    case headingsAndLabels = "2.4.6"

    // MARK: - Understandable (3.x)

    /// 3.1.1 Language of Page (Level A)
    case languageOfPage = "3.1.1"

    /// 3.1.2 Language of Parts (Level AA)
    case languageOfParts = "3.1.2"

    // MARK: - Robust (4.x)

    /// 4.1.2 Name, Role, Value (Level A)
    case nameRoleValue = "4.1.2"

    /// The conformance level for this criterion.
    public var level: WCAGLevel {
        switch self {
        case .nonTextContent, .infoAndRelationships, .bypassBlocks,
             .pageTitled, .linkPurpose, .languageOfPage, .nameRoleValue:
            return .a
        case .contrastMinimum, .headingsAndLabels, .languageOfParts:
            return .aa
        case .contrastEnhanced:
            return .aaa
        }
    }

    /// The WCAG principle this criterion belongs to.
    public var principle: WCAGPrinciple {
        let prefix = rawValue.prefix(1)
        switch prefix {
        case "1": return .perceivable
        case "2": return .operable
        case "3": return .understandable
        case "4": return .robust
        default: return .perceivable
        }
    }

    /// A human-readable name for this criterion.
    public var name: String {
        switch self {
        case .nonTextContent: return "Non-text Content"
        case .infoAndRelationships: return "Info and Relationships"
        case .contrastMinimum: return "Contrast (Minimum)"
        case .contrastEnhanced: return "Contrast (Enhanced)"
        case .bypassBlocks: return "Bypass Blocks"
        case .pageTitled: return "Page Titled"
        case .linkPurpose: return "Link Purpose (In Context)"
        case .headingsAndLabels: return "Headings and Labels"
        case .languageOfPage: return "Language of Page"
        case .languageOfParts: return "Language of Parts"
        case .nameRoleValue: return "Name, Role, Value"
        }
    }
}

// Note: WCAGLevel is defined in ColorContrastCalculator.swift

/// WCAG principles.
public enum WCAGPrinciple: String, Sendable, Codable, CaseIterable {
    /// Content must be perceivable.
    case perceivable = "Perceivable"

    /// Interface must be operable.
    case operable = "Operable"

    /// Information must be understandable.
    case understandable = "Understandable"

    /// Content must be robust.
    case robust = "Robust"
}

/// Protocol for all accessibility checkers.
///
/// Accessibility checkers validate specific WCAG success criteria
/// against semantic nodes in a PDF structure tree.
///
/// ## Implementation Guide
///
/// Conforming types should:
/// 1. Specify which `WCAGSuccessCriterion` they check
/// 2. Implement `check(_:)` to validate a semantic node
/// 3. Return detailed violations for any issues found
/// 4. Be stateless and thread-safe (Sendable)
///
/// ## Example
///
/// ```swift
/// struct AltTextChecker: AccessibilityChecker {
///     let criterion: WCAGSuccessCriterion = .nonTextContent
///
///     func check(_ node: any SemanticNode) -> AccessibilityCheckResult {
///         // Check if figures have alt text...
///     }
/// }
/// ```
public protocol AccessibilityChecker: Sendable {

    /// The WCAG success criterion this checker validates.
    var criterion: WCAGSuccessCriterion { get }

    /// Checks a semantic node for violations of the success criterion.
    ///
    /// - Parameter node: The semantic node to check.
    /// - Returns: The result of the accessibility check.
    func check(_ node: any SemanticNode) -> AccessibilityCheckResult

    /// Checks multiple semantic nodes.
    ///
    /// Default implementation checks each node individually and
    /// aggregates the results.
    ///
    /// - Parameter nodes: The semantic nodes to check.
    /// - Returns: An aggregated check result.
    func check(_ nodes: [any SemanticNode]) -> AccessibilityCheckResult
}

// MARK: - Default Implementation

extension AccessibilityChecker {

    /// Default implementation that checks multiple nodes.
    public func check(_ nodes: [any SemanticNode]) -> AccessibilityCheckResult {
        var allViolations: [AccessibilityViolation] = []

        for node in nodes {
            let result = check(node)
            allViolations.append(contentsOf: result.violations)
        }

        if allViolations.isEmpty {
            return .passing(
                criterion: criterion,
                context: "Checked \(nodes.count) node(s)"
            )
        } else {
            return .failing(
                criterion: criterion,
                violations: allViolations,
                context: "Found \(allViolations.count) violation(s) in \(nodes.count) node(s)"
            )
        }
    }
}

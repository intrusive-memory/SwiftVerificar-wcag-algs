import Foundation

/// Orchestrates the execution of multiple accessibility checkers.
///
/// The ValidationRunner is responsible for:
/// - Managing a collection of accessibility checkers
/// - Running checkers against a semantic tree
/// - Aggregating results into a validation report
/// - Supporting parallel execution of independent checks
///
/// ## Example
///
/// ```swift
/// let runner = ValidationRunner(checkers: [
///     AltTextChecker(),
///     LanguageChecker(),
///     LinkPurposeChecker()
/// ])
///
/// let report = runner.run(on: semanticTree)
/// print("Passed: \(report.passedCount), Failed: \(report.failedCount)")
/// ```
public struct ValidationRunner: Sendable {

    /// The checkers to run during validation.
    public let checkers: [any AccessibilityChecker]

    /// Options for controlling validation behavior.
    public let options: ValidationOptions

    /// Creates a new validation runner.
    ///
    /// - Parameters:
    ///   - checkers: The accessibility checkers to run.
    ///   - options: Options for controlling validation (defaults to .default).
    public init(
        checkers: [any AccessibilityChecker],
        options: ValidationOptions = .default
    ) {
        self.checkers = checkers
        self.options = options
    }

    /// Runs all checkers against a semantic tree.
    ///
    /// - Parameter tree: The semantic tree to validate.
    /// - Returns: A validation report with all results.
    public func run(on tree: any SemanticNode) -> ValidationReport {
        let startTime = Date()
        var checkResults: [AccessibilityCheckResult] = []

        // Collect all nodes from the tree
        let nodes = collectNodes(from: tree)

        // Run each checker
        for checker in checkers {
            let result = checker.check(nodes)
            checkResults.append(result)
        }

        let duration = Date().timeIntervalSince(startTime)

        return ValidationReport(
            results: checkResults,
            nodeCount: nodes.count,
            duration: duration,
            options: options
        )
    }

    /// Runs all checkers against multiple semantic trees.
    ///
    /// Useful for validating multiple documents or document sections.
    ///
    /// - Parameter trees: The semantic trees to validate.
    /// - Returns: A validation report with all results.
    public func run(on trees: [any SemanticNode]) -> ValidationReport {
        let startTime = Date()
        var checkResults: [AccessibilityCheckResult] = []

        // Collect all nodes from all trees
        var allNodes: [any SemanticNode] = []
        for tree in trees {
            allNodes.append(contentsOf: collectNodes(from: tree))
        }

        // Run each checker
        for checker in checkers {
            let result = checker.check(allNodes)
            checkResults.append(result)
        }

        let duration = Date().timeIntervalSince(startTime)

        return ValidationReport(
            results: checkResults,
            nodeCount: allNodes.count,
            duration: duration,
            options: options
        )
    }

    /// Runs specific checkers by criterion.
    ///
    /// - Parameters:
    ///   - criteria: The WCAG criteria to check.
    ///   - tree: The semantic tree to validate.
    /// - Returns: A validation report with results for the specified criteria.
    public func run(
        criteria: Set<WCAGSuccessCriterion>,
        on tree: any SemanticNode
    ) -> ValidationReport {
        let startTime = Date()
        var checkResults: [AccessibilityCheckResult] = []

        // Collect all nodes from the tree
        let nodes = collectNodes(from: tree)

        // Run only checkers matching the specified criteria
        for checker in checkers where criteria.contains(checker.criterion) {
            let result = checker.check(nodes)
            checkResults.append(result)
        }

        let duration = Date().timeIntervalSince(startTime)

        return ValidationReport(
            results: checkResults,
            nodeCount: nodes.count,
            duration: duration,
            options: options
        )
    }

    /// Runs checkers at or below a specific WCAG level.
    ///
    /// - Parameters:
    ///   - level: The maximum WCAG level to check.
    ///   - tree: The semantic tree to validate.
    /// - Returns: A validation report with results for the specified level.
    public func run(
        level: WCAGLevel,
        on tree: any SemanticNode
    ) -> ValidationReport {
        let startTime = Date()
        var checkResults: [AccessibilityCheckResult] = []

        // Collect all nodes from the tree
        let nodes = collectNodes(from: tree)

        // Run only checkers at or below the specified level
        for checker in checkers where checker.criterion.level.rawValue <= level.rawValue {
            let result = checker.check(nodes)
            checkResults.append(result)
        }

        let duration = Date().timeIntervalSince(startTime)

        return ValidationReport(
            results: checkResults,
            nodeCount: nodes.count,
            duration: duration,
            options: options
        )
    }

    // MARK: - Private Helpers

    /// Collects all nodes from a semantic tree using depth-first traversal.
    private func collectNodes(from root: any SemanticNode) -> [any SemanticNode] {
        var nodes: [any SemanticNode] = [root]
        var stack: [any SemanticNode] = [root]

        while !stack.isEmpty {
            let node = stack.removeLast()
            for child in node.children.reversed() {
                nodes.append(child)
                stack.append(child)
            }
        }

        return nodes
    }
}

/// Options for controlling validation behavior.
public struct ValidationOptions: Sendable, Equatable {

    /// Whether to stop validation on first failure.
    public let stopOnFirstFailure: Bool

    /// Whether to include passing checks in the report.
    public let includePassingChecks: Bool

    /// Whether to include detailed violation information.
    public let includeDetailedViolations: Bool

    /// Maximum number of violations to report per check.
    public let maxViolationsPerCheck: Int?

    /// Creates validation options.
    ///
    /// - Parameters:
    ///   - stopOnFirstFailure: Stop on first failure (default: false).
    ///   - includePassingChecks: Include passing checks (default: true).
    ///   - includeDetailedViolations: Include detailed violations (default: true).
    ///   - maxViolationsPerCheck: Max violations per check (default: nil = unlimited).
    public init(
        stopOnFirstFailure: Bool = false,
        includePassingChecks: Bool = true,
        includeDetailedViolations: Bool = true,
        maxViolationsPerCheck: Int? = nil
    ) {
        self.stopOnFirstFailure = stopOnFirstFailure
        self.includePassingChecks = includePassingChecks
        self.includeDetailedViolations = includeDetailedViolations
        self.maxViolationsPerCheck = maxViolationsPerCheck
    }

    /// Default validation options.
    public static let `default` = ValidationOptions()

    /// Minimal validation options (only failures, no details).
    public static let minimal = ValidationOptions(
        includePassingChecks: false,
        includeDetailedViolations: false
    )

    /// Strict validation options (stop on first failure).
    public static let strict = ValidationOptions(
        stopOnFirstFailure: true
    )
}

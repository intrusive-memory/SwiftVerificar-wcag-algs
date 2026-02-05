import Foundation

/// A comprehensive report of accessibility validation results.
///
/// The ValidationReport aggregates results from multiple accessibility
/// checkers, providing statistics, summaries, and detailed violation
/// information.
///
/// ## Example
///
/// ```swift
/// let report = runner.run(on: semanticTree)
///
/// print("Total: \(report.totalChecks)")
/// print("Passed: \(report.passedCount) (\(report.passRate)%)")
/// print("Failed: \(report.failedCount)")
///
/// for violation in report.allViolations {
///     print("- \(violation.description)")
/// }
/// ```
public struct ValidationReport: Sendable, Equatable {

    /// The results from all accessibility checks.
    public let results: [AccessibilityCheckResult]

    /// The number of nodes that were validated.
    public let nodeCount: Int

    /// The time taken to perform validation.
    public let duration: TimeInterval

    /// The validation options that were used.
    public let options: ValidationOptions

    /// Creates a new validation report.
    ///
    /// - Parameters:
    ///   - results: The check results.
    ///   - nodeCount: Number of nodes validated.
    ///   - duration: Time taken for validation.
    ///   - options: The validation options used.
    public init(
        results: [AccessibilityCheckResult],
        nodeCount: Int,
        duration: TimeInterval,
        options: ValidationOptions
    ) {
        self.results = results
        self.nodeCount = nodeCount
        self.duration = duration
        self.options = options
    }

    // MARK: - Statistics

    /// The total number of checks performed.
    public var totalChecks: Int {
        results.count
    }

    /// The number of checks that passed.
    public var passedCount: Int {
        results.filter { $0.passed }.count
    }

    /// The number of checks that failed.
    public var failedCount: Int {
        results.filter { !$0.passed }.count
    }

    /// Whether all checks passed.
    public var allPassed: Bool {
        results.allSatisfy { $0.passed }
    }

    /// The pass rate as a percentage (0-100).
    public var passRate: Double {
        guard totalChecks > 0 else { return 0 }
        return Double(passedCount) / Double(totalChecks) * 100
    }

    /// The total number of violations across all checks.
    public var totalViolations: Int {
        results.reduce(0) { $0 + $1.violations.count }
    }

    /// All violations from all failed checks.
    public var allViolations: [AccessibilityViolation] {
        results.flatMap { $0.violations }
    }

    // MARK: - Filtering

    /// Results that passed.
    public var passingResults: [AccessibilityCheckResult] {
        results.filter { $0.passed }
    }

    /// Results that failed.
    public var failingResults: [AccessibilityCheckResult] {
        results.filter { !$0.passed }
    }

    /// Results grouped by WCAG principle.
    public var resultsByPrinciple: [WCAGPrinciple: [AccessibilityCheckResult]] {
        Dictionary(grouping: results) { $0.criterion.principle }
    }

    /// Results grouped by WCAG level.
    public var resultsByLevel: [WCAGLevel: [AccessibilityCheckResult]] {
        Dictionary(grouping: results) { $0.criterion.level }
    }

    /// Violations grouped by severity.
    public var violationsBySeverity: [ViolationSeverity: [AccessibilityViolation]] {
        Dictionary(grouping: allViolations) { $0.severity }
    }

    /// Critical violations (highest severity).
    public var criticalViolations: [AccessibilityViolation] {
        violationsBySeverity[.critical] ?? []
    }

    /// Serious violations.
    public var seriousViolations: [AccessibilityViolation] {
        violationsBySeverity[.serious] ?? []
    }

    /// Moderate violations.
    public var moderateViolations: [AccessibilityViolation] {
        violationsBySeverity[.moderate] ?? []
    }

    /// Minor violations.
    public var minorViolations: [AccessibilityViolation] {
        violationsBySeverity[.minor] ?? []
    }

    // MARK: - Formatting

    /// A summary of the validation report as a string.
    public var summary: String {
        """
        Validation Report
        =================
        Total Checks: \(totalChecks)
        Passed: \(passedCount) (\(String(format: "%.1f", passRate))%)
        Failed: \(failedCount)
        Total Violations: \(totalViolations)
        Nodes Validated: \(nodeCount)
        Duration: \(String(format: "%.3f", duration))s
        """
    }

    /// A detailed report as a string, including all violations.
    public var detailedReport: String {
        var report = summary + "\n\n"

        // Add failing results
        if !failingResults.isEmpty {
            report += "Failed Checks\n"
            report += "=============\n\n"

            for result in failingResults {
                report += "[\(result.criterion.rawValue)] \(result.criterion.name)\n"
                report += "Level: \(result.criterion.level.rawValue.uppercased())\n"
                report += "Violations: \(result.violations.count)\n"

                if options.includeDetailedViolations {
                    for (index, violation) in result.violations.enumerated() {
                        let truncated = options.maxViolationsPerCheck.map { index >= $0 } ?? false
                        if truncated {
                            let remaining = result.violations.count - index
                            report += "  ... and \(remaining) more\n"
                            break
                        }

                        report += "\n  \(index + 1). \(violation.severity.rawValue.uppercased()): \(violation.description)\n"
                        report += "     Node Type: \(violation.nodeType.rawValue)\n"
                        if let location = violation.location {
                            report += "     Location: Page \(location.pageIndex), \(location.rect)\n"
                        }
                    }
                }
                report += "\n"
            }
        }

        // Add passing results if requested
        if options.includePassingChecks && !passingResults.isEmpty {
            report += "Passed Checks\n"
            report += "=============\n\n"

            for result in passingResults {
                report += "✓ [\(result.criterion.rawValue)] \(result.criterion.name)\n"
            }
        }

        return report
    }

    /// A JSON-formatted report.
    public var jsonReport: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(JSONReport(from: self)),
              let json = String(data: data, encoding: .utf8) else {
            return "{\"error\": \"Failed to encode report\"}"
        }

        return json
    }

    // MARK: - Export

    /// Exports the report to a file.
    ///
    /// - Parameters:
    ///   - url: The file URL to write to.
    ///   - format: The format to use (default: .text).
    /// - Throws: If writing fails.
    public func export(to url: URL, format: ReportFormat = .text) throws {
        let content: String
        switch format {
        case .text:
            content = detailedReport
        case .json:
            content = jsonReport
        case .summary:
            content = summary
        }

        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}

/// Supported report formats.
public enum ReportFormat: String, Sendable, CaseIterable {
    /// Plain text format with detailed information.
    case text

    /// JSON format for machine processing.
    case json

    /// Summary only (no violation details).
    case summary
}

// MARK: - JSON Representation

/// A JSON-encodable representation of a validation report.
private struct JSONReport: Codable {
    let totalChecks: Int
    let passedCount: Int
    let failedCount: Int
    let passRate: Double
    let totalViolations: Int
    let nodeCount: Int
    let duration: TimeInterval
    let results: [JSONCheckResult]

    init(from report: ValidationReport) {
        self.totalChecks = report.totalChecks
        self.passedCount = report.passedCount
        self.failedCount = report.failedCount
        self.passRate = report.passRate
        self.totalViolations = report.totalViolations
        self.nodeCount = report.nodeCount
        self.duration = report.duration
        self.results = report.results.map { JSONCheckResult(from: $0) }
    }
}

/// A JSON-encodable representation of a check result.
private struct JSONCheckResult: Codable {
    let criterion: String
    let criterionName: String
    let level: String
    let principle: String
    let passed: Bool
    let violationCount: Int
    let violations: [JSONViolation]
    let context: String?

    init(from result: AccessibilityCheckResult) {
        self.criterion = result.criterion.rawValue
        self.criterionName = result.criterion.name
        self.level = result.criterion.level.rawValue
        self.principle = result.criterion.principle.rawValue
        self.passed = result.passed
        self.violationCount = result.violations.count
        self.violations = result.violations.map { JSONViolation(from: $0) }
        self.context = result.context
    }
}

/// A JSON-encodable representation of a violation.
private struct JSONViolation: Codable {
    let id: UUID
    let nodeId: UUID
    let nodeType: String
    let description: String
    let severity: String
    let location: JSONLocation?

    init(from violation: AccessibilityViolation) {
        self.id = violation.id
        self.nodeId = violation.nodeId
        self.nodeType = violation.nodeType.rawValue
        self.description = violation.description
        self.severity = violation.severity.rawValue
        self.location = violation.location.map { JSONLocation(from: $0) }
    }
}

/// A JSON-encodable representation of a location.
private struct JSONLocation: Codable {
    let pageIndex: Int
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    init(from box: BoundingBox) {
        self.pageIndex = box.pageIndex
        self.x = box.rect.origin.x
        self.y = box.rect.origin.y
        self.width = box.rect.width
        self.height = box.rect.height
    }
}

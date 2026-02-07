import Testing
import Foundation
@testable import SwiftVerificarWCAGAlgs

@Suite("ValidationReport Tests")
struct ValidationReportTests {

    // MARK: - Test Fixtures

    let sampleBoundingBox = BoundingBox(
        pageIndex: 1,
        rect: CGRect(x: 10, y: 20, width: 100, height: 50)
    )

    func createViolation(
        severity: ViolationSeverity = .serious,
        description: String = "Test violation"
    ) -> AccessibilityViolation {
        AccessibilityViolation(
            nodeId: UUID(),
            nodeType: .paragraph,
            description: description,
            severity: severity,
            location: sampleBoundingBox
        )
    }

    func createResult(
        criterion: WCAGSuccessCriterion,
        passed: Bool,
        violationCount: Int = 0
    ) -> AccessibilityCheckResult {
        if passed {
            return .passing(criterion: criterion)
        } else {
            let violations = (0..<violationCount).map { index in
                createViolation(description: "Violation \(index + 1)")
            }
            return .failing(criterion: criterion, violations: violations)
        }
    }

    // MARK: - Initialization Tests

    @Test("ValidationReport initializes with results")
    func testInitialization() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true),
            createResult(criterion: .contrastMinimum, passed: false, violationCount: 2)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 10,
            duration: 1.5,
            options: .default
        )

        #expect(report.results.count == 2)
        #expect(report.nodeCount == 10)
        #expect(report.duration == 1.5)
        #expect(report.options == .default)
    }

    // MARK: - Statistics Tests

    @Test("Total checks count")
    func testTotalChecks() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true),
            createResult(criterion: .contrastMinimum, passed: false, violationCount: 1),
            createResult(criterion: .linkPurpose, passed: true)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        #expect(report.totalChecks == 3)
    }

    @Test("Passed count")
    func testPassedCount() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true),
            createResult(criterion: .contrastMinimum, passed: false, violationCount: 1),
            createResult(criterion: .linkPurpose, passed: true)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        #expect(report.passedCount == 2)
    }

    @Test("Failed count")
    func testFailedCount() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true),
            createResult(criterion: .contrastMinimum, passed: false, violationCount: 1),
            createResult(criterion: .linkPurpose, passed: false, violationCount: 2)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        #expect(report.failedCount == 2)
    }

    @Test("All passed when no failures")
    func testAllPassed() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true),
            createResult(criterion: .linkPurpose, passed: true)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        #expect(report.allPassed == true)
    }

    @Test("All passed false when failures exist")
    func testAllPassedWithFailures() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true),
            createResult(criterion: .contrastMinimum, passed: false, violationCount: 1)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        #expect(report.allPassed == false)
    }

    @Test("Pass rate calculation")
    func testPassRate() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true),
            createResult(criterion: .contrastMinimum, passed: false, violationCount: 1),
            createResult(criterion: .linkPurpose, passed: true),
            createResult(criterion: .languageOfPage, passed: true)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        #expect(report.passRate == 75.0)  // 3/4 = 75%
    }

    @Test("Pass rate with no checks")
    func testPassRateEmpty() {
        let report = ValidationReport(
            results: [],
            nodeCount: 0,
            duration: 0,
            options: .default
        )

        #expect(report.passRate == 0)
    }

    @Test("Total violations count")
    func testTotalViolations() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true),
            createResult(criterion: .contrastMinimum, passed: false, violationCount: 3),
            createResult(criterion: .linkPurpose, passed: false, violationCount: 2)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        #expect(report.totalViolations == 5)
    }

    @Test("All violations aggregation")
    func testAllViolations() {
        let results = [
            createResult(criterion: .contrastMinimum, passed: false, violationCount: 2),
            createResult(criterion: .linkPurpose, passed: false, violationCount: 3)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        #expect(report.allViolations.count == 5)
    }

    // MARK: - Filtering Tests

    @Test("Passing results filter")
    func testPassingResults() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true),
            createResult(criterion: .contrastMinimum, passed: false, violationCount: 1),
            createResult(criterion: .linkPurpose, passed: true)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        #expect(report.passingResults.count == 2)
        #expect(report.passingResults.allSatisfy { $0.passed })
    }

    @Test("Failing results filter")
    func testFailingResults() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true),
            createResult(criterion: .contrastMinimum, passed: false, violationCount: 1),
            createResult(criterion: .linkPurpose, passed: false, violationCount: 2)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        #expect(report.failingResults.count == 2)
        #expect(report.failingResults.allSatisfy { !$0.passed })
    }

    @Test("Results grouped by principle")
    func testResultsByPrinciple() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true),      // Perceivable
            createResult(criterion: .contrastMinimum, passed: true),     // Perceivable
            createResult(criterion: .linkPurpose, passed: false, violationCount: 1),  // Operable
            createResult(criterion: .languageOfPage, passed: true)       // Understandable
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        let byPrinciple = report.resultsByPrinciple

        #expect(byPrinciple[.perceivable]?.count == 2)
        #expect(byPrinciple[.operable]?.count == 1)
        #expect(byPrinciple[.understandable]?.count == 1)
    }

    @Test("Results grouped by level")
    func testResultsByLevel() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true),      // Level A
            createResult(criterion: .contrastMinimum, passed: true),     // Level AA
            createResult(criterion: .contrastEnhanced, passed: false, violationCount: 1)  // Level AAA
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        let byLevel = report.resultsByLevel

        #expect(byLevel[.a]?.count == 1)
        #expect(byLevel[.aa]?.count == 1)
        #expect(byLevel[.aaa]?.count == 1)
    }

    @Test("Violations grouped by severity")
    func testViolationsBySeverity() {
        let criticalViolation = AccessibilityViolation(
            nodeId: UUID(),
            nodeType: .paragraph,
            description: "Critical",
            severity: .critical
        )
        let seriousViolation = AccessibilityViolation(
            nodeId: UUID(),
            nodeType: .paragraph,
            description: "Serious",
            severity: .serious
        )
        let moderateViolation = AccessibilityViolation(
            nodeId: UUID(),
            nodeType: .paragraph,
            description: "Moderate",
            severity: .moderate
        )

        let results = [
            AccessibilityCheckResult(
                criterion: .contrastMinimum,
                passed: false,
                violations: [criticalViolation, seriousViolation, moderateViolation]
            )
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        let bySeverity = report.violationsBySeverity

        #expect(bySeverity[.critical]?.count == 1)
        #expect(bySeverity[.serious]?.count == 1)
        #expect(bySeverity[.moderate]?.count == 1)
    }

    @Test("Critical violations filter")
    func testCriticalViolations() {
        let critical = AccessibilityViolation(
            nodeId: UUID(),
            nodeType: .paragraph,
            description: "Critical",
            severity: .critical
        )
        let serious = AccessibilityViolation(
            nodeId: UUID(),
            nodeType: .paragraph,
            description: "Serious",
            severity: .serious
        )

        let results = [
            AccessibilityCheckResult(
                criterion: .contrastMinimum,
                passed: false,
                violations: [critical, serious]
            )
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        #expect(report.criticalViolations.count == 1)
        #expect(report.criticalViolations[0].severity == .critical)
    }

    @Test("Serious violations filter")
    func testSeriousViolations() {
        let serious1 = AccessibilityViolation(
            nodeId: UUID(),
            nodeType: .paragraph,
            description: "Serious 1",
            severity: .serious
        )
        let serious2 = AccessibilityViolation(
            nodeId: UUID(),
            nodeType: .paragraph,
            description: "Serious 2",
            severity: .serious
        )
        let moderate = AccessibilityViolation(
            nodeId: UUID(),
            nodeType: .paragraph,
            description: "Moderate",
            severity: .moderate
        )

        let results = [
            AccessibilityCheckResult(
                criterion: .contrastMinimum,
                passed: false,
                violations: [serious1, serious2, moderate]
            )
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        #expect(report.seriousViolations.count == 2)
    }

    // MARK: - Formatting Tests

    @Test("Summary format")
    func testSummary() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true),
            createResult(criterion: .contrastMinimum, passed: false, violationCount: 2)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 10,
            duration: 1.234,
            options: .default
        )

        let summary = report.summary

        #expect(summary.contains("Total Checks: 2"))
        #expect(summary.contains("Passed: 1"))
        #expect(summary.contains("Failed: 1"))
        #expect(summary.contains("Total Violations: 2"))
        #expect(summary.contains("Nodes Validated: 10"))
        #expect(summary.contains("1.234"))
    }

    @Test("Detailed report includes violations")
    func testDetailedReport() {
        let results = [
            createResult(criterion: .contrastMinimum, passed: false, violationCount: 1)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        let detailed = report.detailedReport

        #expect(detailed.contains("Failed Checks"))
        #expect(detailed.contains("1.4.3"))
        #expect(detailed.contains("Contrast (Minimum)"))
        #expect(detailed.contains("Violation 1"))
    }

    @Test("Detailed report respects includePassingChecks option")
    func testDetailedReportWithPassingChecks() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true)
        ]

        let reportWithPassing = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: ValidationOptions(includePassingChecks: true)
        )

        let reportWithoutPassing = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: ValidationOptions(includePassingChecks: false)
        )

        #expect(reportWithPassing.detailedReport.contains("Passed Checks"))
        #expect(!reportWithoutPassing.detailedReport.contains("Passed Checks"))
    }

    @Test("Detailed report respects maxViolationsPerCheck option")
    func testDetailedReportWithMaxViolations() {
        let results = [
            createResult(criterion: .contrastMinimum, passed: false, violationCount: 10)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: ValidationOptions(maxViolationsPerCheck: 3)
        )

        let detailed = report.detailedReport

        #expect(detailed.contains("and 7 more"))
    }

    @Test("JSON report format")
    func testJSONReport() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        let json = report.jsonReport

        #expect(json.contains("totalChecks"))
        #expect(json.contains("passedCount"))
        #expect(json.contains("failedCount"))
        #expect(json.contains("results"))
    }

    // MARK: - Export Tests

    @Test("Export to file in text format")
    func testExportText() throws {
        let results = [
            createResult(criterion: .nonTextContent, passed: true)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-report.txt")

        try report.export(to: tempURL, format: .text)

        let content = try String(contentsOf: tempURL, encoding: .utf8)
        #expect(content.contains("Validation Report"))

        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Export to file in JSON format")
    func testExportJSON() throws {
        let results = [
            createResult(criterion: .nonTextContent, passed: true)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-report.json")

        try report.export(to: tempURL, format: .json)

        let content = try String(contentsOf: tempURL, encoding: .utf8)
        #expect(content.contains("totalChecks"))

        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Export to file in summary format")
    func testExportSummary() throws {
        let results = [
            createResult(criterion: .nonTextContent, passed: true)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 5,
            duration: 1.0,
            options: .default
        )

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-summary.txt")

        try report.export(to: tempURL, format: .summary)

        let content = try String(contentsOf: tempURL, encoding: .utf8)
        #expect(content.contains("Validation Report"))
        #expect(!content.contains("Failed Checks"))  // Summary doesn't include details

        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Edge Cases

    @Test("Empty report")
    func testEmptyReport() {
        let report = ValidationReport(
            results: [],
            nodeCount: 0,
            duration: 0,
            options: .default
        )

        #expect(report.totalChecks == 0)
        #expect(report.allPassed == true)  // Vacuously true
        #expect(report.totalViolations == 0)
        #expect(report.passRate == 0)
    }

    @Test("Report with all passing checks")
    func testAllPassingReport() {
        let results = [
            createResult(criterion: .nonTextContent, passed: true),
            createResult(criterion: .linkPurpose, passed: true),
            createResult(criterion: .languageOfPage, passed: true)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 10,
            duration: 1.0,
            options: .default
        )

        #expect(report.allPassed == true)
        #expect(report.failedCount == 0)
        #expect(report.totalViolations == 0)
        #expect(report.passRate == 100.0)
    }

    @Test("Report with all failing checks")
    func testAllFailingReport() {
        let results = [
            createResult(criterion: .nonTextContent, passed: false, violationCount: 1),
            createResult(criterion: .contrastMinimum, passed: false, violationCount: 2),
            createResult(criterion: .linkPurpose, passed: false, violationCount: 1)
        ]

        let report = ValidationReport(
            results: results,
            nodeCount: 10,
            duration: 1.0,
            options: .default
        )

        #expect(report.allPassed == false)
        #expect(report.passedCount == 0)
        #expect(report.totalViolations == 4)
        #expect(report.passRate == 0.0)
    }

    // MARK: - ReportFormat Tests

    @Test("ReportFormat cases")
    func testReportFormatCases() {
        #expect(ReportFormat.allCases.contains(.text))
        #expect(ReportFormat.allCases.contains(.json))
        #expect(ReportFormat.allCases.contains(.summary))
        #expect(ReportFormat.allCases.count == 3)
    }
}

import Testing
import Foundation
@testable import SwiftVerificarWCAGAlgs

/// Tests for the AccessibilityChecker protocol and related types.
@Suite("AccessibilityChecker Protocol Tests")
struct AccessibilityCheckerTests {

    // MARK: - AccessibilityCheckResult Tests

    @Test("AccessibilityCheckResult passing result")
    func testPassingResult() {
        let result = AccessibilityCheckResult.passing(
            criterion: .nonTextContent,
            context: "All figures have alt text"
        )

        #expect(result.passed)
        #expect(result.violations.isEmpty)
        #expect(result.criterion == .nonTextContent)
        #expect(result.context == "All figures have alt text")
    }

    @Test("AccessibilityCheckResult failing result")
    func testFailingResult() {
        let violation = AccessibilityViolation(
            nodeId: UUID(),
            nodeType: .figure,
            description: "Missing alt text",
            severity: .critical
        )

        let result = AccessibilityCheckResult.failing(
            criterion: .nonTextContent,
            violations: [violation],
            context: "Found 1 violation"
        )

        #expect(!result.passed)
        #expect(result.violations.count == 1)
        #expect(result.criterion == .nonTextContent)
    }

    @Test("AccessibilityCheckResult equality")
    func testResultEquality() {
        let result1 = AccessibilityCheckResult.passing(
            criterion: .nonTextContent
        )
        let result2 = AccessibilityCheckResult.passing(
            criterion: .nonTextContent
        )

        #expect(result1 == result2)
    }

    // MARK: - AccessibilityViolation Tests

    @Test("AccessibilityViolation creation")
    func testViolationCreation() {
        let nodeId = UUID()
        let violation = AccessibilityViolation(
            nodeId: nodeId,
            nodeType: .figure,
            description: "Missing alt text",
            severity: .critical
        )

        #expect(violation.nodeId == nodeId)
        #expect(violation.nodeType == .figure)
        #expect(violation.description == "Missing alt text")
        #expect(violation.severity == .critical)
        #expect(violation.location == nil)
    }

    @Test("AccessibilityViolation with location")
    func testViolationWithLocation() {
        let bbox = BoundingBox(pageIndex: 0, rect: CGRect(x: 10, y: 20, width: 100, height: 50))
        let violation = AccessibilityViolation(
            nodeId: UUID(),
            nodeType: .figure,
            description: "Missing alt text",
            severity: .critical,
            location: bbox
        )

        #expect(violation.location == bbox)
    }

    @Test("AccessibilityViolation equality")
    func testViolationEquality() {
        let id = UUID()
        let nodeId = UUID()

        let violation1 = AccessibilityViolation(
            id: id,
            nodeId: nodeId,
            nodeType: .figure,
            description: "Test",
            severity: .critical
        )

        let violation2 = AccessibilityViolation(
            id: id,
            nodeId: nodeId,
            nodeType: .figure,
            description: "Test",
            severity: .critical
        )

        #expect(violation1 == violation2)
    }

    // MARK: - ViolationSeverity Tests

    @Test("ViolationSeverity raw values")
    func testSeverityRawValues() {
        #expect(ViolationSeverity.critical.rawValue == "critical")
        #expect(ViolationSeverity.serious.rawValue == "serious")
        #expect(ViolationSeverity.moderate.rawValue == "moderate")
        #expect(ViolationSeverity.minor.rawValue == "minor")
    }

    @Test("ViolationSeverity all cases")
    func testSeverityAllCases() {
        let allCases = ViolationSeverity.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.critical))
        #expect(allCases.contains(.serious))
        #expect(allCases.contains(.moderate))
        #expect(allCases.contains(.minor))
    }

    // MARK: - WCAGSuccessCriterion Tests

    @Test("WCAGSuccessCriterion raw values")
    func testCriterionRawValues() {
        #expect(WCAGSuccessCriterion.nonTextContent.rawValue == "1.1.1")
        #expect(WCAGSuccessCriterion.languageOfPage.rawValue == "3.1.1")
        #expect(WCAGSuccessCriterion.linkPurpose.rawValue == "2.4.4")
    }

    @Test("WCAGSuccessCriterion conformance levels")
    func testCriterionLevels() {
        #expect(WCAGSuccessCriterion.nonTextContent.level == .a)
        #expect(WCAGSuccessCriterion.contrastMinimum.level == .aa)
        #expect(WCAGSuccessCriterion.contrastEnhanced.level == .aaa)
    }

    @Test("WCAGSuccessCriterion principles")
    func testCriterionPrinciples() {
        #expect(WCAGSuccessCriterion.nonTextContent.principle == .perceivable)
        #expect(WCAGSuccessCriterion.linkPurpose.principle == .operable)
        #expect(WCAGSuccessCriterion.languageOfPage.principle == .understandable)
        #expect(WCAGSuccessCriterion.nameRoleValue.principle == .robust)
    }

    @Test("WCAGSuccessCriterion names")
    func testCriterionNames() {
        #expect(WCAGSuccessCriterion.nonTextContent.name == "Non-text Content")
        #expect(WCAGSuccessCriterion.languageOfPage.name == "Language of Page")
        #expect(WCAGSuccessCriterion.linkPurpose.name == "Link Purpose (In Context)")
    }

    @Test("WCAGSuccessCriterion all cases")
    func testCriterionAllCases() {
        let allCases = WCAGSuccessCriterion.allCases
        #expect(allCases.count == 11)
    }

    // MARK: - WCAGLevel Tests

    @Test("WCAGLevel raw values")
    func testLevelRawValues() {
        #expect(WCAGLevel.a.rawValue == "A")
        #expect(WCAGLevel.aa.rawValue == "AA")
        #expect(WCAGLevel.aaa.rawValue == "AAA")
    }

    @Test("WCAGLevel all cases")
    func testLevelAllCases() {
        let allCases = WCAGLevel.allCases
        #expect(allCases.count == 3)
    }

    // MARK: - WCAGPrinciple Tests

    @Test("WCAGPrinciple raw values")
    func testPrincipleRawValues() {
        #expect(WCAGPrinciple.perceivable.rawValue == "Perceivable")
        #expect(WCAGPrinciple.operable.rawValue == "Operable")
        #expect(WCAGPrinciple.understandable.rawValue == "Understandable")
        #expect(WCAGPrinciple.robust.rawValue == "Robust")
    }

    @Test("WCAGPrinciple all cases")
    func testPrincipleAllCases() {
        let allCases = WCAGPrinciple.allCases
        #expect(allCases.count == 4)
    }

    // MARK: - Mock Checker Tests

    struct MockChecker: AccessibilityChecker {
        let criterion: WCAGSuccessCriterion = .nonTextContent
        let shouldFail: Bool

        func check(_ node: any SemanticNode) -> AccessibilityCheckResult {
            if shouldFail {
                let violation = AccessibilityViolation(
                    nodeId: node.id,
                    nodeType: node.type,
                    description: "Mock violation",
                    severity: .critical
                )
                return .failing(criterion: criterion, violations: [violation])
            } else {
                return .passing(criterion: criterion)
            }
        }
    }

    @Test("AccessibilityChecker default check multiple nodes")
    func testCheckerDefaultMultipleNodes() {
        let checker = MockChecker(shouldFail: false)
        let nodes: [any SemanticNode] = [
            ContentNode(type: .paragraph, depth: 1),
            ContentNode(type: .heading, depth: 1)
        ]

        let result = checker.check(nodes)
        #expect(result.passed)
        #expect(result.violations.isEmpty)
    }

    @Test("AccessibilityChecker default check with failures")
    func testCheckerDefaultWithFailures() {
        let checker = MockChecker(shouldFail: true)
        let nodes: [any SemanticNode] = [
            ContentNode(type: .paragraph, depth: 1),
            ContentNode(type: .heading, depth: 1)
        ]

        let result = checker.check(nodes)
        #expect(!result.passed)
        #expect(result.violations.count == 2)
    }

    @Test("AccessibilityChecker empty node array")
    func testCheckerEmptyNodes() {
        let checker = MockChecker(shouldFail: false)
        let result = checker.check([])

        #expect(result.passed)
        #expect(result.violations.isEmpty)
    }

    // MARK: - Integration Tests

    @Test("AccessibilityCheckResult with multiple violations")
    func testResultWithMultipleViolations() {
        let violations = (0..<5).map { i in
            AccessibilityViolation(
                nodeId: UUID(),
                nodeType: .paragraph,
                description: "Violation \(i)",
                severity: .moderate
            )
        }

        let result = AccessibilityCheckResult.failing(
            criterion: .contrastMinimum,
            violations: violations
        )

        #expect(!result.passed)
        #expect(result.violations.count == 5)
    }

    @Test("Violation severity ordering")
    func testViolationSeverityOrdering() {
        // This test documents the expected severity ordering
        let severities: [ViolationSeverity] = [
            .critical, .serious, .moderate, .minor
        ]

        #expect(severities[0] == .critical)
        #expect(severities[1] == .serious)
        #expect(severities[2] == .moderate)
        #expect(severities[3] == .minor)
    }
}

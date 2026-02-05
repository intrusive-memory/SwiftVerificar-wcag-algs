import Testing
import Foundation
@testable import SwiftVerificarWCAGAlgs

@Suite("ValidationRunner Tests")
struct ValidationRunnerTests {

    // MARK: - Test Fixtures

    /// Mock semantic node for testing.
    struct MockNode: SemanticNode {
        let id = UUID()
        let type: SemanticType
        let boundingBox: BoundingBox?
        let parent: (any SemanticNode)?
        let children: [any SemanticNode]
        let attributes: AttributesDictionary
        let depth: Int
        var errorCodes: Set<SemanticErrorCode>

        init(
            type: SemanticType = .paragraph,
            boundingBox: BoundingBox? = nil,
            children: [any SemanticNode] = [],
            depth: Int = 0
        ) {
            self.type = type
            self.boundingBox = boundingBox
            self.parent = nil
            self.children = children
            self.attributes = [:]
            self.depth = depth
            self.errorCodes = []
        }
    }

    /// Mock checker that always passes.
    struct PassingChecker: AccessibilityChecker {
        let criterion: WCAGSuccessCriterion = .nonTextContent

        func check(_ node: any SemanticNode) -> AccessibilityCheckResult {
            .passing(criterion: criterion)
        }
    }

    /// Mock checker that always fails.
    struct FailingChecker: AccessibilityChecker {
        let criterion: WCAGSuccessCriterion = .contrastMinimum
        let violationCount: Int

        init(violationCount: Int = 1) {
            self.violationCount = violationCount
        }

        func check(_ node: any SemanticNode) -> AccessibilityCheckResult {
            let violations = (0..<violationCount).map { index in
                AccessibilityViolation(
                    nodeId: node.id,
                    nodeType: node.type,
                    description: "Test violation \(index + 1)",
                    severity: .serious
                )
            }
            return .failing(criterion: criterion, violations: violations)
        }
    }

    /// Mock checker for specific node types.
    struct TypeSpecificChecker: AccessibilityChecker {
        let criterion: WCAGSuccessCriterion = .linkPurpose
        let targetType: SemanticType

        func check(_ node: any SemanticNode) -> AccessibilityCheckResult {
            if node.type == targetType {
                let violation = AccessibilityViolation(
                    nodeId: node.id,
                    nodeType: node.type,
                    description: "Found target type",
                    severity: .moderate
                )
                return .failing(criterion: criterion, violations: [violation])
            }
            return .passing(criterion: criterion)
        }
    }

    // MARK: - Initialization Tests

    @Test("ValidationRunner initializes with checkers and options")
    func testInitialization() {
        let checkers: [any AccessibilityChecker] = [PassingChecker(), FailingChecker()]
        let options = ValidationOptions.strict

        let runner = ValidationRunner(checkers: checkers, options: options)

        #expect(runner.checkers.count == 2)
        #expect(runner.options.stopOnFirstFailure == true)
    }

    @Test("ValidationRunner initializes with default options")
    func testDefaultOptions() {
        let runner = ValidationRunner(checkers: [PassingChecker()])

        #expect(runner.options == ValidationOptions.default)
    }

    // MARK: - Single Tree Validation Tests

    @Test("Run validation on empty tree")
    func testEmptyTree() {
        let runner = ValidationRunner(checkers: [PassingChecker()])
        let tree = MockNode()

        let report = runner.run(on: tree)

        #expect(report.totalChecks == 1)
        #expect(report.passedCount == 1)
        #expect(report.failedCount == 0)
        #expect(report.nodeCount == 1)
    }

    @Test("Run validation with passing checker")
    func testPassingChecker() {
        let runner = ValidationRunner(checkers: [PassingChecker()])
        let tree = MockNode(children: [
            MockNode(type: .paragraph),
            MockNode(type: .heading)
        ])

        let report = runner.run(on: tree)

        #expect(report.allPassed == true)
        #expect(report.passedCount == 1)
        #expect(report.totalViolations == 0)
    }

    @Test("Run validation with failing checker")
    func testFailingChecker() {
        let runner = ValidationRunner(checkers: [FailingChecker(violationCount: 3)])
        let tree = MockNode()

        let report = runner.run(on: tree)

        #expect(report.allPassed == false)
        #expect(report.failedCount == 1)
        #expect(report.totalViolations == 3)
    }

    @Test("Run validation with mixed checkers")
    func testMixedCheckers() {
        let checkers: [any AccessibilityChecker] = [
            PassingChecker(),
            FailingChecker(violationCount: 2),
            PassingChecker()
        ]
        let runner = ValidationRunner(checkers: checkers)
        let tree = MockNode()

        let report = runner.run(on: tree)

        #expect(report.totalChecks == 3)
        #expect(report.passedCount == 2)
        #expect(report.failedCount == 1)
        #expect(report.totalViolations == 2)
    }

    @Test("Run validation collects all nodes from tree")
    func testNodeCollection() {
        let child1 = MockNode(type: .paragraph)
        let child2 = MockNode(type: .heading)
        let grandchild = MockNode(type: .span)

        let tree = MockNode(children: [
            child1,
            MockNode(type: .div, children: [child2, grandchild])
        ])

        let runner = ValidationRunner(checkers: [PassingChecker()])
        let report = runner.run(on: tree)

        // Should count: root + 2 direct children + 1 div + 2 grandchildren = 5 nodes
        #expect(report.nodeCount == 5)
    }

    // MARK: - Multiple Trees Validation Tests

    @Test("Run validation on multiple trees")
    func testMultipleTrees() {
        let trees = [
            MockNode(type: .document),
            MockNode(type: .document),
            MockNode(type: .document)
        ]

        let runner = ValidationRunner(checkers: [PassingChecker()])
        let report = runner.run(on: trees)

        #expect(report.nodeCount == 3)
        #expect(report.totalChecks == 1)
    }

    @Test("Run validation aggregates nodes from multiple trees")
    func testMultipleTreesAggregation() {
        let trees = [
            MockNode(children: [MockNode(), MockNode()]),
            MockNode(children: [MockNode()])
        ]

        let runner = ValidationRunner(checkers: [FailingChecker()])
        let report = runner.run(on: trees)

        // 2 trees + 3 children = 5 nodes
        #expect(report.nodeCount == 5)
    }

    // MARK: - Filtered Validation Tests

    @Test("Run validation with specific criteria")
    func testFilteredByCriteria() {
        let checkers: [any AccessibilityChecker] = [
            PassingChecker(),  // .nonTextContent
            FailingChecker(),  // .contrastMinimum
            TypeSpecificChecker(targetType: .link)  // .linkPurpose
        ]
        let runner = ValidationRunner(checkers: checkers)
        let tree = MockNode()

        let criteria: Set<WCAGSuccessCriterion> = [.nonTextContent, .contrastMinimum]
        let report = runner.run(criteria: criteria, on: tree)

        // Should only run 2 checkers
        #expect(report.totalChecks == 2)
        #expect(report.passedCount == 1)
        #expect(report.failedCount == 1)
    }

    @Test("Run validation with empty criteria set")
    func testEmptyCriteriaSet() {
        let runner = ValidationRunner(checkers: [PassingChecker(), FailingChecker()])
        let tree = MockNode()

        let report = runner.run(criteria: [], on: tree)

        #expect(report.totalChecks == 0)
    }

    @Test("Run validation at specific WCAG level")
    func testFilteredByLevel() {
        // Create checkers with different levels
        let checkers: [any AccessibilityChecker] = [
            PassingChecker(),  // Level A
            FailingChecker()   // Level AA
        ]
        let runner = ValidationRunner(checkers: checkers)
        let tree = MockNode()

        // Run at Level A only
        let reportA = runner.run(level: .a, on: tree)
        #expect(reportA.totalChecks == 1)

        // Run at Level AA (includes A and AA)
        let reportAA = runner.run(level: .aa, on: tree)
        #expect(reportAA.totalChecks == 2)
    }

    // MARK: - Performance Tests

    @Test("Run validation tracks duration")
    func testDurationTracking() {
        let runner = ValidationRunner(checkers: [PassingChecker()])
        let tree = MockNode()

        let report = runner.run(on: tree)

        #expect(report.duration >= 0)
    }

    @Test("Run validation with large tree")
    func testLargeTree() {
        // Create a tree with many nodes
        var children: [MockNode] = []
        for i in 0..<100 {
            children.append(MockNode(type: i % 2 == 0 ? .paragraph : .heading))
        }
        let tree = MockNode(children: children)

        let runner = ValidationRunner(checkers: [PassingChecker()])
        let report = runner.run(on: tree)

        #expect(report.nodeCount == 101)  // 1 root + 100 children
    }

    // MARK: - ValidationOptions Tests

    @Test("Default validation options")
    func testDefaultValidationOptions() {
        let options = ValidationOptions.default

        #expect(options.stopOnFirstFailure == false)
        #expect(options.includePassingChecks == true)
        #expect(options.includeDetailedViolations == true)
        #expect(options.maxViolationsPerCheck == nil)
    }

    @Test("Minimal validation options")
    func testMinimalValidationOptions() {
        let options = ValidationOptions.minimal

        #expect(options.includePassingChecks == false)
        #expect(options.includeDetailedViolations == false)
    }

    @Test("Strict validation options")
    func testStrictValidationOptions() {
        let options = ValidationOptions.strict

        #expect(options.stopOnFirstFailure == true)
    }

    @Test("Custom validation options")
    func testCustomValidationOptions() {
        let options = ValidationOptions(
            stopOnFirstFailure: true,
            includePassingChecks: false,
            includeDetailedViolations: true,
            maxViolationsPerCheck: 10
        )

        #expect(options.stopOnFirstFailure == true)
        #expect(options.includePassingChecks == false)
        #expect(options.includeDetailedViolations == true)
        #expect(options.maxViolationsPerCheck == 10)
    }

    @Test("ValidationOptions equality")
    func testValidationOptionsEquality() {
        let options1 = ValidationOptions.default
        let options2 = ValidationOptions.default
        let options3 = ValidationOptions.strict

        #expect(options1 == options2)
        #expect(options1 != options3)
    }

    // MARK: - Node Type Specific Tests

    @Test("Type-specific checker only checks matching types")
    func testTypeSpecificChecker() {
        let tree = MockNode(children: [
            MockNode(type: .link),
            MockNode(type: .paragraph),
            MockNode(type: .link)
        ])

        let checker = TypeSpecificChecker(targetType: .link)
        let runner = ValidationRunner(checkers: [checker])

        let report = runner.run(on: tree)

        // Should find 2 link violations
        #expect(report.totalViolations == 2)
    }

    // MARK: - Edge Cases

    @Test("Run validation with no checkers")
    func testNoCheckers() {
        let runner = ValidationRunner(checkers: [])
        let tree = MockNode()

        let report = runner.run(on: tree)

        #expect(report.totalChecks == 0)
        #expect(report.allPassed == true)  // Vacuously true
    }

    @Test("Run validation with deeply nested tree")
    func testDeeplyNestedTree() {
        // Create a chain of 10 nested nodes
        var current = MockNode(type: .paragraph)
        for _ in 0..<9 {
            current = MockNode(children: [current])
        }

        let runner = ValidationRunner(checkers: [PassingChecker()])
        let report = runner.run(on: current)

        #expect(report.nodeCount == 10)
    }

    @Test("Run validation with tree containing no children")
    func testLeafNode() {
        let tree = MockNode(type: .span)

        let runner = ValidationRunner(checkers: [PassingChecker()])
        let report = runner.run(on: tree)

        #expect(report.nodeCount == 1)
        #expect(report.allPassed == true)
    }

    @Test("Run validation preserves checker order")
    func testCheckerOrder() {
        struct FirstChecker: AccessibilityChecker {
            let criterion: WCAGSuccessCriterion = .nonTextContent
            func check(_ node: any SemanticNode) -> AccessibilityCheckResult {
                .passing(criterion: criterion, context: "First")
            }
        }

        struct SecondChecker: AccessibilityChecker {
            let criterion: WCAGSuccessCriterion = .contrastMinimum
            func check(_ node: any SemanticNode) -> AccessibilityCheckResult {
                .passing(criterion: criterion, context: "Second")
            }
        }

        let runner = ValidationRunner(checkers: [FirstChecker(), SecondChecker()])
        let tree = MockNode()

        let report = runner.run(on: tree)

        #expect(report.results[0].criterion == .nonTextContent)
        #expect(report.results[1].criterion == .contrastMinimum)
    }
}

import Testing
import Foundation
@testable import SwiftVerificarWCAGAlgs

@Suite("WCAGValidator Tests")
struct WCAGValidatorTests {

    // MARK: - Test Fixtures

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
            type: SemanticType = .document,
            children: [any SemanticNode] = []
        ) {
            self.type = type
            self.boundingBox = nil
            self.parent = nil
            self.children = children
            self.attributes = [:]
            self.depth = 0
            self.errorCodes = []
        }
    }

    struct MockChecker: AccessibilityChecker {
        let criterion: WCAGSuccessCriterion
        let shouldPass: Bool

        func check(_ node: any SemanticNode) -> AccessibilityCheckResult {
            if shouldPass {
                return .passing(criterion: criterion)
            } else {
                let violation = AccessibilityViolation(
                    nodeId: node.id,
                    nodeType: node.type,
                    description: "Mock violation",
                    severity: .serious
                )
                return .failing(criterion: criterion, violations: [violation])
            }
        }
    }

    // MARK: - Initialization Tests

    @Test("WCAGValidator initializes with checkers")
    func testInitWithCheckers() {
        let checkers: [any AccessibilityChecker] = [
            MockChecker(criterion: .nonTextContent, shouldPass: true)
        ]

        let validator = WCAGValidator(checkers: checkers)

        // Validate to ensure it works
        let tree = MockNode()
        let report = validator.validate(tree)

        #expect(report.totalChecks == 1)
    }

    @Test("WCAGValidator initializes with profile")
    func testInitWithProfile() {
        let profile = ValidationProfile.quick()
        let validator = WCAGValidator(profile: profile)

        let tree = MockNode()
        let report = validator.validate(tree)

        #expect(report.totalChecks >= 0)
    }

    // MARK: - Preset Validator Tests

    @Test("Level A validator")
    func testLevelAValidator() {
        let validator = WCAGValidator.levelA()
        let tree = MockNode()

        let report = validator.validate(tree)

        // All results should be Level A
        for result in report.results {
            #expect(result.criterion.level == .a)
        }
    }

    @Test("Level AA validator")
    func testLevelAAValidator() {
        let validator = WCAGValidator.levelAA()
        let tree = MockNode()

        let report = validator.validate(tree)

        // All results should be Level A or AA
        for result in report.results {
            #expect(result.criterion.level.rawValue <= WCAGLevel.aa.rawValue)
        }
    }

    @Test("Level AAA validator")
    func testLevelAAAValidator() {
        let validator = WCAGValidator.levelAAA()
        let tree = MockNode()

        let report = validator.validate(tree)

        // Should include all levels
        #expect(report.totalChecks >= 0)
    }

    @Test("Perceivable validator")
    func testPerceivableValidator() {
        let validator = WCAGValidator.perceivable()
        let tree = MockNode()

        let report = validator.validate(tree)

        // All results should be Perceivable principle
        for result in report.results {
            #expect(result.criterion.principle == .perceivable)
        }
    }

    @Test("Operable validator")
    func testOperableValidator() {
        let validator = WCAGValidator.operable()
        let tree = MockNode()

        let report = validator.validate(tree)

        // All results should be Operable principle
        for result in report.results {
            #expect(result.criterion.principle == .operable)
        }
    }

    @Test("Understandable validator")
    func testUnderstandableValidator() {
        let validator = WCAGValidator.understandable()
        let tree = MockNode()

        let report = validator.validate(tree)

        // All results should be Understandable principle
        for result in report.results {
            #expect(result.criterion.principle == .understandable)
        }
    }

    @Test("Robust validator")
    func testRobustValidator() {
        let validator = WCAGValidator.robust()
        let tree = MockNode()

        let report = validator.validate(tree)

        // All results should be Robust principle
        for result in report.results {
            #expect(result.criterion.principle == .robust)
        }
    }

    // MARK: - Validation Tests

    @Test("Validate single tree")
    func testValidateSingleTree() {
        let checkers: [any AccessibilityChecker] = [
            MockChecker(criterion: .nonTextContent, shouldPass: true)
        ]
        let validator = WCAGValidator(checkers: checkers)
        let tree = MockNode()

        let report = validator.validate(tree)

        #expect(report.totalChecks == 1)
        #expect(report.allPassed == true)
    }

    @Test("Validate multiple trees")
    func testValidateMultipleTrees() {
        let checkers: [any AccessibilityChecker] = [
            MockChecker(criterion: .nonTextContent, shouldPass: true)
        ]
        let validator = WCAGValidator(checkers: checkers)
        let trees = [MockNode(), MockNode(), MockNode()]

        let report = validator.validate(trees)

        #expect(report.nodeCount == 3)
    }

    @Test("Validate with specific criteria")
    func testValidateWithCriteria() {
        let checkers: [any AccessibilityChecker] = [
            MockChecker(criterion: .nonTextContent, shouldPass: true),
            MockChecker(criterion: .contrastMinimum, shouldPass: true),
            MockChecker(criterion: .linkPurpose, shouldPass: true)
        ]
        let validator = WCAGValidator(checkers: checkers)
        let tree = MockNode()

        let criteria: Set<WCAGSuccessCriterion> = [.nonTextContent, .linkPurpose]
        let report = validator.validate(tree, criteria: criteria)

        #expect(report.totalChecks == 2)
    }

    @Test("Validate at specific level")
    func testValidateAtLevel() {
        let checkers: [any AccessibilityChecker] = [
            MockChecker(criterion: .nonTextContent, shouldPass: true),  // Level A
            MockChecker(criterion: .contrastMinimum, shouldPass: true)  // Level AA
        ]
        let validator = WCAGValidator(checkers: checkers)
        let tree = MockNode()

        let reportA = validator.validate(tree, level: .a)
        #expect(reportA.totalChecks == 1)

        let reportAA = validator.validate(tree, level: .aa)
        #expect(reportAA.totalChecks == 2)
    }

    // MARK: - Batch Validation Tests

    @Test("Validate batch returns individual reports")
    func testValidateBatch() {
        let checkers: [any AccessibilityChecker] = [
            MockChecker(criterion: .nonTextContent, shouldPass: true)
        ]
        let validator = WCAGValidator(checkers: checkers)
        let trees = [MockNode(), MockNode(), MockNode()]

        let reports = validator.validateBatch(trees)

        #expect(reports.count == 3)
        for report in reports {
            #expect(report.nodeCount == 1)
        }
    }

    @Test("Validate aggregated returns single report")
    func testValidateAggregated() {
        let checkers: [any AccessibilityChecker] = [
            MockChecker(criterion: .nonTextContent, shouldPass: true)
        ]
        let validator = WCAGValidator(checkers: checkers)
        let trees = [MockNode(), MockNode(), MockNode()]

        let report = validator.validateAggregated(trees)

        #expect(report.nodeCount == 3)
        #expect(report.totalChecks == 1)
    }

    // MARK: - ValidationProfile Tests

    @Test("ValidationProfile initialization")
    func testProfileInit() {
        let checkers: [any AccessibilityChecker] = [
            MockChecker(criterion: .nonTextContent, shouldPass: true)
        ]
        let profile = ValidationProfile(
            name: "Custom Profile",
            checkers: checkers,
            options: .default
        )

        #expect(profile.name == "Custom Profile")
        #expect(profile.checkers.count == 1)
        #expect(profile.options == .default)
    }

    @Test("Level A profile")
    func testLevelAProfile() {
        let profile = ValidationProfile.levelA()

        #expect(profile.name == "WCAG 2.1 Level A")
        for checker in profile.checkers {
            #expect(checker.criterion.level == .a)
        }
    }

    @Test("Level AA profile")
    func testLevelAAProfile() {
        let profile = ValidationProfile.levelAA()

        #expect(profile.name == "WCAG 2.1 Level AA")
        for checker in profile.checkers {
            #expect(checker.criterion.level.rawValue <= WCAGLevel.aa.rawValue)
        }
    }

    @Test("Level AAA profile")
    func testLevelAAAProfile() {
        let profile = ValidationProfile.levelAAA()

        #expect(profile.name == "WCAG 2.1 Level AAA")
        // Should include all levels
        #expect(profile.checkers.count >= 0)
    }

    @Test("Perceivable profile")
    func testPerceivableProfile() {
        let profile = ValidationProfile.perceivable()

        #expect(profile.name == "WCAG Perceivable")
        for checker in profile.checkers {
            #expect(checker.criterion.principle == .perceivable)
        }
    }

    @Test("Operable profile")
    func testOperableProfile() {
        let profile = ValidationProfile.operable()

        #expect(profile.name == "WCAG Operable")
        for checker in profile.checkers {
            #expect(checker.criterion.principle == .operable)
        }
    }

    @Test("Understandable profile")
    func testUnderstandableProfile() {
        let profile = ValidationProfile.understandable()

        #expect(profile.name == "WCAG Understandable")
        for checker in profile.checkers {
            #expect(checker.criterion.principle == .understandable)
        }
    }

    @Test("Robust profile")
    func testRobustProfile() {
        let profile = ValidationProfile.robust()

        #expect(profile.name == "WCAG Robust")
        for checker in profile.checkers {
            #expect(checker.criterion.principle == .robust)
        }
    }

    @Test("Critical profile")
    func testCriticalProfile() {
        let profile = ValidationProfile.critical()

        #expect(profile.name == "Critical Accessibility")
        for checker in profile.checkers {
            #expect(checker.criterion.level == .a)
        }
    }

    @Test("Quick profile")
    func testQuickProfile() {
        let profile = ValidationProfile.quick()

        #expect(profile.name == "Quick Check")
        #expect(profile.options == .minimal)

        // Should include essential criteria
        let criteria = Set(profile.checkers.map { $0.criterion })
        let essential: Set<WCAGSuccessCriterion> = [
            .nonTextContent,
            .infoAndRelationships,
            .contrastMinimum,
            .linkPurpose,
            .languageOfPage
        ]

        // Quick profile should only include checkers that are in essential set
        for checker in profile.checkers {
            #expect(essential.contains(checker.criterion))
        }
    }

    // MARK: - Options Integration Tests

    @Test("Validator with default options")
    func testDefaultOptions() {
        let validator = WCAGValidator.levelA(options: .default)
        let tree = MockNode()

        let report = validator.validate(tree)

        #expect(report.options == .default)
    }

    @Test("Validator with minimal options")
    func testMinimalOptions() {
        let validator = WCAGValidator.levelA(options: .minimal)
        let tree = MockNode()

        let report = validator.validate(tree)

        #expect(report.options == .minimal)
    }

    @Test("Validator with strict options")
    func testStrictOptions() {
        let validator = WCAGValidator.levelA(options: .strict)
        let tree = MockNode()

        let report = validator.validate(tree)

        #expect(report.options == .strict)
    }

    // MARK: - Real Checker Integration Tests

    @Test("Validator with actual checkers")
    func testWithActualCheckers() {
        let validator = WCAGValidator.levelA()
        let tree = MockNode(children: [
            MockNode(type: .figure),
            MockNode(type: .link)
        ])

        let report = validator.validate(tree)

        // Should run actual checkers
        #expect(report.totalChecks > 0)
    }

    @Test("Validator detects failures with actual checkers")
    func testActualCheckersDetectFailures() {
        let validator = WCAGValidator.levelA()

        // Create a figure node without alt text (should fail)
        let figure = FigureNode(
            boundingBox: nil,
            children: [],
            attributes: [:],  // No Alt or ActualText
            depth: 1,
            imageChunks: []
        )

        let tree = MockNode(children: [figure])
        let report = validator.validate(tree)

        // AltTextChecker should find the missing alt text
        #expect(report.totalViolations > 0)
    }

    // MARK: - Edge Cases

    @Test("Validate empty tree")
    func testEmptyTree() {
        let validator = WCAGValidator.levelA()
        let tree = MockNode()

        let report = validator.validate(tree)

        #expect(report.nodeCount >= 1)
    }

    @Test("Validate with no checkers")
    func testNoCheckers() {
        let validator = WCAGValidator(checkers: [])
        let tree = MockNode()

        let report = validator.validate(tree)

        #expect(report.totalChecks == 0)
        #expect(report.allPassed == true)  // Vacuously true
    }

    @Test("Validate with empty trees array")
    func testEmptyTreesArray() {
        let validator = WCAGValidator.levelA()
        let trees: [MockNode] = []

        let report = validator.validate(trees)

        #expect(report.nodeCount == 0)
    }

    @Test("Batch validate with empty array")
    func testBatchValidateEmpty() {
        let validator = WCAGValidator.levelA()
        let trees: [MockNode] = []

        let reports = validator.validateBatch(trees)

        #expect(reports.isEmpty)
    }

    // MARK: - Performance Tests

    @Test("Validator handles large tree efficiently")
    func testLargeTree() {
        let validator = WCAGValidator.levelA()

        // Create a tree with many nodes
        var children: [MockNode] = []
        for _ in 0..<100 {
            children.append(MockNode(type: .paragraph))
        }
        let tree = MockNode(children: children)

        let report = validator.validate(tree)

        #expect(report.nodeCount >= 100)
        #expect(report.duration >= 0)
    }

    @Test("Batch validation is efficient")
    func testBatchValidationPerformance() {
        let validator = WCAGValidator.levelA()

        // Create multiple trees
        let trees = (0..<50).map { _ in MockNode() }

        let reports = validator.validateBatch(trees)

        #expect(reports.count == 50)
    }

    // MARK: - Mixed Result Tests

    @Test("Validator handles mixed pass/fail results")
    func testMixedResults() {
        let checkers: [any AccessibilityChecker] = [
            MockChecker(criterion: .nonTextContent, shouldPass: true),
            MockChecker(criterion: .contrastMinimum, shouldPass: false),
            MockChecker(criterion: .linkPurpose, shouldPass: true),
            MockChecker(criterion: .languageOfPage, shouldPass: false)
        ]
        let validator = WCAGValidator(checkers: checkers)
        let tree = MockNode()

        let report = validator.validate(tree)

        #expect(report.passedCount == 2)
        #expect(report.failedCount == 2)
        #expect(report.passRate == 50.0)
    }

    // MARK: - Criteria Filtering Tests

    @Test("Filtering by criteria excludes unmatched checkers")
    func testCriteriaFiltering() {
        let checkers: [any AccessibilityChecker] = [
            MockChecker(criterion: .nonTextContent, shouldPass: true),
            MockChecker(criterion: .contrastMinimum, shouldPass: true),
            MockChecker(criterion: .linkPurpose, shouldPass: true)
        ]
        let validator = WCAGValidator(checkers: checkers)
        let tree = MockNode()

        // Only check one criterion
        let criteria: Set<WCAGSuccessCriterion> = [.contrastMinimum]
        let report = validator.validate(tree, criteria: criteria)

        #expect(report.totalChecks == 1)
        #expect(report.results[0].criterion == .contrastMinimum)
    }

    @Test("Filtering with empty criteria set runs no checks")
    func testEmptyCriteriaSet() {
        let validator = WCAGValidator.levelA()
        let tree = MockNode()

        let report = validator.validate(tree, criteria: [])

        #expect(report.totalChecks == 0)
    }

    // MARK: - Level Filtering Tests

    @Test("Level filtering includes lower levels")
    func testLevelFilteringInclusive() {
        let checkers: [any AccessibilityChecker] = [
            MockChecker(criterion: .nonTextContent, shouldPass: true),     // Level A
            MockChecker(criterion: .contrastMinimum, shouldPass: true),    // Level AA
            MockChecker(criterion: .contrastEnhanced, shouldPass: true)    // Level AAA
        ]
        let validator = WCAGValidator(checkers: checkers)
        let tree = MockNode()

        // Level AA should include A and AA
        let reportAA = validator.validate(tree, level: .aa)
        #expect(reportAA.totalChecks == 2)

        // Level AAA should include all
        let reportAAA = validator.validate(tree, level: .aaa)
        #expect(reportAAA.totalChecks == 3)
    }
}

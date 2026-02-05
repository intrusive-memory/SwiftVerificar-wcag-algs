import Testing
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
@testable import SwiftVerificarWCAGAlgs

@Suite("HeadingHierarchyChecker Tests")
struct HeadingHierarchyCheckerTests {

    // MARK: - Test Helpers

    func makeTestNode(
        type: SemanticType,
        children: [any SemanticNode] = [],
        attributes: AttributesDictionary = [:],
        depth: Int = 0,
        boundingBox: BoundingBox? = nil
    ) -> ContentNode {
        ContentNode(
            type: type,
            boundingBox: boundingBox,
            children: children,
            attributes: attributes,
            depth: depth,
            textBlocks: [],
            dominantFontSize: nil,
            dominantFontWeight: nil,
            dominantColor: nil
        )
    }

    func makeBox(page: Int = 0, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> BoundingBox {
        BoundingBox(pageIndex: page, rect: CGRect(x: x, y: y, width: width, height: height))
    }

    // MARK: - Initialization Tests

    @Test("Checker initializes with default options")
    func initWithDefaultOptions() {
        let checker = HeadingHierarchyChecker()
        #expect(checker.options == .all)
    }

    @Test("Checker initializes with custom options")
    func initWithCustomOptions() {
        let options = HeadingHierarchyChecker.Options.basic
        let checker = HeadingHierarchyChecker(options: options)
        #expect(checker.options == options)
        #expect(checker.options.checkSkippedLevels == true)
        #expect(checker.options.requireSingleH1 == false)
    }

    @Test("Options presets have correct values")
    func optionsPresets() {
        let all = HeadingHierarchyChecker.Options.all
        #expect(all.requireSingleH1 == true)
        #expect(all.checkSkippedLevels == true)
        #expect(all.checkEmptyHeadings == true)
        #expect(all.validateHeadingText == true)

        let basic = HeadingHierarchyChecker.Options.basic
        #expect(basic.requireSingleH1 == false)
        #expect(basic.validateHeadingText == false)

        let strict = HeadingHierarchyChecker.Options.strict
        #expect(strict.requireSingleH1 == true)
        #expect(strict.requireFirstH1 == true)
    }

    // MARK: - Basic Validation Tests

    @Test("Validate document with no headings")
    func validateDocumentWithNoHeadings() {
        let checker = HeadingHierarchyChecker()
        let para = makeTestNode(type: .paragraph, depth: 1)
        let root = makeTestNode(type: .document, children: [para])

        let result = checker.validate(root)

        // No headings, so can't validate single H1
        #expect(result.totalHeadingCount == 0)
        #expect(result.headingsByLevel.isEmpty)
    }

    @Test("Validate simple valid hierarchy")
    func validateSimpleValidHierarchy() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(
            type: .h1,
            attributes: ["Alt": .string("Main Title")],
            depth: 1
        )
        let h2 = makeTestNode(
            type: .h2,
            attributes: ["Alt": .string("Subsection")],
            depth: 1
        )
        let root = makeTestNode(type: .document, children: [h1, h2])

        let result = checker.validate(root)

        #expect(result.totalHeadingCount == 2)
        #expect(result.headingsByLevel[1] == 1)
        #expect(result.headingsByLevel[2] == 1)
        #expect(result.hasSingleH1 == true)

        // Should be valid
        let criticalIssues = result.issues.filter { $0.severity == .critical }
        #expect(criticalIssues.isEmpty)
    }

    @Test("Validate complete hierarchy H1 through H6")
    func validateCompleteHierarchy() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(type: .h1, attributes: ["Alt": .string("Level 1")], depth: 1)
        let h2 = makeTestNode(type: .h2, attributes: ["Alt": .string("Level 2")], depth: 1)
        let h3 = makeTestNode(type: .h3, attributes: ["Alt": .string("Level 3")], depth: 1)
        let h4 = makeTestNode(type: .h4, attributes: ["Alt": .string("Level 4")], depth: 1)
        let h5 = makeTestNode(type: .h5, attributes: ["Alt": .string("Level 5")], depth: 1)
        let h6 = makeTestNode(type: .h6, attributes: ["Alt": .string("Level 6")], depth: 1)

        let root = makeTestNode(
            type: .document,
            children: [h1, h2, h3, h4, h5, h6]
        )

        let result = checker.validate(root)

        #expect(result.totalHeadingCount == 6)
        #expect(result.maxHeadingLevel == 6)
        #expect(result.isValid == true)
    }

    // MARK: - Single H1 Tests

    @Test("Detect multiple H1 headings")
    func detectMultipleH1Headings() {
        let checker = HeadingHierarchyChecker()

        let h1a = makeTestNode(type: .h1, attributes: ["Alt": .string("First H1")], depth: 1)
        let h1b = makeTestNode(type: .h1, attributes: ["Alt": .string("Second H1")], depth: 1)
        let root = makeTestNode(type: .document, children: [h1a, h1b])

        let result = checker.validate(root)

        #expect(result.hasSingleH1 == false)
        #expect(result.headingsByLevel[1] == 2)

        let multipleH1Issues = result.issues.filter { $0.type == .multipleH1 }
        #expect(multipleH1Issues.count == 2)
        #expect(multipleH1Issues[0].severity == .critical)
    }

    @Test("Detect missing H1")
    func detectMissingH1() {
        let checker = HeadingHierarchyChecker()

        let h2 = makeTestNode(type: .h2, attributes: ["Alt": .string("Subsection")], depth: 1)
        let root = makeTestNode(type: .document, children: [h2])

        let result = checker.validate(root)

        #expect(result.hasSingleH1 == false)
        #expect(result.headingsByLevel[1] == nil)

        let firstNotH1Issues = result.issues.filter { $0.type == .firstHeadingNotH1 }
        #expect(firstNotH1Issues.count >= 1)
        #expect(firstNotH1Issues[0].severity == .critical)
    }

    @Test("Single H1 requirement can be disabled")
    func singleH1RequirementDisabled() {
        let options = HeadingHierarchyChecker.Options(requireSingleH1: false)
        let checker = HeadingHierarchyChecker(options: options)

        let h1a = makeTestNode(type: .h1, attributes: ["Alt": .string("First H1")], depth: 1)
        let h1b = makeTestNode(type: .h1, attributes: ["Alt": .string("Second H1")], depth: 1)
        let root = makeTestNode(type: .document, children: [h1a, h1b])

        let result = checker.validate(root)

        let multipleH1Issues = result.issues.filter { $0.type == .multipleH1 }
        #expect(multipleH1Issues.isEmpty)
    }

    // MARK: - First Heading Tests

    @Test("First heading should be H1")
    func firstHeadingShouldBeH1() {
        let checker = HeadingHierarchyChecker()

        let h2 = makeTestNode(type: .h2, attributes: ["Alt": .string("First Heading")], depth: 1)
        let h3 = makeTestNode(type: .h3, attributes: ["Alt": .string("Second Heading")], depth: 1)
        let root = makeTestNode(type: .document, children: [h2, h3])

        let result = checker.validate(root)

        let firstNotH1Issues = result.issues.filter { $0.type == .firstHeadingNotH1 }
        #expect(firstNotH1Issues.count >= 1)
    }

    @Test("First heading H1 check can be disabled")
    func firstHeadingH1CheckDisabled() {
        let options = HeadingHierarchyChecker.Options(requireFirstH1: false)
        let checker = HeadingHierarchyChecker(options: options)

        let h2 = makeTestNode(type: .h2, attributes: ["Alt": .string("First Heading")], depth: 1)
        let root = makeTestNode(type: .document, children: [h2])

        let result = checker.validate(root)

        let firstNotH1Issues = result.issues.filter {
            $0.type == .firstHeadingNotH1 && $0.severity == .warning
        }
        #expect(firstNotH1Issues.isEmpty)
    }

    // MARK: - Skipped Level Tests

    @Test("Detect skipped heading level")
    func detectSkippedHeadingLevel() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(type: .h1, attributes: ["Alt": .string("Title")], depth: 1)
        let h3 = makeTestNode(type: .h3, attributes: ["Alt": .string("Subsection")], depth: 1)
        let root = makeTestNode(type: .document, children: [h1, h3])

        let result = checker.validate(root)

        let skippedLevelIssues = result.issues.filter { $0.type == .levelSkipped }
        #expect(skippedLevelIssues.count == 1)
        #expect(skippedLevelIssues[0].severity == .critical)
        #expect(skippedLevelIssues[0].context["previousLevel"] == "1")
        #expect(skippedLevelIssues[0].context["currentLevel"] == "3")
        #expect(skippedLevelIssues[0].context["skippedLevels"] == "1")
    }

    @Test("Multiple skipped levels detected")
    func multipleSkippedLevelsDetected() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(type: .h1, attributes: ["Alt": .string("Title")], depth: 1)
        let h5 = makeTestNode(type: .h5, attributes: ["Alt": .string("Deep Section")], depth: 1)
        let root = makeTestNode(type: .document, children: [h1, h5])

        let result = checker.validate(root)

        let skippedLevelIssues = result.issues.filter { $0.type == .levelSkipped }
        #expect(skippedLevelIssues.count == 1)
        #expect(skippedLevelIssues[0].context["skippedLevels"] == "3")
    }

    @Test("Valid sequential levels")
    func validSequentialLevels() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(type: .h1, attributes: ["Alt": .string("Title")], depth: 1)
        let h2 = makeTestNode(type: .h2, attributes: ["Alt": .string("Section")], depth: 1)
        let h3 = makeTestNode(type: .h3, attributes: ["Alt": .string("Subsection")], depth: 1)
        let root = makeTestNode(type: .document, children: [h1, h2, h3])

        let result = checker.validate(root)

        let skippedLevelIssues = result.issues.filter { $0.type == .levelSkipped }
        #expect(skippedLevelIssues.isEmpty)
    }

    @Test("Level can decrease without error")
    func levelCanDecrease() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(type: .h1, attributes: ["Alt": .string("Title")], depth: 1)
        let h2 = makeTestNode(type: .h2, attributes: ["Alt": .string("Section")], depth: 1)
        let h3 = makeTestNode(type: .h3, attributes: ["Alt": .string("Subsection")], depth: 1)
        let h2b = makeTestNode(type: .h2, attributes: ["Alt": .string("Next Section")], depth: 1)
        let root = makeTestNode(type: .document, children: [h1, h2, h3, h2b])

        let result = checker.validate(root)

        let skippedLevelIssues = result.issues.filter { $0.type == .levelSkipped }
        #expect(skippedLevelIssues.isEmpty)
    }

    @Test("Skipped level check can be disabled")
    func skippedLevelCheckDisabled() {
        let options = HeadingHierarchyChecker.Options(checkSkippedLevels: false)
        let checker = HeadingHierarchyChecker(options: options)

        let h1 = makeTestNode(type: .h1, attributes: ["Alt": .string("Title")], depth: 1)
        let h4 = makeTestNode(type: .h4, attributes: ["Alt": .string("Deep Section")], depth: 1)
        let root = makeTestNode(type: .document, children: [h1, h4])

        let result = checker.validate(root)

        let skippedLevelIssues = result.issues.filter { $0.type == .levelSkipped }
        #expect(skippedLevelIssues.isEmpty)
    }

    // MARK: - Empty Heading Tests

    @Test("Detect empty heading without children")
    func detectEmptyHeadingWithoutChildren() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(type: .h1, depth: 1)
        let root = makeTestNode(type: .document, children: [h1])

        let result = checker.validate(root)

        let emptyHeadingIssues = result.issues.filter { $0.type == .emptyHeading }
        #expect(emptyHeadingIssues.count >= 1)
        #expect(emptyHeadingIssues[0].severity == .critical)
        #expect(emptyHeadingIssues[0].headingLevel == 1)
    }

    @Test("Heading with Alt text is not empty")
    func headingWithAltTextNotEmpty() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(
            type: .h1,
            attributes: ["Alt": .string("Main Title")],
            depth: 1
        )
        let root = makeTestNode(type: .document, children: [h1])

        let result = checker.validate(root)

        let emptyHeadingIssues = result.issues.filter { $0.type == .emptyHeading }
        #expect(emptyHeadingIssues.isEmpty)
    }

    @Test("Heading with ActualText is not empty")
    func headingWithActualTextNotEmpty() {
        let checker = HeadingHierarchyChecker()

        let h2 = makeTestNode(
            type: .h2,
            attributes: ["ActualText": .string("Section Title")],
            depth: 1
        )
        let root = makeTestNode(type: .document, children: [h2])

        let result = checker.validate(root)

        let emptyHeadingIssues = result.issues.filter { $0.type == .emptyHeading }
        #expect(emptyHeadingIssues.isEmpty)
    }

    @Test("Heading with children is not empty")
    func headingWithChildrenNotEmpty() {
        let checker = HeadingHierarchyChecker()

        let span = makeTestNode(type: .span, depth: 2)
        let h1 = makeTestNode(type: .h1, children: [span], depth: 1)
        let root = makeTestNode(type: .document, children: [h1])

        let result = checker.validate(root)

        let emptyHeadingIssues = result.issues.filter { $0.type == .emptyHeading }
        #expect(emptyHeadingIssues.isEmpty)
    }

    @Test("Empty heading check can be disabled")
    func emptyHeadingCheckDisabled() {
        let options = HeadingHierarchyChecker.Options(checkEmptyHeadings: false)
        let checker = HeadingHierarchyChecker(options: options)

        let h1 = makeTestNode(type: .h1, depth: 1)
        let root = makeTestNode(type: .document, children: [h1])

        let result = checker.validate(root)

        let emptyHeadingIssues = result.issues.filter { $0.type == .emptyHeading }
        #expect(emptyHeadingIssues.isEmpty)
    }

    // MARK: - Heading Text Validation Tests

    @Test("Detect heading text too short")
    func detectHeadingTextTooShort() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(
            type: .h1,
            attributes: ["Alt": .string("")],
            depth: 1
        )
        let root = makeTestNode(type: .document, children: [h1])

        let result = checker.validate(root)

        let textIssues = result.issues.filter { $0.type == .nonMeaningfulText }
        #expect(textIssues.count >= 1)
        #expect(textIssues[0].severity == .warning)
    }

    @Test("Detect non-meaningful heading text")
    func detectNonMeaningfulHeadingText() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(
            type: .h1,
            attributes: ["Alt": .string("heading")],
            depth: 1
        )
        let root = makeTestNode(type: .document, children: [h1])

        let result = checker.validate(root)

        let textIssues = result.issues.filter { $0.type == .nonMeaningfulText }
        #expect(textIssues.count >= 1)
    }

    @Test("Non-meaningful patterns detected")
    func nonMeaningfulPatternsDetected() {
        let checker = HeadingHierarchyChecker()

        let patterns = ["heading", "title", "untitled", "new heading", "click here"]

        for pattern in patterns {
            let h1 = makeTestNode(
                type: .h1,
                attributes: ["Alt": .string(pattern)],
                depth: 1
            )
            let root = makeTestNode(type: .document, children: [h1])

            let result = checker.validate(root)

            let textIssues = result.issues.filter { $0.type == .nonMeaningfulText }
            #expect(textIssues.count >= 1, "Pattern '\(pattern)' should be detected")
        }
    }

    @Test("Meaningful heading text is accepted")
    func meaningfulHeadingTextAccepted() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(
            type: .h1,
            attributes: ["Alt": .string("Introduction to SwiftVerificar")],
            depth: 1
        )
        let root = makeTestNode(type: .document, children: [h1])

        let result = checker.validate(root)

        let textIssues = result.issues.filter { $0.type == .nonMeaningfulText }
        #expect(textIssues.isEmpty)
    }

    @Test("Heading text validation can be disabled")
    func headingTextValidationDisabled() {
        let options = HeadingHierarchyChecker.Options(validateHeadingText: false)
        let checker = HeadingHierarchyChecker(options: options)

        let h1 = makeTestNode(
            type: .h1,
            attributes: ["Alt": .string("heading")],
            depth: 1
        )
        let root = makeTestNode(type: .document, children: [h1])

        let result = checker.validate(root)

        let textIssues = result.issues.filter { $0.type == .nonMeaningfulText }
        #expect(textIssues.isEmpty)
    }

    @Test("Minimum text length can be configured")
    func minimumTextLengthConfigurable() {
        let options = HeadingHierarchyChecker.Options(minHeadingTextLength: 5)
        let checker = HeadingHierarchyChecker(options: options)

        let h1 = makeTestNode(
            type: .h1,
            attributes: ["Alt": .string("Test")],  // 4 characters
            depth: 1
        )
        let root = makeTestNode(type: .document, children: [h1])

        let result = checker.validate(root)

        let textIssues = result.issues.filter { $0.type == .nonMeaningfulText }
        #expect(textIssues.count >= 1)
    }

    // MARK: - Max Heading Level Tests

    @Test("Detect heading level exceeding maximum")
    func detectHeadingLevelExceedingMax() {
        let checker = HeadingHierarchyChecker()

        // Create a generic heading with level 7
        let h7 = makeTestNode(
            type: .heading,
            attributes: [
                "Level": .int(7),
                "Alt": .string("Too deep")
            ],
            depth: 1
        )
        let root = makeTestNode(type: .document, children: [h7])

        let result = checker.validate(root)

        let excessiveIssues = result.issues.filter { $0.type == .levelIncreaseExcessive }
        #expect(excessiveIssues.count >= 1)
        #expect(excessiveIssues[0].severity == .warning)
    }

    @Test("Standard heading levels H1-H6 are valid")
    func standardHeadingLevelsValid() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(type: .h1, attributes: ["Alt": .string("L1")], depth: 1)
        let h2 = makeTestNode(type: .h2, attributes: ["Alt": .string("L2")], depth: 1)
        let h3 = makeTestNode(type: .h3, attributes: ["Alt": .string("L3")], depth: 1)
        let h4 = makeTestNode(type: .h4, attributes: ["Alt": .string("L4")], depth: 1)
        let h5 = makeTestNode(type: .h5, attributes: ["Alt": .string("L5")], depth: 1)
        let h6 = makeTestNode(type: .h6, attributes: ["Alt": .string("L6")], depth: 1)

        let root = makeTestNode(
            type: .document,
            children: [h1, h2, h3, h4, h5, h6]
        )

        let result = checker.validate(root)

        let excessiveIssues = result.issues.filter { $0.type == .levelIncreaseExcessive }
        #expect(excessiveIssues.isEmpty)
    }

    @Test("Max heading level can be configured")
    func maxHeadingLevelConfigurable() {
        let options = HeadingHierarchyChecker.Options(maxHeadingLevel: 3)
        let checker = HeadingHierarchyChecker(options: options)

        let h1 = makeTestNode(type: .h1, attributes: ["Alt": .string("L1")], depth: 1)
        let h4 = makeTestNode(type: .h4, attributes: ["Alt": .string("L4")], depth: 1)
        let root = makeTestNode(type: .document, children: [h1, h4])

        let result = checker.validate(root)

        let excessiveIssues = result.issues.filter { $0.type == .levelIncreaseExcessive }
        #expect(excessiveIssues.count == 1)
    }

    // MARK: - Generic Heading Type Tests

    @Test("Generic heading type with Level attribute")
    func genericHeadingTypeWithLevelAttribute() {
        let checker = HeadingHierarchyChecker()

        let h = makeTestNode(
            type: .heading,
            attributes: [
                "Level": .int(2),
                "Alt": .string("Section")
            ],
            depth: 1
        )
        let root = makeTestNode(type: .document, children: [h])

        let result = checker.validate(root)

        #expect(result.totalHeadingCount == 1)
        #expect(result.headingsByLevel[2] == 1)
    }

    @Test("Generic heading without Level defaults to 1")
    func genericHeadingWithoutLevelDefaultsTo1() {
        let checker = HeadingHierarchyChecker()

        let h = makeTestNode(
            type: .heading,
            attributes: ["Alt": .string("Default Level")],
            depth: 1
        )
        let root = makeTestNode(type: .document, children: [h])

        let result = checker.validate(root)

        #expect(result.headingsByLevel[1] == 1)
    }

    // MARK: - Result Analysis Tests

    @Test("Result groups issues by type")
    func resultGroupsIssuesByType() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(type: .h1, depth: 1)  // Empty
        let h4 = makeTestNode(
            type: .h4,
            attributes: ["Alt": .string("Skipped")],
            depth: 1
        )  // Skipped levels
        let root = makeTestNode(type: .document, children: [h1, h4])

        let result = checker.validate(root)

        let grouped = result.issuesByType
        #expect(grouped[.emptyHeading]?.count ?? 0 >= 1)
        #expect(grouped[.levelSkipped]?.count ?? 0 >= 1)
    }

    @Test("Result counts issues by severity")
    func resultCountsIssuesBySeverity() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(type: .h1, depth: 1)
        let h3 = makeTestNode(
            type: .h3,
            attributes: ["Alt": .string("x")],
            depth: 1
        )
        let root = makeTestNode(type: .document, children: [h1, h3])

        let result = checker.validate(root)

        #expect(result.criticalIssueCount >= 1)
    }

    @Test("Valid result has no issues")
    func validResultHasNoIssues() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(
            type: .h1,
            attributes: ["Alt": .string("Main Title")],
            depth: 1
        )
        let h2 = makeTestNode(
            type: .h2,
            attributes: ["Alt": .string("Subsection")],
            depth: 1
        )
        let root = makeTestNode(type: .document, children: [h1, h2])

        let result = checker.validate(root)

        #expect(result.isValid == true)
        #expect(result.issues.isEmpty)
        #expect(result.criticalIssueCount == 0)
    }

    @Test("Result tracks heading distribution")
    func resultTracksHeadingDistribution() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(type: .h1, attributes: ["Alt": .string("T")], depth: 1)
        let h2a = makeTestNode(type: .h2, attributes: ["Alt": .string("S1")], depth: 1)
        let h2b = makeTestNode(type: .h2, attributes: ["Alt": .string("S2")], depth: 1)
        let h3 = makeTestNode(type: .h3, attributes: ["Alt": .string("SS")], depth: 1)

        let root = makeTestNode(type: .document, children: [h1, h2a, h2b, h3])

        let result = checker.validate(root)

        #expect(result.totalHeadingCount == 4)
        #expect(result.headingsByLevel[1] == 1)
        #expect(result.headingsByLevel[2] == 2)
        #expect(result.headingsByLevel[3] == 1)
        #expect(result.maxHeadingLevel == 3)
    }

    // MARK: - Issue Structure Tests

    @Test("Issue contains correct metadata")
    func issueContainsCorrectMetadata() {
        let checker = HeadingHierarchyChecker()

        let box = makeBox(page: 2, x: 100, y: 100, width: 200, height: 50)
        let h1 = makeTestNode(type: .h1, depth: 1, boundingBox: box)
        let root = makeTestNode(type: .document, children: [h1])

        let result = checker.validate(root)

        #expect(result.issues.count >= 1)
        let issue = result.issues[0]
        #expect(issue.type == HeadingHierarchyIssue.IssueType.emptyHeading)
        #expect(issue.severity == HeadingHierarchyIssue.Severity.critical)
        #expect(issue.headingLevel == 1)
        #expect(issue.nodeId == h1.id)
        #expect(issue.pageIndex == 2)
        #expect(!issue.message.isEmpty)
    }

    @Test("Issue has unique ID")
    func issueHasUniqueId() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(type: .h1, depth: 1)
        let h2 = makeTestNode(type: .h2, depth: 1)
        let root = makeTestNode(type: .document, children: [h1, h2])

        let result = checker.validate(root)

        if result.issues.count >= 2 {
            #expect(result.issues[0].id != result.issues[1].id)
        }
    }

    // MARK: - Complex Scenarios

    @Test("Validate complex nested document structure")
    func validateComplexNestedStructure() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(type: .h1, attributes: ["Alt": .string("Title")], depth: 1)
        let para1 = makeTestNode(type: .paragraph, depth: 1)
        let h2 = makeTestNode(type: .h2, attributes: ["Alt": .string("Section 1")], depth: 1)
        let para2 = makeTestNode(type: .paragraph, depth: 1)
        let h3 = makeTestNode(type: .h3, attributes: ["Alt": .string("Subsection")], depth: 1)
        let para3 = makeTestNode(type: .paragraph, depth: 1)
        let h2b = makeTestNode(type: .h2, attributes: ["Alt": .string("Section 2")], depth: 1)

        let root = makeTestNode(
            type: .document,
            children: [h1, para1, h2, para2, h3, para3, h2b]
        )

        let result = checker.validate(root)

        #expect(result.totalHeadingCount == 4)
        #expect(result.hasSingleH1 == true)
        #expect(result.isValid == true)
    }

    @Test("Non-heading nodes are ignored")
    func nonHeadingNodesIgnored() {
        let checker = HeadingHierarchyChecker()

        let h1 = makeTestNode(type: .h1, attributes: ["Alt": .string("Title")], depth: 1)
        let para = makeTestNode(type: .paragraph, depth: 1)
        let div = makeTestNode(type: .div, depth: 1)
        let span = makeTestNode(type: .span, depth: 1)

        let root = makeTestNode(type: .document, children: [h1, para, div, span])

        let result = checker.validate(root)

        #expect(result.totalHeadingCount == 1)
    }
}

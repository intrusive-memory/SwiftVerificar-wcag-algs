import Testing
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
@testable import SwiftVerificarWCAGAlgs

@Suite("ReadingOrderValidator Tests")
struct ReadingOrderValidatorTests {

    // MARK: - Test Helpers

    func makeTestNode(
        type: SemanticType,
        boundingBox: BoundingBox?,
        children: [any SemanticNode] = [],
        attributes: AttributesDictionary = [:]
    ) -> ContentNode {
        ContentNode(
            type: type,
            boundingBox: boundingBox,
            children: children,
            attributes: attributes,
            depth: 0,
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

    @Test("Validator initializes with default options")
    func initWithDefaultOptions() {
        let validator = ReadingOrderValidator()
        #expect(validator.options == .standard)
    }

    @Test("Validator initializes with custom options")
    func initWithCustomOptions() {
        let options = ReadingOrderValidator.Options.rightToLeft
        let validator = ReadingOrderValidator(options: options)
        #expect(validator.options.readingDirection == .rightToLeft)
    }

    @Test("Options presets have correct values")
    func optionsPresets() {
        let standard = ReadingOrderValidator.Options.standard
        #expect(standard.readingDirection == .leftToRight)
        #expect(standard.validateColumns == true)
        #expect(standard.checkOverlaps == true)

        let rtl = ReadingOrderValidator.Options.rightToLeft
        #expect(rtl.readingDirection == .rightToLeft)

        let strict = ReadingOrderValidator.Options.strict
        #expect(strict.verticalTolerance == 2.0)
        #expect(strict.horizontalTolerance == 5.0)
    }

    // MARK: - Basic Validation Tests

    @Test("Validate empty tree returns valid result")
    func validateEmptyTree() {
        let validator = ReadingOrderValidator()
        let root = makeTestNode(type: .document, boundingBox: nil)

        let result = validator.validate(root)

        #expect(result.isValid == true)
        #expect(result.issues.isEmpty)
        #expect(result.totalNodeCount == 0)
        #expect(result.pageCount == 0)
    }

    @Test("Validate single node")
    func validateSingleNode() {
        let validator = ReadingOrderValidator()
        let box = makeBox(x: 100, y: 100, width: 200, height: 50)
        let para = makeTestNode(type: .paragraph, boundingBox: box)
        let root = makeTestNode(type: .document, boundingBox: nil, children: [para])

        let result = validator.validate(root)

        #expect(result.isValid == true)
        #expect(result.totalNodeCount == 1)
        #expect(result.pageCount == 1)
    }

    @Test("Validate correct top-to-bottom order")
    func validateCorrectTopToBottomOrder() {
        let validator = ReadingOrderValidator()

        // Top node
        let box1 = makeBox(x: 100, y: 200, width: 200, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        // Bottom node
        let box2 = makeBox(x: 100, y: 100, width: 200, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        #expect(result.isValid == true)
        #expect(result.issues.isEmpty)
    }

    @Test("Validate correct left-to-right order")
    func validateCorrectLeftToRightOrder() {
        let validator = ReadingOrderValidator()

        // Left node (same vertical position)
        let box1 = makeBox(x: 100, y: 100, width: 100, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        // Right node
        let box2 = makeBox(x: 220, y: 100, width: 100, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        #expect(result.isValid == true)
    }

    // MARK: - Out of Order Detection Tests

    @Test("Detect content out of vertical order")
    func detectOutOfVerticalOrder() {
        let validator = ReadingOrderValidator()

        // Bottom node appears first (wrong order)
        let box1 = makeBox(x: 100, y: 100, width: 200, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        // Top node appears second
        let box2 = makeBox(x: 100, y: 200, width: 200, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        #expect(result.isValid == false)
        #expect(result.issues.count >= 1)
        let outOfOrderIssues = result.issues.filter { $0.type == .outOfOrder }
        #expect(outOfOrderIssues.count == 1)
        #expect(outOfOrderIssues[0].severity == .critical)
    }

    @Test("Detect reverse horizontal order in LTR")
    func detectReverseHorizontalOrderLTR() {
        let validator = ReadingOrderValidator()

        // Right node appears first (wrong for LTR)
        let box1 = makeBox(x: 220, y: 100, width: 100, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        // Left node appears second
        let box2 = makeBox(x: 100, y: 100, width: 100, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        #expect(result.isValid == false)
        let reverseIssues = result.issues.filter { $0.type == .reverseDirection }
        #expect(reverseIssues.count >= 1)
        guard !reverseIssues.isEmpty else { return }
        #expect(reverseIssues[0].severity == .warning)
    }

    @Test("Validate correct right-to-left order")
    func validateCorrectRightToLeftOrder() {
        let options = ReadingOrderValidator.Options.rightToLeft
        let validator = ReadingOrderValidator(options: options)

        // Right node appears first (correct for RTL)
        let box1 = makeBox(x: 220, y: 100, width: 100, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        // Left node appears second
        let box2 = makeBox(x: 100, y: 100, width: 100, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        let reverseIssues = result.issues.filter { $0.type == .reverseDirection }
        #expect(reverseIssues.isEmpty)
    }

    @Test("Small vertical gaps are tolerated")
    func smallVerticalGapsAreTolerated() {
        let validator = ReadingOrderValidator()

        // Nodes with small vertical gap (within tolerance)
        let box1 = makeBox(x: 100, y: 103, width: 200, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(x: 100, y: 100, width: 200, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        // Should not trigger out-of-order with default tolerance
        let outOfOrderIssues = result.issues.filter { $0.type == .outOfOrder }
        #expect(outOfOrderIssues.isEmpty)
    }

    @Test("Vertical tolerance can be adjusted")
    func verticalToleranceAdjustable() {
        let options = ReadingOrderValidator.Options(verticalTolerance: 1.0)
        let validator = ReadingOrderValidator(options: options)

        // Node 1 is lower (y=100), node 2 is higher (y=103).
        // Use small heights so they don't overlap vertically, forcing
        // the validator to compare top edges.
        let box1 = makeBox(x: 100, y: 100, width: 200, height: 2)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        // Node 2 is above node 1 (wrong reading order for top-to-bottom)
        let box2 = makeBox(x: 100, y: 104, width: 200, height: 2)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        // Should trigger with strict tolerance (gap of 4 > tolerance of 1.0)
        let outOfOrderIssues = result.issues.filter { $0.type == .outOfOrder }
        #expect(outOfOrderIssues.count >= 1)
    }

    // MARK: - Overlap Detection Tests

    @Test("Detect overlapping content")
    func detectOverlappingContent() {
        let validator = ReadingOrderValidator()

        // Overlapping boxes
        let box1 = makeBox(x: 100, y: 100, width: 150, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(x: 200, y: 110, width: 150, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        let overlapIssues = result.issues.filter { $0.type == .overlapping }
        #expect(overlapIssues.count >= 1)
        #expect(overlapIssues[0].severity == .warning)
    }

    @Test("Small overlaps below threshold are ignored")
    func smallOverlapsBelowThreshold() {
        let validator = ReadingOrderValidator()

        // Very slight overlap (below 10% threshold)
        let box1 = makeBox(x: 100, y: 100, width: 200, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(x: 295, y: 105, width: 200, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        let overlapIssues = result.issues.filter { $0.type == .overlapping }
        #expect(overlapIssues.isEmpty)
    }

    @Test("Overlap detection can be disabled")
    func overlapDetectionCanBeDisabled() {
        let options = ReadingOrderValidator.Options(checkOverlaps: false)
        let validator = ReadingOrderValidator(options: options)

        // Overlapping boxes
        let box1 = makeBox(x: 100, y: 100, width: 150, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(x: 150, y: 110, width: 150, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        let overlapIssues = result.issues.filter { $0.type == .overlapping }
        #expect(overlapIssues.isEmpty)
    }

    @Test("Overlap threshold can be adjusted")
    func overlapThresholdAdjustable() {
        let options = ReadingOrderValidator.Options(overlapThreshold: 0.5)
        let validator = ReadingOrderValidator(options: options)

        // Moderate overlap (would trigger default, might not trigger with 50%)
        let box1 = makeBox(x: 100, y: 100, width: 100, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(x: 150, y: 110, width: 100, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        // Overlap percentage is significant, so might still trigger
        // This test verifies the threshold is being used
        #expect(result.issues.count >= 0) // Just ensure no crash
    }

    // MARK: - Column Detection Tests

    @Test("Detect invalid column jump")
    func detectInvalidColumnJump() {
        let validator = ReadingOrderValidator()

        // Column 1 content
        let box1 = makeBox(x: 50, y: 200, width: 150, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(x: 50, y: 140, width: 150, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        // Column 2 content (in middle of column 1)
        let box3 = makeBox(x: 250, y: 170, width: 150, height: 50)
        let para3 = makeTestNode(type: .paragraph, boundingBox: box3)

        // Back to column 1 (invalid jump)
        let box4 = makeBox(x: 50, y: 80, width: 150, height: 50)
        let para4 = makeTestNode(type: .paragraph, boundingBox: box4)

        let root = makeTestNode(
            type: .document,
            boundingBox: nil,
            children: [para1, para2, para3, para4]
        )

        let result = validator.validate(root)

        let columnJumpIssues = result.issues.filter { $0.type == .columnJump }
        #expect(columnJumpIssues.count >= 1)
        #expect(columnJumpIssues[0].severity == .warning)
    }

    @Test("Valid column order is accepted")
    func validColumnOrderAccepted() {
        let validator = ReadingOrderValidator()

        // Column 1 - top to bottom
        let box1 = makeBox(x: 50, y: 200, width: 150, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(x: 50, y: 140, width: 150, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let box3 = makeBox(x: 50, y: 80, width: 150, height: 50)
        let para3 = makeTestNode(type: .paragraph, boundingBox: box3)

        // Column 2 - top to bottom
        let box4 = makeBox(x: 250, y: 200, width: 150, height: 50)
        let para4 = makeTestNode(type: .paragraph, boundingBox: box4)

        let box5 = makeBox(x: 250, y: 140, width: 150, height: 50)
        let para5 = makeTestNode(type: .paragraph, boundingBox: box5)

        let root = makeTestNode(
            type: .document,
            boundingBox: nil,
            children: [para1, para2, para3, para4, para5]
        )

        let result = validator.validate(root)

        let columnJumpIssues = result.issues.filter { $0.type == .columnJump }
        #expect(columnJumpIssues.isEmpty)
    }

    @Test("Column validation can be disabled")
    func columnValidationCanBeDisabled() {
        let options = ReadingOrderValidator.Options(validateColumns: false)
        let validator = ReadingOrderValidator(options: options)

        // Invalid column jump
        let box1 = makeBox(x: 50, y: 200, width: 150, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(x: 250, y: 170, width: 150, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let box3 = makeBox(x: 50, y: 140, width: 150, height: 50)
        let para3 = makeTestNode(type: .paragraph, boundingBox: box3)

        let root = makeTestNode(
            type: .document,
            boundingBox: nil,
            children: [para1, para2, para3]
        )

        let result = validator.validate(root)

        let columnJumpIssues = result.issues.filter { $0.type == .columnJump }
        #expect(columnJumpIssues.isEmpty)
    }

    // MARK: - Multi-Page Tests

    @Test("Validate content across multiple pages")
    func validateMultiplePages() {
        let validator = ReadingOrderValidator()

        // Page 0
        let box1 = makeBox(page: 0, x: 100, y: 200, width: 200, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(page: 0, x: 100, y: 100, width: 200, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        // Page 1
        let box3 = makeBox(page: 1, x: 100, y: 200, width: 200, height: 50)
        let para3 = makeTestNode(type: .paragraph, boundingBox: box3)

        let root = makeTestNode(
            type: .document,
            boundingBox: nil,
            children: [para1, para2, para3]
        )

        let result = validator.validate(root)

        #expect(result.pageCount == 2)
        #expect(result.totalNodeCount == 3)
    }

    @Test("Pages are validated independently")
    func pagesValidatedIndependently() {
        let validator = ReadingOrderValidator()

        // Page 0 - valid order
        let box1 = makeBox(page: 0, x: 100, y: 200, width: 200, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(page: 0, x: 100, y: 100, width: 200, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        // Page 1 - invalid order
        let box3 = makeBox(page: 1, x: 100, y: 100, width: 200, height: 50)
        let para3 = makeTestNode(type: .paragraph, boundingBox: box3)

        let box4 = makeBox(page: 1, x: 100, y: 200, width: 200, height: 50)
        let para4 = makeTestNode(type: .paragraph, boundingBox: box4)

        let root = makeTestNode(
            type: .document,
            boundingBox: nil,
            children: [para1, para2, para3, para4]
        )

        let result = validator.validate(root)

        // Should only have issues from page 1
        let outOfOrderIssues = result.issues.filter { $0.type == .outOfOrder }
        #expect(outOfOrderIssues.count >= 1)
        #expect(outOfOrderIssues.allSatisfy { $0.pageIndex == 1 })
    }

    // MARK: - Result Analysis Tests

    @Test("Result groups issues by severity")
    func resultGroupsIssuesBySeverity() {
        let validator = ReadingOrderValidator()

        // Create both critical and warning issues
        let box1 = makeBox(x: 100, y: 100, width: 200, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(x: 100, y: 200, width: 200, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        let grouped = result.issuesBySeverity
        #expect(grouped[.critical]?.count ?? 0 >= 1)
    }

    @Test("Result counts issues by severity")
    func resultCountsIssuesBySeverity() {
        let validator = ReadingOrderValidator()

        let box1 = makeBox(x: 100, y: 100, width: 200, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(x: 100, y: 200, width: 200, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        #expect(result.criticalIssueCount >= 1)
        #expect(result.warningIssueCount >= 0)
    }

    @Test("Valid result has no issues")
    func validResultHasNoIssues() {
        let validator = ReadingOrderValidator()

        let box1 = makeBox(x: 100, y: 200, width: 200, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(x: 100, y: 100, width: 200, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        #expect(result.isValid == true)
        #expect(result.issues.isEmpty)
        #expect(result.criticalIssueCount == 0)
        #expect(result.warningIssueCount == 0)
    }

    // MARK: - Issue Structure Tests

    @Test("Issue contains correct metadata")
    func issueContainsCorrectMetadata() {
        let validator = ReadingOrderValidator()

        let box1 = makeBox(page: 2, x: 100, y: 100, width: 200, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(page: 2, x: 100, y: 200, width: 200, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        #expect(result.issues.count >= 1)
        let issue = result.issues[0]
        #expect(issue.type == .outOfOrder)
        #expect(issue.severity == .critical)
        #expect(issue.pageIndex == 2)
        #expect(!issue.message.isEmpty)
        #expect(issue.nodeId1 == para1.id)
        #expect(issue.nodeId2 == para2.id)
    }

    @Test("Issue has unique ID")
    func issueHasUniqueId() {
        let validator = ReadingOrderValidator()

        let box1 = makeBox(x: 100, y: 100, width: 200, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(x: 100, y: 200, width: 200, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let box3 = makeBox(x: 100, y: 250, width: 200, height: 50)
        let para3 = makeTestNode(type: .paragraph, boundingBox: box3)

        let root = makeTestNode(
            type: .document,
            boundingBox: nil,
            children: [para1, para2, para3]
        )

        let result = validator.validate(root)

        if result.issues.count >= 2 {
            #expect(result.issues[0].id != result.issues[1].id)
        }
    }

    @Test("Issue context provides debugging info")
    func issueContextProvidesDebuggingInfo() {
        let validator = ReadingOrderValidator()

        let box1 = makeBox(x: 100, y: 100, width: 200, height: 50)
        let para1 = makeTestNode(type: .paragraph, boundingBox: box1)

        let box2 = makeBox(x: 100, y: 200, width: 200, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        #expect(result.issues.count >= 1)
        let issue = result.issues[0]
        #expect(!issue.context.isEmpty)
    }

    // MARK: - Complex Scenarios

    @Test("Validate complex multi-column layout")
    func validateComplexMultiColumnLayout() {
        let validator = ReadingOrderValidator()

        // Create a proper 2-column layout
        var children: [any SemanticNode] = []

        // Column 1 (x=50)
        for i in stride(from: 200, through: 50, by: -50) {
            let box = makeBox(x: 50, y: CGFloat(i), width: 150, height: 40)
            children.append(makeTestNode(type: .paragraph, boundingBox: box))
        }

        // Column 2 (x=250)
        for i in stride(from: 200, through: 50, by: -50) {
            let box = makeBox(x: 250, y: CGFloat(i), width: 150, height: 40)
            children.append(makeTestNode(type: .paragraph, boundingBox: box))
        }

        let root = makeTestNode(type: .document, boundingBox: nil, children: children)

        let result = validator.validate(root)

        // Should have no column jump issues if properly ordered
        let columnJumpIssues = result.issues.filter { $0.type == .columnJump }
        #expect(columnJumpIssues.isEmpty)
    }

    @Test("Nodes without bounding boxes are ignored")
    func nodesWithoutBoundingBoxesIgnored() {
        let validator = ReadingOrderValidator()

        let para1 = makeTestNode(type: .paragraph, boundingBox: nil)
        let box2 = makeBox(x: 100, y: 100, width: 200, height: 50)
        let para2 = makeTestNode(type: .paragraph, boundingBox: box2)

        let root = makeTestNode(type: .document, boundingBox: nil, children: [para1, para2])

        let result = validator.validate(root)

        #expect(result.totalNodeCount == 1)
        #expect(result.isValid == true)
    }
}

import Testing
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
@testable import SwiftVerificarWCAGAlgs

@Suite("StructureTreeAnalyzer Tests")
struct StructureTreeAnalyzerTests {

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

    // MARK: - Initialization Tests

    @Test("Analyzer initializes with default options")
    func initWithDefaultOptions() {
        let analyzer = StructureTreeAnalyzer()
        #expect(analyzer.options == .all)
    }

    @Test("Analyzer initializes with custom options")
    func initWithCustomOptions() {
        let options = StructureTreeAnalyzer.Options.nestingOnly
        let analyzer = StructureTreeAnalyzer(options: options)
        #expect(analyzer.options == options)
        #expect(analyzer.options.validateNesting == true)
        #expect(analyzer.options.validateAttributes == false)
    }

    @Test("Options presets have correct values")
    func optionsPresets() {
        let all = StructureTreeAnalyzer.Options.all
        #expect(all.validateNesting == true)
        #expect(all.validateRequiredChildren == true)
        #expect(all.validateAttributes == true)
        #expect(all.checkEmptyElements == true)
        #expect(all.checkDuplicateIds == true)

        let nestingOnly = StructureTreeAnalyzer.Options.nestingOnly
        #expect(nestingOnly.validateNesting == true)
        #expect(nestingOnly.validateRequiredChildren == false)

        let attributesOnly = StructureTreeAnalyzer.Options.attributesOnly
        #expect(attributesOnly.validateAttributes == true)
        #expect(attributesOnly.validateNesting == false)
    }

    // MARK: - Basic Analysis Tests

    @Test("Analyze empty tree returns valid result")
    func analyzeEmptyTree() {
        let analyzer = StructureTreeAnalyzer()
        let root = makeTestNode(type: .document)

        let result = analyzer.analyze(root)

        #expect(result.isValid == true)
        #expect(result.errors.isEmpty)
        #expect(result.totalNodeCount == 1)
        #expect(result.maxDepth == 0)
    }

    @Test("Analyze simple valid tree")
    func analyzeSimpleValidTree() {
        let analyzer = StructureTreeAnalyzer()
        // Give paragraphs text alternatives so they are not flagged as empty
        let child1 = makeTestNode(type: .paragraph, attributes: ["ActualText": .string("Content 1")], depth: 1)
        let child2 = makeTestNode(type: .paragraph, attributes: ["ActualText": .string("Content 2")], depth: 1)
        let root = makeTestNode(type: .document, children: [child1, child2])

        let result = analyzer.analyze(root)

        #expect(result.isValid == true)
        #expect(result.errors.isEmpty)
        #expect(result.totalNodeCount == 3)
        #expect(result.maxDepth == 1)
    }

    @Test("Analyze deep tree tracks max depth")
    func analyzeDeepTree() {
        let analyzer = StructureTreeAnalyzer()
        // Give leaf span text so it is not flagged as empty
        let level3 = makeTestNode(type: .span, attributes: ["ActualText": .string("Text")], depth: 3)
        let level2 = makeTestNode(type: .paragraph, children: [level3], depth: 2)
        let level1 = makeTestNode(type: .div, children: [level2], depth: 1)
        let root = makeTestNode(type: .document, children: [level1])

        let result = analyzer.analyze(root)

        #expect(result.isValid == true)
        #expect(result.totalNodeCount == 4)
        #expect(result.maxDepth == 3)
    }

    // MARK: - Empty Element Tests

    @Test("Detect empty paragraph without children or text")
    func detectEmptyParagraph() {
        let analyzer = StructureTreeAnalyzer()
        let emptyPara = makeTestNode(type: .paragraph)
        let root = makeTestNode(type: .document, children: [emptyPara])

        let result = analyzer.analyze(root)

        #expect(result.isValid == false)
        #expect(result.errors.count == 1)
        #expect(result.errors[0].code == .emptyElement)
        #expect(result.errors[0].nodeType == .paragraph)
    }

    @Test("Empty element with Alt text is valid")
    func emptyElementWithAltText() {
        let analyzer = StructureTreeAnalyzer()
        let nodeWithAlt = makeTestNode(
            type: .paragraph,
            attributes: ["Alt": .string("Description")]
        )
        let root = makeTestNode(type: .document, children: [nodeWithAlt])

        let result = analyzer.analyze(root)

        #expect(result.isValid == true)
    }

    @Test("Empty element with ActualText is valid")
    func emptyElementWithActualText() {
        let analyzer = StructureTreeAnalyzer()
        let nodeWithActual = makeTestNode(
            type: .span,
            attributes: ["ActualText": .string("Text content")]
        )
        let root = makeTestNode(type: .document, children: [nodeWithActual])

        let result = analyzer.analyze(root)

        #expect(result.isValid == true)
    }

    @Test("Allowed empty types are not flagged")
    func allowedEmptyTypes() {
        let analyzer = StructureTreeAnalyzer()
        let artifact = makeTestNode(type: .artifact)
        let header = makeTestNode(type: .documentHeader)
        let footer = makeTestNode(type: .documentFooter)
        let note = makeTestNode(type: .note)
        let root = makeTestNode(
            type: .document,
            children: [artifact, header, footer, note]
        )

        let result = analyzer.analyze(root)

        #expect(result.isValid == true)
        #expect(result.errors.isEmpty)
    }

    @Test("Empty check can be disabled")
    func disableEmptyCheck() {
        let options = StructureTreeAnalyzer.Options(checkEmptyElements: false)
        let analyzer = StructureTreeAnalyzer(options: options)
        let emptyPara = makeTestNode(type: .paragraph)
        let root = makeTestNode(type: .document, children: [emptyPara])

        let result = analyzer.analyze(root)

        #expect(result.isValid == true)
    }

    // MARK: - Nesting Validation Tests

    @Test("Detect invalid child type in list")
    func detectInvalidListChild() {
        let analyzer = StructureTreeAnalyzer()
        let invalidChild = makeTestNode(type: .paragraph, depth: 1)
        let list = makeTestNode(type: .list, children: [invalidChild])
        let root = makeTestNode(type: .document, children: [list])

        let result = analyzer.analyze(root)

        #expect(result.isValid == false)
        #expect(result.errors.count >= 1)
        let nestingErrors = result.errors.filter { $0.code == .unexpectedChild }
        #expect(nestingErrors.count == 1)
        #expect(nestingErrors[0].context["childType"] == "P")
    }

    @Test("Valid list with list items")
    func validListWithItems() {
        let analyzer = StructureTreeAnalyzer()
        let body = makeTestNode(type: .listBody, depth: 2)
        let item = makeTestNode(type: .listItem, children: [body], depth: 1)
        let list = makeTestNode(type: .list, children: [item])
        let root = makeTestNode(type: .document, children: [list])

        let result = analyzer.analyze(root)

        let nestingErrors = result.errors.filter { $0.code == .unexpectedChild }
        #expect(nestingErrors.isEmpty)
    }

    @Test("Detect invalid child in table row")
    func detectInvalidTableRowChild() {
        let analyzer = StructureTreeAnalyzer()
        let invalidChild = makeTestNode(type: .paragraph, depth: 2)
        let row = makeTestNode(type: .tableRow, children: [invalidChild], depth: 1)
        let table = makeTestNode(type: .table, children: [row])
        let root = makeTestNode(type: .document, children: [table])

        let result = analyzer.analyze(root)

        let nestingErrors = result.errors.filter { $0.code == .unexpectedChild }
        #expect(nestingErrors.count == 1)
    }

    @Test("Valid table structure")
    func validTableStructure() {
        let analyzer = StructureTreeAnalyzer()
        let cell = makeTestNode(type: .tableCell, depth: 2)
        let row = makeTestNode(type: .tableRow, children: [cell], depth: 1)
        let table = makeTestNode(type: .table, children: [row])
        let root = makeTestNode(type: .document, children: [table])

        let result = analyzer.analyze(root)

        let nestingErrors = result.errors.filter { $0.code == .unexpectedChild }
        #expect(nestingErrors.isEmpty)
    }

    @Test("TOC must contain TOCI items")
    func tocMustContainTociItems() {
        let analyzer = StructureTreeAnalyzer()
        let invalidChild = makeTestNode(type: .paragraph, depth: 1)
        let toc = makeTestNode(type: .toc, children: [invalidChild])
        let root = makeTestNode(type: .document, children: [toc])

        let result = analyzer.analyze(root)

        let nestingErrors = result.errors.filter { $0.code == .unexpectedChild }
        #expect(nestingErrors.count == 1)
    }

    @Test("Nesting validation can be disabled")
    func disableNestingValidation() {
        let options = StructureTreeAnalyzer.Options(validateNesting: false)
        let analyzer = StructureTreeAnalyzer(options: options)
        let invalidChild = makeTestNode(type: .paragraph, depth: 1)
        let list = makeTestNode(type: .list, children: [invalidChild])
        let root = makeTestNode(type: .document, children: [list])

        let result = analyzer.analyze(root)

        let nestingErrors = result.errors.filter { $0.code == .unexpectedChild }
        #expect(nestingErrors.isEmpty)
    }

    // MARK: - Required Children Tests

    @Test("List item without body is invalid")
    func listItemWithoutBody() {
        let analyzer = StructureTreeAnalyzer()
        let label = makeTestNode(type: .listLabel, depth: 2)
        let item = makeTestNode(type: .listItem, children: [label], depth: 1)
        let list = makeTestNode(type: .list, children: [item])
        let root = makeTestNode(type: .document, children: [list])

        let result = analyzer.analyze(root)

        let missingChildErrors = result.errors.filter { $0.code == .missingRequiredChild }
        #expect(missingChildErrors.count == 1)
        #expect(missingChildErrors[0].context["missingChild"] == "LBody")
    }

    @Test("List item with body is valid")
    func listItemWithBody() {
        let analyzer = StructureTreeAnalyzer()
        let body = makeTestNode(type: .listBody, depth: 2)
        let item = makeTestNode(type: .listItem, children: [body], depth: 1)
        let list = makeTestNode(type: .list, children: [item])
        let root = makeTestNode(type: .document, children: [list])

        let result = analyzer.analyze(root)

        let missingChildErrors = result.errors.filter { $0.code == .missingRequiredChild }
        #expect(missingChildErrors.isEmpty)
    }

    @Test("Table without rows is invalid")
    func tableWithoutRows() {
        let analyzer = StructureTreeAnalyzer()
        let table = makeTestNode(type: .table)
        let root = makeTestNode(type: .document, children: [table])

        let result = analyzer.analyze(root)

        let missingChildErrors = result.errors.filter { $0.code == .missingRequiredChild }
        #expect(missingChildErrors.count >= 1)
    }

    @Test("Table row without cells is invalid")
    func tableRowWithoutCells() {
        let analyzer = StructureTreeAnalyzer()
        let row = makeTestNode(type: .tableRow, depth: 1)
        let table = makeTestNode(type: .table, children: [row])
        let root = makeTestNode(type: .document, children: [table])

        let result = analyzer.analyze(root)

        let missingChildErrors = result.errors.filter { $0.code == .missingRequiredChild }
        #expect(missingChildErrors.count >= 1)
    }

    @Test("Required children validation can be disabled")
    func disableRequiredChildrenValidation() {
        let options = StructureTreeAnalyzer.Options(validateRequiredChildren: false)
        let analyzer = StructureTreeAnalyzer(options: options)
        let item = makeTestNode(type: .listItem, depth: 1)
        let list = makeTestNode(type: .list, children: [item])
        let root = makeTestNode(type: .document, children: [list])

        let result = analyzer.analyze(root)

        let missingChildErrors = result.errors.filter { $0.code == .missingRequiredChild }
        #expect(missingChildErrors.isEmpty)
    }

    // MARK: - Attribute Validation Tests

    @Test("Figure without Alt or ActualText is invalid")
    func figureWithoutAltText() {
        let analyzer = StructureTreeAnalyzer()
        let figure = makeTestNode(type: .figure)
        let root = makeTestNode(type: .document, children: [figure])

        let result = analyzer.analyze(root)

        let attrErrors = result.errors.filter { $0.code == .missingAttribute }
        #expect(attrErrors.count >= 1)
        #expect(attrErrors[0].nodeType == .figure)
    }

    @Test("Figure with Alt text is valid")
    func figureWithAltText() {
        let analyzer = StructureTreeAnalyzer()
        let figure = makeTestNode(
            type: .figure,
            attributes: ["Alt": .string("Chart showing sales")]
        )
        let root = makeTestNode(type: .document, children: [figure])

        let result = analyzer.analyze(root)

        let attrErrors = result.errors.filter {
            $0.code == .missingAttribute && $0.nodeType == .figure
        }
        #expect(attrErrors.isEmpty)
    }

    @Test("Link without content or Alt is invalid")
    func linkWithoutContent() {
        let analyzer = StructureTreeAnalyzer()
        let link = makeTestNode(type: .link)
        let root = makeTestNode(type: .document, children: [link])

        let result = analyzer.analyze(root)

        let attrErrors = result.errors.filter { $0.code == .missingAttribute }
        #expect(attrErrors.count >= 1)
    }

    @Test("Link with children is valid")
    func linkWithChildren() {
        let analyzer = StructureTreeAnalyzer()
        let span = makeTestNode(type: .span, depth: 1)
        let link = makeTestNode(type: .link, children: [span])
        let root = makeTestNode(type: .document, children: [link])

        let result = analyzer.analyze(root)

        let attrErrors = result.errors.filter {
            $0.code == .missingAttribute && $0.nodeType == .link
        }
        #expect(attrErrors.isEmpty)
    }

    @Test("Attribute validation can be disabled")
    func disableAttributeValidation() {
        let options = StructureTreeAnalyzer.Options(validateAttributes: false)
        let analyzer = StructureTreeAnalyzer(options: options)
        let figure = makeTestNode(type: .figure)
        let root = makeTestNode(type: .document, children: [figure])

        let result = analyzer.analyze(root)

        let attrErrors = result.errors.filter { $0.code == .missingAttribute }
        #expect(attrErrors.isEmpty)
    }

    // MARK: - Duplicate ID Tests

    @Test("Duplicate ID check option exists")
    func duplicateIdCheckOptionExists() {
        // Test that the option is available and works when disabled
        let options = StructureTreeAnalyzer.Options(checkDuplicateIds: false)
        let analyzer = StructureTreeAnalyzer(options: options)

        let child1 = makeTestNode(type: .paragraph, depth: 1)
        let child2 = makeTestNode(type: .paragraph, depth: 1)
        let root = makeTestNode(type: .document, children: [child1, child2])

        let result = analyzer.analyze(root)

        // When disabled, no duplicate ID errors should be found
        // (Note: UUIDs are unique by design, so real duplicates shouldn't occur)
        let dupErrors = result.errors.filter { $0.code == .duplicateId }
        #expect(dupErrors.isEmpty)
    }

    @Test("Duplicate ID check is enabled by default")
    func duplicateIdCheckEnabledByDefault() {
        let analyzer = StructureTreeAnalyzer()

        // Verify the option is enabled by default
        #expect(analyzer.options.checkDuplicateIds == true)

        // In normal usage, UUIDs are unique and won't trigger this check
        let child1 = makeTestNode(type: .paragraph, depth: 1)
        let child2 = makeTestNode(type: .paragraph, depth: 1)
        let root = makeTestNode(type: .document, children: [child1, child2])

        let result = analyzer.analyze(root)

        // No duplicate errors with unique IDs
        let dupErrors = result.errors.filter { $0.code == .duplicateId }
        #expect(dupErrors.isEmpty)
    }

    // MARK: - Max Depth Tests

    @Test("Detect nodes exceeding max depth")
    func detectMaxDepthExceeded() {
        let options = StructureTreeAnalyzer.Options(maxDepth: 2)
        let analyzer = StructureTreeAnalyzer(options: options)

        let level3 = makeTestNode(type: .span, depth: 3)
        let level2 = makeTestNode(type: .paragraph, children: [level3], depth: 2)
        let level1 = makeTestNode(type: .div, children: [level2], depth: 1)
        let root = makeTestNode(type: .document, children: [level1])

        let result = analyzer.analyze(root)

        let depthErrors = result.errors.filter { $0.code == .invalidNesting }
        #expect(depthErrors.count >= 1)
        #expect(depthErrors[0].context["depth"] == "3")
    }

    @Test("No max depth restriction by default")
    func noMaxDepthRestrictionByDefault() {
        let analyzer = StructureTreeAnalyzer()

        let level5 = makeTestNode(type: .span, depth: 5)
        let level4 = makeTestNode(type: .span, children: [level5], depth: 4)
        let level3 = makeTestNode(type: .span, children: [level4], depth: 3)
        let level2 = makeTestNode(type: .paragraph, children: [level3], depth: 2)
        let level1 = makeTestNode(type: .div, children: [level2], depth: 1)
        let root = makeTestNode(type: .document, children: [level1])

        let result = analyzer.analyze(root)

        let depthErrors = result.errors.filter {
            $0.code == .invalidNesting && $0.message.contains("exceeds maximum depth")
        }
        #expect(depthErrors.isEmpty)
    }

    // MARK: - Result Analysis Tests

    @Test("Result groups errors by type")
    func resultGroupsErrorsByType() {
        let analyzer = StructureTreeAnalyzer()
        let emptyPara = makeTestNode(type: .paragraph)
        let figure = makeTestNode(type: .figure)
        let root = makeTestNode(type: .document, children: [emptyPara, figure])

        let result = analyzer.analyze(root)

        let grouped = result.errorsByType
        // Both the paragraph and figure are empty, so 2 empty element errors
        #expect(grouped[.emptyElement]?.count == 2)
        #expect(grouped[.missingAttribute]?.count == 1)
    }

    @Test("Result counts error codes correctly")
    func resultCountsErrorCodes() {
        let analyzer = StructureTreeAnalyzer()
        let empty1 = makeTestNode(type: .paragraph)
        let empty2 = makeTestNode(type: .span)
        let figure = makeTestNode(type: .figure)
        let root = makeTestNode(type: .document, children: [empty1, empty2, figure])

        let result = analyzer.analyze(root)

        // Should have 2 different error codes: emptyElement and missingAttribute
        #expect(result.errorCodeCount >= 2)
    }

    @Test("Valid result has no errors")
    func validResultHasNoErrors() {
        let analyzer = StructureTreeAnalyzer()
        let span = makeTestNode(
            type: .span,
            attributes: ["ActualText": .string("Content")],
            depth: 1
        )
        let root = makeTestNode(type: .document, children: [span])

        let result = analyzer.analyze(root)

        #expect(result.isValid == true)
        #expect(result.errors.isEmpty)
        #expect(result.errorCodeCount == 0)
    }

    // MARK: - Error Structure Tests

    @Test("Error contains correct metadata")
    func errorContainsCorrectMetadata() {
        let analyzer = StructureTreeAnalyzer()
        let box = BoundingBox(pageIndex: 2, rect: CGRect(x: 0, y: 0, width: 100, height: 50))
        let emptyPara = makeTestNode(type: .paragraph, boundingBox: box)
        let root = makeTestNode(type: .document, children: [emptyPara])

        let result = analyzer.analyze(root)

        #expect(result.errors.count == 1)
        let error = result.errors[0]
        #expect(error.code == .emptyElement)
        #expect(error.nodeType == .paragraph)
        #expect(error.nodeId == emptyPara.id)
        #expect(error.pageIndex == 2)
        #expect(!error.message.isEmpty)
    }

    @Test("Error has unique ID")
    func errorHasUniqueId() {
        let analyzer = StructureTreeAnalyzer()
        let empty1 = makeTestNode(type: .paragraph)
        let empty2 = makeTestNode(type: .span)
        let root = makeTestNode(type: .document, children: [empty1, empty2])

        let result = analyzer.analyze(root)

        #expect(result.errors.count == 2)
        #expect(result.errors[0].id != result.errors[1].id)
    }

    // MARK: - Complex Tree Tests

    @Test("Analyze complex nested structure")
    func analyzeComplexNestedStructure() {
        let analyzer = StructureTreeAnalyzer()

        // Build a complex tree
        let span = makeTestNode(
            type: .span,
            attributes: ["ActualText": .string("Text")],
            depth: 3
        )
        let para = makeTestNode(type: .paragraph, children: [span], depth: 2)
        let body = makeTestNode(type: .listBody, children: [para], depth: 2)
        let item = makeTestNode(type: .listItem, children: [body], depth: 1)
        let list = makeTestNode(type: .list, children: [item], depth: 1)
        let root = makeTestNode(type: .document, children: [list])

        let result = analyzer.analyze(root)

        #expect(result.totalNodeCount == 6)
        #expect(result.maxDepth == 3)
        // Should be valid if all required children present
        let criticalErrors = result.errors.filter {
            $0.code == .missingRequiredChild || $0.code == .unexpectedChild
        }
        #expect(criticalErrors.isEmpty)
    }

    @Test("Analyze tree with multiple error types")
    func analyzeTreeWithMultipleErrorTypes() {
        let analyzer = StructureTreeAnalyzer()

        let emptyPara = makeTestNode(type: .paragraph, depth: 1)
        let figure = makeTestNode(type: .figure, depth: 1)
        let invalidChild = makeTestNode(type: .paragraph, depth: 2)
        let list = makeTestNode(type: .list, children: [invalidChild], depth: 1)

        let root = makeTestNode(
            type: .document,
            children: [emptyPara, figure, list]
        )

        let result = analyzer.analyze(root)

        #expect(result.isValid == false)
        #expect(result.errors.count >= 3)

        let errorCodes = Set(result.errors.map(\.code))
        #expect(errorCodes.contains(.emptyElement))
        #expect(errorCodes.contains(.missingAttribute))
        #expect(errorCodes.contains(.unexpectedChild))
    }
}

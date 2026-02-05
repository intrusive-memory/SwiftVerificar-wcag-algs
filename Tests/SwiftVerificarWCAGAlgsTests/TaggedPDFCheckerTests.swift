import Testing
import Foundation
@testable import SwiftVerificarWCAGAlgs

@Suite("TaggedPDFChecker Tests")
struct TaggedPDFCheckerTests {

    // MARK: - Initialization Tests

    @Test("TaggedPDFChecker default initialization")
    func testDefaultInitialization() {
        let checker = TaggedPDFChecker()

        #expect(checker.requirement == .documentMustBeTagged)
        #expect(checker.minimumStructureElements == 1)
        #expect(checker.requireDocumentRoot == true)
        #expect(checker.requireAllContentTagged == true)
    }

    @Test("TaggedPDFChecker custom initialization")
    func testCustomInitialization() {
        let checker = TaggedPDFChecker(
            minimumStructureElements: 5,
            requireDocumentRoot: false,
            requireAllContentTagged: false
        )

        #expect(checker.minimumStructureElements == 5)
        #expect(checker.requireDocumentRoot == false)
        #expect(checker.requireAllContentTagged == false)
    }

    @Test("TaggedPDFChecker strict preset")
    func testStrictPreset() {
        let checker = TaggedPDFChecker.strict

        #expect(checker.minimumStructureElements == 1)
        #expect(checker.requireDocumentRoot == true)
        #expect(checker.requireAllContentTagged == true)
    }

    @Test("TaggedPDFChecker lenient preset")
    func testLenientPreset() {
        let checker = TaggedPDFChecker.lenient

        #expect(checker.minimumStructureElements == 1)
        #expect(checker.requireDocumentRoot == false)
        #expect(checker.requireAllContentTagged == false)
    }

    @Test("TaggedPDFChecker basic preset")
    func testBasicPreset() {
        let checker = TaggedPDFChecker.basic

        #expect(checker.minimumStructureElements == 1)
        #expect(checker.requireDocumentRoot == false)
        #expect(checker.requireAllContentTagged == false)
    }

    // MARK: - Valid Document Tests

    @Test("Check valid document with proper structure")
    func testValidDocument() {
        let checker = TaggedPDFChecker()

        let paragraph = ContentNode(type: .paragraph, depth: 2)
        let heading = ContentNode(type: .h1, depth: 2)

        let document = ContentNode(
            type: .document,
            children: [paragraph, heading],
            depth: 1
        )

        let result = checker.check(document)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
        #expect(result.context?.contains("properly tagged") == true)
    }

    @Test("Check valid document with nested structure")
    func testValidNestedDocument() {
        let checker = TaggedPDFChecker()

        let innerParagraph = ContentNode(type: .paragraph, depth: 3)
        let div = ContentNode(type: .div, children: [innerParagraph], depth: 2)
        let document = ContentNode(type: .document, children: [div], depth: 1)

        let result = checker.check(document)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    @Test("Check document with multiple content types")
    func testDocumentWithMultipleContentTypes() {
        let checker = TaggedPDFChecker()

        let children: [any SemanticNode] = [
            ContentNode(type: .h1, depth: 2),
            ContentNode(type: .paragraph, depth: 2),
            TableNode(depth: 2),
            FigureNode(depth: 2),
            ListNode(depth: 2)
        ]

        let document = ContentNode(type: .document, children: children, depth: 1)

        let result = checker.check(document)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    // MARK: - Invalid Document Root Tests

    @Test("Check document with wrong root type")
    func testWrongRootType() {
        let checker = TaggedPDFChecker()

        let paragraph = ContentNode(type: .paragraph, depth: 1)

        let result = checker.check(paragraph)

        #expect(result.passed == false)
        #expect(result.violations.count >= 1)

        let hasRootViolation = result.violations.contains { violation in
            violation.description.contains("Document root")
        }
        #expect(hasRootViolation)
    }

    @Test("Check document with wrong root type - lenient mode")
    func testWrongRootTypeLenient() {
        let checker = TaggedPDFChecker.lenient

        let paragraph = ContentNode(
            type: .paragraph,
            children: [ContentNode(type: .span, depth: 2)],
            depth: 1
        )

        let result = checker.check(paragraph)

        // Lenient mode doesn't require document root, so may pass if structure exists
        #expect(result.violations.filter { $0.description.contains("Document root") }.isEmpty)
    }

    // MARK: - Empty Document Tests

    @Test("Check empty document")
    func testEmptyDocument() {
        let checker = TaggedPDFChecker()

        let emptyDocument = ContentNode(type: .document, children: [], depth: 1)

        let result = checker.check(emptyDocument)

        #expect(result.passed == false)
        #expect(result.violations.count >= 1)

        let hasEmptyViolation = result.violations.contains { violation in
            violation.description.contains("empty")
        }
        #expect(hasEmptyViolation)
    }

    @Test("Check document below minimum elements")
    func testBelowMinimumElements() {
        let checker = TaggedPDFChecker(minimumStructureElements: 5)

        let paragraph = ContentNode(type: .paragraph, depth: 2)
        let document = ContentNode(type: .document, children: [paragraph], depth: 1)

        let result = checker.check(document)

        #expect(result.passed == false)

        let hasMinimumViolation = result.violations.contains { violation in
            violation.description.contains("minimum")
        }
        #expect(hasMinimumViolation)
    }

    // MARK: - Missing Required Elements Tests

    @Test("Check document with no content elements")
    func testNoContentElements() {
        let checker = TaggedPDFChecker()

        // Document with only artifacts
        let artifact = ContentNode(type: .artifact, depth: 2)
        let document = ContentNode(type: .document, children: [artifact], depth: 1)

        let result = checker.check(document)

        #expect(result.passed == false)

        let hasMissingElementsViolation = result.violations.contains { violation in
            violation.description.contains("missing required structure elements")
        }
        #expect(hasMissingElementsViolation)
    }

    @Test("Check document with only headers and footers")
    func testOnlyHeadersAndFooters() {
        let checker = TaggedPDFChecker()

        let children: [any SemanticNode] = [
            ContentNode(type: .documentHeader, depth: 2),
            ContentNode(type: .documentFooter, depth: 2)
        ]

        let document = ContentNode(type: .document, children: children, depth: 1)

        let result = checker.check(document)

        #expect(result.passed == false)
    }

    // MARK: - Untagged Content Tests

    @Test("Check document with artifacts - strict mode")
    func testDocumentWithArtifactsStrict() {
        let checker = TaggedPDFChecker.strict

        let children: [any SemanticNode] = [
            ContentNode(type: .paragraph, depth: 2),
            ContentNode(type: .artifact, depth: 2)
        ]

        let document = ContentNode(type: .document, children: children, depth: 1)

        let result = checker.check(document)

        // Strict mode flags artifacts as untagged content
        let hasArtifactViolation = result.violations.contains { violation in
            violation.description.contains("untagged")
        }
        #expect(hasArtifactViolation)
    }

    @Test("Check document with artifacts - lenient mode")
    func testDocumentWithArtifactsLenient() {
        let checker = TaggedPDFChecker.lenient

        let children: [any SemanticNode] = [
            ContentNode(type: .paragraph, depth: 2),
            ContentNode(type: .artifact, depth: 2)
        ]

        let document = ContentNode(type: .document, children: children, depth: 1)

        let result = checker.check(document)

        // Lenient mode doesn't flag artifacts
        let hasArtifactViolation = result.violations.contains { violation in
            violation.description.contains("artifact")
        }
        #expect(!hasArtifactViolation)
    }

    @Test("Check document with empty elements")
    func testDocumentWithEmptyElements() {
        let checker = TaggedPDFChecker.strict

        var emptyNode = ContentNode(type: .span, depth: 2)
        emptyNode.errorCodes.insert(.emptyElement)

        let children: [any SemanticNode] = [
            ContentNode(type: .paragraph, depth: 2),
            emptyNode
        ]

        let document = ContentNode(type: .document, children: children, depth: 1)

        let result = checker.check(document)

        let hasEmptyViolation = result.violations.contains { violation in
            violation.description.contains("untagged")
        }
        #expect(hasEmptyViolation)
    }

    // MARK: - Invalid Elements Tests

    @Test("Check document with suspicious empty elements")
    func testSuspiciousEmptyElements() {
        let checker = TaggedPDFChecker()

        // Empty element with no content and no bounding box
        let suspiciousNode = ContentNode(
            type: .span,
            boundingBox: nil,
            children: [],
            depth: 2
        )

        let document = ContentNode(
            type: .document,
            children: [
                ContentNode(type: .paragraph, depth: 2),
                suspiciousNode
            ],
            depth: 1
        )

        let result = checker.check(document)

        // Should detect suspicious element
        let hasSuspiciousViolation = result.violations.contains { violation in
            violation.description.contains("invalid") || violation.description.contains("unrecognized")
        }
        #expect(hasSuspiciousViolation)
    }

    // MARK: - Element Counting Tests

    @Test("Count structure elements correctly")
    func testElementCounting() {
        let checker = TaggedPDFChecker(minimumStructureElements: 4)

        let children: [any SemanticNode] = [
            ContentNode(type: .h1, depth: 2),
            ContentNode(type: .paragraph, depth: 2),
            ContentNode(type: .paragraph, depth: 2)
        ]

        let document = ContentNode(type: .document, children: children, depth: 1)

        let result = checker.check(document)

        // Document (1) + 3 children = 4 elements total
        #expect(result.passed == true)
    }

    @Test("Count nested structure elements")
    func testNestedElementCounting() {
        let checker = TaggedPDFChecker(minimumStructureElements: 5)

        let innerSpan = ContentNode(type: .span, depth: 3)
        let paragraph = ContentNode(type: .paragraph, children: [innerSpan], depth: 2)
        let div = ContentNode(type: .div, children: [paragraph], depth: 2)
        let document = ContentNode(type: .document, children: [div], depth: 1)

        let result = checker.check(document)

        // Document (1) + Div (1) + Paragraph (1) + Span (1) = 4 elements
        #expect(result.passed == false) // Less than 5
    }

    // MARK: - Multi-Node Check Tests

    @Test("Check multiple valid documents")
    func testMultipleValidDocuments() {
        let checker = TaggedPDFChecker()

        let doc1 = ContentNode(
            type: .document,
            children: [ContentNode(type: .paragraph, depth: 2)],
            depth: 1
        )

        let doc2 = ContentNode(
            type: .document,
            children: [ContentNode(type: .h1, depth: 2)],
            depth: 1
        )

        let result = checker.check([doc1, doc2])

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    @Test("Check multiple documents with mixed results")
    func testMultipleDocumentsMixedResults() {
        let checker = TaggedPDFChecker()

        let validDoc = ContentNode(
            type: .document,
            children: [ContentNode(type: .paragraph, depth: 2)],
            depth: 1
        )

        let emptyDoc = ContentNode(type: .document, children: [], depth: 1)

        let result = checker.check([validDoc, emptyDoc])

        #expect(result.passed == false)
        #expect(result.violations.count >= 1)
    }

    // MARK: - Edge Cases

    @Test("Check deeply nested structure")
    func testDeeplyNestedStructure() {
        let checker = TaggedPDFChecker()

        var current: any SemanticNode = ContentNode(type: .span, depth: 10)
        for depth in (2..<10).reversed() {
            current = ContentNode(type: .div, children: [current], depth: depth)
        }
        let document = ContentNode(type: .document, children: [current], depth: 1)

        let result = checker.check(document)

        // Should pass as long as it has structure
        #expect(result.passed == true)
    }

    @Test("Check document with all semantic types")
    func testDocumentWithAllSemanticTypes() {
        let checker = TaggedPDFChecker()

        let children: [any SemanticNode] = [
            ContentNode(type: .h1, depth: 2),
            ContentNode(type: .paragraph, depth: 2),
            ContentNode(type: .div, depth: 2),
            ContentNode(type: .blockQuote, depth: 2),
            TableNode(depth: 2),
            FigureNode(depth: 2),
            ListNode(depth: 2)
        ]

        let document = ContentNode(type: .document, children: children, depth: 1)

        let result = checker.check(document)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    @Test("Check violation includes node information")
    func testViolationIncludesNodeInfo() {
        let checker = TaggedPDFChecker()

        let emptyDoc = ContentNode(type: .document, children: [], depth: 1)

        let result = checker.check(emptyDoc)

        #expect(result.passed == false)
        #expect(!result.violations.isEmpty)

        let violation = result.violations.first!
        #expect(violation.nodeId == emptyDoc.id)
        #expect(violation.nodeType == .document)
    }

    @Test("Check result context includes element count")
    func testResultContextIncludesCount() {
        let checker = TaggedPDFChecker()

        let children: [any SemanticNode] = [
            ContentNode(type: .paragraph, depth: 2),
            ContentNode(type: .paragraph, depth: 2)
        ]

        let document = ContentNode(type: .document, children: children, depth: 1)

        let result = checker.check(document)

        #expect(result.passed == true)
        #expect(result.context != nil)
        // Context should mention element count
        #expect(result.context?.contains("structure element") == true)
    }

    // MARK: - Specific Requirement Tests

    @Test("Verify requirement is documentMustBeTagged")
    func testRequirement() {
        let checker = TaggedPDFChecker()
        #expect(checker.requirement == .documentMustBeTagged)
    }

    @Test("Check empty array returns passing")
    func testEmptyArray() {
        let checker = TaggedPDFChecker()
        let result = checker.check([])

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }
}

import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

/// Tests for SemanticNode protocol, SemanticErrorCode, and AttributeValue.
@Suite("SemanticNode Protocol Tests")
struct SemanticNodeTests {

    // MARK: - Test Helpers

    func makeContentNode(
        type: SemanticType = .paragraph,
        depth: Int = 1,
        children: [any SemanticNode] = [],
        attributes: AttributesDictionary = [:]
    ) -> ContentNode {
        ContentNode(
            type: type,
            children: children,
            attributes: attributes,
            depth: depth
        )
    }

    // MARK: - SemanticErrorCode Tests

    @Test("SemanticErrorCode has expected cases in general range")
    func generalErrorCodes() {
        #expect(SemanticErrorCode.missingAltText.rawValue == 1000)
        #expect(SemanticErrorCode.emptyElement.rawValue == 1001)
        #expect(SemanticErrorCode.invalidNesting.rawValue == 1002)
        #expect(SemanticErrorCode.duplicateId.rawValue == 1007)
    }

    @Test("SemanticErrorCode has expected cases in table range")
    func tableErrorCodes() {
        #expect(SemanticErrorCode.tableCellBelowNextRow.rawValue == 1100)
        #expect(SemanticErrorCode.tableRowCountMismatch.rawValue == 1104)
        #expect(SemanticErrorCode.tableMissingHeaders.rawValue == 1108)
        #expect(SemanticErrorCode.tableIrregularStructure.rawValue == 1109)
    }

    @Test("SemanticErrorCode has expected cases in list range")
    func listErrorCodes() {
        #expect(SemanticErrorCode.listItemMissingLabel.rawValue == 1200)
        #expect(SemanticErrorCode.listItemMissingBody.rawValue == 1201)
        #expect(SemanticErrorCode.listNestingTooDeep.rawValue == 1204)
    }

    @Test("SemanticErrorCode has expected cases in heading range")
    func headingErrorCodes() {
        #expect(SemanticErrorCode.headingLevelSkipped.rawValue == 1300)
        #expect(SemanticErrorCode.multipleH1Headings.rawValue == 1301)
        #expect(SemanticErrorCode.emptyHeading.rawValue == 1302)
    }

    @Test("SemanticErrorCode has expected cases in figure range")
    func figureErrorCodes() {
        #expect(SemanticErrorCode.figureMissingAltText.rawValue == 1400)
        #expect(SemanticErrorCode.figureCaptionNotAssociated.rawValue == 1401)
    }

    @Test("SemanticErrorCode is Codable")
    func errorCodeCodable() throws {
        let code = SemanticErrorCode.missingAltText
        let encoder = JSONEncoder()
        let data = try encoder.encode(code)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SemanticErrorCode.self, from: data)
        #expect(decoded == code)
    }

    // MARK: - AttributeValue Tests

    @Test("AttributeValue.string stores and retrieves value")
    func attributeValueString() {
        let value = AttributeValue.string("test")
        #expect(value.stringValue == "test")
        #expect(value.boolValue == nil)
        #expect(value.intValue == nil)
    }

    @Test("AttributeValue.bool stores and retrieves value")
    func attributeValueBool() {
        let value = AttributeValue.bool(true)
        #expect(value.boolValue == true)
        #expect(value.stringValue == nil)
    }

    @Test("AttributeValue.int stores and retrieves value")
    func attributeValueInt() {
        let value = AttributeValue.int(42)
        #expect(value.intValue == 42)
        #expect(value.doubleValue == nil)
    }

    @Test("AttributeValue.double stores and retrieves value")
    func attributeValueDouble() {
        let value = AttributeValue.double(3.14)
        #expect(value.doubleValue == 3.14)
        #expect(value.intValue == nil)
    }

    @Test("AttributeValue.array stores and retrieves values")
    func attributeValueArray() {
        let value = AttributeValue.array([.string("a"), .int(1)])
        #expect(value.arrayValue?.count == 2)
        #expect(value.stringValue == nil)
    }

    @Test("AttributeValue.null has nil accessors")
    func attributeValueNull() {
        let value = AttributeValue.null
        #expect(value.stringValue == nil)
        #expect(value.boolValue == nil)
        #expect(value.intValue == nil)
        #expect(value.doubleValue == nil)
        #expect(value.arrayValue == nil)
    }

    @Test("AttributeValue is Codable")
    func attributeValueCodable() throws {
        let values: [AttributeValue] = [
            .string("test"),
            .bool(true),
            .int(42),
            .double(3.14),
            .array([.string("a")]),
            .null
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for value in values {
            let data = try encoder.encode(value)
            let decoded = try decoder.decode(AttributeValue.self, from: data)
            #expect(decoded == value)
        }
    }

    @Test("AttributeValue is Hashable")
    func attributeValueHashable() {
        let value1 = AttributeValue.string("test")
        let value2 = AttributeValue.string("test")
        let value3 = AttributeValue.string("other")

        var set: Set<AttributeValue> = []
        set.insert(value1)
        set.insert(value2)
        set.insert(value3)

        #expect(set.count == 2)
    }

    // MARK: - SemanticNode Protocol Default Implementation Tests

    @Test("pageIndex returns boundingBox page index")
    func pageIndexFromBoundingBox() {
        let box = BoundingBox(pageIndex: 3, rect: CGRect(x: 0, y: 0, width: 100, height: 50))
        let node = ContentNode(type: .paragraph, boundingBox: box, depth: 1)
        #expect(node.pageIndex == 3)
    }

    @Test("pageIndex returns nil when no bounding box")
    func pageIndexNilWhenNoBoundingBox() {
        let node = makeContentNode()
        #expect(node.pageIndex == nil)
    }

    @Test("hasChildren returns true when children exist")
    func hasChildrenTrue() {
        let child = makeContentNode()
        let parent = ContentNode(type: .div, children: [child], depth: 0)
        #expect(parent.hasChildren)
    }

    @Test("hasChildren returns false when no children")
    func hasChildrenFalse() {
        let node = makeContentNode()
        #expect(!node.hasChildren)
    }

    @Test("childCount returns correct count")
    func childCountCorrect() {
        let child1 = makeContentNode()
        let child2 = makeContentNode()
        let parent = ContentNode(type: .div, children: [child1, child2], depth: 0)
        #expect(parent.childCount == 2)
    }

    @Test("hasErrors returns true when errorCodes is not empty")
    func hasErrorsTrue() {
        var node = makeContentNode()
        node.addError(.missingAltText)
        #expect(node.hasErrors)
    }

    @Test("hasErrors returns false when errorCodes is empty")
    func hasErrorsFalse() {
        let node = makeContentNode()
        #expect(!node.hasErrors)
    }

    // MARK: - Attribute Accessor Tests

    @Test("altText returns Alt attribute value")
    func altTextFromAttributes() {
        let node = ContentNode(
            type: .figure,
            attributes: ["Alt": .string("Image description")],
            depth: 1
        )
        #expect(node.altText == "Image description")
    }

    @Test("altText returns nil when not present")
    func altTextNil() {
        let node = makeContentNode()
        #expect(node.altText == nil)
    }

    @Test("actualText returns ActualText attribute value")
    func actualTextFromAttributes() {
        let node = ContentNode(
            type: .figure,
            attributes: ["ActualText": .string("Replacement text")],
            depth: 1
        )
        #expect(node.actualText == "Replacement text")
    }

    @Test("language returns Lang attribute value")
    func languageFromAttributes() {
        let node = ContentNode(
            type: .paragraph,
            attributes: ["Lang": .string("en-US")],
            depth: 1
        )
        #expect(node.language == "en-US")
    }

    @Test("title returns Title attribute value")
    func titleFromAttributes() {
        let node = ContentNode(
            type: .section,
            attributes: ["Title": .string("Section Title")],
            depth: 1
        )
        #expect(node.title == "Section Title")
    }

    @Test("hasTextAlternative returns true with Alt")
    func hasTextAlternativeWithAlt() {
        let node = ContentNode(
            type: .figure,
            attributes: ["Alt": .string("Description")],
            depth: 1
        )
        #expect(node.hasTextAlternative)
    }

    @Test("hasTextAlternative returns true with ActualText")
    func hasTextAlternativeWithActualText() {
        let node = ContentNode(
            type: .figure,
            attributes: ["ActualText": .string("Replacement")],
            depth: 1
        )
        #expect(node.hasTextAlternative)
    }

    @Test("hasTextAlternative returns false when empty")
    func hasTextAlternativeFalseWhenEmpty() {
        let node = ContentNode(
            type: .figure,
            attributes: ["Alt": .string("")],
            depth: 1
        )
        #expect(!node.hasTextAlternative)
    }

    @Test("textDescription prefers Alt over ActualText")
    func textDescriptionPrefersAlt() {
        let node = ContentNode(
            type: .figure,
            attributes: [
                "Alt": .string("Alt text"),
                "ActualText": .string("Actual text"),
                "Title": .string("Title text")
            ],
            depth: 1
        )
        #expect(node.textDescription == "Alt text")
    }

    @Test("textDescription falls back to ActualText")
    func textDescriptionFallsBackToActualText() {
        let node = ContentNode(
            type: .figure,
            attributes: [
                "ActualText": .string("Actual text"),
                "Title": .string("Title text")
            ],
            depth: 1
        )
        #expect(node.textDescription == "Actual text")
    }

    @Test("textDescription falls back to Title")
    func textDescriptionFallsBackToTitle() {
        let node = ContentNode(
            type: .figure,
            attributes: ["Title": .string("Title text")],
            depth: 1
        )
        #expect(node.textDescription == "Title text")
    }

    // MARK: - Descendant Tests

    @Test("allDescendants includes self and children recursively")
    func allDescendantsRecursive() {
        let grandchild = makeContentNode(type: .span, depth: 3)
        let child = ContentNode(type: .paragraph, children: [grandchild], depth: 2)
        let root = ContentNode(type: .document, children: [child], depth: 0)

        let descendants = root.allDescendants
        #expect(descendants.count == 3)
    }

    @Test("descendants(ofType:) filters by type")
    func descendantsOfType() {
        let span1 = makeContentNode(type: .span, depth: 2)
        let span2 = makeContentNode(type: .span, depth: 2)
        let para = ContentNode(type: .paragraph, children: [span1, span2], depth: 1)
        let root = ContentNode(type: .document, children: [para], depth: 0)

        let spans = root.descendants(ofType: .span)
        #expect(spans.count == 2)
    }

    @Test("firstDescendant(where:) finds matching node")
    func firstDescendantWhere() {
        let target = makeContentNode(type: .link, depth: 3)
        let para = ContentNode(type: .paragraph, children: [target], depth: 2)
        let root = ContentNode(type: .document, children: [para], depth: 0)

        let found = root.firstDescendant { $0.type == .link }
        #expect(found != nil)
        #expect(found?.type == .link)
    }

    @Test("firstDescendant(where:) returns nil when not found")
    func firstDescendantWhereNotFound() {
        let para = makeContentNode(type: .paragraph, depth: 1)
        let root = ContentNode(type: .document, children: [para], depth: 0)

        let found = root.firstDescendant { $0.type == .figure }
        #expect(found == nil)
    }

    @Test("descendantCount returns total count including self")
    func descendantCountTotal() {
        let grandchild = makeContentNode(type: .span, depth: 3)
        let child = ContentNode(type: .paragraph, children: [grandchild], depth: 2)
        let root = ContentNode(type: .document, children: [child], depth: 0)

        #expect(root.descendantCount == 3)
    }

    @Test("maxDepth returns maximum depth in subtree")
    func maxDepthComputed() {
        let deep = makeContentNode(type: .span, depth: 5)
        let mid = ContentNode(type: .paragraph, children: [deep], depth: 3)
        let root = ContentNode(type: .document, children: [mid], depth: 0)

        #expect(root.maxDepth == 5)
    }

    // MARK: - Error Management Tests

    @Test("addError inserts error code")
    func addErrorInserts() {
        var node = makeContentNode()
        node.addError(.missingAltText)
        #expect(node.errorCodes.contains(.missingAltText))
    }

    @Test("removeError removes error code")
    func removeErrorRemoves() {
        var node = makeContentNode()
        node.addError(.missingAltText)
        node.addError(.emptyElement)
        node.removeError(.missingAltText)
        #expect(!node.errorCodes.contains(.missingAltText))
        #expect(node.errorCodes.contains(.emptyElement))
    }

    @Test("clearErrors removes all error codes")
    func clearErrorsRemovesAll() {
        var node = makeContentNode()
        node.addError(.missingAltText)
        node.addError(.emptyElement)
        node.clearErrors()
        #expect(node.errorCodes.isEmpty)
    }
}

import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

/// Tests for the ListNode struct and ListKind enum.
@Suite("ListNode Tests")
struct ListNodeTests {

    // MARK: - Test Helpers

    func makeBoundingBox(page: Int = 0) -> BoundingBox {
        BoundingBox(pageIndex: page, rect: CGRect(x: 0, y: 0, width: 200, height: 100))
    }

    func makeLabel(text: String = "1.") -> ContentNode {
        let chunk = TextChunk(
            boundingBox: makeBoundingBox(),
            value: text,
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let line = TextLine(boundingBox: makeBoundingBox(), chunks: [chunk])
        let block = TextBlock(boundingBox: makeBoundingBox(), lines: [line])
        return ContentNode(
            type: .listLabel,
            depth: 3,
            textBlocks: [block]
        )
    }

    func makeBody(text: String = "List item content") -> ContentNode {
        let chunk = TextChunk(
            boundingBox: makeBoundingBox(),
            value: text,
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let line = TextLine(boundingBox: makeBoundingBox(), chunks: [chunk])
        let block = TextBlock(boundingBox: makeBoundingBox(), lines: [line])
        return ContentNode(
            type: .listBody,
            depth: 3,
            textBlocks: [block]
        )
    }

    func makeListItem(label: String? = "1.", body: String? = "Content") -> ContentNode {
        var children: [any SemanticNode] = []
        if let labelText = label {
            children.append(makeLabel(text: labelText))
        }
        if let bodyText = body {
            children.append(makeBody(text: bodyText))
        }
        return ContentNode(
            type: .listItem,
            children: children,
            depth: 2
        )
    }

    // MARK: - ListKind Tests

    @Test("ListKind.unordered is not ordered")
    func listKindUnorderedNotOrdered() {
        #expect(!ListKind.unordered.isOrdered)
        #expect(ListKind.unordered.isUnordered)
    }

    @Test("ListKind.orderedArabic is ordered")
    func listKindArabicIsOrdered() {
        #expect(ListKind.orderedArabic.isOrdered)
        #expect(!ListKind.orderedArabic.isUnordered)
    }

    @Test("ListKind.orderedRomanUpper is ordered")
    func listKindRomanUpperIsOrdered() {
        #expect(ListKind.orderedRomanUpper.isOrdered)
    }

    @Test("ListKind.orderedRomanLower is ordered")
    func listKindRomanLowerIsOrdered() {
        #expect(ListKind.orderedRomanLower.isOrdered)
    }

    @Test("ListKind.orderedAlphaUpper is ordered")
    func listKindAlphaUpperIsOrdered() {
        #expect(ListKind.orderedAlphaUpper.isOrdered)
    }

    @Test("ListKind.orderedAlphaLower is ordered")
    func listKindAlphaLowerIsOrdered() {
        #expect(ListKind.orderedAlphaLower.isOrdered)
    }

    @Test("ListKind.orderedCircled is ordered")
    func listKindCircledIsOrdered() {
        #expect(ListKind.orderedCircled.isOrdered)
    }

    @Test("ListKind.unknown is not ordered")
    func listKindUnknownNotOrdered() {
        #expect(!ListKind.unknown.isOrdered)
        #expect(!ListKind.unknown.isUnordered)
    }

    @Test("ListKind is Codable")
    func listKindCodable() throws {
        let kinds: [ListKind] = [
            .unordered, .orderedArabic, .orderedRomanUpper,
            .orderedRomanLower, .orderedAlphaUpper, .orderedAlphaLower,
            .orderedCircled, .unknown
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for kind in kinds {
            let data = try encoder.encode(kind)
            let decoded = try decoder.decode(ListKind.self, from: data)
            #expect(decoded == kind)
        }
    }

    // MARK: - ListNode Initialization Tests

    @Test("ListNode initializes with default values")
    func initWithDefaults() {
        let list = ListNode()
        #expect(list.type == .list)
        #expect(list.listKind == .unknown)
        #expect(list.startNumber == nil)
        #expect(list.nestingLevel == 0)
        #expect(list.children.isEmpty)
    }

    @Test("ListNode initializes with listKind and depth")
    func initWithKindAndDepth() {
        let list = ListNode(listKind: .orderedArabic, depth: 2)
        #expect(list.listKind == .orderedArabic)
        #expect(list.depth == 2)
    }

    @Test("ListNode initializes with all properties")
    func initWithAllProperties() {
        let id = UUID()
        let box = makeBoundingBox()
        let item = makeListItem()

        let list = ListNode(
            id: id,
            boundingBox: box,
            children: [item],
            attributes: ["Lang": .string("en")],
            depth: 1,
            errorCodes: [.listItemMissingLabel],
            listKind: .orderedArabic,
            startNumber: 5,
            nestingLevel: 2
        )

        #expect(list.id == id)
        #expect(list.type == .list)
        #expect(list.boundingBox == box)
        #expect(list.children.count == 1)
        #expect(list.listKind == .orderedArabic)
        #expect(list.startNumber == 5)
        #expect(list.nestingLevel == 2)
        #expect(list.errorCodes.contains(.listItemMissingLabel))
    }

    // MARK: - SemanticNode Protocol Conformance Tests

    @Test("ListNode type is always list")
    func typeIsList() {
        let list = ListNode()
        #expect(list.type == .list)
    }

    @Test("ListNode conforms to SemanticNode")
    func conformsToSemanticNode() {
        let list: any SemanticNode = ListNode()
        #expect(list.type == .list)
    }

    @Test("ListNode is Sendable")
    func sendable() {
        let list = ListNode()
        let sendable: any Sendable = list
        #expect(sendable is ListNode)
    }

    // MARK: - Item Accessor Tests

    @Test("items returns LI children")
    func itemsReturnsLI() {
        let item1 = makeListItem(label: "1.")
        let item2 = makeListItem(label: "2.")
        let list = ListNode(children: [item1, item2])

        #expect(list.items.count == 2)
    }

    @Test("items excludes non-LI children")
    func itemsExcludesNonLI() {
        let item = makeListItem()
        let other = ContentNode(type: .paragraph, depth: 2)
        let list = ListNode(children: [item, other])

        #expect(list.items.count == 1)
    }

    @Test("itemCount returns correct count")
    func itemCountCorrect() {
        let item1 = makeListItem()
        let item2 = makeListItem()
        let item3 = makeListItem()
        let list = ListNode(children: [item1, item2, item3])

        #expect(list.itemCount == 3)
    }

    @Test("hasItems returns true when items exist")
    func hasItemsTrue() {
        let list = ListNode(children: [makeListItem()])
        #expect(list.hasItems)
    }

    @Test("hasItems returns false when empty")
    func hasItemsFalse() {
        let list = ListNode()
        #expect(!list.hasItems)
    }

    // MARK: - Label and Body Tests

    @Test("label(for:) returns label child")
    func labelForItem() {
        let item = makeListItem(label: "1.", body: "Content")
        let list = ListNode(children: [item])

        let label = list.label(for: list.items[0])
        #expect(label != nil)
        #expect(label?.type == .listLabel)
    }

    @Test("label(for:) returns nil for item without label")
    func labelForItemWithoutLabel() {
        let item = makeListItem(label: nil, body: "Content")
        let list = ListNode(children: [item])

        let label = list.label(for: list.items[0])
        #expect(label == nil)
    }

    @Test("label(for:) returns nil for non-item")
    func labelForNonItem() {
        let para = ContentNode(type: .paragraph, depth: 2)
        let list = ListNode()

        let label = list.label(for: para)
        #expect(label == nil)
    }

    @Test("body(for:) returns body child")
    func bodyForItem() {
        let item = makeListItem(label: "1.", body: "Content")
        let list = ListNode(children: [item])

        let body = list.body(for: list.items[0])
        #expect(body != nil)
        #expect(body?.type == .listBody)
    }

    @Test("body(for:) returns nil for item without body")
    func bodyForItemWithoutBody() {
        let item = makeListItem(label: "1.", body: nil)
        let list = ListNode(children: [item])

        let body = list.body(for: list.items[0])
        #expect(body == nil)
    }

    @Test("labels returns all label nodes")
    func labelsReturnsAll() {
        let item1 = makeListItem(label: "1.")
        let item2 = makeListItem(label: "2.")
        let item3 = makeListItem(label: nil, body: "No label")
        let list = ListNode(children: [item1, item2, item3])

        #expect(list.labels.count == 2)
    }

    @Test("bodies returns all body nodes")
    func bodiesReturnsAll() {
        let item1 = makeListItem(label: "1.", body: "First")
        let item2 = makeListItem(label: "2.", body: "Second")
        let item3 = makeListItem(label: "3.", body: nil)
        let list = ListNode(children: [item1, item2, item3])

        #expect(list.bodies.count == 2)
    }

    @Test("labelTexts returns all label text values")
    func labelTextsReturnsAll() {
        let item1 = makeListItem(label: "1.")
        let item2 = makeListItem(label: "2.")
        let list = ListNode(children: [item1, item2])

        #expect(list.labelTexts.count == 2)
        #expect(list.labelTexts[0] == "1.")
        #expect(list.labelTexts[1] == "2.")
    }

    // MARK: - Structure Analysis Tests

    @Test("allItemsHaveLabels returns true when all have labels")
    func allItemsHaveLabelsTrue() {
        let item1 = makeListItem(label: "1.")
        let item2 = makeListItem(label: "2.")
        let list = ListNode(children: [item1, item2])

        #expect(list.allItemsHaveLabels)
    }

    @Test("allItemsHaveLabels returns false when some missing")
    func allItemsHaveLabelsFalse() {
        let item1 = makeListItem(label: "1.")
        let item2 = makeListItem(label: nil, body: "Content")
        let list = ListNode(children: [item1, item2])

        #expect(!list.allItemsHaveLabels)
    }

    @Test("allItemsHaveBodies returns true when all have bodies")
    func allItemsHaveBodiesTrue() {
        let item1 = makeListItem(label: "1.", body: "First")
        let item2 = makeListItem(label: "2.", body: "Second")
        let list = ListNode(children: [item1, item2])

        #expect(list.allItemsHaveBodies)
    }

    @Test("allItemsHaveBodies returns false when some missing")
    func allItemsHaveBodiesFalse() {
        let item1 = makeListItem(label: "1.", body: "Content")
        let item2 = makeListItem(label: "2.", body: nil)
        let list = ListNode(children: [item1, item2])

        #expect(!list.allItemsHaveBodies)
    }

    @Test("hasProperStructure returns true when all complete")
    func hasProperStructureTrue() {
        let item1 = makeListItem(label: "1.", body: "First")
        let item2 = makeListItem(label: "2.", body: "Second")
        let list = ListNode(children: [item1, item2])

        #expect(list.hasProperStructure)
    }

    @Test("hasProperStructure returns false when missing parts")
    func hasProperStructureFalse() {
        let item1 = makeListItem(label: "1.", body: "Content")
        let item2 = makeListItem(label: nil, body: "No label")
        let list = ListNode(children: [item1, item2])

        #expect(!list.hasProperStructure)
    }

    @Test("itemsMissingLabels returns items without labels")
    func itemsMissingLabelsCorrect() {
        let item1 = makeListItem(label: "1.", body: "Content")
        let item2 = makeListItem(label: nil, body: "No label")
        let item3 = makeListItem(label: nil, body: "Also no label")
        let list = ListNode(children: [item1, item2, item3])

        #expect(list.itemsMissingLabels.count == 2)
    }

    @Test("itemsMissingBodies returns items without bodies")
    func itemsMissingBodiesCorrect() {
        let item1 = makeListItem(label: "1.", body: "Content")
        let item2 = makeListItem(label: "2.", body: nil)
        let list = ListNode(children: [item1, item2])

        #expect(list.itemsMissingBodies.count == 1)
    }

    // MARK: - Ordered/Unordered Tests

    @Test("isOrdered returns true for ordered list kinds")
    func isOrderedTrue() {
        let list = ListNode(listKind: .orderedArabic)
        #expect(list.isOrdered)
    }

    @Test("isOrdered returns false for unordered list")
    func isOrderedFalse() {
        let list = ListNode(listKind: .unordered)
        #expect(!list.isOrdered)
    }

    @Test("isUnordered returns true for unordered list")
    func isUnorderedTrue() {
        let list = ListNode(listKind: .unordered)
        #expect(list.isUnordered)
    }

    @Test("isUnordered returns false for ordered list")
    func isUnorderedFalse() {
        let list = ListNode(listKind: .orderedRomanUpper)
        #expect(!list.isUnordered)
    }

    // MARK: - Nested List Tests

    @Test("nestedLists finds lists inside item bodies")
    func nestedListsFound() {
        // Create a nested list
        let nestedItem = makeListItem(label: "a.", body: "Nested content")
        let nestedList = ListNode(children: [nestedItem], listKind: .orderedAlphaLower)

        // Create body with nested list
        let bodyWithNested = ContentNode(
            type: .listBody,
            children: [nestedList],
            depth: 3
        )
        let parentItem = ContentNode(
            type: .listItem,
            children: [makeLabel(), bodyWithNested],
            depth: 2
        )
        let parentList = ListNode(children: [parentItem])

        #expect(parentList.nestedLists.count == 1)
    }

    @Test("hasNestedLists returns true when nested lists exist")
    func hasNestedListsTrue() {
        let nestedList = ListNode(children: [makeListItem()])
        let bodyWithNested = ContentNode(
            type: .listBody,
            children: [nestedList],
            depth: 3
        )
        let item = ContentNode(
            type: .listItem,
            children: [makeLabel(), bodyWithNested],
            depth: 2
        )
        let parentList = ListNode(children: [item])

        #expect(parentList.hasNestedLists)
    }

    @Test("hasNestedLists returns false when no nested lists")
    func hasNestedListsFalse() {
        let list = ListNode(children: [makeListItem()])
        #expect(!list.hasNestedLists)
    }

    // MARK: - Validation Tests

    @Test("validateStructure reports missing labels")
    func validateReportsMissingLabels() {
        let item1 = makeListItem(label: "1.", body: "Content")
        let item2 = makeListItem(label: nil, body: "No label")
        let list = ListNode(children: [item1, item2])

        let errors = list.validateStructure()
        #expect(errors.contains(.listItemMissingLabel))
    }

    @Test("validateStructure reports missing bodies")
    func validateReportsMissingBodies() {
        let item1 = makeListItem(label: "1.", body: "Content")
        let item2 = makeListItem(label: "2.", body: nil)
        let list = ListNode(children: [item1, item2])

        let errors = list.validateStructure()
        #expect(errors.contains(.listItemMissingBody))
    }

    @Test("validateStructure reports excessive nesting")
    func validateReportsExcessiveNesting() {
        let list = ListNode(listKind: .unordered, nestingLevel: 6)

        let errors = list.validateStructure()
        #expect(errors.contains(.listNestingTooDeep))
    }

    @Test("validateStructure does not report for proper structure")
    func validateNoErrorsForProperStructure() {
        let item1 = makeListItem(label: "1.", body: "First")
        let item2 = makeListItem(label: "2.", body: "Second")
        let list = ListNode(children: [item1, item2])

        let errors = list.validateStructure()
        #expect(errors.isEmpty)
    }

    // MARK: - withDetectedKind Tests

    @Test("withDetectedKind creates new list with kind")
    func withDetectedKindCreatesNew() {
        let original = ListNode(depth: 2, nestingLevel: 1)
        let updated = original.withDetectedKind(.orderedArabic, startNumber: 5)

        #expect(updated.id == original.id)
        #expect(updated.depth == original.depth)
        #expect(updated.nestingLevel == original.nestingLevel)
        #expect(updated.listKind == .orderedArabic)
        #expect(updated.startNumber == 5)
        #expect(original.listKind == .unknown)  // Original unchanged
    }

    // MARK: - withNestingLevel Tests

    @Test("withNestingLevel creates new list with level")
    func withNestingLevelCreatesNew() {
        let original = ListNode(listKind: .unordered)
        let updated = original.withNestingLevel(3)

        #expect(updated.id == original.id)
        #expect(updated.listKind == original.listKind)
        #expect(updated.nestingLevel == 3)
        #expect(original.nestingLevel == 0)  // Original unchanged
    }

    // MARK: - Hashable Tests

    @Test("ListNode is Hashable by ID")
    func hashableById() {
        let id = UUID()
        let list1 = ListNode(id: id)
        let list2 = ListNode(id: id, listKind: .orderedArabic)

        var set: Set<ListNode> = []
        set.insert(list1)
        set.insert(list2)

        #expect(set.count == 1)
    }

    // MARK: - Equatable Tests

    @Test("ListNode equality is by ID")
    func equalityById() {
        let id = UUID()
        let list1 = ListNode(id: id, listKind: .unordered)
        let list2 = ListNode(id: id, listKind: .orderedArabic)
        let list3 = ListNode()

        #expect(list1 == list2)
        #expect(list1 != list3)
    }

    // MARK: - Codable Tests

    @Test("ListNode encodes and decodes correctly")
    func codableRoundTrip() throws {
        let original = ListNode(
            boundingBox: makeBoundingBox(),
            attributes: ["Lang": .string("en")],
            depth: 1,
            errorCodes: [.listItemMissingLabel],
            listKind: .orderedArabic,
            startNumber: 3,
            nestingLevel: 2
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ListNode.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.type == .list)
        #expect(decoded.depth == original.depth)
        #expect(decoded.listKind == original.listKind)
        #expect(decoded.startNumber == original.startNumber)
        #expect(decoded.nestingLevel == original.nestingLevel)
        #expect(decoded.errorCodes == original.errorCodes)
    }

    // MARK: - CustomStringConvertible Tests

    @Test("description shows item count and kind")
    func descriptionShowsCountAndKind() {
        let item1 = makeListItem()
        let item2 = makeListItem()
        let list = ListNode(children: [item1, item2], listKind: .orderedArabic)

        let desc = list.description
        #expect(desc.contains("List"))
        #expect(desc.contains("2 items"))
        #expect(desc.contains("orderedArabic"))
    }

    @Test("description shows nesting level when nested")
    func descriptionShowsNesting() {
        let list = ListNode(nestingLevel: 2)

        let desc = list.description
        #expect(desc.contains("(level 2)"))
    }

    @Test("description omits kind for unknown")
    func descriptionOmitsUnknownKind() {
        let list = ListNode(listKind: .unknown)

        let desc = list.description
        #expect(!desc.contains("unknown"))
    }
}

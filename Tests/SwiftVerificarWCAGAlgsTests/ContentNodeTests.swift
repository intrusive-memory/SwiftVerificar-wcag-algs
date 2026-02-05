import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

/// Tests for the ContentNode struct.
@Suite("ContentNode Tests")
struct ContentNodeTests {

    // MARK: - Test Helpers

    func makeBoundingBox(page: Int = 0) -> BoundingBox {
        BoundingBox(pageIndex: page, rect: CGRect(x: 0, y: 0, width: 100, height: 50))
    }

    func makeTextChunk(text: String, fontSize: CGFloat = 12) -> TextChunk {
        TextChunk(
            boundingBox: makeBoundingBox(),
            value: text,
            fontName: "Helvetica",
            fontSize: fontSize,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
    }

    func makeTextLine(text: String) -> TextLine {
        let chunk = makeTextChunk(text: text)
        return TextLine(boundingBox: makeBoundingBox(), chunks: [chunk])
    }

    func makeTextBlock(text: String) -> TextBlock {
        let line = makeTextLine(text: text)
        return TextBlock(boundingBox: makeBoundingBox(), lines: [line])
    }

    // MARK: - Initialization Tests

    @Test("ContentNode initializes with type and depth")
    func initWithTypeAndDepth() {
        let node = ContentNode(type: .paragraph, depth: 2)
        #expect(node.type == .paragraph)
        #expect(node.depth == 2)
        #expect(node.boundingBox == nil)
        #expect(node.children.isEmpty)
        #expect(node.textBlocks.isEmpty)
    }

    @Test("ContentNode initializes with all properties")
    func initWithAllProperties() {
        let id = UUID()
        let box = makeBoundingBox()
        let block = makeTextBlock(text: "Hello")
        let attrs: AttributesDictionary = ["Alt": .string("Description")]

        let node = ContentNode(
            id: id,
            type: .paragraph,
            boundingBox: box,
            children: [],
            attributes: attrs,
            depth: 1,
            errorCodes: [.emptyElement],
            textBlocks: [block],
            dominantFontSize: 12,
            dominantFontWeight: 400
        )

        #expect(node.id == id)
        #expect(node.type == .paragraph)
        #expect(node.boundingBox == box)
        #expect(node.textBlocks.count == 1)
        #expect(node.dominantFontSize == 12)
        #expect(node.dominantFontWeight == 400)
        #expect(node.errorCodes.contains(.emptyElement))
    }

    // MARK: - SemanticNode Protocol Conformance Tests

    @Test("ContentNode conforms to SemanticNode")
    func conformsToSemanticNode() {
        let node: any SemanticNode = ContentNode(type: .paragraph)
        #expect(node.type == .paragraph)
    }

    @Test("ContentNode is Identifiable with UUID")
    func identifiable() {
        let node = ContentNode(type: .paragraph)
        #expect(node.id is UUID)
    }

    @Test("ContentNode is Sendable")
    func sendable() {
        let node = ContentNode(type: .paragraph)
        let sendable: any Sendable = node
        #expect(sendable is ContentNode)
    }

    // MARK: - Text Content Tests

    @Test("text joins text blocks with double newlines")
    func textJoinsBlocks() {
        let block1 = makeTextBlock(text: "First")
        let block2 = makeTextBlock(text: "Second")
        let node = ContentNode(
            type: .div,
            depth: 1,
            textBlocks: [block1, block2]
        )
        #expect(node.text == "First\n\nSecond")
    }

    @Test("text is empty when no blocks")
    func textEmptyWhenNoBlocks() {
        let node = ContentNode(type: .paragraph)
        #expect(node.text == "")
    }

    @Test("hasTextContent returns true when text exists")
    func hasTextContentTrue() {
        let block = makeTextBlock(text: "Content")
        let node = ContentNode(type: .paragraph, depth: 1, textBlocks: [block])
        #expect(node.hasTextContent)
    }

    @Test("hasTextContent returns false when empty")
    func hasTextContentFalse() {
        let node = ContentNode(type: .paragraph)
        #expect(!node.hasTextContent)
    }

    @Test("textBlockCount returns correct count")
    func textBlockCountCorrect() {
        let block1 = makeTextBlock(text: "One")
        let block2 = makeTextBlock(text: "Two")
        let node = ContentNode(type: .div, depth: 1, textBlocks: [block1, block2])
        #expect(node.textBlockCount == 2)
    }

    @Test("totalLineCount sums lines across blocks")
    func totalLineCountSums() {
        let block = makeTextBlock(text: "Test")
        let node = ContentNode(type: .paragraph, depth: 1, textBlocks: [block, block])
        #expect(node.totalLineCount == 2)
    }

    @Test("totalChunkCount sums chunks across all blocks and lines")
    func totalChunkCountSums() {
        let block = makeTextBlock(text: "Test")
        let node = ContentNode(type: .paragraph, depth: 1, textBlocks: [block])
        #expect(node.totalChunkCount == 1)
    }

    // MARK: - Large Text Tests

    @Test("isLargeText returns true for 18pt font")
    func isLargeTextAt18pt() {
        let node = ContentNode(
            type: .paragraph,
            dominantFontSize: 18,
            dominantFontWeight: 400
        )
        #expect(node.isLargeText)
    }

    @Test("isLargeText returns true for 24pt font")
    func isLargeTextAt24pt() {
        let node = ContentNode(
            type: .paragraph,
            dominantFontSize: 24,
            dominantFontWeight: 400
        )
        #expect(node.isLargeText)
    }

    @Test("isLargeText returns true for 14pt bold")
    func isLargeTextAt14ptBold() {
        let node = ContentNode(
            type: .paragraph,
            dominantFontSize: 14,
            dominantFontWeight: 700
        )
        #expect(node.isLargeText)
    }

    @Test("isLargeText returns false for 14pt regular")
    func isLargeTextFalseAt14ptRegular() {
        let node = ContentNode(
            type: .paragraph,
            dominantFontSize: 14,
            dominantFontWeight: 400
        )
        #expect(!node.isLargeText)
    }

    @Test("isLargeText returns false for 12pt")
    func isLargeTextFalseAt12pt() {
        let node = ContentNode(
            type: .paragraph,
            dominantFontSize: 12,
            dominantFontWeight: 400
        )
        #expect(!node.isLargeText)
    }

    @Test("isLargeText returns false when no font size")
    func isLargeTextFalseWhenNoFontSize() {
        let node = ContentNode(type: .paragraph)
        #expect(!node.isLargeText)
    }

    @Test("textType returns large for large text")
    func textTypeLarge() {
        let node = ContentNode(
            type: .paragraph,
            dominantFontSize: 20,
            dominantFontWeight: 400
        )
        #expect(node.textType == .large)
    }

    @Test("textType returns regular for regular text")
    func textTypeRegular() {
        let node = ContentNode(
            type: .paragraph,
            dominantFontSize: 12,
            dominantFontWeight: 400
        )
        #expect(node.textType == .regular)
    }

    // MARK: - Heading Tests

    @Test("isHeading returns true for heading types")
    func isHeadingTrue() {
        let h1 = ContentNode(type: .h1)
        let h2 = ContentNode(type: .h2)
        let heading = ContentNode(type: .heading)

        #expect(h1.isHeading)
        #expect(h2.isHeading)
        #expect(heading.isHeading)
    }

    @Test("isHeading returns false for non-heading types")
    func isHeadingFalse() {
        let para = ContentNode(type: .paragraph)
        #expect(!para.isHeading)
    }

    @Test("headingLevel returns correct level")
    func headingLevelCorrect() {
        let h1 = ContentNode(type: .h1)
        let h3 = ContentNode(type: .h3)
        let h6 = ContentNode(type: .h6)

        #expect(h1.headingLevel == 1)
        #expect(h3.headingLevel == 3)
        #expect(h6.headingLevel == 6)
    }

    @Test("headingLevel returns nil for non-specific headings")
    func headingLevelNil() {
        let heading = ContentNode(type: .heading)
        let para = ContentNode(type: .paragraph)

        #expect(heading.headingLevel == nil)
        #expect(para.headingLevel == nil)
    }

    // MARK: - Factory Method Tests

    @Test("document() creates document node")
    func documentFactory() {
        let doc = ContentNode.document()
        #expect(doc.type == .document)
        #expect(doc.depth == 0)
    }

    @Test("paragraph() creates paragraph node")
    func paragraphFactory() {
        let block = makeTextBlock(text: "Test")
        let para = ContentNode.paragraph(textBlocks: [block])
        #expect(para.type == .paragraph)
        #expect(para.depth == 1)
        #expect(para.textBlocks.count == 1)
    }

    @Test("heading(level:) creates correct heading type")
    func headingFactory() {
        let h1 = ContentNode.heading(level: 1)
        let h3 = ContentNode.heading(level: 3)
        let h6 = ContentNode.heading(level: 6)
        let hGeneric = ContentNode.heading(level: 0)
        let hOutOfRange = ContentNode.heading(level: 7)

        #expect(h1.type == .h1)
        #expect(h3.type == .h3)
        #expect(h6.type == .h6)
        #expect(hGeneric.type == .heading)
        #expect(hOutOfRange.type == .heading)
    }

    @Test("span() creates span node")
    func spanFactory() {
        let span = ContentNode.span()
        #expect(span.type == .span)
        #expect(span.depth == 2)
    }

    @Test("caption() creates caption node")
    func captionFactory() {
        let caption = ContentNode.caption()
        #expect(caption.type == .caption)
        #expect(caption.depth == 2)
    }

    // MARK: - Hashable Tests

    @Test("ContentNode is Hashable by ID")
    func hashableById() {
        let id = UUID()
        let node1 = ContentNode(id: id, type: .paragraph, depth: 1)
        let node2 = ContentNode(id: id, type: .span, depth: 2)

        var set: Set<ContentNode> = []
        set.insert(node1)
        set.insert(node2)

        #expect(set.count == 1)
    }

    // MARK: - Equatable Tests

    @Test("ContentNode equality is by ID")
    func equalityById() {
        let id = UUID()
        let node1 = ContentNode(id: id, type: .paragraph, depth: 1)
        let node2 = ContentNode(id: id, type: .span, depth: 2)
        let node3 = ContentNode(type: .paragraph, depth: 1)

        #expect(node1 == node2)
        #expect(node1 != node3)
    }

    // MARK: - Codable Tests

    @Test("ContentNode encodes and decodes correctly")
    func codableRoundTrip() throws {
        let block = makeTextBlock(text: "Test content")
        let original = ContentNode(
            type: .paragraph,
            boundingBox: makeBoundingBox(),
            attributes: ["Alt": .string("Description")],
            depth: 1,
            errorCodes: [.missingAltText],
            textBlocks: [block],
            dominantFontSize: 12,
            dominantFontWeight: 400
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ContentNode.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.type == original.type)
        #expect(decoded.depth == original.depth)
        #expect(decoded.dominantFontSize == original.dominantFontSize)
        #expect(decoded.errorCodes == original.errorCodes)
    }

    // MARK: - CustomStringConvertible Tests

    @Test("description includes type and text preview")
    func descriptionFormat() {
        let block = makeTextBlock(text: "Hello World")
        let node = ContentNode(
            type: .paragraph,
            depth: 1,
            textBlocks: [block]
        )

        let desc = node.description
        #expect(desc.contains("P"))
        #expect(desc.contains("Hello World"))
    }

    @Test("description truncates long text")
    func descriptionTruncates() {
        let longText = String(repeating: "A", count: 100)
        let block = makeTextBlock(text: longText)
        let node = ContentNode(
            type: .paragraph,
            depth: 0,
            textBlocks: [block]
        )

        let desc = node.description
        #expect(desc.contains("..."))
    }

    // MARK: - Error Management Tests

    @Test("addError adds to errorCodes set")
    func addErrorWorks() {
        var node = ContentNode(type: .paragraph)
        node.addError(.emptyElement)
        node.addError(.missingAltText)

        #expect(node.errorCodes.count == 2)
        #expect(node.errorCodes.contains(.emptyElement))
        #expect(node.errorCodes.contains(.missingAltText))
    }

    @Test("removeError removes from errorCodes set")
    func removeErrorWorks() {
        var node = ContentNode(
            type: .paragraph,
            errorCodes: [.emptyElement, .missingAltText]
        )
        node.removeError(.emptyElement)

        #expect(node.errorCodes.count == 1)
        #expect(!node.errorCodes.contains(.emptyElement))
        #expect(node.errorCodes.contains(.missingAltText))
    }

    @Test("clearErrors empties errorCodes set")
    func clearErrorsWorks() {
        var node = ContentNode(
            type: .paragraph,
            errorCodes: [.emptyElement, .missingAltText]
        )
        node.clearErrors()

        #expect(node.errorCodes.isEmpty)
    }
}

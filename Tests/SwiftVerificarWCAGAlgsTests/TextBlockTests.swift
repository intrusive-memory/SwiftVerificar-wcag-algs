import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

/// Tests for `TextBlock` struct.
@Suite("TextBlock Tests")
struct TextBlockTests {

    // MARK: - Helpers

    private func makeBox(page: Int = 0, x: CGFloat = 0, y: CGFloat = 0,
                         width: CGFloat = 300, height: CGFloat = 100) -> BoundingBox {
        BoundingBox(pageIndex: page, x: x, y: y, width: width, height: height)
    }

    private func makeColor() -> CGColor {
        CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
    }

    private func makeChunk(value: String) -> TextChunk {
        TextChunk(
            boundingBox: BoundingBox(pageIndex: 0, x: 0, y: 0, width: 50, height: 12),
            value: value,
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: makeColor()
        )
    }

    private func makeLine(text: String) -> TextLine {
        TextLine(
            boundingBox: BoundingBox(pageIndex: 0, x: 0, y: 0, width: 200, height: 15),
            chunks: [makeChunk(value: text)]
        )
    }

    private func makeBlock(lineTexts: [String] = ["Line one", "Line two"],
                            page: Int = 0) -> TextBlock {
        let lines = lineTexts.map { makeLine(text: $0) }
        return TextBlock(boundingBox: makeBox(page: page), lines: lines)
    }

    // MARK: - Initialization

    @Test("TextBlock stores all properties")
    func initStoresProperties() {
        let box = makeBox(page: 2)
        let lines = [makeLine(text: "A"), makeLine(text: "B")]
        let block = TextBlock(boundingBox: box, lines: lines)

        #expect(block.boundingBox == box)
        #expect(block.lines.count == 2)
    }

    // MARK: - ContentChunk Conformance

    @Test("TextBlock conforms to ContentChunk")
    func contentChunkConformance() {
        let block = makeBlock(page: 5)
        let asChunk: any ContentChunk = block
        #expect(asChunk.pageIndex == 5)
    }

    @Test("pageIndex delegates to boundingBox")
    func pageIndexDelegation() {
        let block = makeBlock(page: 9)
        #expect(block.pageIndex == 9)
    }

    // MARK: - Computed Properties

    @Test("text joins lines with newlines")
    func textJoinsWithNewlines() {
        let block = makeBlock(lineTexts: ["Hello", "World"])
        #expect(block.text == "Hello\nWorld")
    }

    @Test("text is empty string when no lines")
    func textEmptyLines() {
        let block = TextBlock(boundingBox: makeBox(), lines: [])
        #expect(block.text == "")
    }

    @Test("text with single line returns that line's text")
    func textSingleLine() {
        let block = makeBlock(lineTexts: ["Only line"])
        #expect(block.text == "Only line")
    }

    @Test("text with three lines uses newline separators")
    func textThreeLines() {
        let block = makeBlock(lineTexts: ["A", "B", "C"])
        #expect(block.text == "A\nB\nC")
    }

    @Test("lineCount returns number of lines")
    func lineCount() {
        let block = makeBlock(lineTexts: ["A", "B", "C"])
        #expect(block.lineCount == 3)
    }

    @Test("lineCount is zero for empty block")
    func lineCountZero() {
        let block = TextBlock(boundingBox: makeBox(), lines: [])
        #expect(block.lineCount == 0)
    }

    @Test("totalChunkCount sums chunks across all lines")
    func totalChunkCount() {
        let line1 = TextLine(
            boundingBox: makeBox(),
            chunks: [makeChunk(value: "A"), makeChunk(value: "B")]
        )
        let line2 = TextLine(
            boundingBox: makeBox(),
            chunks: [makeChunk(value: "C")]
        )
        let block = TextBlock(boundingBox: makeBox(), lines: [line1, line2])
        #expect(block.totalChunkCount == 3)
    }

    @Test("totalChunkCount is zero for empty block")
    func totalChunkCountZero() {
        let block = TextBlock(boundingBox: makeBox(), lines: [])
        #expect(block.totalChunkCount == 0)
    }

    @Test("isEmpty is true for empty lines array")
    func isEmptyNoLines() {
        let block = TextBlock(boundingBox: makeBox(), lines: [])
        #expect(block.isEmpty == true)
    }

    @Test("isEmpty is true when all lines have empty text")
    func isEmptyEmptyText() {
        let emptyLine = TextLine(
            boundingBox: makeBox(),
            chunks: [makeChunk(value: "")]
        )
        let block = TextBlock(boundingBox: makeBox(), lines: [emptyLine])
        #expect(block.isEmpty == true)
    }

    @Test("isEmpty is false for block with content")
    func isNotEmpty() {
        let block = makeBlock()
        #expect(block.isEmpty == false)
    }

    @Test("allChunks returns all chunks in order")
    func allChunksOrder() {
        let line1 = TextLine(
            boundingBox: makeBox(),
            chunks: [makeChunk(value: "A"), makeChunk(value: "B")]
        )
        let line2 = TextLine(
            boundingBox: makeBox(),
            chunks: [makeChunk(value: "C")]
        )
        let block = TextBlock(boundingBox: makeBox(), lines: [line1, line2])
        let values = block.allChunks.map(\.value)
        #expect(values == ["A", "B", "C"])
    }

    @Test("allChunks is empty for empty block")
    func allChunksEmpty() {
        let block = TextBlock(boundingBox: makeBox(), lines: [])
        #expect(block.allChunks.isEmpty)
    }

    // MARK: - Equatable / Hashable

    @Test("Equal blocks are equal")
    func equalBlocks() {
        let a = makeBlock(lineTexts: ["X", "Y"])
        let b = makeBlock(lineTexts: ["X", "Y"])
        #expect(a == b)
    }

    @Test("Blocks with different lines are not equal")
    func differentLines() {
        let a = makeBlock(lineTexts: ["X"])
        let b = makeBlock(lineTexts: ["Y"])
        #expect(a != b)
    }

    @Test("Blocks can be used in a Set")
    func setUsage() {
        let a = makeBlock(lineTexts: ["A"])
        let b = makeBlock(lineTexts: ["B"])
        let c = makeBlock(lineTexts: ["A"]) // duplicate of a
        let set: Set<TextBlock> = [a, b, c]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("TextBlock roundtrips through Codable")
    func codableRoundtrip() throws {
        let block = makeBlock(lineTexts: ["Hello", "World"])
        let data = try JSONEncoder().encode(block)
        let decoded = try JSONDecoder().decode(TextBlock.self, from: data)

        #expect(decoded.boundingBox == block.boundingBox)
        #expect(decoded.lineCount == block.lineCount)
        #expect(decoded.text == block.text)
    }

    @Test("TextBlock Codable with empty lines")
    func codableEmptyLines() throws {
        let block = TextBlock(boundingBox: makeBox(), lines: [])
        let data = try JSONEncoder().encode(block)
        let decoded = try JSONDecoder().decode(TextBlock.self, from: data)
        #expect(decoded.lines.isEmpty)
    }

    // MARK: - Sendable

    @Test("TextBlock is Sendable")
    func sendable() async {
        let block = makeBlock()
        let task = Task { @Sendable in
            return block.text
        }
        let result = await task.value
        #expect(result == "Line one\nLine two")
    }
}

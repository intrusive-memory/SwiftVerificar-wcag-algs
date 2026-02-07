import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

/// Tests for `TextColumn` struct.
@Suite("TextColumn Tests")
struct TextColumnTests {

    // MARK: - Helpers

    private func makeBox(page: Int = 0, x: CGFloat = 0, y: CGFloat = 0,
                         width: CGFloat = 300, height: CGFloat = 400) -> BoundingBox {
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

    private func makeBlock(lineTexts: [String]) -> TextBlock {
        let lines = lineTexts.map { makeLine(text: $0) }
        return TextBlock(
            boundingBox: BoundingBox(pageIndex: 0, x: 0, y: 0, width: 200, height: 50),
            lines: lines
        )
    }

    private func makeColumn(
        blockContents: [[String]] = [["Line 1", "Line 2"], ["Line 3"]],
        page: Int = 0
    ) -> TextColumn {
        let blocks = blockContents.map { makeBlock(lineTexts: $0) }
        return TextColumn(boundingBox: makeBox(page: page), blocks: blocks)
    }

    // MARK: - Initialization

    @Test("TextColumn stores all properties")
    func initStoresProperties() {
        let box = makeBox(page: 3)
        let blocks = [makeBlock(lineTexts: ["A"]), makeBlock(lineTexts: ["B"])]
        let column = TextColumn(boundingBox: box, blocks: blocks)

        #expect(column.boundingBox == box)
        #expect(column.blocks.count == 2)
    }

    // MARK: - ContentChunk Conformance

    @Test("TextColumn conforms to ContentChunk")
    func contentChunkConformance() {
        let column = makeColumn(page: 6)
        let asChunk: any ContentChunk = column
        #expect(asChunk.pageIndex == 6)
    }

    @Test("pageIndex delegates to boundingBox")
    func pageIndexDelegation() {
        let column = makeColumn(page: 8)
        #expect(column.pageIndex == 8)
    }

    // MARK: - Computed Properties

    @Test("text joins blocks with double newlines")
    func textJoinsWithDoubleNewlines() {
        let column = makeColumn(blockContents: [["Hello"], ["World"]])
        #expect(column.text == "Hello\n\nWorld")
    }

    @Test("text is empty string when no blocks")
    func textEmptyBlocks() {
        let column = TextColumn(boundingBox: makeBox(), blocks: [])
        #expect(column.text == "")
    }

    @Test("text with single block returns that block's text")
    func textSingleBlock() {
        let column = makeColumn(blockContents: [["Only block"]])
        #expect(column.text == "Only block")
    }

    @Test("text with multi-line blocks uses correct separators")
    func textMultiLineBlocks() {
        let column = makeColumn(blockContents: [["A", "B"], ["C", "D"]])
        #expect(column.text == "A\nB\n\nC\nD")
    }

    @Test("blockCount returns number of blocks")
    func blockCount() {
        let column = makeColumn(blockContents: [["A"], ["B"], ["C"]])
        #expect(column.blockCount == 3)
    }

    @Test("blockCount is zero for empty column")
    func blockCountZero() {
        let column = TextColumn(boundingBox: makeBox(), blocks: [])
        #expect(column.blockCount == 0)
    }

    @Test("totalLineCount sums lines across all blocks")
    func totalLineCount() {
        let column = makeColumn(blockContents: [["A", "B"], ["C"]])
        #expect(column.totalLineCount == 3)
    }

    @Test("totalLineCount is zero for empty column")
    func totalLineCountZero() {
        let column = TextColumn(boundingBox: makeBox(), blocks: [])
        #expect(column.totalLineCount == 0)
    }

    @Test("totalChunkCount sums chunks across all blocks and lines")
    func totalChunkCount() {
        // Each line has 1 chunk in our helper, so 3 lines = 3 chunks
        let column = makeColumn(blockContents: [["A", "B"], ["C"]])
        #expect(column.totalChunkCount == 3)
    }

    @Test("totalChunkCount with multi-chunk lines")
    func totalChunkCountMultiChunk() {
        let line1 = TextLine(
            boundingBox: makeBox(),
            chunks: [makeChunk(value: "A"), makeChunk(value: "B")]
        )
        let line2 = TextLine(
            boundingBox: makeBox(),
            chunks: [makeChunk(value: "C")]
        )
        let block = TextBlock(boundingBox: makeBox(), lines: [line1, line2])
        let column = TextColumn(boundingBox: makeBox(), blocks: [block])
        #expect(column.totalChunkCount == 3)
    }

    @Test("isEmpty is true for empty blocks array")
    func isEmptyNoBlocks() {
        let column = TextColumn(boundingBox: makeBox(), blocks: [])
        #expect(column.isEmpty == true)
    }

    @Test("isEmpty is true when all blocks have empty text")
    func isEmptyEmptyBlocks() {
        let emptyBlock = TextBlock(
            boundingBox: makeBox(),
            lines: [TextLine(
                boundingBox: makeBox(),
                chunks: [makeChunk(value: "")]
            )]
        )
        let column = TextColumn(boundingBox: makeBox(), blocks: [emptyBlock])
        #expect(column.isEmpty == true)
    }

    @Test("isEmpty is false for column with content")
    func isNotEmpty() {
        let column = makeColumn()
        #expect(column.isEmpty == false)
    }

    @Test("allLines returns all lines in order")
    func allLinesOrder() {
        let column = makeColumn(blockContents: [["A", "B"], ["C"]])
        let lineTexts = column.allLines.map(\.text)
        #expect(lineTexts == ["A", "B", "C"])
    }

    @Test("allLines is empty for empty column")
    func allLinesEmpty() {
        let column = TextColumn(boundingBox: makeBox(), blocks: [])
        #expect(column.allLines.isEmpty)
    }

    @Test("allChunks returns all chunks in order")
    func allChunksOrder() {
        let column = makeColumn(blockContents: [["A", "B"], ["C"]])
        let values = column.allChunks.map(\.value)
        #expect(values == ["A", "B", "C"])
    }

    @Test("allChunks is empty for empty column")
    func allChunksEmpty() {
        let column = TextColumn(boundingBox: makeBox(), blocks: [])
        #expect(column.allChunks.isEmpty)
    }

    // MARK: - Equatable / Hashable

    @Test("Equal columns are equal")
    func equalColumns() {
        let a = makeColumn(blockContents: [["X"]])
        let b = makeColumn(blockContents: [["X"]])
        #expect(a == b)
    }

    @Test("Columns with different blocks are not equal")
    func differentBlocks() {
        let a = makeColumn(blockContents: [["X"]])
        let b = makeColumn(blockContents: [["Y"]])
        #expect(a != b)
    }

    @Test("Columns can be used in a Set")
    func setUsage() {
        let a = makeColumn(blockContents: [["A"]])
        let b = makeColumn(blockContents: [["B"]])
        let c = makeColumn(blockContents: [["A"]]) // duplicate of a
        let set: Set<TextColumn> = [a, b, c]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("TextColumn roundtrips through Codable")
    func codableRoundtrip() throws {
        let column = makeColumn(blockContents: [["Hello", "World"], ["Paragraph 2"]])
        let data = try JSONEncoder().encode(column)
        let decoded = try JSONDecoder().decode(TextColumn.self, from: data)

        #expect(decoded.boundingBox == column.boundingBox)
        #expect(decoded.blockCount == column.blockCount)
        #expect(decoded.text == column.text)
    }

    @Test("TextColumn Codable with empty blocks")
    func codableEmptyBlocks() throws {
        let column = TextColumn(boundingBox: makeBox(), blocks: [])
        let data = try JSONEncoder().encode(column)
        let decoded = try JSONDecoder().decode(TextColumn.self, from: data)
        #expect(decoded.blocks.isEmpty)
    }

    // MARK: - Sendable

    @Test("TextColumn is Sendable")
    func sendable() async {
        let column = makeColumn()
        let task = Task { @Sendable in
            return column.text
        }
        let result = await task.value
        #expect(result.contains("Line 1"))
    }

    // MARK: - Integration: Hierarchical structure

    @Test("Nested structure: Column > Block > Line > Chunk hierarchy")
    func nestedHierarchy() {
        let chunk1 = makeChunk(value: "Word1 ")
        let chunk2 = makeChunk(value: "Word2")
        let line = TextLine(
            boundingBox: makeBox(),
            chunks: [chunk1, chunk2]
        )
        let block = TextBlock(boundingBox: makeBox(), lines: [line])
        let column = TextColumn(boundingBox: makeBox(), blocks: [block])

        #expect(column.blockCount == 1)
        #expect(column.totalLineCount == 1)
        #expect(column.totalChunkCount == 2)
        #expect(column.text == "Word1 Word2")
        #expect(column.allChunks.map(\.value) == ["Word1 ", "Word2"])
    }
}

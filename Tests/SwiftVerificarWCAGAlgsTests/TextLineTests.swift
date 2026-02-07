import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

/// Tests for `TextLine` struct.
@Suite("TextLine Tests")
struct TextLineTests {

    // MARK: - Helpers

    private func makeBox(page: Int = 0, x: CGFloat = 0, y: CGFloat = 0,
                         width: CGFloat = 200, height: CGFloat = 20) -> BoundingBox {
        BoundingBox(pageIndex: page, x: x, y: y, width: width, height: height)
    }

    private func makeColor() -> CGColor {
        CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
    }

    private func makeChunk(value: String = "Hello", x: CGFloat = 0,
                            width: CGFloat = 50) -> TextChunk {
        TextChunk(
            boundingBox: BoundingBox(pageIndex: 0, x: x, y: 0, width: width, height: 20),
            value: value,
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: makeColor()
        )
    }

    private func makeLine(
        chunks: [TextChunk]? = nil,
        isLineStart: Bool = false,
        isLineEnd: Bool = false,
        page: Int = 0
    ) -> TextLine {
        let lineChunks = chunks ?? [makeChunk(value: "Hello "), makeChunk(value: "World")]
        return TextLine(
            boundingBox: makeBox(page: page),
            chunks: lineChunks,
            isLineStart: isLineStart,
            isLineEnd: isLineEnd
        )
    }

    // MARK: - Initialization

    @Test("TextLine stores all properties")
    func initStoresProperties() {
        let chunks = [makeChunk(value: "A"), makeChunk(value: "B")]
        let box = makeBox(page: 3)
        let line = TextLine(
            boundingBox: box,
            chunks: chunks,
            isLineStart: true,
            isLineEnd: false
        )

        #expect(line.boundingBox == box)
        #expect(line.chunks.count == 2)
        #expect(line.isLineStart == true)
        #expect(line.isLineEnd == false)
    }

    @Test("TextLine default isLineStart is false")
    func defaultLineStart() {
        let line = TextLine(boundingBox: makeBox(), chunks: [makeChunk()])
        #expect(line.isLineStart == false)
    }

    @Test("TextLine default isLineEnd is false")
    func defaultLineEnd() {
        let line = TextLine(boundingBox: makeBox(), chunks: [makeChunk()])
        #expect(line.isLineEnd == false)
    }

    // MARK: - ContentChunk Conformance

    @Test("TextLine conforms to ContentChunk")
    func contentChunkConformance() {
        let line = makeLine(page: 7)
        let asChunk: any ContentChunk = line
        #expect(asChunk.pageIndex == 7)
    }

    @Test("pageIndex delegates to boundingBox")
    func pageIndexDelegation() {
        let line = makeLine(page: 4)
        #expect(line.pageIndex == 4)
    }

    // MARK: - Computed Properties

    @Test("text concatenates chunk values")
    func textConcatenation() {
        let chunks = [
            makeChunk(value: "Hello "),
            makeChunk(value: "World"),
            makeChunk(value: "!")
        ]
        let line = TextLine(boundingBox: makeBox(), chunks: chunks)
        #expect(line.text == "Hello World!")
    }

    @Test("text is empty string when no chunks")
    func textEmptyChunks() {
        let line = TextLine(boundingBox: makeBox(), chunks: [])
        #expect(line.text == "")
    }

    @Test("text with single chunk returns that chunk's value")
    func textSingleChunk() {
        let line = TextLine(
            boundingBox: makeBox(),
            chunks: [makeChunk(value: "Alone")]
        )
        #expect(line.text == "Alone")
    }

    @Test("chunkCount returns number of chunks")
    func chunkCount() {
        let chunks = [makeChunk(value: "A"), makeChunk(value: "B"), makeChunk(value: "C")]
        let line = TextLine(boundingBox: makeBox(), chunks: chunks)
        #expect(line.chunkCount == 3)
    }

    @Test("chunkCount is zero for empty line")
    func chunkCountZero() {
        let line = TextLine(boundingBox: makeBox(), chunks: [])
        #expect(line.chunkCount == 0)
    }

    @Test("isEmpty is true for empty chunks array")
    func isEmptyNoChunks() {
        let line = TextLine(boundingBox: makeBox(), chunks: [])
        #expect(line.isEmpty == true)
    }

    @Test("isEmpty is true when all chunks have empty values")
    func isEmptyEmptyValues() {
        let line = TextLine(
            boundingBox: makeBox(),
            chunks: [makeChunk(value: ""), makeChunk(value: "")]
        )
        #expect(line.isEmpty == true)
    }

    @Test("isEmpty is false for line with content")
    func isNotEmpty() {
        let line = makeLine()
        #expect(line.isEmpty == false)
    }

    // MARK: - Equatable / Hashable

    @Test("Equal lines are equal")
    func equalLines() {
        let a = makeLine()
        let b = makeLine()
        #expect(a == b)
    }

    @Test("Lines with different isLineStart are not equal")
    func differentLineStart() {
        let a = makeLine(isLineStart: true)
        let b = makeLine(isLineStart: false)
        #expect(a != b)
    }

    @Test("Lines with different chunks are not equal")
    func differentChunks() {
        let a = makeLine(chunks: [makeChunk(value: "A")])
        let b = makeLine(chunks: [makeChunk(value: "B")])
        #expect(a != b)
    }

    @Test("Lines can be used in a Set")
    func setUsage() {
        let a = makeLine(chunks: [makeChunk(value: "A")])
        let b = makeLine(chunks: [makeChunk(value: "B")])
        let c = makeLine(chunks: [makeChunk(value: "A")]) // duplicate of a
        let set: Set<TextLine> = [a, b, c]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("TextLine roundtrips through Codable")
    func codableRoundtrip() throws {
        let line = makeLine(isLineStart: true, isLineEnd: true)
        let data = try JSONEncoder().encode(line)
        let decoded = try JSONDecoder().decode(TextLine.self, from: data)

        #expect(decoded.boundingBox == line.boundingBox)
        #expect(decoded.chunks.count == line.chunks.count)
        #expect(decoded.isLineStart == true)
        #expect(decoded.isLineEnd == true)
        #expect(decoded.text == line.text)
    }

    @Test("TextLine Codable with empty chunks")
    func codableEmptyChunks() throws {
        let line = TextLine(boundingBox: makeBox(), chunks: [])
        let data = try JSONEncoder().encode(line)
        let decoded = try JSONDecoder().decode(TextLine.self, from: data)
        #expect(decoded.chunks.isEmpty)
    }

    // MARK: - Sendable

    @Test("TextLine is Sendable")
    func sendable() async {
        let line = makeLine()
        let task = Task { @Sendable in
            return line.text
        }
        let result = await task.value
        #expect(result == "Hello World")
    }
}

import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

/// Tests for `LineArtChunk` struct.
@Suite("LineArtChunk Tests")
struct LineArtChunkTests {

    // MARK: - Helpers

    /// Creates a bounding box for testing.
    private func makeBox(page: Int = 0, x: CGFloat = 0, y: CGFloat = 0,
                         width: CGFloat = 200, height: CGFloat = 200) -> BoundingBox {
        BoundingBox(pageIndex: page, x: x, y: y, width: width, height: height)
    }

    /// Creates a horizontal line chunk on a page.
    private func makeHLine(page: Int = 0, y: CGFloat = 50,
                           fromX: CGFloat = 0, toX: CGFloat = 100) -> LineChunk {
        LineChunk(
            pageIndex: page,
            startPoint: CGPoint(x: fromX, y: y),
            endPoint: CGPoint(x: toX, y: y)
        )
    }

    /// Creates a vertical line chunk on a page.
    private func makeVLine(page: Int = 0, x: CGFloat = 50,
                           fromY: CGFloat = 0, toY: CGFloat = 100) -> LineChunk {
        LineChunk(
            pageIndex: page,
            startPoint: CGPoint(x: x, y: fromY),
            endPoint: CGPoint(x: x, y: toY)
        )
    }

    /// Creates a simple line art chunk with a box of horizontal and vertical lines.
    private func makeGridArt(page: Int = 0) -> LineArtChunk {
        let lines = [
            makeHLine(page: page, y: 0, fromX: 0, toX: 100),
            makeHLine(page: page, y: 50, fromX: 0, toX: 100),
            makeHLine(page: page, y: 100, fromX: 0, toX: 100),
            makeVLine(page: page, x: 0, fromY: 0, toY: 100),
            makeVLine(page: page, x: 50, fromY: 0, toY: 100),
            makeVLine(page: page, x: 100, fromY: 0, toY: 100),
        ]
        return LineArtChunk(lines: lines, altText: "A grid")
    }

    // MARK: - Initialization (explicit bounding box)

    @Test("LineArtChunk stores all properties with explicit bounding box")
    func initExplicitBox() {
        let box = makeBox(page: 2)
        let lines = [makeHLine(page: 2), makeVLine(page: 2)]
        let chunk = LineArtChunk(
            boundingBox: box,
            lines: lines,
            altText: "Diagram",
            actualText: "A flowchart"
        )

        #expect(chunk.boundingBox == box)
        #expect(chunk.lines.count == 2)
        #expect(chunk.altText == "Diagram")
        #expect(chunk.actualText == "A flowchart")
    }

    @Test("LineArtChunk explicit box default optional values")
    func initExplicitBoxDefaults() {
        let box = makeBox()
        let chunk = LineArtChunk(boundingBox: box, lines: [])

        #expect(chunk.altText == nil)
        #expect(chunk.actualText == nil)
        #expect(chunk.lines.isEmpty)
    }

    // MARK: - Initialization (auto-computed bounding box)

    @Test("LineArtChunk auto-computes bounding box from lines")
    func initAutoBox() {
        let lines = [
            makeHLine(page: 0, y: 10, fromX: 5, toX: 95),
            makeHLine(page: 0, y: 90, fromX: 5, toX: 95),
        ]
        let chunk = LineArtChunk(lines: lines)

        #expect(chunk.boundingBox.pageIndex == 0)
        // The bounding box should encompass both lines
        #expect(chunk.boundingBox.leftX <= 5)
        #expect(chunk.boundingBox.rightX >= 95)
        #expect(chunk.boundingBox.bottomY <= 10)
        #expect(chunk.boundingBox.topY >= 90)
    }

    @Test("LineArtChunk with empty lines gets zero bounding box")
    func initEmptyLines() {
        let chunk = LineArtChunk(lines: [])

        #expect(chunk.boundingBox.pageIndex == 0)
        #expect(chunk.boundingBox.rect == .zero)
        #expect(chunk.isEmpty)
    }

    @Test("LineArtChunk auto-box with single line")
    func initAutoBoxSingleLine() {
        let line = makeHLine(page: 3, y: 50, fromX: 10, toX: 90)
        let chunk = LineArtChunk(lines: [line])

        #expect(chunk.boundingBox.pageIndex == 3)
        #expect(chunk.boundingBox == line.boundingBox)
    }

    // MARK: - ContentChunk Conformance

    @Test("LineArtChunk conforms to ContentChunk protocol")
    func contentChunkConformance() {
        let chunk = LineArtChunk(
            boundingBox: makeBox(page: 4),
            lines: []
        )
        let contentChunk: any ContentChunk = chunk
        #expect(contentChunk.pageIndex == 4)
    }

    @Test("LineArtChunk pageIndex delegates to boundingBox")
    func pageIndexDelegation() {
        let chunk = LineArtChunk(
            boundingBox: makeBox(page: 7),
            lines: []
        )
        #expect(chunk.pageIndex == 7)
    }

    // MARK: - hasAlternativeText

    @Test("hasAlternativeText true with altText")
    func hasAltTextWithAlt() {
        let chunk = LineArtChunk(boundingBox: makeBox(), lines: [], altText: "Diagram")
        #expect(chunk.hasAlternativeText == true)
    }

    @Test("hasAlternativeText true with actualText")
    func hasAltTextWithActual() {
        let chunk = LineArtChunk(boundingBox: makeBox(), lines: [], actualText: "Flowchart")
        #expect(chunk.hasAlternativeText == true)
    }

    @Test("hasAlternativeText true with both")
    func hasAltTextWithBoth() {
        let chunk = LineArtChunk(
            boundingBox: makeBox(),
            lines: [],
            altText: "Alt",
            actualText: "Actual"
        )
        #expect(chunk.hasAlternativeText == true)
    }

    @Test("hasAlternativeText false with nil")
    func hasAltTextNil() {
        let chunk = LineArtChunk(boundingBox: makeBox(), lines: [])
        #expect(chunk.hasAlternativeText == false)
    }

    @Test("hasAlternativeText false with empty altText")
    func hasAltTextEmpty() {
        let chunk = LineArtChunk(boundingBox: makeBox(), lines: [], altText: "")
        #expect(chunk.hasAlternativeText == false)
    }

    @Test("hasAlternativeText false with empty actualText")
    func hasAltTextEmptyActual() {
        let chunk = LineArtChunk(boundingBox: makeBox(), lines: [], actualText: "")
        #expect(chunk.hasAlternativeText == false)
    }

    // MARK: - lineCount and isEmpty

    @Test("lineCount returns correct value")
    func lineCountCorrect() {
        let art = makeGridArt()
        #expect(art.lineCount == 6)
    }

    @Test("lineCount for empty art")
    func lineCountEmpty() {
        let chunk = LineArtChunk(boundingBox: makeBox(), lines: [])
        #expect(chunk.lineCount == 0)
    }

    @Test("isEmpty is true for empty art")
    func isEmptyTrue() {
        let chunk = LineArtChunk(boundingBox: makeBox(), lines: [])
        #expect(chunk.isEmpty == true)
    }

    @Test("isEmpty is false for non-empty art")
    func isEmptyFalse() {
        let chunk = LineArtChunk(
            boundingBox: makeBox(),
            lines: [makeHLine()]
        )
        #expect(chunk.isEmpty == false)
    }

    // MARK: - totalLength

    @Test("totalLength sums all line lengths")
    func totalLengthSum() {
        let lines = [
            makeHLine(y: 0, fromX: 0, toX: 100),   // length 100
            makeHLine(y: 50, fromX: 0, toX: 100),   // length 100
            makeVLine(x: 0, fromY: 0, toY: 50),     // length 50
        ]
        let chunk = LineArtChunk(lines: lines)
        #expect(abs(chunk.totalLength - 250.0) < 0.001)
    }

    @Test("totalLength for empty art is zero")
    func totalLengthEmpty() {
        let chunk = LineArtChunk(boundingBox: makeBox(), lines: [])
        #expect(abs(chunk.totalLength) < 0.001)
    }

    // MARK: - horizontalLines / verticalLines

    @Test("horizontalLines filters correctly")
    func horizontalLinesFilter() {
        let art = makeGridArt()
        #expect(art.horizontalLines.count == 3)
    }

    @Test("verticalLines filters correctly")
    func verticalLinesFilter() {
        let art = makeGridArt()
        #expect(art.verticalLines.count == 3)
    }

    @Test("horizontalLines empty when all vertical")
    func horizontalLinesEmpty() {
        let lines = [makeVLine(x: 0), makeVLine(x: 50)]
        let chunk = LineArtChunk(lines: lines)
        #expect(chunk.horizontalLines.isEmpty)
    }

    // MARK: - appearsGridLike

    @Test("Grid art appears grid-like")
    func appearsGridLikeTrue() {
        let art = makeGridArt()
        #expect(art.appearsGridLike == true)
    }

    @Test("Single line does not appear grid-like")
    func appearsGridLikeFalse() {
        let chunk = LineArtChunk(lines: [makeHLine()])
        #expect(chunk.appearsGridLike == false)
    }

    @Test("Only horizontal lines not grid-like")
    func appearsGridLikeOnlyHorizontal() {
        let lines = [makeHLine(y: 0), makeHLine(y: 50), makeHLine(y: 100)]
        let chunk = LineArtChunk(lines: lines)
        #expect(chunk.appearsGridLike == false)
    }

    @Test("Two H + Two V is grid-like")
    func appearsGridLikeMinimal() {
        let lines = [
            makeHLine(y: 0), makeHLine(y: 100),
            makeVLine(x: 0), makeVLine(x: 100),
        ]
        let chunk = LineArtChunk(lines: lines)
        #expect(chunk.appearsGridLike == true)
    }

    // MARK: - textDescription

    @Test("textDescription prefers altText")
    func textDescriptionPrefersAlt() {
        let chunk = LineArtChunk(
            boundingBox: makeBox(),
            lines: [],
            altText: "Alt",
            actualText: "Actual"
        )
        #expect(chunk.textDescription == "Alt")
    }

    @Test("textDescription falls back to actualText")
    func textDescriptionFallback() {
        let chunk = LineArtChunk(
            boundingBox: makeBox(),
            lines: [],
            actualText: "Actual"
        )
        #expect(chunk.textDescription == "Actual")
    }

    @Test("textDescription returns nil when none set")
    func textDescriptionNil() {
        let chunk = LineArtChunk(boundingBox: makeBox(), lines: [])
        #expect(chunk.textDescription == nil)
    }

    @Test("textDescription skips empty altText")
    func textDescriptionSkipsEmpty() {
        let chunk = LineArtChunk(
            boundingBox: makeBox(),
            lines: [],
            altText: "",
            actualText: "Actual"
        )
        #expect(chunk.textDescription == "Actual")
    }

    // MARK: - area

    @Test("area returns bounding box area")
    func areaValue() {
        let box = makeBox(width: 50, height: 80)
        let chunk = LineArtChunk(boundingBox: box, lines: [])
        #expect(abs(chunk.area - 4000.0) < 0.001)
    }

    // MARK: - Equatable and Hashable

    @Test("Equal LineArtChunks are equal")
    func equalityTrue() {
        let lines = [makeHLine(), makeVLine()]
        let chunk1 = LineArtChunk(boundingBox: makeBox(), lines: lines, altText: "test")
        let chunk2 = LineArtChunk(boundingBox: makeBox(), lines: lines, altText: "test")
        #expect(chunk1 == chunk2)
    }

    @Test("Different LineArtChunks are not equal")
    func equalityFalse() {
        let chunk1 = LineArtChunk(boundingBox: makeBox(), lines: [makeHLine()], altText: "one")
        let chunk2 = LineArtChunk(boundingBox: makeBox(), lines: [makeVLine()], altText: "two")
        #expect(chunk1 != chunk2)
    }

    @Test("LineArtChunks can be used in a Set")
    func hashableSet() {
        let chunk1 = LineArtChunk(boundingBox: makeBox(), lines: [makeHLine()], altText: "one")
        let chunk2 = LineArtChunk(boundingBox: makeBox(), lines: [makeVLine()], altText: "two")
        let chunk3 = LineArtChunk(boundingBox: makeBox(), lines: [makeHLine()], altText: "one")
        let set: Set<LineArtChunk> = [chunk1, chunk2, chunk3]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("LineArtChunk roundtrips through Codable")
    func codableRoundtrip() throws {
        let lines = [
            makeHLine(y: 10, fromX: 0, toX: 100),
            makeVLine(x: 50, fromY: 0, toY: 100),
        ]
        let chunk = LineArtChunk(
            boundingBox: makeBox(page: 1),
            lines: lines,
            altText: "A cross",
            actualText: "Plus sign"
        )

        let data = try JSONEncoder().encode(chunk)
        let decoded = try JSONDecoder().decode(LineArtChunk.self, from: data)

        #expect(decoded.boundingBox == chunk.boundingBox)
        #expect(decoded.lines.count == chunk.lines.count)
        #expect(decoded.altText == "A cross")
        #expect(decoded.actualText == "Plus sign")
    }

    @Test("LineArtChunk Codable preserves nil optionals")
    func codableNilOptionals() throws {
        let chunk = LineArtChunk(boundingBox: makeBox(), lines: [])

        let data = try JSONEncoder().encode(chunk)
        let decoded = try JSONDecoder().decode(LineArtChunk.self, from: data)

        #expect(decoded.altText == nil)
        #expect(decoded.actualText == nil)
    }

    // MARK: - Sendable

    @Test("LineArtChunk is Sendable")
    func sendableConformance() async {
        let chunk = makeGridArt()
        let task = Task { chunk }
        let result = await task.value
        #expect(result.lineCount == 6)
    }
}

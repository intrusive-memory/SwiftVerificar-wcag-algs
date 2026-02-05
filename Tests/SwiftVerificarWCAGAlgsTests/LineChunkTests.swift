import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

/// Tests for `LineChunk` struct.
@Suite("LineChunk Tests")
struct LineChunkTests {

    // MARK: - Helpers

    /// Creates a default bounding box for testing.
    private func makeBox(page: Int = 0, x: CGFloat = 0, y: CGFloat = 0,
                         width: CGFloat = 100, height: CGFloat = 0.5) -> BoundingBox {
        BoundingBox(pageIndex: page, x: x, y: y, width: width, height: height)
    }

    /// Creates a horizontal line on the given page.
    private func makeHorizontalLine(
        page: Int = 0,
        y: CGFloat = 50,
        fromX: CGFloat = 10,
        toX: CGFloat = 110,
        lineWidth: CGFloat = 1.0,
        color: [CGFloat] = [0, 0, 0, 1]
    ) -> LineChunk {
        LineChunk(
            pageIndex: page,
            startPoint: CGPoint(x: fromX, y: y),
            endPoint: CGPoint(x: toX, y: y),
            lineWidth: lineWidth,
            strokeColorComponents: color
        )
    }

    /// Creates a vertical line on the given page.
    private func makeVerticalLine(
        page: Int = 0,
        x: CGFloat = 50,
        fromY: CGFloat = 10,
        toY: CGFloat = 110,
        lineWidth: CGFloat = 1.0
    ) -> LineChunk {
        LineChunk(
            pageIndex: page,
            startPoint: CGPoint(x: x, y: fromY),
            endPoint: CGPoint(x: x, y: toY),
            lineWidth: lineWidth
        )
    }

    /// Creates a diagonal line on the given page.
    private func makeDiagonalLine(
        page: Int = 0,
        from: CGPoint = CGPoint(x: 0, y: 0),
        to: CGPoint = CGPoint(x: 100, y: 100)
    ) -> LineChunk {
        LineChunk(pageIndex: page, startPoint: from, endPoint: to)
    }

    // MARK: - Initialization (with explicit bounding box)

    @Test("LineChunk stores all properties with explicit bounding box")
    func initWithExplicitBox() {
        let box = makeBox(page: 2, x: 10, y: 20, width: 100, height: 1)
        let start = CGPoint(x: 10, y: 20.5)
        let end = CGPoint(x: 110, y: 20.5)
        let chunk = LineChunk(
            boundingBox: box,
            startPoint: start,
            endPoint: end,
            lineWidth: 2.0,
            strokeColorComponents: [1, 0, 0, 1]
        )

        #expect(chunk.boundingBox == box)
        #expect(chunk.startPoint == start)
        #expect(chunk.endPoint == end)
        #expect(chunk.lineWidth == 2.0)
        #expect(chunk.strokeColorComponents == [1, 0, 0, 1])
    }

    @Test("LineChunk default values with explicit bounding box")
    func initExplicitBoxDefaults() {
        let box = makeBox()
        let chunk = LineChunk(
            boundingBox: box,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 100, y: 0)
        )
        #expect(chunk.lineWidth == 1.0)
        #expect(chunk.strokeColorComponents == [0, 0, 0, 1])
    }

    // MARK: - Initialization (auto-computed bounding box)

    @Test("LineChunk auto-computes bounding box from endpoints and width")
    func initAutoBox() {
        let chunk = LineChunk(
            pageIndex: 3,
            startPoint: CGPoint(x: 10, y: 20),
            endPoint: CGPoint(x: 110, y: 20),
            lineWidth: 4.0
        )

        #expect(chunk.boundingBox.pageIndex == 3)
        // With lineWidth 4, halfWidth = 2
        #expect(abs(chunk.boundingBox.leftX - 8.0) < 0.001)
        #expect(abs(chunk.boundingBox.bottomY - 18.0) < 0.001)
        #expect(abs(chunk.boundingBox.rightX - 112.0) < 0.001)
        #expect(abs(chunk.boundingBox.topY - 22.0) < 0.001)
    }

    @Test("LineChunk auto bounding box for diagonal line")
    func initAutoBoxDiagonal() {
        let chunk = LineChunk(
            pageIndex: 0,
            startPoint: CGPoint(x: 10, y: 20),
            endPoint: CGPoint(x: 50, y: 80),
            lineWidth: 2.0
        )

        // halfWidth = 1
        #expect(abs(chunk.boundingBox.leftX - 9.0) < 0.001)
        #expect(abs(chunk.boundingBox.bottomY - 19.0) < 0.001)
        #expect(abs(chunk.boundingBox.rightX - 51.0) < 0.001)
        #expect(abs(chunk.boundingBox.topY - 81.0) < 0.001)
    }

    @Test("LineChunk auto bounding box for reversed endpoints")
    func initAutoBoxReversed() {
        let chunk = LineChunk(
            pageIndex: 0,
            startPoint: CGPoint(x: 100, y: 80),
            endPoint: CGPoint(x: 10, y: 20),
            lineWidth: 2.0
        )

        // Same as forward direction
        #expect(abs(chunk.boundingBox.leftX - 9.0) < 0.001)
        #expect(abs(chunk.boundingBox.bottomY - 19.0) < 0.001)
        #expect(abs(chunk.boundingBox.rightX - 101.0) < 0.001)
        #expect(abs(chunk.boundingBox.topY - 81.0) < 0.001)
    }

    // MARK: - ContentChunk Conformance

    @Test("LineChunk conforms to ContentChunk protocol")
    func contentChunkConformance() {
        let chunk = makeHorizontalLine(page: 5)
        let contentChunk: any ContentChunk = chunk
        #expect(contentChunk.pageIndex == 5)
    }

    @Test("LineChunk pageIndex delegates to boundingBox")
    func pageIndexDelegation() {
        let chunk = makeHorizontalLine(page: 3)
        #expect(chunk.pageIndex == 3)
        #expect(chunk.pageIndex == chunk.boundingBox.pageIndex)
    }

    // MARK: - length

    @Test("Length of horizontal line")
    func lengthHorizontal() {
        let chunk = makeHorizontalLine(fromX: 10, toX: 110)
        #expect(abs(chunk.length - 100.0) < 0.001)
    }

    @Test("Length of vertical line")
    func lengthVertical() {
        let chunk = makeVerticalLine(fromY: 10, toY: 110)
        #expect(abs(chunk.length - 100.0) < 0.001)
    }

    @Test("Length of diagonal line")
    func lengthDiagonal() {
        let chunk = makeDiagonalLine(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 3, y: 4))
        #expect(abs(chunk.length - 5.0) < 0.001)
    }

    @Test("Length of zero-length line")
    func lengthZero() {
        let chunk = makeDiagonalLine(
            from: CGPoint(x: 50, y: 50),
            to: CGPoint(x: 50, y: 50)
        )
        #expect(abs(chunk.length) < 0.001)
    }

    // MARK: - isHorizontal / isVertical

    @Test("Horizontal line is detected as horizontal")
    func isHorizontalTrue() {
        let chunk = makeHorizontalLine()
        #expect(chunk.isHorizontal == true)
        #expect(chunk.isVertical == false)
    }

    @Test("Vertical line is detected as vertical")
    func isVerticalTrue() {
        let chunk = makeVerticalLine()
        #expect(chunk.isVertical == true)
        #expect(chunk.isHorizontal == false)
    }

    @Test("Diagonal line is neither horizontal nor vertical")
    func diagonalNotAxisAligned() {
        let chunk = makeDiagonalLine(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 100, y: 100))
        #expect(chunk.isHorizontal == false)
        #expect(chunk.isVertical == false)
    }

    @Test("Nearly horizontal line is considered horizontal")
    func nearlyHorizontal() {
        // A line with tiny y-variation
        let chunk = LineChunk(
            pageIndex: 0,
            startPoint: CGPoint(x: 0, y: 50),
            endPoint: CGPoint(x: 200, y: 50.1)
        )
        #expect(chunk.isHorizontal == true)
    }

    @Test("Nearly vertical line is considered vertical")
    func nearlyVertical() {
        let chunk = LineChunk(
            pageIndex: 0,
            startPoint: CGPoint(x: 50, y: 0),
            endPoint: CGPoint(x: 50.1, y: 200)
        )
        #expect(chunk.isVertical == true)
    }

    @Test("Zero-length line is both horizontal and vertical")
    func zeroLengthIsAxisAligned() {
        let chunk = makeDiagonalLine(
            from: CGPoint(x: 50, y: 50),
            to: CGPoint(x: 50, y: 50)
        )
        #expect(chunk.isHorizontal == true)
        #expect(chunk.isVertical == true)
    }

    // MARK: - isAxisAligned

    @Test("Horizontal line is axis-aligned")
    func axisAlignedHorizontal() {
        let chunk = makeHorizontalLine()
        #expect(chunk.isAxisAligned == true)
    }

    @Test("Vertical line is axis-aligned")
    func axisAlignedVertical() {
        let chunk = makeVerticalLine()
        #expect(chunk.isAxisAligned == true)
    }

    @Test("Diagonal line is not axis-aligned")
    func axisAlignedDiagonal() {
        let chunk = makeDiagonalLine()
        #expect(chunk.isAxisAligned == false)
    }

    // MARK: - angle

    @Test("Angle of horizontal line pointing right is 0")
    func angleHorizontalRight() {
        let chunk = makeHorizontalLine(fromX: 0, toX: 100)
        #expect(abs(chunk.angle) < 0.001)
    }

    @Test("Angle of vertical line pointing up is pi/2")
    func angleVerticalUp() {
        let chunk = makeVerticalLine(fromY: 0, toY: 100)
        #expect(abs(chunk.angle - .pi / 2) < 0.001)
    }

    @Test("Angle of 45-degree diagonal")
    func angle45() {
        let chunk = makeDiagonalLine(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 100, y: 100))
        #expect(abs(chunk.angle - .pi / 4) < 0.001)
    }

    // MARK: - midpoint

    @Test("Midpoint of horizontal line")
    func midpointHorizontal() {
        let chunk = makeHorizontalLine(y: 50, fromX: 10, toX: 110)
        #expect(abs(chunk.midpoint.x - 60.0) < 0.001)
        #expect(abs(chunk.midpoint.y - 50.0) < 0.001)
    }

    @Test("Midpoint of diagonal line")
    func midpointDiagonal() {
        let chunk = makeDiagonalLine(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 100, y: 200))
        #expect(abs(chunk.midpoint.x - 50.0) < 0.001)
        #expect(abs(chunk.midpoint.y - 100.0) < 0.001)
    }

    // MARK: - strokeColor

    @Test("strokeColor creates CGColor from components")
    func strokeColorCreation() {
        let chunk = makeHorizontalLine(color: [1, 0, 0, 1])
        let color = chunk.strokeColor
        #expect(color.numberOfComponents >= 3)
    }

    @Test("strokeColor with default black components")
    func strokeColorDefault() {
        let chunk = makeHorizontalLine()
        let color = chunk.strokeColor
        #expect(color.numberOfComponents >= 3)
    }

    // MARK: - distance(to:)

    @Test("Distance to point on the line is zero")
    func distanceOnLine() {
        let chunk = makeHorizontalLine(y: 50, fromX: 0, toX: 100)
        let distance = chunk.distance(to: CGPoint(x: 50, y: 50))
        #expect(abs(distance) < 0.001)
    }

    @Test("Distance to point above horizontal line")
    func distanceAboveLine() {
        let chunk = makeHorizontalLine(y: 50, fromX: 0, toX: 100)
        let distance = chunk.distance(to: CGPoint(x: 50, y: 60))
        #expect(abs(distance - 10.0) < 0.001)
    }

    @Test("Distance to point past the endpoint")
    func distancePastEndpoint() {
        let chunk = makeHorizontalLine(y: 50, fromX: 0, toX: 100)
        let distance = chunk.distance(to: CGPoint(x: 110, y: 50))
        #expect(abs(distance - 10.0) < 0.001)
    }

    @Test("Distance to point from zero-length line")
    func distanceFromZeroLength() {
        let chunk = makeDiagonalLine(
            from: CGPoint(x: 50, y: 50),
            to: CGPoint(x: 50, y: 50)
        )
        let distance = chunk.distance(to: CGPoint(x: 53, y: 54))
        #expect(abs(distance - 5.0) < 0.001) // 3-4-5 triangle
    }

    @Test("Distance to point before the startpoint")
    func distanceBeforeStart() {
        let chunk = makeHorizontalLine(y: 50, fromX: 10, toX: 100)
        let distance = chunk.distance(to: CGPoint(x: 0, y: 50))
        #expect(abs(distance - 10.0) < 0.001)
    }

    // MARK: - isCollinear

    @Test("Collinear overlapping horizontal lines")
    func collinearOverlapping() {
        let line1 = makeHorizontalLine(y: 50, fromX: 0, toX: 100)
        let line2 = makeHorizontalLine(y: 50, fromX: 50, toX: 150)
        #expect(line1.isCollinear(with: line2, tolerance: 1.0) == true)
    }

    @Test("Collinear adjacent horizontal lines")
    func collinearAdjacent() {
        let line1 = makeHorizontalLine(y: 50, fromX: 0, toX: 100)
        let line2 = makeHorizontalLine(y: 50, fromX: 100, toX: 200)
        #expect(line1.isCollinear(with: line2, tolerance: 1.0) == true)
    }

    @Test("Non-collinear parallel lines")
    func nonCollinearParallel() {
        let line1 = makeHorizontalLine(y: 50, fromX: 0, toX: 100)
        let line2 = makeHorizontalLine(y: 60, fromX: 0, toX: 100)
        #expect(line1.isCollinear(with: line2, tolerance: 1.0) == false)
    }

    @Test("Non-collinear lines on different pages")
    func nonCollinearDifferentPages() {
        let line1 = makeHorizontalLine(page: 0, y: 50, fromX: 0, toX: 100)
        let line2 = makeHorizontalLine(page: 1, y: 50, fromX: 0, toX: 100)
        #expect(line1.isCollinear(with: line2) == false)
    }

    // MARK: - Equatable and Hashable

    @Test("Equal LineChunks are equal")
    func equalityTrue() {
        let line1 = makeHorizontalLine(y: 50, fromX: 0, toX: 100)
        let line2 = makeHorizontalLine(y: 50, fromX: 0, toX: 100)
        #expect(line1 == line2)
    }

    @Test("Different LineChunks are not equal")
    func equalityFalse() {
        let line1 = makeHorizontalLine(y: 50, fromX: 0, toX: 100)
        let line2 = makeHorizontalLine(y: 60, fromX: 0, toX: 100)
        #expect(line1 != line2)
    }

    @Test("LineChunks with different colors are not equal")
    func equalityDifferentColor() {
        let line1 = makeHorizontalLine(color: [1, 0, 0, 1])
        let line2 = makeHorizontalLine(color: [0, 1, 0, 1])
        #expect(line1 != line2)
    }

    @Test("LineChunks can be used in a Set")
    func hashableSet() {
        let line1 = makeHorizontalLine(y: 50)
        let line2 = makeHorizontalLine(y: 60)
        let line3 = makeHorizontalLine(y: 50) // duplicate of line1
        let set: Set<LineChunk> = [line1, line2, line3]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("LineChunk roundtrips through Codable")
    func codableRoundtrip() throws {
        let chunk = LineChunk(
            pageIndex: 2,
            startPoint: CGPoint(x: 10.5, y: 20.3),
            endPoint: CGPoint(x: 110.7, y: 20.3),
            lineWidth: 2.5,
            strokeColorComponents: [1, 0, 0.5, 0.8]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(chunk)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LineChunk.self, from: data)

        #expect(decoded.boundingBox == chunk.boundingBox)
        #expect(decoded.startPoint == chunk.startPoint)
        #expect(decoded.endPoint == chunk.endPoint)
        #expect(decoded.lineWidth == chunk.lineWidth)
        #expect(decoded.strokeColorComponents == chunk.strokeColorComponents)
    }

    @Test("LineChunk Codable preserves explicit bounding box")
    func codableExplicitBox() throws {
        let box = makeBox(page: 5, x: 0, y: 0, width: 200, height: 10)
        let chunk = LineChunk(
            boundingBox: box,
            startPoint: CGPoint(x: 0, y: 5),
            endPoint: CGPoint(x: 200, y: 5),
            lineWidth: 3.0
        )

        let data = try JSONEncoder().encode(chunk)
        let decoded = try JSONDecoder().decode(LineChunk.self, from: data)

        #expect(decoded.boundingBox == box)
        #expect(decoded.startPoint.x == 0)
        #expect(decoded.endPoint.x == 200)
    }

    // MARK: - Sendable

    @Test("LineChunk is Sendable")
    func sendableConformance() async {
        let chunk = makeHorizontalLine()
        let task = Task { chunk }
        let result = await task.value
        #expect(result.isHorizontal == true)
    }
}

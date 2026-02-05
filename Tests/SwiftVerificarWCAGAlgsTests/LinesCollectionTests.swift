import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

/// Tests for `LinesCollection` struct.
@Suite("LinesCollection Tests")
struct LinesCollectionTests {

    // MARK: - Helpers

    /// Creates a horizontal line chunk.
    private func makeHLine(page: Int = 0, y: CGFloat = 50,
                           fromX: CGFloat = 0, toX: CGFloat = 100,
                           lineWidth: CGFloat = 1.0) -> LineChunk {
        LineChunk(
            pageIndex: page,
            startPoint: CGPoint(x: fromX, y: y),
            endPoint: CGPoint(x: toX, y: y),
            lineWidth: lineWidth
        )
    }

    /// Creates a vertical line chunk.
    private func makeVLine(page: Int = 0, x: CGFloat = 50,
                           fromY: CGFloat = 0, toY: CGFloat = 100,
                           lineWidth: CGFloat = 1.0) -> LineChunk {
        LineChunk(
            pageIndex: page,
            startPoint: CGPoint(x: x, y: fromY),
            endPoint: CGPoint(x: x, y: toY),
            lineWidth: lineWidth
        )
    }

    /// Creates a diagonal line chunk.
    private func makeDiagLine(page: Int = 0,
                              from: CGPoint = CGPoint(x: 0, y: 0),
                              to: CGPoint = CGPoint(x: 100, y: 100)) -> LineChunk {
        LineChunk(pageIndex: page, startPoint: from, endPoint: to)
    }

    /// Creates a sample collection with mixed line types across pages.
    private func makeSampleCollection() -> LinesCollection {
        LinesCollection(lines: [
            makeHLine(page: 0, y: 10, fromX: 0, toX: 100),
            makeHLine(page: 0, y: 50, fromX: 0, toX: 100),
            makeVLine(page: 0, x: 0, fromY: 0, toY: 100),
            makeVLine(page: 0, x: 100, fromY: 0, toY: 100),
            makeDiagLine(page: 0, from: CGPoint(x: 0, y: 0), to: CGPoint(x: 100, y: 100)),
            makeHLine(page: 1, y: 20, fromX: 10, toX: 90),
            makeVLine(page: 1, x: 50, fromY: 10, toY: 90),
        ])
    }

    // MARK: - Initialization

    @Test("Empty LinesCollection has no lines")
    func initEmpty() {
        let collection = LinesCollection()
        #expect(collection.isEmpty)
        #expect(collection.count == 0)
    }

    @Test("LinesCollection stores lines sorted by page index")
    func initSorted() {
        let line1 = makeHLine(page: 2)
        let line2 = makeHLine(page: 0)
        let line3 = makeHLine(page: 1)

        let collection = LinesCollection(lines: [line1, line2, line3])

        #expect(collection.count == 3)
        #expect(collection.lines[0].pageIndex == 0)
        #expect(collection.lines[1].pageIndex == 1)
        #expect(collection.lines[2].pageIndex == 2)
    }

    @Test("LinesCollection with default empty array")
    func initDefaultEmpty() {
        let collection = LinesCollection(lines: [])
        #expect(collection.isEmpty)
    }

    // MARK: - Computed Properties

    @Test("isEmpty returns true for empty collection")
    func isEmptyTrue() {
        let collection = LinesCollection()
        #expect(collection.isEmpty == true)
    }

    @Test("isEmpty returns false for non-empty collection")
    func isEmptyFalse() {
        let collection = LinesCollection(lines: [makeHLine()])
        #expect(collection.isEmpty == false)
    }

    @Test("count returns correct value")
    func countCorrect() {
        let collection = makeSampleCollection()
        #expect(collection.count == 7)
    }

    @Test("pageIndices returns correct set")
    func pageIndicesCorrect() {
        let collection = makeSampleCollection()
        #expect(collection.pageIndices == Set([0, 1]))
    }

    @Test("pageIndices empty for empty collection")
    func pageIndicesEmpty() {
        let collection = LinesCollection()
        #expect(collection.pageIndices.isEmpty)
    }

    @Test("pageCount returns correct value")
    func pageCountCorrect() {
        let collection = makeSampleCollection()
        #expect(collection.pageCount == 2)
    }

    @Test("pageCount is zero for empty collection")
    func pageCountEmpty() {
        let collection = LinesCollection()
        #expect(collection.pageCount == 0)
    }

    // MARK: - Orientation Filtering

    @Test("horizontalLines returns only horizontal lines")
    func horizontalLinesFilter() {
        let collection = makeSampleCollection()
        let hLines = collection.horizontalLines
        #expect(hLines.count == 3) // 2 on page 0, 1 on page 1
        for line in hLines {
            #expect(line.isHorizontal == true)
        }
    }

    @Test("verticalLines returns only vertical lines")
    func verticalLinesFilter() {
        let collection = makeSampleCollection()
        let vLines = collection.verticalLines
        #expect(vLines.count == 3) // 2 on page 0, 1 on page 1
        for line in vLines {
            #expect(line.isVertical == true)
        }
    }

    @Test("axisAlignedLines returns horizontal and vertical only")
    func axisAlignedFilter() {
        let collection = makeSampleCollection()
        let aligned = collection.axisAlignedLines
        #expect(aligned.count == 6) // all except the diagonal
        for line in aligned {
            #expect(line.isAxisAligned == true)
        }
    }

    @Test("filterHorizontal returns LinesCollection of horizontal lines")
    func filterHorizontalCollection() {
        let collection = makeSampleCollection()
        let filtered = collection.filterHorizontal()
        #expect(filtered.count == 3)
    }

    @Test("filterVertical returns LinesCollection of vertical lines")
    func filterVerticalCollection() {
        let collection = makeSampleCollection()
        let filtered = collection.filterVertical()
        #expect(filtered.count == 3)
    }

    @Test("filterAxisAligned returns LinesCollection")
    func filterAxisAlignedCollection() {
        let collection = makeSampleCollection()
        let filtered = collection.filterAxisAligned()
        #expect(filtered.count == 6)
    }

    // MARK: - Page Filtering

    @Test("lines(onPage:) returns lines on specified page")
    func linesOnPage() {
        let collection = makeSampleCollection()
        let page0Lines = collection.lines(onPage: 0)
        let page1Lines = collection.lines(onPage: 1)
        let page2Lines = collection.lines(onPage: 2)

        #expect(page0Lines.count == 5)
        #expect(page1Lines.count == 2)
        #expect(page2Lines.count == 0)
    }

    @Test("filtered(byPage:) returns LinesCollection for page")
    func filteredByPage() {
        let collection = makeSampleCollection()
        let filtered = collection.filtered(byPage: 1)

        #expect(filtered.count == 2)
        for line in filtered {
            #expect(line.pageIndex == 1)
        }
    }

    @Test("filtered(byPage:) returns empty for non-existent page")
    func filteredByPageEmpty() {
        let collection = makeSampleCollection()
        let filtered = collection.filtered(byPage: 99)
        #expect(filtered.isEmpty)
    }

    // MARK: - Spatial Queries

    @Test("lines(overlapping:) returns overlapping lines")
    func linesOverlapping() {
        let collection = LinesCollection(lines: [
            makeHLine(page: 0, y: 50, fromX: 0, toX: 100),
            makeHLine(page: 0, y: 200, fromX: 0, toX: 100),
            makeVLine(page: 0, x: 50, fromY: 0, toY: 100),
        ])

        let box = BoundingBox(pageIndex: 0, x: 40, y: 40, width: 20, height: 20)
        let overlapping = collection.lines(overlapping: box)

        // The horizontal line at y=50 and the vertical line at x=50 should overlap
        #expect(overlapping.count == 2)
    }

    @Test("lines(overlapping:) excludes non-overlapping lines")
    func linesNotOverlapping() {
        let collection = LinesCollection(lines: [
            makeHLine(page: 0, y: 50, fromX: 0, toX: 100),
        ])

        let box = BoundingBox(pageIndex: 0, x: 200, y: 200, width: 50, height: 50)
        let overlapping = collection.lines(overlapping: box)
        #expect(overlapping.isEmpty)
    }

    @Test("lines(overlapping:) respects page index")
    func linesOverlappingPage() {
        let collection = LinesCollection(lines: [
            makeHLine(page: 0, y: 50, fromX: 0, toX: 100),
            makeHLine(page: 1, y: 50, fromX: 0, toX: 100),
        ])

        let box = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 200, height: 200)
        let overlapping = collection.lines(overlapping: box)
        #expect(overlapping.count == 1)
    }

    @Test("filtered(overlapping:) returns LinesCollection")
    func filteredOverlapping() {
        let collection = LinesCollection(lines: [
            makeHLine(page: 0, y: 50, fromX: 0, toX: 100),
            makeVLine(page: 0, x: 50, fromY: 0, toY: 100),
        ])

        let box = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 200, height: 200)
        let filtered = collection.filtered(overlapping: box)
        #expect(filtered.count == 2)
    }

    @Test("lines(near:onPage:maxDistance:) finds nearby lines")
    func linesNearPoint() {
        let collection = LinesCollection(lines: [
            makeHLine(page: 0, y: 50, fromX: 0, toX: 100),
            makeHLine(page: 0, y: 200, fromX: 0, toX: 100),
        ])

        let nearby = collection.lines(
            near: CGPoint(x: 50, y: 55),
            onPage: 0,
            maxDistance: 10
        )
        #expect(nearby.count == 1)
    }

    @Test("lines(near:onPage:maxDistance:) excludes distant lines")
    func linesNearPointExcludes() {
        let collection = LinesCollection(lines: [
            makeHLine(page: 0, y: 50, fromX: 0, toX: 100),
        ])

        let nearby = collection.lines(
            near: CGPoint(x: 50, y: 200),
            onPage: 0,
            maxDistance: 10
        )
        #expect(nearby.isEmpty)
    }

    @Test("lines(near:box:maxDistance:) finds nearby lines")
    func linesNearBox() {
        let collection = LinesCollection(lines: [
            makeHLine(page: 0, y: 50, fromX: 0, toX: 100),
            makeHLine(page: 0, y: 200, fromX: 0, toX: 100),
        ])

        let box = BoundingBox(pageIndex: 0, x: 0, y: 45, width: 50, height: 10)
        let nearby = collection.lines(near: box, maxDistance: 5)
        #expect(nearby.count == 1)
    }

    @Test("lines(containedIn:) returns fully contained lines")
    func linesContainedIn() {
        let collection = LinesCollection(lines: [
            makeHLine(page: 0, y: 50, fromX: 10, toX: 90),
            makeHLine(page: 0, y: 200, fromX: 0, toX: 100),
        ])

        let box = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        let contained = collection.lines(containedIn: box)
        // Only the first line is fully contained
        #expect(contained.count == 1)
    }

    // MARK: - Mutation Methods

    @Test("adding a single line returns new collection")
    func addingSingleLine() {
        let collection = LinesCollection(lines: [makeHLine(page: 0)])
        let newLine = makeVLine(page: 0)
        let updated = collection.adding(newLine)

        #expect(updated.count == 2)
        #expect(collection.count == 1) // original unchanged
    }

    @Test("adding multiple lines returns new collection")
    func addingMultipleLines() {
        let collection = LinesCollection(lines: [makeHLine()])
        let newLines = [makeVLine(), makeHLine(y: 100)]
        let updated = collection.adding(newLines)

        #expect(updated.count == 3)
        #expect(collection.count == 1)
    }

    @Test("merged collections combine all lines")
    func mergedCollections() {
        let c1 = LinesCollection(lines: [makeHLine(page: 0), makeVLine(page: 0)])
        let c2 = LinesCollection(lines: [makeHLine(page: 1)])
        let merged = c1.merged(with: c2)

        #expect(merged.count == 3)
    }

    @Test("merged result is sorted by page index")
    func mergedSorted() {
        let c1 = LinesCollection(lines: [makeHLine(page: 2)])
        let c2 = LinesCollection(lines: [makeHLine(page: 0)])
        let merged = c1.merged(with: c2)

        #expect(merged.lines[0].pageIndex == 0)
        #expect(merged.lines[1].pageIndex == 2)
    }

    // MARK: - Line Width Filtering

    @Test("lines(withMinWidth:) filters by minimum width")
    func linesWithMinWidth() {
        let collection = LinesCollection(lines: [
            makeHLine(lineWidth: 0.5),
            makeHLine(lineWidth: 1.0),
            makeHLine(lineWidth: 2.0),
            makeHLine(lineWidth: 3.0),
        ])
        let thick = collection.lines(withMinWidth: 2.0)
        #expect(thick.count == 2)
    }

    @Test("lines(withMaxWidth:) filters by maximum width")
    func linesWithMaxWidth() {
        let collection = LinesCollection(lines: [
            makeHLine(lineWidth: 0.5),
            makeHLine(lineWidth: 1.0),
            makeHLine(lineWidth: 2.0),
            makeHLine(lineWidth: 3.0),
        ])
        let thin = collection.lines(withMaxWidth: 1.0)
        #expect(thin.count == 2)
    }

    // MARK: - Length Filtering

    @Test("lines(withMinLength:) filters by minimum length")
    func linesWithMinLength() {
        let collection = LinesCollection(lines: [
            makeHLine(fromX: 0, toX: 10),   // length ~10
            makeHLine(fromX: 0, toX: 50),   // length ~50
            makeHLine(fromX: 0, toX: 100),  // length ~100
        ])
        let long = collection.lines(withMinLength: 50)
        #expect(long.count == 2)
    }

    // MARK: - Statistics

    @Test("totalLength sums all line lengths")
    func totalLengthSum() {
        let collection = LinesCollection(lines: [
            makeHLine(fromX: 0, toX: 100),  // length 100
            makeHLine(fromX: 0, toX: 50),   // length 50
            makeVLine(fromY: 0, toY: 75),   // length 75
        ])
        #expect(abs(collection.totalLength - 225.0) < 0.001)
    }

    @Test("totalLength is zero for empty collection")
    func totalLengthEmpty() {
        let collection = LinesCollection()
        #expect(abs(collection.totalLength) < 0.001)
    }

    @Test("averageLineWidth returns correct average")
    func averageLineWidthCorrect() {
        let collection = LinesCollection(lines: [
            makeHLine(lineWidth: 1.0),
            makeHLine(lineWidth: 2.0),
            makeHLine(lineWidth: 3.0),
        ])
        let avg = collection.averageLineWidth
        #expect(avg != nil)
        #expect(abs(avg! - 2.0) < 0.001)
    }

    @Test("averageLineWidth returns nil for empty collection")
    func averageLineWidthEmpty() {
        let collection = LinesCollection()
        #expect(collection.averageLineWidth == nil)
    }

    @Test("combinedBoundingBox for single-page collection")
    func combinedBoundingBoxSinglePage() {
        let collection = LinesCollection(lines: [
            makeHLine(page: 0, y: 10, fromX: 0, toX: 100),
            makeHLine(page: 0, y: 90, fromX: 0, toX: 100),
            makeVLine(page: 0, x: 50, fromY: 0, toY: 100),
        ])
        let combined = collection.combinedBoundingBox
        #expect(combined != nil)
        #expect(combined?.pageIndex == 0)
    }

    @Test("combinedBoundingBox returns nil for empty collection")
    func combinedBoundingBoxEmpty() {
        let collection = LinesCollection()
        #expect(collection.combinedBoundingBox == nil)
    }

    @Test("combinedBoundingBox(forPage:) returns box for specified page")
    func combinedBoundingBoxForPage() {
        let collection = makeSampleCollection()
        let box0 = collection.combinedBoundingBox(forPage: 0)
        let box1 = collection.combinedBoundingBox(forPage: 1)
        let box99 = collection.combinedBoundingBox(forPage: 99)

        #expect(box0 != nil)
        #expect(box0?.pageIndex == 0)
        #expect(box1 != nil)
        #expect(box1?.pageIndex == 1)
        #expect(box99 == nil)
    }

    // MARK: - Sequence Conformance

    @Test("LinesCollection is iterable via for-in")
    func sequenceIterable() {
        let lines = [makeHLine(y: 10), makeHLine(y: 20), makeHLine(y: 30)]
        let collection = LinesCollection(lines: lines)

        var count = 0
        for _ in collection {
            count += 1
        }
        #expect(count == 3)
    }

    @Test("LinesCollection supports map")
    func sequenceMap() {
        let collection = LinesCollection(lines: [
            makeHLine(fromX: 0, toX: 100),
            makeHLine(fromX: 0, toX: 50),
        ])
        let lengths = collection.map(\.length)
        #expect(lengths.count == 2)
    }

    @Test("LinesCollection supports filter")
    func sequenceFilter() {
        let collection = LinesCollection(lines: [
            makeHLine(lineWidth: 1.0),
            makeHLine(lineWidth: 3.0),
        ])
        let thick = collection.filter { $0.lineWidth > 2.0 }
        #expect(thick.count == 1)
    }

    // MARK: - Collection Conformance

    @Test("Subscript access works correctly")
    func subscriptAccess() {
        let h = makeHLine(y: 10)
        let v = makeVLine(x: 20)
        let collection = LinesCollection(lines: [h, v])

        #expect(collection[0].isHorizontal)
        // The second might be either depending on sort, but we check count
        #expect(collection.count == 2)
    }

    @Test("startIndex and endIndex are correct")
    func indexBounds() {
        let collection = LinesCollection(lines: [makeHLine(), makeVLine()])
        #expect(collection.startIndex == 0)
        #expect(collection.endIndex == 2)
    }

    @Test("index(after:) increments correctly")
    func indexAfter() {
        let collection = LinesCollection(lines: [makeHLine(), makeVLine()])
        #expect(collection.index(after: 0) == 1)
        #expect(collection.index(after: 1) == 2)
    }

    @Test("Collection supports contains(where:)")
    func collectionContainsWhere() {
        let collection = LinesCollection(lines: [
            makeHLine(lineWidth: 1.0),
            makeHLine(lineWidth: 5.0),
        ])
        #expect(collection.contains { $0.lineWidth == 5.0 })
    }

    @Test("Collection supports first(where:)")
    func collectionFirstWhere() {
        let collection = LinesCollection(lines: [
            makeHLine(lineWidth: 1.0),
            makeHLine(lineWidth: 5.0),
        ])
        let found = collection.first { $0.lineWidth == 5.0 }
        #expect(found != nil)
        #expect(found?.lineWidth == 5.0)
    }

    // MARK: - Equatable and Hashable

    @Test("Equal LinesCollections are equal")
    func equalityTrue() {
        let lines = [makeHLine(y: 10), makeVLine(x: 20)]
        let c1 = LinesCollection(lines: lines)
        let c2 = LinesCollection(lines: lines)
        #expect(c1 == c2)
    }

    @Test("Different LinesCollections are not equal")
    func equalityFalse() {
        let c1 = LinesCollection(lines: [makeHLine(y: 10)])
        let c2 = LinesCollection(lines: [makeHLine(y: 20)])
        #expect(c1 != c2)
    }

    @Test("LinesCollections can be used in a Set")
    func hashableSet() {
        let c1 = LinesCollection(lines: [makeHLine(y: 10)])
        let c2 = LinesCollection(lines: [makeHLine(y: 20)])
        let c3 = LinesCollection(lines: [makeHLine(y: 10)]) // same as c1
        let set: Set<LinesCollection> = [c1, c2, c3]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("LinesCollection roundtrips through Codable")
    func codableRoundtrip() throws {
        let collection = LinesCollection(lines: [
            makeHLine(page: 0, y: 50, fromX: 10, toX: 90),
            makeVLine(page: 1, x: 50, fromY: 10, toY: 90),
        ])

        let data = try JSONEncoder().encode(collection)
        let decoded = try JSONDecoder().decode(LinesCollection.self, from: data)

        #expect(decoded.count == collection.count)
        #expect(decoded.lines[0].pageIndex == 0)
        #expect(decoded.lines[1].pageIndex == 1)
    }

    @Test("Empty LinesCollection roundtrips through Codable")
    func codableEmpty() throws {
        let collection = LinesCollection()
        let data = try JSONEncoder().encode(collection)
        let decoded = try JSONDecoder().decode(LinesCollection.self, from: data)
        #expect(decoded.isEmpty)
    }

    // MARK: - Sendable

    @Test("LinesCollection is Sendable")
    func sendableConformance() async {
        let collection = makeSampleCollection()
        let task = Task { collection }
        let result = await task.value
        #expect(result.count == 7)
    }
}

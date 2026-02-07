import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

@Suite("MultiBoundingBox Tests")
struct MultiBoundingBoxTests {

    // MARK: - Initialization Tests

    @Test("Init with empty array")
    func initEmpty() {
        let multi = MultiBoundingBox()
        #expect(multi.isEmpty)
        #expect(multi.count == 0)
    }

    @Test("Init with single box")
    func initSingleBox() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        let multi = MultiBoundingBox(box: box)
        #expect(multi.count == 1)
        #expect(!multi.isEmpty)
        #expect(multi.first == box)
    }

    @Test("Init with multiple boxes sorts by page index")
    func initMultipleSorted() {
        let box1 = BoundingBox(pageIndex: 2, x: 0, y: 0, width: 10, height: 10)
        let box2 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let box3 = BoundingBox(pageIndex: 1, x: 0, y: 0, width: 10, height: 10)
        let multi = MultiBoundingBox(boxes: [box1, box2, box3])
        #expect(multi.count == 3)
        #expect(multi.boxes[0].pageIndex == 0)
        #expect(multi.boxes[1].pageIndex == 1)
        #expect(multi.boxes[2].pageIndex == 2)
    }

    // MARK: - Computed Properties Tests

    @Test("pageIndices returns correct set")
    func pageIndices() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let box2 = BoundingBox(pageIndex: 1, x: 0, y: 0, width: 10, height: 10)
        let box3 = BoundingBox(pageIndex: 0, x: 50, y: 50, width: 10, height: 10)
        let multi = MultiBoundingBox(boxes: [box1, box2, box3])
        #expect(multi.pageIndices == Set([0, 1]))
    }

    @Test("pageCount returns distinct page count")
    func pageCount() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let box2 = BoundingBox(pageIndex: 1, x: 0, y: 0, width: 10, height: 10)
        let box3 = BoundingBox(pageIndex: 0, x: 50, y: 50, width: 10, height: 10)
        let multi = MultiBoundingBox(boxes: [box1, box2, box3])
        #expect(multi.pageCount == 2)
    }

    @Test("isMultiPage returns true for multiple pages")
    func isMultiPage() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let box2 = BoundingBox(pageIndex: 1, x: 0, y: 0, width: 10, height: 10)
        let multi = MultiBoundingBox(boxes: [box1, box2])
        #expect(multi.isMultiPage)
    }

    @Test("isMultiPage returns false for single page")
    func isNotMultiPage() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let box2 = BoundingBox(pageIndex: 0, x: 50, y: 50, width: 10, height: 10)
        let multi = MultiBoundingBox(boxes: [box1, box2])
        #expect(!multi.isMultiPage)
    }

    @Test("first returns lowest page index box")
    func firstBox() {
        let box1 = BoundingBox(pageIndex: 2, x: 0, y: 0, width: 10, height: 10)
        let box2 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let multi = MultiBoundingBox(boxes: [box1, box2])
        #expect(multi.first?.pageIndex == 0)
    }

    @Test("last returns highest page index box")
    func lastBox() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let box2 = BoundingBox(pageIndex: 2, x: 0, y: 0, width: 10, height: 10)
        let multi = MultiBoundingBox(boxes: [box1, box2])
        #expect(multi.last?.pageIndex == 2)
    }

    @Test("first returns nil for empty collection")
    func firstBoxEmpty() {
        let multi = MultiBoundingBox()
        #expect(multi.first == nil)
    }

    @Test("last returns nil for empty collection")
    func lastBoxEmpty() {
        let multi = MultiBoundingBox()
        #expect(multi.last == nil)
    }

    @Test("totalArea sums all box areas")
    func totalArea() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10) // area 100
        let box2 = BoundingBox(pageIndex: 1, x: 0, y: 0, width: 20, height: 5)  // area 100
        let multi = MultiBoundingBox(boxes: [box1, box2])
        #expect(multi.totalArea == 200)
    }

    @Test("totalArea of empty collection is 0")
    func totalAreaEmpty() {
        let multi = MultiBoundingBox()
        #expect(multi.totalArea == 0)
    }

    // MARK: - Query Methods Tests

    @Test("boxes(onPage:) returns correct subset")
    func boxesOnPage() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let box2 = BoundingBox(pageIndex: 1, x: 0, y: 0, width: 10, height: 10)
        let box3 = BoundingBox(pageIndex: 0, x: 50, y: 50, width: 10, height: 10)
        let multi = MultiBoundingBox(boxes: [box1, box2, box3])
        let page0Boxes = multi.boxes(onPage: 0)
        #expect(page0Boxes.count == 2)
        #expect(page0Boxes.allSatisfy { $0.pageIndex == 0 })
    }

    @Test("boxes(onPage:) returns empty for non-existent page")
    func boxesOnNonExistentPage() {
        let box = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let multi = MultiBoundingBox(box: box)
        #expect(multi.boxes(onPage: 5).isEmpty)
    }

    @Test("unionBox(forPage:) returns union of all boxes on a page")
    func unionBoxForPage() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let box2 = BoundingBox(pageIndex: 0, x: 50, y: 50, width: 10, height: 10)
        let multi = MultiBoundingBox(boxes: [box1, box2])
        let result = multi.unionBox(forPage: 0)
        #expect(result != nil)
        #expect(result?.leftX == 0)
        #expect(result?.bottomY == 0)
        #expect(result?.rightX == 60)
        #expect(result?.topY == 60)
    }

    @Test("unionBox(forPage:) returns nil for non-existent page")
    func unionBoxForNonExistentPage() {
        let box = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let multi = MultiBoundingBox(box: box)
        #expect(multi.unionBox(forPage: 5) == nil)
    }

    @Test("unionBox(forPage:) returns single box for page with one box")
    func unionBoxForSingleBoxPage() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 30, height: 40)
        let multi = MultiBoundingBox(box: box)
        let result = multi.unionBox(forPage: 0)
        #expect(result == box)
    }

    // MARK: - Mutation Methods Tests

    @Test("adding single box returns new multi with added box")
    func addingSingleBox() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let multi = MultiBoundingBox(box: box1)
        let box2 = BoundingBox(pageIndex: 1, x: 0, y: 0, width: 10, height: 10)
        let result = multi.adding(box2)
        #expect(result.count == 2)
        #expect(multi.count == 1) // Original is unchanged
    }

    @Test("adding multiple boxes returns new multi with all boxes")
    func addingMultipleBoxes() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let multi = MultiBoundingBox(box: box1)
        let newBoxes = [
            BoundingBox(pageIndex: 1, x: 0, y: 0, width: 10, height: 10),
            BoundingBox(pageIndex: 2, x: 0, y: 0, width: 10, height: 10)
        ]
        let result = multi.adding(newBoxes)
        #expect(result.count == 3)
    }

    @Test("merged combines two multis")
    func merged() {
        let multi1 = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        ])
        let multi2 = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 1, x: 0, y: 0, width: 10, height: 10),
            BoundingBox(pageIndex: 2, x: 0, y: 0, width: 10, height: 10)
        ])
        let result = multi1.merged(with: multi2)
        #expect(result.count == 3)
        #expect(result.pageCount == 3)
    }

    @Test("filtered returns only boxes on specified page")
    func filtered() {
        let multi = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10),
            BoundingBox(pageIndex: 1, x: 0, y: 0, width: 10, height: 10),
            BoundingBox(pageIndex: 0, x: 50, y: 50, width: 10, height: 10)
        ])
        let filtered = multi.filtered(byPage: 0)
        #expect(filtered.count == 2)
        #expect(filtered.boxes.allSatisfy { $0.pageIndex == 0 })
    }

    // MARK: - Geometric Query Tests

    @Test("intersects returns true when any box intersects")
    func intersectsTrue() {
        let multi = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 50, height: 50),
            BoundingBox(pageIndex: 1, x: 0, y: 0, width: 50, height: 50)
        ])
        let target = BoundingBox(pageIndex: 0, x: 25, y: 25, width: 50, height: 50)
        #expect(multi.intersects(target))
    }

    @Test("intersects returns false when no box intersects")
    func intersectsFalse() {
        let multi = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        ])
        let target = BoundingBox(pageIndex: 0, x: 100, y: 100, width: 10, height: 10)
        #expect(!multi.intersects(target))
    }

    @Test("intersects returns false for different pages")
    func intersectsDifferentPage() {
        let multi = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        ])
        let target = BoundingBox(pageIndex: 1, x: 0, y: 0, width: 100, height: 100)
        #expect(!multi.intersects(target))
    }

    @Test("contains returns true when any box contains")
    func containsTrue() {
        let multi = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        ])
        let inner = BoundingBox(pageIndex: 0, x: 10, y: 10, width: 10, height: 10)
        #expect(multi.contains(inner))
    }

    @Test("contains returns false when no box contains")
    func containsFalse() {
        let multi = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 50, height: 50)
        ])
        let outer = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        #expect(!multi.contains(outer))
    }

    @Test("contains point on page returns true")
    func containsPointTrue() {
        let multi = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100),
            BoundingBox(pageIndex: 1, x: 0, y: 0, width: 100, height: 100)
        ])
        #expect(multi.contains(point: CGPoint(x: 50, y: 50), onPage: 0))
        #expect(multi.contains(point: CGPoint(x: 50, y: 50), onPage: 1))
    }

    @Test("contains point on wrong page returns false")
    func containsPointWrongPage() {
        let multi = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        ])
        #expect(!multi.contains(point: CGPoint(x: 50, y: 50), onPage: 1))
    }

    @Test("contains point outside all boxes returns false")
    func containsPointOutside() {
        let multi = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        ])
        #expect(!multi.contains(point: CGPoint(x: 50, y: 50), onPage: 0))
    }

    // MARK: - Sequence and Collection Conformance Tests

    @Test("Can iterate over boxes using for-in")
    func iteratable() {
        let multi = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10),
            BoundingBox(pageIndex: 1, x: 0, y: 0, width: 10, height: 10),
            BoundingBox(pageIndex: 2, x: 0, y: 0, width: 10, height: 10)
        ])
        var pageIndices: [Int] = []
        for box in multi {
            pageIndices.append(box.pageIndex)
        }
        #expect(pageIndices == [0, 1, 2])
    }

    @Test("Can access boxes by subscript")
    func subscriptAccess() {
        let multi = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10),
            BoundingBox(pageIndex: 1, x: 0, y: 0, width: 20, height: 20)
        ])
        #expect(multi[0].pageIndex == 0)
        #expect(multi[1].pageIndex == 1)
        #expect(multi[1].width == 20)
    }

    @Test("startIndex and endIndex are correct")
    func collectionIndices() {
        let multi = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10),
            BoundingBox(pageIndex: 1, x: 0, y: 0, width: 10, height: 10)
        ])
        #expect(multi.startIndex == 0)
        #expect(multi.endIndex == 2)
    }

    @Test("map works on MultiBoundingBox")
    func mapOperation() {
        let multi = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10),
            BoundingBox(pageIndex: 1, x: 0, y: 0, width: 20, height: 20)
        ])
        let areas = multi.map(\.area)
        #expect(areas == [100, 400])
    }

    // MARK: - Equatable Tests

    @Test("Equal multis are equal")
    func equality() {
        let boxes = [
            BoundingBox(pageIndex: 0, x: 10, y: 20, width: 30, height: 40),
            BoundingBox(pageIndex: 1, x: 50, y: 60, width: 70, height: 80)
        ]
        let multi1 = MultiBoundingBox(boxes: boxes)
        let multi2 = MultiBoundingBox(boxes: boxes)
        #expect(multi1 == multi2)
    }

    @Test("Different multis are not equal")
    func inequality() {
        let multi1 = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        ])
        let multi2 = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 20, height: 20)
        ])
        #expect(multi1 != multi2)
    }

    // MARK: - Codable Tests

    @Test("Encoding and decoding roundtrip")
    func codableRoundtrip() throws {
        let original = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 10, y: 20, width: 30, height: 40),
            BoundingBox(pageIndex: 1, x: 50, y: 60, width: 70, height: 80)
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MultiBoundingBox.self, from: data)
        #expect(decoded.count == 2)
        #expect(decoded[0].pageIndex == 0)
        #expect(decoded[1].pageIndex == 1)
    }

    // MARK: - Edge Case Tests

    @Test("Adding to empty multi")
    func addingToEmpty() {
        let multi = MultiBoundingBox()
        let box = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let result = multi.adding(box)
        #expect(result.count == 1)
    }

    @Test("Merged with empty multi")
    func mergedWithEmpty() {
        let multi = MultiBoundingBox(boxes: [
            BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        ])
        let empty = MultiBoundingBox()
        let result = multi.merged(with: empty)
        #expect(result.count == 1)
    }

    @Test("Sorted ordering is maintained for same-page boxes")
    func sortStability() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let box2 = BoundingBox(pageIndex: 0, x: 50, y: 50, width: 10, height: 10)
        let multi = MultiBoundingBox(boxes: [box1, box2])
        #expect(multi.count == 2)
        // Both on page 0, order preserved from sorted (stable sort in Swift)
        #expect(multi[0].leftX == 0)
        #expect(multi[1].leftX == 50)
    }
}

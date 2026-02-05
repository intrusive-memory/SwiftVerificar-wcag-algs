import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

@Suite("BoundingBox Tests")
struct BoundingBoxTests {

    // MARK: - Initialization Tests

    @Test("Init with pageIndex and rect")
    func initWithPageIndexAndRect() {
        let box = BoundingBox(pageIndex: 0, rect: CGRect(x: 10, y: 20, width: 100, height: 50))
        #expect(box.pageIndex == 0)
        #expect(box.rect == CGRect(x: 10, y: 20, width: 100, height: 50))
    }

    @Test("Init with explicit coordinates")
    func initWithExplicitCoordinates() {
        let box = BoundingBox(pageIndex: 2, x: 10, y: 20, width: 100, height: 50)
        #expect(box.pageIndex == 2)
        #expect(box.rect.origin.x == 10)
        #expect(box.rect.origin.y == 20)
        #expect(box.rect.size.width == 100)
        #expect(box.rect.size.height == 50)
    }

    @Test("Init with corner coordinates")
    func initWithCornerCoordinates() {
        let box = BoundingBox(pageIndex: 1, leftX: 10, bottomY: 20, rightX: 110, topY: 70)
        #expect(box.pageIndex == 1)
        #expect(box.leftX == 10)
        #expect(box.bottomY == 20)
        #expect(box.rightX == 110)
        #expect(box.topY == 70)
        #expect(box.width == 100)
        #expect(box.height == 50)
    }

    // MARK: - Computed Properties Tests

    @Test("leftX returns minX of rect")
    func leftX() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        #expect(box.leftX == 10)
    }

    @Test("bottomY returns minY of rect")
    func bottomY() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        #expect(box.bottomY == 20)
    }

    @Test("rightX returns maxX of rect")
    func rightX() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        #expect(box.rightX == 110)
    }

    @Test("topY returns maxY of rect")
    func topY() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        #expect(box.topY == 70)
    }

    @Test("width returns rect width")
    func width() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        #expect(box.width == 100)
    }

    @Test("height returns rect height")
    func height() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        #expect(box.height == 50)
    }

    @Test("area returns width times height")
    func area() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        #expect(box.area == 5000)
    }

    @Test("center returns midpoint")
    func center() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        #expect(box.center.x == 60)
        #expect(box.center.y == 45)
    }

    @Test("isEmpty returns true for zero-size rect")
    func isEmptyForZeroRect() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 0, height: 50)
        #expect(box.isEmpty)
    }

    @Test("isEmpty returns false for normal rect")
    func isNotEmptyForNormalRect() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        #expect(!box.isEmpty)
    }

    // MARK: - Union Tests

    @Test("Union of boxes on same page produces enclosing box")
    func unionSamePage() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 50, height: 50)
        let box2 = BoundingBox(pageIndex: 0, x: 25, y: 25, width: 50, height: 50)
        let result = box1.union(with: box2)
        #expect(result != nil)
        #expect(result?.pageIndex == 0)
        #expect(result?.leftX == 0)
        #expect(result?.bottomY == 0)
        #expect(result?.rightX == 75)
        #expect(result?.topY == 75)
    }

    @Test("Union of boxes on different pages returns nil")
    func unionDifferentPages() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 50, height: 50)
        let box2 = BoundingBox(pageIndex: 1, x: 25, y: 25, width: 50, height: 50)
        #expect(box1.union(with: box2) == nil)
    }

    @Test("Union of non-overlapping boxes produces enclosing box")
    func unionNonOverlapping() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let box2 = BoundingBox(pageIndex: 0, x: 100, y: 100, width: 10, height: 10)
        let result = box1.union(with: box2)
        #expect(result != nil)
        #expect(result?.leftX == 0)
        #expect(result?.bottomY == 0)
        #expect(result?.rightX == 110)
        #expect(result?.topY == 110)
    }

    // MARK: - Intersection Tests

    @Test("Intersection of overlapping boxes on same page")
    func intersectionOverlapping() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 50, height: 50)
        let box2 = BoundingBox(pageIndex: 0, x: 25, y: 25, width: 50, height: 50)
        let result = box1.intersection(with: box2)
        #expect(result != nil)
        #expect(result?.pageIndex == 0)
        #expect(result?.leftX == 25)
        #expect(result?.bottomY == 25)
        #expect(result?.rightX == 50)
        #expect(result?.topY == 50)
    }

    @Test("Intersection of non-overlapping boxes returns nil")
    func intersectionNonOverlapping() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let box2 = BoundingBox(pageIndex: 0, x: 100, y: 100, width: 10, height: 10)
        #expect(box1.intersection(with: box2) == nil)
    }

    @Test("Intersection of boxes on different pages returns nil")
    func intersectionDifferentPages() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 50, height: 50)
        let box2 = BoundingBox(pageIndex: 1, x: 25, y: 25, width: 50, height: 50)
        #expect(box1.intersection(with: box2) == nil)
    }

    // MARK: - Containment Tests

    @Test("Contains returns true when box fully contains another on same page")
    func containsBoxTrue() {
        let outer = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        let inner = BoundingBox(pageIndex: 0, x: 10, y: 10, width: 30, height: 30)
        #expect(outer.contains(inner))
    }

    @Test("Contains returns false when box does not contain another")
    func containsBoxFalse() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 50, height: 50)
        let box2 = BoundingBox(pageIndex: 0, x: 25, y: 25, width: 50, height: 50)
        #expect(!box1.contains(box2))
    }

    @Test("Contains returns false for different pages")
    func containsBoxDifferentPages() {
        let outer = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        let inner = BoundingBox(pageIndex: 1, x: 10, y: 10, width: 30, height: 30)
        #expect(!outer.contains(inner))
    }

    @Test("Contains point returns true for point inside")
    func containsPointTrue() {
        let box = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        #expect(box.contains(point: CGPoint(x: 50, y: 50)))
    }

    @Test("Contains point returns false for point outside")
    func containsPointFalse() {
        let box = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        #expect(!box.contains(point: CGPoint(x: 150, y: 150)))
    }

    // MARK: - Intersects Tests

    @Test("Intersects returns true for overlapping boxes on same page")
    func intersectsTrue() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 50, height: 50)
        let box2 = BoundingBox(pageIndex: 0, x: 25, y: 25, width: 50, height: 50)
        #expect(box1.intersects(box2))
    }

    @Test("Intersects returns false for non-overlapping boxes")
    func intersectsFalse() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let box2 = BoundingBox(pageIndex: 0, x: 100, y: 100, width: 10, height: 10)
        #expect(!box1.intersects(box2))
    }

    @Test("Intersects returns false for different pages")
    func intersectsDifferentPages() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        let box2 = BoundingBox(pageIndex: 1, x: 0, y: 0, width: 100, height: 100)
        #expect(!box1.intersects(box2))
    }

    // MARK: - Overlap Percentage Tests

    @Test("Overlap percentage of identical boxes is 1.0")
    func overlapIdentical() {
        let box = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        let result = box.overlapPercentage(with: box)
        #expect(abs(result - 1.0) < 0.001)
    }

    @Test("Overlap percentage of non-overlapping boxes is 0.0")
    func overlapNonOverlapping() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)
        let box2 = BoundingBox(pageIndex: 0, x: 100, y: 100, width: 10, height: 10)
        #expect(box1.overlapPercentage(with: box2) == 0.0)
    }

    @Test("Overlap percentage of partially overlapping boxes")
    func overlapPartial() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        let box2 = BoundingBox(pageIndex: 0, x: 50, y: 50, width: 100, height: 100)
        // Intersection: 50x50 = 2500, min area: 10000
        let result = box1.overlapPercentage(with: box2)
        #expect(abs(result - 0.25) < 0.001)
    }

    @Test("Overlap percentage of different pages is 0.0")
    func overlapDifferentPages() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        let box2 = BoundingBox(pageIndex: 1, x: 0, y: 0, width: 100, height: 100)
        #expect(box1.overlapPercentage(with: box2) == 0.0)
    }

    @Test("Overlap percentage with zero-area box returns 0.0")
    func overlapZeroArea() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        let box2 = BoundingBox(pageIndex: 0, x: 50, y: 50, width: 0, height: 0)
        #expect(box1.overlapPercentage(with: box2) == 0.0)
    }

    // MARK: - InsetBy Tests

    @Test("InsetBy shrinks the box")
    func insetByShrinks() {
        let box = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 100, height: 100)
        let inset = box.insetBy(dx: 10, dy: 10)
        #expect(inset.pageIndex == 0)
        #expect(inset.leftX == 10)
        #expect(inset.bottomY == 10)
        #expect(inset.width == 80)
        #expect(inset.height == 80)
    }

    @Test("InsetBy with negative values expands the box")
    func insetByExpands() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 10, width: 80, height: 80)
        let expanded = box.insetBy(dx: -10, dy: -10)
        #expect(expanded.leftX == 0)
        #expect(expanded.bottomY == 0)
        #expect(expanded.width == 100)
        #expect(expanded.height == 100)
    }

    // MARK: - Equatable and Hashable Tests

    @Test("Equal boxes are equal")
    func equality() {
        let box1 = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        let box2 = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        #expect(box1 == box2)
    }

    @Test("Boxes with different pages are not equal")
    func inequalityDifferentPages() {
        let box1 = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        let box2 = BoundingBox(pageIndex: 1, x: 10, y: 20, width: 100, height: 50)
        #expect(box1 != box2)
    }

    @Test("Boxes with different rects are not equal")
    func inequalityDifferentRects() {
        let box1 = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        let box2 = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 200, height: 50)
        #expect(box1 != box2)
    }

    @Test("Equal boxes have equal hash values")
    func hashableConsistency() {
        let box1 = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        let box2 = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        #expect(box1.hashValue == box2.hashValue)
    }

    @Test("Boxes can be used in sets")
    func setUsage() {
        let box1 = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        let box2 = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        let box3 = BoundingBox(pageIndex: 1, x: 10, y: 20, width: 100, height: 50)
        let set: Set<BoundingBox> = [box1, box2, box3]
        #expect(set.count == 2)
    }

    // MARK: - Codable Tests

    @Test("Encoding and decoding roundtrip")
    func codableRoundtrip() throws {
        let original = BoundingBox(pageIndex: 3, x: 10.5, y: 20.5, width: 100.25, height: 50.75)
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BoundingBox.self, from: data)
        #expect(decoded.pageIndex == original.pageIndex)
        #expect(abs(decoded.rect.origin.x - original.rect.origin.x) < 0.001)
        #expect(abs(decoded.rect.origin.y - original.rect.origin.y) < 0.001)
        #expect(abs(decoded.rect.size.width - original.rect.size.width) < 0.001)
        #expect(abs(decoded.rect.size.height - original.rect.size.height) < 0.001)
    }

    @Test("Encoding produces expected JSON keys")
    func encodingKeys() throws {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        let data = try JSONEncoder().encode(box)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["pageIndex"] != nil)
        #expect(json?["x"] != nil)
        #expect(json?["y"] != nil)
        #expect(json?["width"] != nil)
        #expect(json?["height"] != nil)
    }

    // MARK: - Edge Case Tests

    @Test("Box with negative coordinates")
    func negativeCoordinates() {
        let box = BoundingBox(pageIndex: 0, x: -10, y: -20, width: 100, height: 50)
        #expect(box.leftX == -10)
        #expect(box.bottomY == -20)
        #expect(box.rightX == 90)
        #expect(box.topY == 30)
    }

    @Test("Union with self produces same box")
    func unionWithSelf() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        let result = box.union(with: box)
        #expect(result == box)
    }

    @Test("Intersection with self produces same box")
    func intersectionWithSelf() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        let result = box.intersection(with: box)
        #expect(result == box)
    }

    @Test("Contains self returns true")
    func containsSelf() {
        let box = BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        #expect(box.contains(box))
    }

    @Test("Large page index")
    func largePageIndex() {
        let box = BoundingBox(pageIndex: 9999, x: 0, y: 0, width: 100, height: 100)
        #expect(box.pageIndex == 9999)
    }
}

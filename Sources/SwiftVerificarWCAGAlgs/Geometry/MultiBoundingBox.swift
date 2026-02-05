import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// A collection of bounding boxes that may span multiple pages.
///
/// `MultiBoundingBox` represents content that crosses page boundaries,
/// such as a table or paragraph that continues from one page to the next.
/// Each component `BoundingBox` is associated with a specific page.
///
/// - Note: Ported from veraPDF-wcag-algs `MultiBoundingBox` Java class.
public struct MultiBoundingBox: Equatable, Hashable, Sendable, Codable {

    // MARK: - Properties

    /// The individual bounding boxes, each on a specific page.
    ///
    /// Sorted by page index in ascending order.
    public let boxes: [BoundingBox]

    // MARK: - Initialization

    /// Creates a multi-page bounding box from an array of bounding boxes.
    ///
    /// The boxes are stored sorted by page index.
    ///
    /// - Parameter boxes: The bounding boxes to include.
    public init(boxes: [BoundingBox]) {
        self.boxes = boxes.sorted { $0.pageIndex < $1.pageIndex }
    }

    /// Creates a multi-page bounding box from a single bounding box.
    ///
    /// - Parameter box: The single bounding box.
    public init(box: BoundingBox) {
        self.boxes = [box]
    }

    /// Creates an empty multi-page bounding box.
    public init() {
        self.boxes = []
    }

    // MARK: - Computed Properties

    /// Whether this multi-bounding box has no boxes.
    public var isEmpty: Bool { boxes.isEmpty }

    /// The number of bounding boxes in this collection.
    public var count: Int { boxes.count }

    /// The set of page indices covered by this multi-bounding box.
    public var pageIndices: Set<Int> {
        Set(boxes.map(\.pageIndex))
    }

    /// The number of distinct pages this multi-bounding box spans.
    public var pageCount: Int {
        pageIndices.count
    }

    /// Whether this multi-bounding box spans more than one page.
    public var isMultiPage: Bool {
        pageCount > 1
    }

    /// The first (lowest page index) bounding box, if any.
    public var first: BoundingBox? {
        boxes.first
    }

    /// The last (highest page index) bounding box, if any.
    public var last: BoundingBox? {
        boxes.last
    }

    /// The total area across all bounding boxes.
    public var totalArea: CGFloat {
        boxes.reduce(0) { $0 + $1.area }
    }

    // MARK: - Query Methods

    /// Returns all bounding boxes on the specified page.
    ///
    /// - Parameter pageIndex: The zero-based page index.
    /// - Returns: An array of bounding boxes on that page.
    public func boxes(onPage pageIndex: Int) -> [BoundingBox] {
        boxes.filter { $0.pageIndex == pageIndex }
    }

    /// Returns the union bounding box for a specific page.
    ///
    /// Computes the smallest rectangle that contains all bounding boxes
    /// on the given page. Returns `nil` if there are no boxes on that page.
    ///
    /// - Parameter pageIndex: The zero-based page index.
    /// - Returns: A single bounding box encompassing all boxes on the page, or `nil`.
    public func unionBox(forPage pageIndex: Int) -> BoundingBox? {
        let pageBoxes = boxes(onPage: pageIndex)
        guard let first = pageBoxes.first else { return nil }
        return pageBoxes.dropFirst().reduce(first) { result, box in
            result.union(with: box) ?? result
        }
    }

    // MARK: - Mutation (returning new instances)

    /// Returns a new `MultiBoundingBox` with the given box appended.
    ///
    /// - Parameter box: The bounding box to add.
    /// - Returns: A new `MultiBoundingBox` including the additional box.
    public func adding(_ box: BoundingBox) -> MultiBoundingBox {
        MultiBoundingBox(boxes: boxes + [box])
    }

    /// Returns a new `MultiBoundingBox` with all the given boxes appended.
    ///
    /// - Parameter newBoxes: The bounding boxes to add.
    /// - Returns: A new `MultiBoundingBox` including the additional boxes.
    public func adding(_ newBoxes: [BoundingBox]) -> MultiBoundingBox {
        MultiBoundingBox(boxes: boxes + newBoxes)
    }

    /// Returns a new `MultiBoundingBox` merged with another.
    ///
    /// Combines all boxes from both into a single sorted collection.
    ///
    /// - Parameter other: The other multi-bounding box to merge with.
    /// - Returns: A new `MultiBoundingBox` containing all boxes from both.
    public func merged(with other: MultiBoundingBox) -> MultiBoundingBox {
        MultiBoundingBox(boxes: boxes + other.boxes)
    }

    /// Returns a new `MultiBoundingBox` containing only boxes on the specified page.
    ///
    /// - Parameter pageIndex: The zero-based page index to filter by.
    /// - Returns: A new `MultiBoundingBox` containing only the matching boxes.
    public func filtered(byPage pageIndex: Int) -> MultiBoundingBox {
        MultiBoundingBox(boxes: boxes(onPage: pageIndex))
    }

    // MARK: - Geometric Queries

    /// Checks whether any box in this collection intersects the given box.
    ///
    /// - Parameter other: The bounding box to check against.
    /// - Returns: `true` if any contained box intersects with `other`.
    public func intersects(_ other: BoundingBox) -> Bool {
        boxes.contains { $0.intersects(other) }
    }

    /// Checks whether any box in this collection contains the given box.
    ///
    /// - Parameter other: The bounding box to check containment of.
    /// - Returns: `true` if any contained box fully contains `other`.
    public func contains(_ other: BoundingBox) -> Bool {
        boxes.contains { $0.contains(other) }
    }

    /// Checks whether any box in this collection contains the given point
    /// on the specified page.
    ///
    /// - Parameters:
    ///   - point: The point to check.
    ///   - pageIndex: The page to check on.
    /// - Returns: `true` if any box on that page contains the point.
    public func contains(point: CGPoint, onPage pageIndex: Int) -> Bool {
        boxes(onPage: pageIndex).contains { $0.contains(point: point) }
    }
}

// MARK: - Sequence Conformance

extension MultiBoundingBox: Sequence {
    /// Returns an iterator over the bounding boxes.
    public func makeIterator() -> IndexingIterator<[BoundingBox]> {
        boxes.makeIterator()
    }
}

// MARK: - Collection Conformance

extension MultiBoundingBox: Collection {
    /// The index type for accessing bounding boxes.
    public typealias Index = Int

    /// The start index of the collection.
    public var startIndex: Int { boxes.startIndex }

    /// The end index of the collection.
    public var endIndex: Int { boxes.endIndex }

    /// Returns the bounding box at the given index.
    public subscript(position: Int) -> BoundingBox {
        boxes[position]
    }

    /// Returns the index after the given index.
    public func index(after i: Int) -> Int {
        boxes.index(after: i)
    }
}

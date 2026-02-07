import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// A collection of `LineChunk` items with filtering and querying capabilities.
///
/// `LinesCollection` provides methods for filtering lines by page, orientation
/// (horizontal/vertical), spatial overlap, and proximity. It is used extensively
/// in table border detection and visual structure analysis for WCAG compliance.
///
/// The collection maintains its lines sorted by page index for efficient
/// page-based queries.
///
/// - Note: Ported from veraPDF-wcag-algs `LinesCollection` Java class.
public struct LinesCollection: Sendable, Hashable, Codable {

    // MARK: - Properties

    /// The individual line segments in this collection, sorted by page index.
    public let lines: [LineChunk]

    // MARK: - Initialization

    /// Creates a lines collection from an array of line chunks.
    ///
    /// The lines are stored sorted by page index.
    ///
    /// - Parameter lines: The line chunks to include.
    public init(lines: [LineChunk] = []) {
        self.lines = lines.sorted { $0.pageIndex < $1.pageIndex }
    }

    // MARK: - Computed Properties

    /// Whether this collection contains no lines.
    public var isEmpty: Bool {
        lines.isEmpty
    }

    /// The number of lines in this collection.
    public var count: Int {
        lines.count
    }

    /// The set of page indices that have lines in this collection.
    public var pageIndices: Set<Int> {
        Set(lines.map(\.pageIndex))
    }

    /// The number of distinct pages with lines.
    public var pageCount: Int {
        pageIndices.count
    }

    /// All horizontal lines in this collection.
    public var horizontalLines: [LineChunk] {
        lines.filter(\.isHorizontal)
    }

    /// All vertical lines in this collection.
    public var verticalLines: [LineChunk] {
        lines.filter(\.isVertical)
    }

    /// All axis-aligned lines (horizontal or vertical) in this collection.
    public var axisAlignedLines: [LineChunk] {
        lines.filter(\.isAxisAligned)
    }

    // MARK: - Page Filtering

    /// Returns all lines on the specified page.
    ///
    /// - Parameter pageIndex: The zero-based page index.
    /// - Returns: An array of line chunks on that page.
    public func lines(onPage pageIndex: Int) -> [LineChunk] {
        lines.filter { $0.pageIndex == pageIndex }
    }

    /// Returns a new `LinesCollection` containing only lines on the specified page.
    ///
    /// - Parameter pageIndex: The zero-based page index to filter by.
    /// - Returns: A new `LinesCollection` containing only the matching lines.
    public func filtered(byPage pageIndex: Int) -> LinesCollection {
        LinesCollection(lines: lines(onPage: pageIndex))
    }

    // MARK: - Orientation Filtering

    /// Returns a new `LinesCollection` containing only horizontal lines.
    public func filterHorizontal() -> LinesCollection {
        LinesCollection(lines: horizontalLines)
    }

    /// Returns a new `LinesCollection` containing only vertical lines.
    public func filterVertical() -> LinesCollection {
        LinesCollection(lines: verticalLines)
    }

    /// Returns a new `LinesCollection` containing only axis-aligned lines.
    public func filterAxisAligned() -> LinesCollection {
        LinesCollection(lines: axisAlignedLines)
    }

    // MARK: - Spatial Queries

    /// Returns all lines that overlap with the given bounding box.
    ///
    /// A line overlaps if its bounding box intersects the given box.
    ///
    /// - Parameter box: The bounding box to check overlap with.
    /// - Returns: An array of line chunks whose bounding boxes intersect the given box.
    public func lines(overlapping box: BoundingBox) -> [LineChunk] {
        lines.filter { $0.boundingBox.intersects(box) }
    }

    /// Returns a new `LinesCollection` containing only lines that overlap
    /// with the given bounding box.
    ///
    /// - Parameter box: The bounding box to check overlap with.
    /// - Returns: A new `LinesCollection` containing the overlapping lines.
    public func filtered(overlapping box: BoundingBox) -> LinesCollection {
        LinesCollection(lines: lines(overlapping: box))
    }

    /// Returns all lines within a given distance of a point.
    ///
    /// - Parameters:
    ///   - point: The reference point.
    ///   - pageIndex: The page the point is on.
    ///   - maxDistance: The maximum distance from the point.
    /// - Returns: An array of line chunks within the distance threshold.
    public func lines(near point: CGPoint, onPage pageIndex: Int, maxDistance: CGFloat) -> [LineChunk] {
        lines(onPage: pageIndex).filter { line in
            line.distance(to: point) <= maxDistance
        }
    }

    /// Returns all lines within a given distance of the specified bounding box.
    ///
    /// Checks whether any part of the line is within `maxDistance` of the box.
    ///
    /// - Parameters:
    ///   - box: The reference bounding box.
    ///   - maxDistance: The maximum distance from the bounding box.
    /// - Returns: An array of line chunks within the distance threshold.
    public func lines(near box: BoundingBox, maxDistance: CGFloat) -> [LineChunk] {
        let expandedBox = box.insetBy(dx: -maxDistance, dy: -maxDistance)
        return lines.filter { $0.boundingBox.intersects(expandedBox) }
    }

    /// Returns all lines contained within the given bounding box.
    ///
    /// A line is contained if its bounding box is fully inside the given box.
    ///
    /// - Parameter box: The bounding box to check containment within.
    /// - Returns: An array of line chunks fully contained within the box.
    public func lines(containedIn box: BoundingBox) -> [LineChunk] {
        lines.filter { box.contains($0.boundingBox) }
    }

    // MARK: - Mutation (returning new instances)

    /// Returns a new `LinesCollection` with the given line appended.
    ///
    /// - Parameter line: The line chunk to add.
    /// - Returns: A new `LinesCollection` including the additional line.
    public func adding(_ line: LineChunk) -> LinesCollection {
        LinesCollection(lines: lines + [line])
    }

    /// Returns a new `LinesCollection` with all the given lines appended.
    ///
    /// - Parameter newLines: The line chunks to add.
    /// - Returns: A new `LinesCollection` including the additional lines.
    public func adding(_ newLines: [LineChunk]) -> LinesCollection {
        LinesCollection(lines: lines + newLines)
    }

    /// Returns a new `LinesCollection` merged with another.
    ///
    /// - Parameter other: The other lines collection to merge with.
    /// - Returns: A new `LinesCollection` containing all lines from both.
    public func merged(with other: LinesCollection) -> LinesCollection {
        LinesCollection(lines: lines + other.lines)
    }

    // MARK: - Line Width Filtering

    /// Returns all lines with a width greater than or equal to the given threshold.
    ///
    /// - Parameter minWidth: The minimum line width in points.
    /// - Returns: An array of line chunks meeting the width threshold.
    public func lines(withMinWidth minWidth: CGFloat) -> [LineChunk] {
        lines.filter { $0.lineWidth >= minWidth }
    }

    /// Returns all lines with a width less than or equal to the given threshold.
    ///
    /// - Parameter maxWidth: The maximum line width in points.
    /// - Returns: An array of line chunks meeting the width threshold.
    public func lines(withMaxWidth maxWidth: CGFloat) -> [LineChunk] {
        lines.filter { $0.lineWidth <= maxWidth }
    }

    // MARK: - Length Filtering

    /// Returns all lines with a length greater than or equal to the given threshold.
    ///
    /// - Parameter minLength: The minimum line length in points.
    /// - Returns: An array of line chunks meeting the length threshold.
    public func lines(withMinLength minLength: CGFloat) -> [LineChunk] {
        lines.filter { $0.length >= minLength }
    }

    // MARK: - Statistics

    /// The total length of all lines in this collection.
    public var totalLength: CGFloat {
        lines.reduce(0) { $0 + $1.length }
    }

    /// The average line width across all lines.
    ///
    /// Returns `nil` if the collection is empty.
    public var averageLineWidth: CGFloat? {
        guard !lines.isEmpty else { return nil }
        let total = lines.reduce(CGFloat(0)) { $0 + $1.lineWidth }
        return total / CGFloat(lines.count)
    }

    /// The combined bounding box of all lines in this collection.
    ///
    /// Returns `nil` if the collection is empty or lines span multiple pages.
    /// If lines span multiple pages, use `combinedBoundingBox(forPage:)` instead.
    public var combinedBoundingBox: BoundingBox? {
        guard let first = lines.first else { return nil }
        return lines.dropFirst().reduce(first.boundingBox) { result, line in
            result.union(with: line.boundingBox) ?? result
        }
    }

    /// The combined bounding box of all lines on a specific page.
    ///
    /// - Parameter pageIndex: The zero-based page index.
    /// - Returns: A bounding box encompassing all lines on the page, or `nil`.
    public func combinedBoundingBox(forPage pageIndex: Int) -> BoundingBox? {
        let pageLines = lines(onPage: pageIndex)
        guard let first = pageLines.first else { return nil }
        return pageLines.dropFirst().reduce(first.boundingBox) { result, line in
            result.union(with: line.boundingBox) ?? result
        }
    }
}

// MARK: - Sequence Conformance

extension LinesCollection: Sequence {
    /// Returns an iterator over the line chunks.
    public func makeIterator() -> IndexingIterator<[LineChunk]> {
        lines.makeIterator()
    }
}

// MARK: - Collection Conformance

extension LinesCollection: Collection {
    /// The index type for accessing line chunks.
    public typealias Index = Int

    /// The start index of the collection.
    public var startIndex: Int { lines.startIndex }

    /// The end index of the collection.
    public var endIndex: Int { lines.endIndex }

    /// Returns the line chunk at the given index.
    public subscript(position: Int) -> LineChunk {
        lines[position]
    }

    /// Returns the index after the given index.
    public func index(after i: Int) -> Int {
        lines.index(after: i)
    }
}

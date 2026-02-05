import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// A bounding box for PDF content with page tracking.
///
/// Represents a rectangular region on a specific page of a PDF document.
/// Uses `CGRect` internally for the geometric component and includes a
/// `pageIndex` to identify which page the box belongs to.
///
/// This is the foundational geometry type used throughout the WCAG
/// accessibility algorithms package.
///
/// - Note: Ported from veraPDF-wcag-algs `BoundingBox` Java class,
///   with the addition of `pageIndex` for multi-page support.
public struct BoundingBox: Equatable, Hashable, Sendable, Codable {

    // MARK: - Properties

    /// The zero-based index of the page this bounding box belongs to.
    public let pageIndex: Int

    /// The rectangular region on the page, in PDF coordinate space.
    public let rect: CGRect

    // MARK: - Initialization

    /// Creates a bounding box for a specific page and rectangle.
    ///
    /// - Parameters:
    ///   - pageIndex: The zero-based page index.
    ///   - rect: The rectangular region in PDF coordinate space.
    public init(pageIndex: Int, rect: CGRect) {
        self.pageIndex = pageIndex
        self.rect = rect
    }

    /// Creates a bounding box from explicit coordinates.
    ///
    /// - Parameters:
    ///   - pageIndex: The zero-based page index.
    ///   - x: The x-coordinate of the origin.
    ///   - y: The y-coordinate of the origin.
    ///   - width: The width of the rectangle.
    ///   - height: The height of the rectangle.
    public init(pageIndex: Int, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.pageIndex = pageIndex
        self.rect = CGRect(x: x, y: y, width: width, height: height)
    }

    /// Creates a bounding box from corner coordinates.
    ///
    /// - Parameters:
    ///   - pageIndex: The zero-based page index.
    ///   - leftX: The left x-coordinate.
    ///   - bottomY: The bottom y-coordinate.
    ///   - rightX: The right x-coordinate.
    ///   - topY: The top y-coordinate.
    public init(pageIndex: Int, leftX: CGFloat, bottomY: CGFloat, rightX: CGFloat, topY: CGFloat) {
        self.pageIndex = pageIndex
        self.rect = CGRect(
            x: leftX,
            y: bottomY,
            width: rightX - leftX,
            height: topY - bottomY
        )
    }

    // MARK: - Computed Properties

    /// The left x-coordinate of the bounding box.
    public var leftX: CGFloat { rect.minX }

    /// The bottom y-coordinate of the bounding box.
    public var bottomY: CGFloat { rect.minY }

    /// The right x-coordinate of the bounding box.
    public var rightX: CGFloat { rect.maxX }

    /// The top y-coordinate of the bounding box.
    public var topY: CGFloat { rect.maxY }

    /// The width of the bounding box.
    public var width: CGFloat { rect.width }

    /// The height of the bounding box.
    public var height: CGFloat { rect.height }

    /// The area of the bounding box.
    public var area: CGFloat { rect.width * rect.height }

    /// The center point of the bounding box.
    public var center: CGPoint {
        CGPoint(x: rect.midX, y: rect.midY)
    }

    /// Whether the bounding box has zero or negative area.
    public var isEmpty: Bool { rect.isEmpty }

    // MARK: - Geometric Operations

    /// Returns the union of this bounding box with another.
    ///
    /// Both bounding boxes must be on the same page. If they are on
    /// different pages, returns `nil`.
    ///
    /// - Parameter other: The other bounding box to union with.
    /// - Returns: A new bounding box covering both regions, or `nil` if on different pages.
    public func union(with other: BoundingBox) -> BoundingBox? {
        guard pageIndex == other.pageIndex else { return nil }
        return BoundingBox(pageIndex: pageIndex, rect: rect.union(other.rect))
    }

    /// Returns the intersection of this bounding box with another.
    ///
    /// Both bounding boxes must be on the same page and must actually
    /// intersect. If either condition is not met, returns `nil`.
    ///
    /// - Parameter other: The other bounding box to intersect with.
    /// - Returns: A new bounding box covering the intersection, or `nil`.
    public func intersection(with other: BoundingBox) -> BoundingBox? {
        guard pageIndex == other.pageIndex,
              rect.intersects(other.rect) else { return nil }
        return BoundingBox(pageIndex: pageIndex, rect: rect.intersection(other.rect))
    }

    /// Checks whether this bounding box fully contains another.
    ///
    /// Both must be on the same page for containment to be true.
    ///
    /// - Parameter other: The bounding box to check containment of.
    /// - Returns: `true` if this box fully contains the other on the same page.
    public func contains(_ other: BoundingBox) -> Bool {
        pageIndex == other.pageIndex && rect.contains(other.rect)
    }

    /// Checks whether this bounding box contains a point.
    ///
    /// - Parameter point: The point to check.
    /// - Returns: `true` if the point is inside this bounding box.
    public func contains(point: CGPoint) -> Bool {
        rect.contains(point)
    }

    /// Checks whether this bounding box intersects another.
    ///
    /// Both must be on the same page for intersection to be true.
    ///
    /// - Parameter other: The bounding box to check intersection with.
    /// - Returns: `true` if the boxes overlap on the same page.
    public func intersects(_ other: BoundingBox) -> Bool {
        pageIndex == other.pageIndex && rect.intersects(other.rect)
    }

    /// Calculates the overlap percentage between this box and another.
    ///
    /// The overlap percentage is the area of the intersection divided by
    /// the area of the smaller box. Returns 0 if the boxes do not
    /// intersect or are on different pages.
    ///
    /// - Parameter other: The other bounding box.
    /// - Returns: A value between 0.0 and 1.0 representing the overlap fraction.
    public func overlapPercentage(with other: BoundingBox) -> CGFloat {
        guard let intersection = intersection(with: other) else { return 0 }
        let minArea = min(area, other.area)
        guard minArea > 0 else { return 0 }
        return intersection.area / minArea
    }

    /// Returns a new bounding box expanded by the given insets.
    ///
    /// Positive values expand the box; negative values shrink it.
    ///
    /// - Parameters:
    ///   - dx: The amount to expand horizontally (each side).
    ///   - dy: The amount to expand vertically (each side).
    /// - Returns: A new bounding box with the applied insets.
    public func insetBy(dx: CGFloat, dy: CGFloat) -> BoundingBox {
        BoundingBox(pageIndex: pageIndex, rect: rect.insetBy(dx: dx, dy: dy))
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case pageIndex
        case x
        case y
        case width
        case height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.pageIndex = try container.decode(Int.self, forKey: .pageIndex)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.rect = CGRect(x: x, y: y, width: width, height: height)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pageIndex, forKey: .pageIndex)
        try container.encode(rect.origin.x, forKey: .x)
        try container.encode(rect.origin.y, forKey: .y)
        try container.encode(rect.size.width, forKey: .width)
        try container.encode(rect.size.height, forKey: .height)
    }
}

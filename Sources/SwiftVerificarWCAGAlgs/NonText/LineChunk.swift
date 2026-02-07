import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// A line/path graphics chunk extracted from a PDF document.
///
/// Represents a single drawn line segment with start and end points,
/// line width, and color. Lines are fundamental primitives used to
/// detect table borders, separators, and other visual structures
/// in PDF accessibility analysis.
///
/// `LineChunk` conforms to `ContentChunk`, making it interoperable with
/// other content types in the content analysis pipeline.
///
/// - Note: Ported from veraPDF-wcag-algs `LineChunk` Java class.
public struct LineChunk: ContentChunk, Sendable, Hashable, Codable {

    // MARK: - ContentChunk Conformance

    /// The bounding box of this line chunk, specifying its location and page.
    public let boundingBox: BoundingBox

    // MARK: - Line Geometry

    /// The start point of the line segment.
    public let startPoint: CGPoint

    /// The end point of the line segment.
    public let endPoint: CGPoint

    /// The width (thickness) of the line in points.
    public let lineWidth: CGFloat

    // MARK: - Line Appearance

    /// The sRGB color components of the line stroke.
    ///
    /// Stored as an array of `CGFloat` values (e.g. `[r, g, b, a]` for RGBA)
    /// for `Codable` compatibility. Use `strokeColor` for a `CGColor` representation.
    public let strokeColorComponents: [CGFloat]

    // MARK: - Initialization

    /// Creates a new line chunk with all properties.
    ///
    /// - Parameters:
    ///   - boundingBox: The spatial location and page of this line.
    ///   - startPoint: The start point of the line segment.
    ///   - endPoint: The end point of the line segment.
    ///   - lineWidth: The width of the line in points.
    ///   - strokeColorComponents: The sRGB color components of the stroke.
    public init(
        boundingBox: BoundingBox,
        startPoint: CGPoint,
        endPoint: CGPoint,
        lineWidth: CGFloat = 1.0,
        strokeColorComponents: [CGFloat] = [0, 0, 0, 1]
    ) {
        self.boundingBox = boundingBox
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.lineWidth = lineWidth
        self.strokeColorComponents = strokeColorComponents
    }

    /// Creates a new line chunk, automatically computing the bounding box
    /// from the start and end points.
    ///
    /// The bounding box is computed as the smallest rectangle enclosing
    /// both endpoints, expanded by half the line width in each direction.
    ///
    /// - Parameters:
    ///   - pageIndex: The zero-based page index this line is on.
    ///   - startPoint: The start point of the line segment.
    ///   - endPoint: The end point of the line segment.
    ///   - lineWidth: The width of the line in points.
    ///   - strokeColorComponents: The sRGB color components of the stroke.
    public init(
        pageIndex: Int,
        startPoint: CGPoint,
        endPoint: CGPoint,
        lineWidth: CGFloat = 1.0,
        strokeColorComponents: [CGFloat] = [0, 0, 0, 1]
    ) {
        let halfWidth = lineWidth / 2.0
        let minX = min(startPoint.x, endPoint.x) - halfWidth
        let minY = min(startPoint.y, endPoint.y) - halfWidth
        let maxX = max(startPoint.x, endPoint.x) + halfWidth
        let maxY = max(startPoint.y, endPoint.y) + halfWidth

        self.boundingBox = BoundingBox(
            pageIndex: pageIndex,
            leftX: minX,
            bottomY: minY,
            rightX: maxX,
            topY: maxY
        )
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.lineWidth = lineWidth
        self.strokeColorComponents = strokeColorComponents
    }

    // MARK: - Computed Properties

    /// The length of the line segment.
    public var length: CGFloat {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        return sqrt(dx * dx + dy * dy)
    }

    /// Whether this line is approximately horizontal.
    ///
    /// A line is considered horizontal if the absolute difference in
    /// y-coordinates is less than or equal to 1% of its length, or
    /// if the y-difference is less than 0.5 points.
    public var isHorizontal: Bool {
        let dy = abs(endPoint.y - startPoint.y)
        let len = length
        guard len > 0 else { return true }
        return dy <= max(len * 0.01, 0.5)
    }

    /// Whether this line is approximately vertical.
    ///
    /// A line is considered vertical if the absolute difference in
    /// x-coordinates is less than or equal to 1% of its length, or
    /// if the x-difference is less than 0.5 points.
    public var isVertical: Bool {
        let dx = abs(endPoint.x - startPoint.x)
        let len = length
        guard len > 0 else { return true }
        return dx <= max(len * 0.01, 0.5)
    }

    /// Whether this line is axis-aligned (either horizontal or vertical).
    public var isAxisAligned: Bool {
        isHorizontal || isVertical
    }

    /// The angle of the line in radians, measured from the positive x-axis.
    ///
    /// Returns a value in the range `(-pi, pi]`.
    public var angle: CGFloat {
        atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
    }

    /// The midpoint of the line segment.
    public var midpoint: CGPoint {
        CGPoint(
            x: (startPoint.x + endPoint.x) / 2.0,
            y: (startPoint.y + endPoint.y) / 2.0
        )
    }

    /// The stroke color as a `CGColor` in sRGB color space.
    ///
    /// Returns a black color if the components cannot be converted.
    public var strokeColor: CGColor {
        guard let srgb = CGColorSpace(name: CGColorSpace.sRGB) else {
            return CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
        return CGColor(colorSpace: srgb, components: strokeColorComponents)
            ?? CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    }

    // MARK: - Geometric Queries

    /// Returns the perpendicular distance from this line to a given point.
    ///
    /// Uses the standard point-to-line-segment distance formula.
    ///
    /// - Parameter point: The point to measure distance to.
    /// - Returns: The shortest distance from the point to this line segment.
    public func distance(to point: CGPoint) -> CGFloat {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let lengthSquared = dx * dx + dy * dy

        guard lengthSquared > 0 else {
            // Degenerate line (zero length): distance to the start point
            let px = point.x - startPoint.x
            let py = point.y - startPoint.y
            return sqrt(px * px + py * py)
        }

        // Parameter t of the closest point on the infinite line
        var t = ((point.x - startPoint.x) * dx + (point.y - startPoint.y) * dy) / lengthSquared

        // Clamp t to [0, 1] to restrict to the segment
        t = max(0, min(1, t))

        // Closest point on the segment
        let closestX = startPoint.x + t * dx
        let closestY = startPoint.y + t * dy

        let px = point.x - closestX
        let py = point.y - closestY
        return sqrt(px * px + py * py)
    }

    /// Returns the perpendicular distance from this line (extended infinitely)
    /// to a given point.
    ///
    /// Unlike `distance(to:)`, this measures the shortest distance to the
    /// infinite line defined by the start and end points, not just the segment.
    ///
    /// - Parameter point: The point to measure perpendicular distance to.
    /// - Returns: The perpendicular distance from the point to the infinite line.
    public func perpendicularDistance(to point: CGPoint) -> CGFloat {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let lengthSquared = dx * dx + dy * dy

        guard lengthSquared > 0 else {
            // Degenerate line (zero length): distance to the start point
            let px = point.x - startPoint.x
            let py = point.y - startPoint.y
            return sqrt(px * px + py * py)
        }

        // Perpendicular distance = |cross product| / length
        let cross = abs((point.x - startPoint.x) * dy - (point.y - startPoint.y) * dx)
        return cross / sqrt(lengthSquared)
    }

    /// Checks whether this line is approximately collinear with another line.
    ///
    /// Two lines are collinear if all four endpoints are close to the
    /// infinite line defined by the other segment. This uses perpendicular
    /// distance rather than segment distance, so it correctly identifies
    /// adjacent or non-overlapping collinear segments.
    ///
    /// - Parameters:
    ///   - other: The other line to check against.
    ///   - tolerance: The maximum allowed perpendicular distance.
    /// - Returns: `true` if the lines are approximately collinear.
    public func isCollinear(with other: LineChunk, tolerance: CGFloat = 1.0) -> Bool {
        guard pageIndex == other.pageIndex else { return false }

        // Check that all four endpoints are close to the other's infinite line
        let d1 = other.perpendicularDistance(to: startPoint)
        let d2 = other.perpendicularDistance(to: endPoint)
        let d3 = perpendicularDistance(to: other.startPoint)
        let d4 = perpendicularDistance(to: other.endPoint)

        return d1 <= tolerance && d2 <= tolerance
            && d3 <= tolerance && d4 <= tolerance
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case boundingBox
        case startX, startY
        case endX, endY
        case lineWidth
        case strokeColorComponents
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.boundingBox = try container.decode(BoundingBox.self, forKey: .boundingBox)
        let sx = try container.decode(CGFloat.self, forKey: .startX)
        let sy = try container.decode(CGFloat.self, forKey: .startY)
        self.startPoint = CGPoint(x: sx, y: sy)
        let ex = try container.decode(CGFloat.self, forKey: .endX)
        let ey = try container.decode(CGFloat.self, forKey: .endY)
        self.endPoint = CGPoint(x: ex, y: ey)
        self.lineWidth = try container.decode(CGFloat.self, forKey: .lineWidth)
        self.strokeColorComponents = try container.decode([CGFloat].self, forKey: .strokeColorComponents)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(startPoint.x, forKey: .startX)
        try container.encode(startPoint.y, forKey: .startY)
        try container.encode(endPoint.x, forKey: .endX)
        try container.encode(endPoint.y, forKey: .endY)
        try container.encode(lineWidth, forKey: .lineWidth)
        try container.encode(strokeColorComponents, forKey: .strokeColorComponents)
    }

    // MARK: - Hashable

    public static func == (lhs: LineChunk, rhs: LineChunk) -> Bool {
        lhs.boundingBox == rhs.boundingBox
            && lhs.startPoint == rhs.startPoint
            && lhs.endPoint == rhs.endPoint
            && lhs.lineWidth == rhs.lineWidth
            && lhs.strokeColorComponents == rhs.strokeColorComponents
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(boundingBox)
        hasher.combine(startPoint.x)
        hasher.combine(startPoint.y)
        hasher.combine(endPoint.x)
        hasher.combine(endPoint.y)
        hasher.combine(lineWidth)
    }
}

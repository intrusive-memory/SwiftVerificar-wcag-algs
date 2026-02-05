import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Protocol for all content chunks in a PDF document.
///
/// A content chunk represents a discrete piece of content (text, image,
/// line art, etc.) with a known spatial location on a specific page.
/// All concrete chunk types (text, image, line art) conform to this protocol.
///
/// This is the base protocol for the content model used in WCAG
/// accessibility analysis.
///
/// - Note: Ported from veraPDF-wcag-algs `IChunk` Java interface,
///   consolidating `IChunk` and `InfoChunk`.
public protocol ContentChunk: Sendable {

    /// The bounding box of this content chunk, specifying its location
    /// and the page it appears on.
    var boundingBox: BoundingBox { get }

    /// The zero-based index of the page this chunk belongs to.
    ///
    /// This is a convenience accessor that delegates to `boundingBox.pageIndex`.
    var pageIndex: Int { get }
}

// MARK: - Default Implementation

extension ContentChunk {

    /// Default implementation returns the page index from the bounding box.
    public var pageIndex: Int {
        boundingBox.pageIndex
    }
}

import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// An image content chunk extracted from a PDF document.
///
/// Represents a raster image embedded in a PDF page, including its spatial
/// location, pixel dimensions, color space information, and optional
/// alt text. This type is used in WCAG accessibility analysis to verify
/// that images have appropriate alternative text and contrast.
///
/// `ImageChunk` conforms to `ContentChunk`, making it interoperable with
/// other content types (text, line art) in the content analysis pipeline.
///
/// - Note: Ported from veraPDF-wcag-algs `ImageChunk` Java class.
public struct ImageChunk: ContentChunk, Sendable, Hashable, Codable {

    // MARK: - ContentChunk Conformance

    /// The bounding box of this image chunk, specifying its location and page.
    public let boundingBox: BoundingBox

    // MARK: - Image Metadata

    /// The width of the image in pixels.
    public let pixelWidth: Int

    /// The height of the image in pixels.
    public let pixelHeight: Int

    /// The number of bits per color component (e.g. 8 for 8-bit color).
    public let bitsPerComponent: Int

    /// The name of the color space used by this image (e.g. "DeviceRGB", "DeviceGray").
    public let colorSpaceName: String

    /// The number of color components per pixel (e.g. 3 for RGB, 1 for grayscale, 4 for CMYK).
    public let numberOfComponents: Int

    // MARK: - Accessibility Properties

    /// The alternative text for this image, if provided.
    ///
    /// In accessible PDFs, images should have alt text describing their content.
    /// This is a critical WCAG requirement for non-text content.
    public let altText: String?

    /// The actual text replacement for this image, if provided.
    ///
    /// `ActualText` is a PDF structure attribute that provides a text replacement
    /// for the image content. It differs from `altText` in that it is meant to
    /// replace the image entirely in text extraction.
    public let actualText: String?

    // MARK: - Initialization

    /// Creates a new image chunk with all metadata.
    ///
    /// - Parameters:
    ///   - boundingBox: The spatial location and page of this image.
    ///   - pixelWidth: The width of the image in pixels.
    ///   - pixelHeight: The height of the image in pixels.
    ///   - bitsPerComponent: The number of bits per color component.
    ///   - colorSpaceName: The name of the color space.
    ///   - numberOfComponents: The number of color components per pixel.
    ///   - altText: The alternative text, if any.
    ///   - actualText: The actual text replacement, if any.
    public init(
        boundingBox: BoundingBox,
        pixelWidth: Int,
        pixelHeight: Int,
        bitsPerComponent: Int = 8,
        colorSpaceName: String = "DeviceRGB",
        numberOfComponents: Int = 3,
        altText: String? = nil,
        actualText: String? = nil
    ) {
        self.boundingBox = boundingBox
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.bitsPerComponent = bitsPerComponent
        self.colorSpaceName = colorSpaceName
        self.numberOfComponents = numberOfComponents
        self.altText = altText
        self.actualText = actualText
    }

    // MARK: - Computed Properties

    /// Whether this image has any form of alternative text (alt text or actual text).
    ///
    /// Per WCAG 2.1 Success Criterion 1.1.1, all non-text content must have
    /// a text alternative that serves the equivalent purpose.
    public var hasAlternativeText: Bool {
        (altText != nil && altText?.isEmpty == false)
            || (actualText != nil && actualText?.isEmpty == false)
    }

    /// The total number of pixels in the image.
    public var pixelCount: Int {
        pixelWidth * pixelHeight
    }

    /// Whether this image is grayscale (single-component color space).
    public var isGrayscale: Bool {
        numberOfComponents == 1
    }

    /// The aspect ratio of the image (width / height).
    ///
    /// Returns `nil` if the height is zero.
    public var aspectRatio: CGFloat? {
        guard pixelHeight > 0 else { return nil }
        return CGFloat(pixelWidth) / CGFloat(pixelHeight)
    }

    /// The effective resolution (pixels per point) in the horizontal direction.
    ///
    /// Compares the pixel width to the bounding box width to determine
    /// the effective DPI-like measure. Returns `nil` if the bounding box
    /// has zero width.
    public var horizontalResolution: CGFloat? {
        guard boundingBox.width > 0 else { return nil }
        return CGFloat(pixelWidth) / boundingBox.width
    }

    /// The effective resolution (pixels per point) in the vertical direction.
    ///
    /// Compares the pixel height to the bounding box height to determine
    /// the effective DPI-like measure. Returns `nil` if the bounding box
    /// has zero height.
    public var verticalResolution: CGFloat? {
        guard boundingBox.height > 0 else { return nil }
        return CGFloat(pixelHeight) / boundingBox.height
    }

    /// The best available text description for this image.
    ///
    /// Prefers `altText` over `actualText`. Returns `nil` if neither is available.
    public var textDescription: String? {
        if let alt = altText, !alt.isEmpty {
            return alt
        }
        if let actual = actualText, !actual.isEmpty {
            return actual
        }
        return nil
    }
}

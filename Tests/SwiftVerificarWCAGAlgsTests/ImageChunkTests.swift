import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

/// Tests for `ImageChunk` struct.
@Suite("ImageChunk Tests")
struct ImageChunkTests {

    // MARK: - Helpers

    /// Creates a default bounding box for testing.
    private func makeBox(page: Int = 0, x: CGFloat = 10, y: CGFloat = 20,
                         width: CGFloat = 200, height: CGFloat = 150) -> BoundingBox {
        BoundingBox(pageIndex: page, x: x, y: y, width: width, height: height)
    }

    /// Creates a default image chunk for testing.
    private func makeImage(
        page: Int = 0,
        pixelWidth: Int = 800,
        pixelHeight: Int = 600,
        bitsPerComponent: Int = 8,
        colorSpaceName: String = "DeviceRGB",
        numberOfComponents: Int = 3,
        altText: String? = nil,
        actualText: String? = nil,
        boxWidth: CGFloat = 200,
        boxHeight: CGFloat = 150
    ) -> ImageChunk {
        ImageChunk(
            boundingBox: BoundingBox(pageIndex: page, x: 10, y: 20, width: boxWidth, height: boxHeight),
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            bitsPerComponent: bitsPerComponent,
            colorSpaceName: colorSpaceName,
            numberOfComponents: numberOfComponents,
            altText: altText,
            actualText: actualText
        )
    }

    // MARK: - Initialization

    @Test("ImageChunk stores all properties correctly")
    func initStoresProperties() {
        let box = makeBox(page: 3, x: 50, y: 100, width: 300, height: 200)
        let chunk = ImageChunk(
            boundingBox: box,
            pixelWidth: 1200,
            pixelHeight: 800,
            bitsPerComponent: 16,
            colorSpaceName: "DeviceCMYK",
            numberOfComponents: 4,
            altText: "A sunset",
            actualText: "Photo of sunset"
        )

        #expect(chunk.boundingBox == box)
        #expect(chunk.pixelWidth == 1200)
        #expect(chunk.pixelHeight == 800)
        #expect(chunk.bitsPerComponent == 16)
        #expect(chunk.colorSpaceName == "DeviceCMYK")
        #expect(chunk.numberOfComponents == 4)
        #expect(chunk.altText == "A sunset")
        #expect(chunk.actualText == "Photo of sunset")
    }

    @Test("ImageChunk default values")
    func initDefaultValues() {
        let box = makeBox()
        let chunk = ImageChunk(boundingBox: box, pixelWidth: 100, pixelHeight: 100)

        #expect(chunk.bitsPerComponent == 8)
        #expect(chunk.colorSpaceName == "DeviceRGB")
        #expect(chunk.numberOfComponents == 3)
        #expect(chunk.altText == nil)
        #expect(chunk.actualText == nil)
    }

    // MARK: - ContentChunk Conformance

    @Test("ImageChunk conforms to ContentChunk protocol")
    func contentChunkConformance() {
        let chunk = makeImage(page: 5)
        let contentChunk: any ContentChunk = chunk
        #expect(contentChunk.pageIndex == 5)
        #expect(contentChunk.boundingBox.pageIndex == 5)
    }

    @Test("ImageChunk pageIndex delegates to boundingBox")
    func pageIndexDelegation() {
        let chunk = makeImage(page: 7)
        #expect(chunk.pageIndex == 7)
        #expect(chunk.pageIndex == chunk.boundingBox.pageIndex)
    }

    // MARK: - hasAlternativeText

    @Test("hasAlternativeText returns true with altText")
    func hasAltTextWithAlt() {
        let chunk = makeImage(altText: "A chart")
        #expect(chunk.hasAlternativeText == true)
    }

    @Test("hasAlternativeText returns true with actualText")
    func hasAltTextWithActual() {
        let chunk = makeImage(actualText: "Chart showing data")
        #expect(chunk.hasAlternativeText == true)
    }

    @Test("hasAlternativeText returns true with both")
    func hasAltTextWithBoth() {
        let chunk = makeImage(altText: "A chart", actualText: "Chart data")
        #expect(chunk.hasAlternativeText == true)
    }

    @Test("hasAlternativeText returns false with nil")
    func hasAltTextNil() {
        let chunk = makeImage()
        #expect(chunk.hasAlternativeText == false)
    }

    @Test("hasAlternativeText returns false with empty string altText")
    func hasAltTextEmpty() {
        let chunk = makeImage(altText: "")
        #expect(chunk.hasAlternativeText == false)
    }

    @Test("hasAlternativeText returns false with empty string actualText")
    func hasAltTextEmptyActual() {
        let chunk = makeImage(actualText: "")
        #expect(chunk.hasAlternativeText == false)
    }

    @Test("hasAlternativeText returns false with both empty strings")
    func hasAltTextBothEmpty() {
        let chunk = makeImage(altText: "", actualText: "")
        #expect(chunk.hasAlternativeText == false)
    }

    // MARK: - pixelCount

    @Test("pixelCount returns correct value")
    func pixelCountCorrect() {
        let chunk = makeImage(pixelWidth: 800, pixelHeight: 600)
        #expect(chunk.pixelCount == 480_000)
    }

    @Test("pixelCount with zero dimension")
    func pixelCountZero() {
        let chunk = makeImage(pixelWidth: 0, pixelHeight: 600)
        #expect(chunk.pixelCount == 0)
    }

    @Test("pixelCount with single pixel")
    func pixelCountSingle() {
        let chunk = makeImage(pixelWidth: 1, pixelHeight: 1)
        #expect(chunk.pixelCount == 1)
    }

    // MARK: - isGrayscale

    @Test("isGrayscale returns true for single component")
    func isGrayscaleTrue() {
        let chunk = makeImage(colorSpaceName: "DeviceGray", numberOfComponents: 1)
        #expect(chunk.isGrayscale == true)
    }

    @Test("isGrayscale returns false for RGB")
    func isGrayscaleRGB() {
        let chunk = makeImage(numberOfComponents: 3)
        #expect(chunk.isGrayscale == false)
    }

    @Test("isGrayscale returns false for CMYK")
    func isGrayscaleCMYK() {
        let chunk = makeImage(numberOfComponents: 4)
        #expect(chunk.isGrayscale == false)
    }

    // MARK: - aspectRatio

    @Test("aspectRatio returns correct value")
    func aspectRatioCorrect() {
        let chunk = makeImage(pixelWidth: 800, pixelHeight: 600)
        let ratio = chunk.aspectRatio
        #expect(ratio != nil)
        #expect(abs(ratio! - (800.0 / 600.0)) < 0.001)
    }

    @Test("aspectRatio returns nil for zero height")
    func aspectRatioZeroHeight() {
        let chunk = makeImage(pixelWidth: 800, pixelHeight: 0)
        #expect(chunk.aspectRatio == nil)
    }

    @Test("aspectRatio for square image")
    func aspectRatioSquare() {
        let chunk = makeImage(pixelWidth: 500, pixelHeight: 500)
        let ratio = chunk.aspectRatio
        #expect(ratio != nil)
        #expect(abs(ratio! - 1.0) < 0.001)
    }

    // MARK: - Resolution

    @Test("horizontalResolution returns correct value")
    func horizontalResolutionCorrect() {
        let chunk = makeImage(pixelWidth: 800, boxWidth: 200)
        let resolution = chunk.horizontalResolution
        #expect(resolution != nil)
        #expect(abs(resolution! - 4.0) < 0.001)
    }

    @Test("verticalResolution returns correct value")
    func verticalResolutionCorrect() {
        let chunk = makeImage(pixelHeight: 600, boxHeight: 150)
        let resolution = chunk.verticalResolution
        #expect(resolution != nil)
        #expect(abs(resolution! - 4.0) < 0.001)
    }

    @Test("horizontalResolution returns nil for zero-width box")
    func horizontalResolutionZeroWidth() {
        let chunk = makeImage(boxWidth: 0)
        #expect(chunk.horizontalResolution == nil)
    }

    @Test("verticalResolution returns nil for zero-height box")
    func verticalResolutionZeroHeight() {
        let chunk = makeImage(boxHeight: 0)
        #expect(chunk.verticalResolution == nil)
    }

    // MARK: - textDescription

    @Test("textDescription prefers altText over actualText")
    func textDescriptionPrefersAlt() {
        let chunk = makeImage(altText: "Alt", actualText: "Actual")
        #expect(chunk.textDescription == "Alt")
    }

    @Test("textDescription falls back to actualText")
    func textDescriptionFallback() {
        let chunk = makeImage(actualText: "Actual")
        #expect(chunk.textDescription == "Actual")
    }

    @Test("textDescription returns nil when none set")
    func textDescriptionNil() {
        let chunk = makeImage()
        #expect(chunk.textDescription == nil)
    }

    @Test("textDescription skips empty altText and uses actualText")
    func textDescriptionSkipsEmpty() {
        let chunk = makeImage(altText: "", actualText: "Actual")
        #expect(chunk.textDescription == "Actual")
    }

    @Test("textDescription returns nil when both empty")
    func textDescriptionBothEmpty() {
        let chunk = makeImage(altText: "", actualText: "")
        #expect(chunk.textDescription == nil)
    }

    // MARK: - Equatable and Hashable

    @Test("Equal ImageChunks are equal")
    func equalityTrue() {
        let chunk1 = makeImage(altText: "test")
        let chunk2 = makeImage(altText: "test")
        #expect(chunk1 == chunk2)
    }

    @Test("Different ImageChunks are not equal")
    func equalityFalse() {
        let chunk1 = makeImage(pixelWidth: 800)
        let chunk2 = makeImage(pixelWidth: 1024)
        #expect(chunk1 != chunk2)
    }

    @Test("ImageChunks can be used in a Set")
    func hashableSet() {
        let chunk1 = makeImage(altText: "one")
        let chunk2 = makeImage(altText: "two")
        let chunk3 = makeImage(altText: "one")
        let set: Set<ImageChunk> = [chunk1, chunk2, chunk3]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("ImageChunk roundtrips through Codable")
    func codableRoundtrip() throws {
        let chunk = ImageChunk(
            boundingBox: makeBox(page: 2, x: 10, y: 20, width: 300, height: 200),
            pixelWidth: 1200,
            pixelHeight: 800,
            bitsPerComponent: 16,
            colorSpaceName: "DeviceCMYK",
            numberOfComponents: 4,
            altText: "A sunset photo",
            actualText: "Photo of sunset over ocean"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(chunk)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ImageChunk.self, from: data)

        #expect(decoded.boundingBox == chunk.boundingBox)
        #expect(decoded.pixelWidth == chunk.pixelWidth)
        #expect(decoded.pixelHeight == chunk.pixelHeight)
        #expect(decoded.bitsPerComponent == chunk.bitsPerComponent)
        #expect(decoded.colorSpaceName == chunk.colorSpaceName)
        #expect(decoded.numberOfComponents == chunk.numberOfComponents)
        #expect(decoded.altText == chunk.altText)
        #expect(decoded.actualText == chunk.actualText)
    }

    @Test("ImageChunk Codable preserves nil optional values")
    func codableNilValues() throws {
        let chunk = makeImage()
        let encoder = JSONEncoder()
        let data = try encoder.encode(chunk)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ImageChunk.self, from: data)

        #expect(decoded.altText == nil)
        #expect(decoded.actualText == nil)
    }

    // MARK: - Sendable

    @Test("ImageChunk is Sendable")
    func sendableConformance() async {
        let chunk = makeImage(altText: "test")
        let task = Task { chunk }
        let result = await task.value
        #expect(result.altText == "test")
    }
}

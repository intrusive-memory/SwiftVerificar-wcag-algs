import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

/// Tests for `TextChunk` struct.
@Suite("TextChunk Tests")
struct TextChunkTests {

    // MARK: - Helpers

    /// Creates a default bounding box for testing.
    private func makeBox(page: Int = 0, x: CGFloat = 0, y: CGFloat = 0,
                         width: CGFloat = 100, height: CGFloat = 20) -> BoundingBox {
        BoundingBox(pageIndex: page, x: x, y: y, width: width, height: height)
    }

    /// Creates a CGColor in sRGB color space.
    private func makeColor(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) -> CGColor {
        CGColor(srgbRed: r, green: g, blue: b, alpha: a)
    }

    /// Creates a default text chunk for testing.
    private func makeChunk(
        value: String = "Hello",
        fontSize: CGFloat = 12,
        fontWeight: CGFloat = 400,
        italicAngle: CGFloat = 0,
        slantDegree: CGFloat = 0,
        isUnderlined: Bool = false,
        baseline: CGFloat = 0,
        textColor: CGColor? = nil,
        backgroundColor: CGColor? = nil,
        contrastRatio: CGFloat? = nil,
        symbolPositions: [CGPoint] = []
    ) -> TextChunk {
        TextChunk(
            boundingBox: makeBox(),
            value: value,
            fontName: "Helvetica",
            fontSize: fontSize,
            fontWeight: fontWeight,
            italicAngle: italicAngle,
            textColor: textColor ?? makeColor(r: 0, g: 0, b: 0),
            backgroundColor: backgroundColor,
            contrastRatio: contrastRatio,
            isUnderlined: isUnderlined,
            baseline: baseline,
            slantDegree: slantDegree,
            symbolPositions: symbolPositions
        )
    }

    // MARK: - Initialization

    @Test("TextChunk stores all properties correctly")
    func initStoresProperties() {
        let box = makeBox(page: 2, x: 10, y: 20, width: 200, height: 30)
        let textColor = makeColor(r: 0, g: 0, b: 0)
        let bgColor = makeColor(r: 1, g: 1, b: 1)
        let positions = [CGPoint(x: 10, y: 20), CGPoint(x: 15, y: 20)]

        let chunk = TextChunk(
            boundingBox: box,
            value: "AB",
            fontName: "TimesNewRoman",
            fontSize: 14,
            fontWeight: 700,
            italicAngle: -12.0,
            textColor: textColor,
            backgroundColor: bgColor,
            contrastRatio: 21.0,
            isUnderlined: true,
            baseline: 5.0,
            slantDegree: 15.0,
            symbolPositions: positions
        )

        #expect(chunk.boundingBox == box)
        #expect(chunk.value == "AB")
        #expect(chunk.fontName == "TimesNewRoman")
        #expect(chunk.fontSize == 14)
        #expect(chunk.fontWeight == 700)
        #expect(chunk.italicAngle == -12.0)
        #expect(chunk.contrastRatio == 21.0)
        #expect(chunk.isUnderlined == true)
        #expect(chunk.baseline == 5.0)
        #expect(chunk.slantDegree == 15.0)
        #expect(chunk.symbolPositions == positions)
    }

    @Test("TextChunk default optional values are nil")
    func defaultOptionalValues() {
        let chunk = makeChunk()
        #expect(chunk.backgroundColor == nil)
        #expect(chunk.contrastRatio == nil)
    }

    @Test("TextChunk default boolean values are false")
    func defaultBooleanValues() {
        let chunk = makeChunk()
        #expect(chunk.isUnderlined == false)
    }

    @Test("TextChunk default numeric values are zero")
    func defaultNumericValues() {
        let chunk = makeChunk()
        #expect(chunk.baseline == 0)
        #expect(chunk.slantDegree == 0)
    }

    @Test("TextChunk default symbolPositions is empty")
    func defaultSymbolPositions() {
        let chunk = makeChunk()
        #expect(chunk.symbolPositions.isEmpty)
    }

    // MARK: - ContentChunk Conformance

    @Test("TextChunk conforms to ContentChunk")
    func contentChunkConformance() {
        let chunk = makeChunk()
        let asContentChunk: any ContentChunk = chunk
        #expect(asContentChunk.pageIndex == 0)
        #expect(asContentChunk.boundingBox == makeBox())
    }

    @Test("pageIndex delegates to boundingBox")
    func pageIndexDelegation() {
        let box = makeBox(page: 5)
        let chunk = TextChunk(
            boundingBox: box,
            value: "Test",
            fontName: "Arial",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: makeColor(r: 0, g: 0, b: 0)
        )
        #expect(chunk.pageIndex == 5)
    }

    // MARK: - isBold

    @Test("Weight 400 is not bold")
    func normalWeightNotBold() {
        let chunk = makeChunk(fontWeight: 400)
        #expect(chunk.isBold == false)
    }

    @Test("Weight 500 is not bold")
    func mediumWeightNotBold() {
        let chunk = makeChunk(fontWeight: 500)
        #expect(chunk.isBold == false)
    }

    @Test("Weight 599 is not bold")
    func weight599NotBold() {
        let chunk = makeChunk(fontWeight: 599)
        #expect(chunk.isBold == false)
    }

    @Test("Weight 600 is bold")
    func weight600IsBold() {
        let chunk = makeChunk(fontWeight: 600)
        #expect(chunk.isBold == true)
    }

    @Test("Weight 700 is bold")
    func weight700IsBold() {
        let chunk = makeChunk(fontWeight: 700)
        #expect(chunk.isBold == true)
    }

    @Test("Weight 900 is bold")
    func weight900IsBold() {
        let chunk = makeChunk(fontWeight: 900)
        #expect(chunk.isBold == true)
    }

    // MARK: - isItalic

    @Test("Zero italic angle and zero slant is not italic")
    func noItalicNoSlant() {
        let chunk = makeChunk(italicAngle: 0, slantDegree: 0)
        #expect(chunk.isItalic == false)
    }

    @Test("Positive italic angle is italic")
    func positiveItalicAngle() {
        let chunk = makeChunk(italicAngle: 12)
        #expect(chunk.isItalic == true)
    }

    @Test("Negative italic angle is italic")
    func negativeItalicAngle() {
        let chunk = makeChunk(italicAngle: -12)
        #expect(chunk.isItalic == true)
    }

    @Test("Small italic angle is italic")
    func smallItalicAngle() {
        let chunk = makeChunk(italicAngle: 0.1)
        #expect(chunk.isItalic == true)
    }

    @Test("Slant degree 10 is not italic")
    func slant10NotItalic() {
        let chunk = makeChunk(italicAngle: 0, slantDegree: 10)
        #expect(chunk.isItalic == false)
    }

    @Test("Slant degree 11 is italic")
    func slant11IsItalic() {
        let chunk = makeChunk(italicAngle: 0, slantDegree: 11)
        #expect(chunk.isItalic == true)
    }

    @Test("Both italic angle and high slant is italic")
    func bothItalicAndSlant() {
        let chunk = makeChunk(italicAngle: -12, slantDegree: 15)
        #expect(chunk.isItalic == true)
    }

    // MARK: - textType

    @Test("Size 12pt normal weight is regular")
    func size12Regular() {
        let chunk = makeChunk(fontSize: 12, fontWeight: 400)
        #expect(chunk.textType == .regular)
    }

    @Test("Size 17.9pt is regular")
    func size17_9Regular() {
        let chunk = makeChunk(fontSize: 17.9, fontWeight: 400)
        #expect(chunk.textType == .regular)
    }

    @Test("Size 18pt is large")
    func size18Large() {
        let chunk = makeChunk(fontSize: 18, fontWeight: 400)
        #expect(chunk.textType == .large)
    }

    @Test("Size 24pt is large")
    func size24Large() {
        let chunk = makeChunk(fontSize: 24, fontWeight: 400)
        #expect(chunk.textType == .large)
    }

    @Test("Size 14pt bold (weight 700) is large")
    func size14BoldLarge() {
        let chunk = makeChunk(fontSize: 14, fontWeight: 700)
        #expect(chunk.textType == .large)
    }

    @Test("Size 14pt semibold (weight 600) is large")
    func size14SemiBoldLarge() {
        let chunk = makeChunk(fontSize: 14, fontWeight: 600)
        #expect(chunk.textType == .large)
    }

    @Test("Size 14pt normal weight is regular")
    func size14NormalRegular() {
        let chunk = makeChunk(fontSize: 14, fontWeight: 400)
        #expect(chunk.textType == .regular)
    }

    @Test("Size 13.9pt bold is regular")
    func size13_9BoldRegular() {
        let chunk = makeChunk(fontSize: 13.9, fontWeight: 700)
        #expect(chunk.textType == .regular)
    }

    @Test("Size 18pt bold is large")
    func size18BoldLarge() {
        let chunk = makeChunk(fontSize: 18, fontWeight: 700)
        #expect(chunk.textType == .large)
    }

    // MARK: - Hashable / Equatable

    @Test("Equal chunks are equal")
    func equalChunks() {
        let a = makeChunk(value: "test")
        let b = makeChunk(value: "test")
        #expect(a == b)
    }

    @Test("Chunks with different values are not equal")
    func differentValues() {
        let a = makeChunk(value: "hello")
        let b = makeChunk(value: "world")
        #expect(a != b)
    }

    @Test("Chunks with different font sizes are not equal")
    func differentFontSizes() {
        let a = makeChunk(fontSize: 12)
        let b = makeChunk(fontSize: 14)
        #expect(a != b)
    }

    @Test("Chunks with different font weights are not equal")
    func differentFontWeights() {
        let a = makeChunk(fontWeight: 400)
        let b = makeChunk(fontWeight: 700)
        #expect(a != b)
    }

    @Test("Equal chunks have same hash value")
    func equalHashValues() {
        let a = makeChunk(value: "test", fontSize: 14, fontWeight: 700)
        let b = makeChunk(value: "test", fontSize: 14, fontWeight: 700)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Chunks can be used in a Set")
    func setUsage() {
        let a = makeChunk(value: "hello")
        let b = makeChunk(value: "world")
        let c = makeChunk(value: "hello") // duplicate of a
        let set: Set<TextChunk> = [a, b, c]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("TextChunk roundtrips through Codable")
    func codableRoundtrip() throws {
        let positions = [CGPoint(x: 10, y: 20), CGPoint(x: 15, y: 20)]
        let chunk = TextChunk(
            boundingBox: makeBox(page: 1, x: 5, y: 10, width: 50, height: 15),
            value: "Hello",
            fontName: "Helvetica-Bold",
            fontSize: 16,
            fontWeight: 700,
            italicAngle: -12,
            textColor: makeColor(r: 0, g: 0, b: 0),
            backgroundColor: makeColor(r: 1, g: 1, b: 1),
            contrastRatio: 21.0,
            isUnderlined: true,
            baseline: 3.0,
            slantDegree: 5.0,
            symbolPositions: positions
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(chunk)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TextChunk.self, from: data)

        #expect(decoded.boundingBox == chunk.boundingBox)
        #expect(decoded.value == chunk.value)
        #expect(decoded.fontName == chunk.fontName)
        #expect(decoded.fontSize == chunk.fontSize)
        #expect(decoded.fontWeight == chunk.fontWeight)
        #expect(decoded.italicAngle == chunk.italicAngle)
        #expect(decoded.contrastRatio == chunk.contrastRatio)
        #expect(decoded.isUnderlined == chunk.isUnderlined)
        #expect(decoded.baseline == chunk.baseline)
        #expect(decoded.slantDegree == chunk.slantDegree)
        #expect(decoded.symbolPositions == chunk.symbolPositions)
    }

    @Test("TextChunk Codable with nil optionals")
    func codableWithNilOptionals() throws {
        let chunk = makeChunk()
        let data = try JSONEncoder().encode(chunk)
        let decoded = try JSONDecoder().decode(TextChunk.self, from: data)

        #expect(decoded.value == chunk.value)
        #expect(decoded.backgroundColor == nil)
        #expect(decoded.contrastRatio == nil)
    }

    @Test("TextChunk Codable with empty symbolPositions")
    func codableEmptySymbols() throws {
        let chunk = makeChunk(symbolPositions: [])
        let data = try JSONEncoder().encode(chunk)
        let decoded = try JSONDecoder().decode(TextChunk.self, from: data)
        #expect(decoded.symbolPositions.isEmpty)
    }

    // MARK: - CGColor Helper Tests

    @Test("componentsFromCGColor extracts sRGB components")
    func componentsExtraction() {
        let color = makeColor(r: 0.5, g: 0.25, b: 0.75, a: 1.0)
        let components = TextChunk.componentsFromCGColor(color)
        #expect(components.count == 4)
        #expect(abs(components[0] - 0.5) < 0.01)
        #expect(abs(components[1] - 0.25) < 0.01)
        #expect(abs(components[2] - 0.75) < 0.01)
        #expect(abs(components[3] - 1.0) < 0.01)
    }

    @Test("cgColorFromComponents creates a valid CGColor")
    func colorCreation() {
        let components: [CGFloat] = [0.5, 0.25, 0.75, 1.0]
        let color = TextChunk.cgColorFromComponents(components)
        #expect(color.numberOfComponents >= 3)
    }

    @Test("CGColor roundtrip through components")
    func colorRoundtrip() {
        let original = makeColor(r: 0.3, g: 0.6, b: 0.9, a: 1.0)
        let components = TextChunk.componentsFromCGColor(original)
        let recreated = TextChunk.cgColorFromComponents(components)
        let recreatedComponents = TextChunk.componentsFromCGColor(recreated)

        #expect(abs(components[0] - recreatedComponents[0]) < 0.01)
        #expect(abs(components[1] - recreatedComponents[1]) < 0.01)
        #expect(abs(components[2] - recreatedComponents[2]) < 0.01)
    }

    // MARK: - Sendable

    @Test("TextChunk is Sendable")
    func sendable() async {
        let chunk = makeChunk()
        let task = Task { @Sendable in
            return chunk.value
        }
        let result = await task.value
        #expect(result == "Hello")
    }
}

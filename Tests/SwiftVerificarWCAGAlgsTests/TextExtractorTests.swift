import Testing
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
@testable import SwiftVerificarWCAGAlgs

@Suite("TextExtractor Tests")
struct TextExtractorTests {

    // MARK: - Initialization Tests

    @Test("Extractor initializes with default settings")
    func testInitializationDefaults() {
        let extractor = TextExtractor()
        #expect(extractor.preserveFormatting == true)
        #expect(extractor.normalizeWhitespace == false)
    }

    @Test("Extractor initializes with custom settings")
    func testInitializationCustom() {
        let extractor = TextExtractor(preserveFormatting: false, normalizeWhitespace: true)
        #expect(extractor.preserveFormatting == false)
        #expect(extractor.normalizeWhitespace == true)
    }

    // MARK: - Plain Text Extraction Tests

    @Test("Extract plain text: empty node")
    func testExtractPlainTextEmpty() {
        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, depth: 1)
        let text = extractor.extractPlainText(from: node)
        #expect(text.isEmpty)
    }

    @Test("Extract plain text: single paragraph")
    func testExtractPlainTextSingleParagraph() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))
        let chunk = TextChunk(
            boundingBox: bbox,
            value: "Hello, world!",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let line = TextLine(boundingBox: bbox, chunks: [chunk])
        let block = TextBlock(boundingBox: bbox, lines: [line])

        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, textBlocks: [block])
        let text = extractor.extractPlainText(from: node)

        #expect(text == "Hello, world!")
    }

    @Test("Extract plain text: multiple lines")
    func testExtractPlainTextMultipleLines() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 40))

        let chunk1 = TextChunk(
            boundingBox: bbox,
            value: "First line",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let chunk2 = TextChunk(
            boundingBox: bbox,
            value: "Second line",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )

        let line1 = TextLine(boundingBox: bbox, chunks: [chunk1])
        let line2 = TextLine(boundingBox: bbox, chunks: [chunk2])
        let block = TextBlock(boundingBox: bbox, lines: [line1, line2])

        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, textBlocks: [block])
        let text = extractor.extractPlainText(from: node)

        #expect(text.contains("First line"))
        #expect(text.contains("Second line"))
    }

    @Test("Extract plain text: nested nodes")
    func testExtractPlainTextNestedNodes() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))

        let chunk1 = TextChunk(
            boundingBox: bbox,
            value: "Parent text",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let line1 = TextLine(boundingBox: bbox, chunks: [chunk1])
        let block1 = TextBlock(boundingBox: bbox, lines: [line1])

        let chunk2 = TextChunk(
            boundingBox: bbox,
            value: "Child text",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let line2 = TextLine(boundingBox: bbox, chunks: [chunk2])
        let block2 = TextBlock(boundingBox: bbox, lines: [line2])

        let childNode = ContentNode(type: .span, textBlocks: [block2])
        let parentNode = ContentNode(type: .paragraph, children: [childNode], textBlocks: [block1])

        let extractor = TextExtractor()
        let text = extractor.extractPlainText(from: parentNode)

        #expect(text.contains("Parent text"))
        #expect(text.contains("Child text"))
    }

    @Test("Extract plain text: with whitespace normalization")
    func testExtractPlainTextNormalizeWhitespace() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))
        let chunk = TextChunk(
            boundingBox: bbox,
            value: "Hello    world!   ",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let line = TextLine(boundingBox: bbox, chunks: [chunk])
        let block = TextBlock(boundingBox: bbox, lines: [line])

        let extractor = TextExtractor(normalizeWhitespace: true)
        let node = ContentNode(type: .paragraph, textBlocks: [block])
        let text = extractor.extractPlainText(from: node)

        #expect(text == "Hello world!")
    }

    // MARK: - Text Chunk Extraction Tests

    @Test("Extract text chunks: empty node")
    func testExtractTextChunksEmpty() {
        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, depth: 1)
        let chunks = extractor.extractTextChunks(from: node)
        #expect(chunks.isEmpty)
    }

    @Test("Extract text chunks: single chunk")
    func testExtractTextChunksSingle() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))
        let chunk = TextChunk(
            boundingBox: bbox,
            value: "Test",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let line = TextLine(boundingBox: bbox, chunks: [chunk])
        let block = TextBlock(boundingBox: bbox, lines: [line])

        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, textBlocks: [block])
        let chunks = extractor.extractTextChunks(from: node)

        #expect(chunks.count == 1)
        #expect(chunks[0].value == "Test")
    }

    @Test("Extract text chunks: multiple chunks")
    func testExtractTextChunksMultiple() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))

        let chunk1 = TextChunk(
            boundingBox: bbox,
            value: "First",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let chunk2 = TextChunk(
            boundingBox: bbox,
            value: "Second",
            fontName: "Helvetica-Bold",
            fontSize: 14,
            fontWeight: 700,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )

        let line = TextLine(boundingBox: bbox, chunks: [chunk1, chunk2])
        let block = TextBlock(boundingBox: bbox, lines: [line])

        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, textBlocks: [block])
        let chunks = extractor.extractTextChunks(from: node)

        #expect(chunks.count == 2)
        #expect(chunks[0].value == "First")
        #expect(chunks[1].value == "Second")
        #expect(chunks[1].isBold)
    }

    @Test("Extract text chunks: nested nodes")
    func testExtractTextChunksNested() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))

        let chunk1 = TextChunk(
            boundingBox: bbox,
            value: "Parent",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let line1 = TextLine(boundingBox: bbox, chunks: [chunk1])
        let block1 = TextBlock(boundingBox: bbox, lines: [line1])

        let chunk2 = TextChunk(
            boundingBox: bbox,
            value: "Child",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let line2 = TextLine(boundingBox: bbox, chunks: [chunk2])
        let block2 = TextBlock(boundingBox: bbox, lines: [line2])

        let childNode = ContentNode(type: .span, textBlocks: [block2])
        let parentNode = ContentNode(type: .paragraph, children: [childNode], textBlocks: [block1])

        let extractor = TextExtractor()
        let chunks = extractor.extractTextChunks(from: parentNode)

        #expect(chunks.count == 2)
    }

    // MARK: - Text Statistics Tests

    @Test("Extract text statistics: empty node")
    func testExtractTextStatisticsEmpty() {
        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, depth: 1)
        let stats = extractor.extractTextStatistics(from: node)

        #expect(stats.totalChunks == 0)
        #expect(stats.totalCharacters == 0)
        #expect(stats.totalWords == 0)
    }

    @Test("Extract text statistics: single chunk")
    func testExtractTextStatisticsSingle() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))
        let chunk = TextChunk(
            boundingBox: bbox,
            value: "Hello world",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let line = TextLine(boundingBox: bbox, chunks: [chunk])
        let block = TextBlock(boundingBox: bbox, lines: [line])

        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, textBlocks: [block])
        let stats = extractor.extractTextStatistics(from: node)

        #expect(stats.totalChunks == 1)
        #expect(stats.totalCharacters == 11)
        #expect(stats.totalWords == 2)
        #expect(stats.averageFontSize == 12)
        #expect(stats.minFontSize == 12)
        #expect(stats.maxFontSize == 12)
    }

    @Test("Extract text statistics: multiple font sizes")
    func testExtractTextStatisticsMultipleFontSizes() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))

        let chunk1 = TextChunk(
            boundingBox: bbox,
            value: "Small",
            fontName: "Helvetica",
            fontSize: 10,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let chunk2 = TextChunk(
            boundingBox: bbox,
            value: "Large",
            fontName: "Helvetica",
            fontSize: 20,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )

        let line = TextLine(boundingBox: bbox, chunks: [chunk1, chunk2])
        let block = TextBlock(boundingBox: bbox, lines: [line])

        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, textBlocks: [block])
        let stats = extractor.extractTextStatistics(from: node)

        #expect(stats.minFontSize == 10)
        #expect(stats.maxFontSize == 20)
        #expect(stats.averageFontSize == 15)
        #expect(stats.uniqueFontSizes.count == 2)
    }

    @Test("Extract text statistics: bold and italic count")
    func testExtractTextStatisticsBoldItalic() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))

        let normalChunk = TextChunk(
            boundingBox: bbox,
            value: "Normal",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let boldChunk = TextChunk(
            boundingBox: bbox,
            value: "Bold",
            fontName: "Helvetica-Bold",
            fontSize: 12,
            fontWeight: 700,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let italicChunk = TextChunk(
            boundingBox: bbox,
            value: "Italic",
            fontName: "Helvetica-Oblique",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 15,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let underlinedChunk = TextChunk(
            boundingBox: bbox,
            value: "Underlined",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1),
            isUnderlined: true
        )

        let line = TextLine(boundingBox: bbox, chunks: [normalChunk, boldChunk, italicChunk, underlinedChunk])
        let block = TextBlock(boundingBox: bbox, lines: [line])

        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, textBlocks: [block])
        let stats = extractor.extractTextStatistics(from: node)

        #expect(stats.totalChunks == 4)
        #expect(stats.boldCount == 1)
        #expect(stats.italicCount == 1)
        #expect(stats.underlinedCount == 1)
    }

    @Test("Extract text statistics: dominant font family")
    func testExtractTextStatisticsDominantFontFamily() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))

        let chunk1 = TextChunk(
            boundingBox: bbox,
            value: "Helvetica1",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let chunk2 = TextChunk(
            boundingBox: bbox,
            value: "Helvetica2",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let chunk3 = TextChunk(
            boundingBox: bbox,
            value: "Times",
            fontName: "Times",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )

        let line = TextLine(boundingBox: bbox, chunks: [chunk1, chunk2, chunk3])
        let block = TextBlock(boundingBox: bbox, lines: [line])

        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, textBlocks: [block])
        let stats = extractor.extractTextStatistics(from: node)

        #expect(stats.dominantFontFamily == "Helvetica")
        #expect(stats.uniqueFontFamilies.count == 2)
    }

    @Test("Extract text statistics: large text classification")
    func testExtractTextStatisticsLargeText() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 30))
        let chunk = TextChunk(
            boundingBox: bbox,
            value: "Large heading",
            fontName: "Helvetica-Bold",
            fontSize: 18,
            fontWeight: 700,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let line = TextLine(boundingBox: bbox, chunks: [chunk])
        let block = TextBlock(boundingBox: bbox, lines: [line])

        let extractor = TextExtractor()
        let node = ContentNode(type: .h1, textBlocks: [block])
        let stats = extractor.extractTextStatistics(from: node)

        #expect(stats.isLargeText)
        #expect(stats.textType == .large)
    }

    // MARK: - Dominant Property Tests

    @Test("Dominant font size: single size")
    func testDominantFontSizeSingle() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))
        let chunk = TextChunk(
            boundingBox: bbox,
            value: "Test",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let line = TextLine(boundingBox: bbox, chunks: [chunk])
        let block = TextBlock(boundingBox: bbox, lines: [line])

        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, textBlocks: [block])
        let dominantSize = extractor.dominantFontSize(in: node)

        #expect(dominantSize == 12)
    }

    @Test("Dominant font size: mixed sizes")
    func testDominantFontSizeMixed() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))

        // More characters at size 12
        let chunk1 = TextChunk(
            boundingBox: bbox,
            value: "This is a longer text",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        // Fewer characters at size 16
        let chunk2 = TextChunk(
            boundingBox: bbox,
            value: "Short",
            fontName: "Helvetica",
            fontSize: 16,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )

        let line = TextLine(boundingBox: bbox, chunks: [chunk1, chunk2])
        let block = TextBlock(boundingBox: bbox, lines: [line])

        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, textBlocks: [block])
        let dominantSize = extractor.dominantFontSize(in: node)

        #expect(dominantSize == 12)
    }

    @Test("Dominant font weight: empty node")
    func testDominantFontWeightEmpty() {
        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, depth: 1)
        let dominantWeight = extractor.dominantFontWeight(in: node)

        #expect(dominantWeight == nil)
    }

    @Test("Dominant color: single color")
    func testDominantColorSingle() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))
        let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)

        let chunk = TextChunk(
            boundingBox: bbox,
            value: "Test",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: black
        )
        let line = TextLine(boundingBox: bbox, chunks: [chunk])
        let block = TextBlock(boundingBox: bbox, lines: [line])

        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, textBlocks: [block])
        let dominantColor = extractor.dominantColor(in: node)

        #expect(dominantColor != nil)
    }

    // MARK: - Text Lines and Blocks Extraction Tests

    @Test("Extract text lines: empty node")
    func testExtractTextLinesEmpty() {
        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, depth: 1)
        let lines = extractor.extractTextLines(from: node)
        #expect(lines.isEmpty)
    }

    @Test("Extract text lines: multiple lines")
    func testExtractTextLinesMultiple() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 40))

        let chunk1 = TextChunk(
            boundingBox: bbox,
            value: "Line 1",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let chunk2 = TextChunk(
            boundingBox: bbox,
            value: "Line 2",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )

        let line1 = TextLine(boundingBox: bbox, chunks: [chunk1])
        let line2 = TextLine(boundingBox: bbox, chunks: [chunk2])
        let block = TextBlock(boundingBox: bbox, lines: [line1, line2])

        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, textBlocks: [block])
        let lines = extractor.extractTextLines(from: node)

        #expect(lines.count == 2)
    }

    @Test("Extract text blocks: empty node")
    func testExtractTextBlocksEmpty() {
        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, depth: 1)
        let blocks = extractor.extractTextBlocks(from: node)
        #expect(blocks.isEmpty)
    }

    @Test("Extract text blocks: multiple blocks")
    func testExtractTextBlocksMultiple() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))

        let chunk1 = TextChunk(
            boundingBox: bbox,
            value: "Block 1",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let chunk2 = TextChunk(
            boundingBox: bbox,
            value: "Block 2",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )

        let line1 = TextLine(boundingBox: bbox, chunks: [chunk1])
        let line2 = TextLine(boundingBox: bbox, chunks: [chunk2])
        let block1 = TextBlock(boundingBox: bbox, lines: [line1])
        let block2 = TextBlock(boundingBox: bbox, lines: [line2])

        let extractor = TextExtractor()
        let node = ContentNode(type: .paragraph, textBlocks: [block1, block2])
        let blocks = extractor.extractTextBlocks(from: node)

        #expect(blocks.count == 2)
    }

    // MARK: - Codable Tests

    @Test("Text extractor is codable")
    func testTextExtractorCodable() throws {
        let extractor = TextExtractor(preserveFormatting: false, normalizeWhitespace: true)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(extractor)
        let decoded = try decoder.decode(TextExtractor.self, from: data)

        #expect(decoded.preserveFormatting == extractor.preserveFormatting)
        #expect(decoded.normalizeWhitespace == extractor.normalizeWhitespace)
    }

    @Test("Text statistics is codable")
    func testTextStatisticsCodable() throws {
        let stats = TextStatistics.empty
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(stats)
        let decoded = try decoder.decode(TextStatistics.self, from: data)

        #expect(decoded.totalChunks == stats.totalChunks)
        #expect(decoded.totalCharacters == stats.totalCharacters)
    }

    // MARK: - Edge Cases

    @Test("Extract from non-content node")
    func testExtractFromNonContentNode() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let figureNode = FigureNode(
            boundingBox: bbox,
            attributes: ["Alt": .string("Test figure")],
            imageChunks: []
        )

        let extractor = TextExtractor()
        let text = extractor.extractPlainText(from: figureNode)
        let chunks = extractor.extractTextChunks(from: figureNode)

        #expect(text.isEmpty)
        #expect(chunks.isEmpty)
    }

    @Test("Empty statistics properties")
    func testEmptyStatisticsProperties() {
        let stats = TextStatistics.empty
        #expect(stats.totalChunks == 0)
        #expect(stats.totalCharacters == 0)
        #expect(stats.totalWords == 0)
        #expect(stats.dominantFontFamily == nil)
        #expect(stats.dominantColor == nil)
        #expect(stats.uniqueFontFamilies.isEmpty)
        #expect(stats.uniqueFontSizes.isEmpty)
        #expect(!stats.isLargeText)
        #expect(stats.textType == .regular)
    }
}

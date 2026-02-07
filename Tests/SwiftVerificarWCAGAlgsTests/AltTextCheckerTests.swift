import Testing
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
@testable import SwiftVerificarWCAGAlgs

/// Tests for the AltTextChecker implementation.
@Suite("AltTextChecker Tests")
struct AltTextCheckerTests {

    // MARK: - Basic Functionality Tests

    @Test("AltTextChecker criterion")
    func testCheckerCriterion() {
        let checker = AltTextChecker()
        #expect(checker.criterion == .nonTextContent)
    }

    @Test("AltTextChecker default initialization")
    func testDefaultInitialization() {
        let checker = AltTextChecker()
        #expect(checker.minimumAltTextLength == 1)
        #expect(checker.checkImageChunks == true)
        #expect(checker.acceptCaptionAsAlt == false)
    }

    @Test("AltTextChecker custom initialization")
    func testCustomInitialization() {
        let checker = AltTextChecker(
            minimumAltTextLength: 10,
            checkImageChunks: false,
            acceptCaptionAsAlt: true
        )

        #expect(checker.minimumAltTextLength == 10)
        #expect(checker.checkImageChunks == false)
        #expect(checker.acceptCaptionAsAlt == true)
    }

    // MARK: - Non-Figure Node Tests

    @Test("AltTextChecker ignores non-figure nodes")
    func testIgnoresNonFigureNodes() {
        let checker = AltTextChecker()
        let paragraph = ContentNode(type: .paragraph, depth: 1)

        let result = checker.check(paragraph)
        #expect(result.passed)
        #expect(result.violations.isEmpty)
    }

    @Test("AltTextChecker ignores multiple non-figure nodes")
    func testIgnoresMultipleNonFigureNodes() {
        let checker = AltTextChecker()
        let nodes: [any SemanticNode] = [
            ContentNode(type: .paragraph, depth: 1),
            ContentNode(type: .heading, depth: 1),
            ContentNode(type: .span, depth: 2)
        ]

        let result = checker.check(nodes)
        #expect(result.passed)
    }

    // MARK: - Figure with Alt Text Tests

    @Test("Figure with valid alt text passes")
    func testFigureWithValidAltText() {
        let checker = AltTextChecker()
        let image = ImageChunk(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 100)),
            pixelWidth: 100,
            pixelHeight: 100
        )

        let attributes: AttributesDictionary = [
            "Alt": .string("A descriptive image")
        ]

        let figure = FigureNode(
            image: image,
            depth: 1,
            attributes: attributes
        )

        let result = checker.check(figure)
        #expect(result.passed)
        #expect(result.violations.isEmpty)
    }

    @Test("Figure with ActualText passes")
    func testFigureWithActualText() {
        let checker = AltTextChecker()
        let image = ImageChunk(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 100)),
            pixelWidth: 100,
            pixelHeight: 100
        )

        let attributes: AttributesDictionary = [
            "ActualText": .string("Company logo")
        ]

        let figure = FigureNode(
            image: image,
            depth: 1,
            attributes: attributes
        )

        let result = checker.check(figure)
        #expect(result.passed)
    }

    // MARK: - Missing Alt Text Tests

    @Test("Figure without alt text fails")
    func testFigureWithoutAltText() {
        let checker = AltTextChecker()
        let image = ImageChunk(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 100)),
            pixelWidth: 100,
            pixelHeight: 100
        )

        let figure = FigureNode(
            image: image,
            depth: 1,
            attributes: [:]
        )

        let result = checker.check(figure)
        #expect(!result.passed)
        #expect(result.violations.count == 1)
        #expect(result.violations[0].severity == .critical)
    }

    @Test("Figure with empty alt text fails")
    func testFigureWithEmptyAltText() {
        let checker = AltTextChecker()
        let image = ImageChunk(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 100)),
            pixelWidth: 100,
            pixelHeight: 100
        )

        let attributes: AttributesDictionary = [
            "Alt": .string("")
        ]

        let figure = FigureNode(
            image: image,
            depth: 1,
            attributes: attributes
        )

        let result = checker.check(figure)
        #expect(!result.passed)
        #expect(result.violations.count >= 1)
    }

    @Test("Figure with whitespace-only alt text fails")
    func testFigureWithWhitespaceAltText() {
        let checker = AltTextChecker()
        let image = ImageChunk(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 100)),
            pixelWidth: 100,
            pixelHeight: 100
        )

        let attributes: AttributesDictionary = [
            "Alt": .string("   \n\t   ")
        ]

        let figure = FigureNode(
            image: image,
            depth: 1,
            attributes: attributes
        )

        let result = checker.check(figure)
        #expect(!result.passed)
        #expect(result.violations.contains { $0.description.contains("whitespace-only") })
    }

    // MARK: - Minimum Length Tests

    @Test("Alt text below minimum length fails")
    func testAltTextBelowMinimumLength() {
        let checker = AltTextChecker(minimumAltTextLength: 10)
        let image = ImageChunk(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 100)),
            pixelWidth: 100,
            pixelHeight: 100
        )

        let attributes: AttributesDictionary = [
            "Alt": .string("Short")
        ]

        let figure = FigureNode(
            image: image,
            depth: 1,
            attributes: attributes
        )

        let result = checker.check(figure)
        #expect(!result.passed)
        #expect(result.violations.contains { $0.description.contains("too short") })
    }

    @Test("Alt text meeting minimum length passes")
    func testAltTextMeetsMinimumLength() {
        let checker = AltTextChecker(minimumAltTextLength: 10)
        let image = ImageChunk(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 100)),
            pixelWidth: 100,
            pixelHeight: 100
        )

        let attributes: AttributesDictionary = [
            "Alt": .string("This is a sufficiently long description")
        ]

        let figure = FigureNode(
            image: image,
            depth: 1,
            attributes: attributes
        )

        let result = checker.check(figure)
        #expect(result.passed)
    }

    // MARK: - Caption Tests

    @Test("Figure with caption passes when accepting captions")
    func testFigureWithCaptionAccepted() {
        let checker = AltTextChecker(acceptCaptionAsAlt: true)
        let image = ImageChunk(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 100)),
            pixelWidth: 100,
            pixelHeight: 100
        )

        let captionText = [
            TextBlock(
                boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 100, width: 100, height: 20)),
                lines: [
                    TextLine(
                        boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 100, width: 100, height: 20)),
                        chunks: [
                            TextChunk(
                                boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 100, width: 100, height: 20)),
                                value: "Figure 1: A diagram",
                                fontName: "Helvetica",
                                fontSize: 10,
                                fontWeight: 400,
                                italicAngle: 0,
                                textColor: CGColor(gray: 0, alpha: 1)
                            )
                        ]
                    )
                ]
            )
        ]

        let caption = ContentNode(
            type: .caption,
            depth: 2,
            textBlocks: captionText
        )

        let figure = FigureNode(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 120)),
            children: [caption],
            attributes: [:],
            depth: 1,
            imageChunks: [image]
        )

        let result = checker.check(figure)
        #expect(result.passed)
    }

    @Test("Figure with caption fails when not accepting captions")
    func testFigureWithCaptionNotAccepted() {
        let checker = AltTextChecker(acceptCaptionAsAlt: false)
        let image = ImageChunk(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 100)),
            pixelWidth: 100,
            pixelHeight: 100
        )

        let captionText = [
            TextBlock(
                boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 100, width: 100, height: 20)),
                lines: [
                    TextLine(
                        boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 100, width: 100, height: 20)),
                        chunks: [
                            TextChunk(
                                boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 100, width: 100, height: 20)),
                                value: "Figure 1: A diagram",
                                fontName: "Helvetica",
                                fontSize: 10,
                                fontWeight: 400,
                                italicAngle: 0,
                                textColor: CGColor(gray: 0, alpha: 1)
                            )
                        ]
                    )
                ]
            )
        ]

        let caption = ContentNode(
            type: .caption,
            depth: 2,
            textBlocks: captionText
        )

        let figure = FigureNode(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 120)),
            children: [caption],
            attributes: [:],
            depth: 1,
            imageChunks: [image]
        )

        let result = checker.check(figure)
        #expect(!result.passed)
    }

    // MARK: - Figure Without Visual Content Tests

    @Test("Figure without visual content is ignored")
    func testFigureWithoutVisualContent() {
        let checker = AltTextChecker()
        let figure = FigureNode(
            boundingBox: nil,
            attributes: [:],
            depth: 1,
            imageChunks: [],
            lineArtChunks: []
        )

        let result = checker.check(figure)
        #expect(result.passed)
    }

    // MARK: - Multiple Figures Tests

    @Test("Multiple figures with alt text all pass")
    func testMultipleFiguresWithAltText() {
        let checker = AltTextChecker()

        let figures: [FigureNode] = (0..<3).map { i in
            let image = ImageChunk(
                boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: CGFloat(i * 100), y: 0, width: 100, height: 100)),
                pixelWidth: 100,
                pixelHeight: 100
            )

            return FigureNode(
                image: image,
                depth: 1,
                attributes: ["Alt": .string("Image \(i)")]
            )
        }

        let result = checker.check(figures)
        #expect(result.passed)
    }

    @Test("Multiple figures with some missing alt text fail")
    func testMultipleFiguresSomeMissingAltText() {
        let checker = AltTextChecker()

        let figure1 = FigureNode(
            image: ImageChunk(
                boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 100)),
                pixelWidth: 100,
                pixelHeight: 100
            ),
            depth: 1,
            attributes: ["Alt": .string("Image 1")]
        )

        let figure2 = FigureNode(
            image: ImageChunk(
                boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 100, y: 0, width: 100, height: 100)),
                pixelWidth: 100,
                pixelHeight: 100
            ),
            depth: 1,
            attributes: [:]
        )

        let result = checker.check([figure1, figure2])
        #expect(!result.passed)
        #expect(result.violations.count >= 1)
    }

    // MARK: - Preset Checker Tests

    @Test("Strict checker preset")
    func testStrictChecker() {
        let checker = AltTextChecker.strict
        #expect(checker.minimumAltTextLength == 10)
        #expect(checker.checkImageChunks == true)
        #expect(checker.acceptCaptionAsAlt == false)
    }

    @Test("Lenient checker preset")
    func testLenientChecker() {
        let checker = AltTextChecker.lenient
        #expect(checker.minimumAltTextLength == 1)
        #expect(checker.checkImageChunks == false)
        #expect(checker.acceptCaptionAsAlt == true)
    }

    @Test("Accepting captions checker preset")
    func testAcceptingCaptionsChecker() {
        let checker = AltTextChecker.acceptingCaptions
        #expect(checker.minimumAltTextLength == 1)
        #expect(checker.checkImageChunks == true)
        #expect(checker.acceptCaptionAsAlt == true)
    }

    // MARK: - Line Art Tests

    @Test("Figure with line art and alt text passes")
    func testFigureWithLineArt() {
        let checker = AltTextChecker()
        let lineArt = LineArtChunk(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 100)),
            lines: []
        )

        let figure = FigureNode(
            lineArt: lineArt,
            depth: 1,
            attributes: ["Alt": .string("A diagram")]
        )

        let result = checker.check(figure)
        #expect(result.passed)
    }

    @Test("Figure with line art without alt text fails")
    func testFigureWithLineArtNoAlt() {
        let checker = AltTextChecker()
        let lineArt = LineArtChunk(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 100)),
            lines: []
        )

        let figure = FigureNode(
            lineArt: lineArt,
            depth: 1,
            attributes: [:]
        )

        let result = checker.check(figure)
        #expect(!result.passed)
    }

    // MARK: - Multiple Visual Elements Tests

    @Test("Figure with multiple images and alt text passes")
    func testFigureWithMultipleImages() {
        let checker = AltTextChecker()

        let images = (0..<3).map { i in
            ImageChunk(
                boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: CGFloat(i * 50), y: 0, width: 50, height: 50)),
                pixelWidth: 50,
                pixelHeight: 50
            )
        }

        let figure = FigureNode(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 150, height: 50)),
            attributes: ["Alt": .string("A composite image")],
            depth: 1,
            imageChunks: images
        )

        let result = checker.check(figure)
        #expect(result.passed)
    }

    // MARK: - Edge Cases

    @Test("Figure with both Alt and ActualText prefers Alt")
    func testFigureWithBothAltTypes() {
        let checker = AltTextChecker()
        let image = ImageChunk(
            boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 100)),
            pixelWidth: 100,
            pixelHeight: 100
        )

        let attributes: AttributesDictionary = [
            "Alt": .string("Alt text"),
            "ActualText": .string("Actual text")
        ]

        let figure = FigureNode(
            image: image,
            depth: 1,
            attributes: attributes
        )

        let result = checker.check(figure)
        #expect(result.passed)
    }

    @Test("Violation includes location information")
    func testViolationIncludesLocation() {
        let checker = AltTextChecker()
        let bbox = BoundingBox(pageIndex: 0, rect: CGRect(x: 10, y: 20, width: 100, height: 100))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 100,
            pixelHeight: 100
        )

        let figure = FigureNode(
            image: image,
            depth: 1,
            attributes: [:]
        )

        let result = checker.check(figure)
        #expect(!result.passed)
        #expect(result.violations[0].location == bbox)
    }
}

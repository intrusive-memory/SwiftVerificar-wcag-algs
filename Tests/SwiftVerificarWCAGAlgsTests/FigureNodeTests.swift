import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

/// Tests for the FigureNode struct.
@Suite("FigureNode Tests")
struct FigureNodeTests {

    // MARK: - Test Helpers

    func makeBoundingBox(page: Int = 0) -> BoundingBox {
        BoundingBox(pageIndex: page, rect: CGRect(x: 0, y: 0, width: 200, height: 150))
    }

    func makeImageChunk(
        altText: String? = nil,
        actualText: String? = nil
    ) -> ImageChunk {
        ImageChunk(
            boundingBox: makeBoundingBox(),
            pixelWidth: 800,
            pixelHeight: 600,
            altText: altText,
            actualText: actualText
        )
    }

    func makeLineArtChunk(
        altText: String? = nil,
        actualText: String? = nil
    ) -> LineArtChunk {
        let line = LineChunk(
            pageIndex: 0,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 100, y: 100),
            lineWidth: 1.0
        )
        return LineArtChunk(
            lines: [line],
            altText: altText,
            actualText: actualText
        )
    }

    func makeCaption(text: String = "Figure caption") -> ContentNode {
        let chunk = TextChunk(
            boundingBox: makeBoundingBox(),
            value: text,
            fontName: "Helvetica",
            fontSize: 10,
            fontWeight: 400,
            italicAngle: 0,
            textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        )
        let line = TextLine(boundingBox: makeBoundingBox(), chunks: [chunk])
        let block = TextBlock(boundingBox: makeBoundingBox(), lines: [line])
        return ContentNode.caption(textBlocks: [block])
    }

    // MARK: - Initialization Tests

    @Test("FigureNode initializes with default values")
    func initWithDefaults() {
        let figure = FigureNode()
        #expect(figure.type == .figure)
        #expect(figure.boundingBox == nil)
        #expect(figure.imageChunks.isEmpty)
        #expect(figure.lineArtChunks.isEmpty)
        #expect(figure.children.isEmpty)
        #expect(figure.errorCodes.isEmpty)
    }

    @Test("FigureNode initializes with image")
    func initWithImage() {
        let image = makeImageChunk()
        let figure = FigureNode(image: image)

        #expect(figure.imageChunks.count == 1)
        #expect(figure.boundingBox == image.boundingBox)
    }

    @Test("FigureNode initializes with line art")
    func initWithLineArt() {
        let lineArt = makeLineArtChunk()
        let figure = FigureNode(lineArt: lineArt)

        #expect(figure.lineArtChunks.count == 1)
    }

    @Test("FigureNode initializes with all properties")
    func initWithAllProperties() {
        let id = UUID()
        let box = makeBoundingBox()
        let image = makeImageChunk()
        let lineArt = makeLineArtChunk()
        let caption = makeCaption()
        let attrs: AttributesDictionary = ["Alt": .string("Description")]

        let figure = FigureNode(
            id: id,
            boundingBox: box,
            children: [caption],
            attributes: attrs,
            depth: 2,
            errorCodes: [.figureMissingAltText],
            imageChunks: [image],
            lineArtChunks: [lineArt]
        )

        #expect(figure.id == id)
        #expect(figure.type == .figure)
        #expect(figure.boundingBox == box)
        #expect(figure.children.count == 1)
        #expect(figure.imageChunks.count == 1)
        #expect(figure.lineArtChunks.count == 1)
        #expect(figure.depth == 2)
        #expect(figure.errorCodes.contains(.figureMissingAltText))
    }

    // MARK: - SemanticNode Protocol Conformance Tests

    @Test("FigureNode type is always figure")
    func typeIsFigure() {
        let figure = FigureNode()
        #expect(figure.type == .figure)
    }

    @Test("FigureNode conforms to SemanticNode")
    func conformsToSemanticNode() {
        let figure: any SemanticNode = FigureNode()
        #expect(figure.type == .figure)
    }

    @Test("FigureNode is Sendable")
    func sendable() {
        let figure = FigureNode()
        let sendable: any Sendable = figure
        #expect(sendable is FigureNode)
    }

    // MARK: - Visual Content Tests

    @Test("hasVisualContent returns true with images")
    func hasVisualContentWithImages() {
        let figure = FigureNode(image: makeImageChunk())
        #expect(figure.hasVisualContent)
    }

    @Test("hasVisualContent returns true with line art")
    func hasVisualContentWithLineArt() {
        let figure = FigureNode(lineArt: makeLineArtChunk())
        #expect(figure.hasVisualContent)
    }

    @Test("hasVisualContent returns false when empty")
    func hasVisualContentFalseWhenEmpty() {
        let figure = FigureNode()
        #expect(!figure.hasVisualContent)
    }

    @Test("imageCount returns correct count")
    func imageCountCorrect() {
        let image1 = makeImageChunk()
        let image2 = makeImageChunk()
        let figure = FigureNode(imageChunks: [image1, image2])
        #expect(figure.imageCount == 2)
    }

    @Test("lineArtCount returns correct count")
    func lineArtCountCorrect() {
        let art1 = makeLineArtChunk()
        let art2 = makeLineArtChunk()
        let figure = FigureNode(lineArtChunks: [art1, art2])
        #expect(figure.lineArtCount == 2)
    }

    @Test("visualElementCount returns total")
    func visualElementCountTotal() {
        let figure = FigureNode(
            imageChunks: [makeImageChunk()],
            lineArtChunks: [makeLineArtChunk(), makeLineArtChunk()]
        )
        #expect(figure.visualElementCount == 3)
    }

    // MARK: - Alt Text Tests

    @Test("hasAltText returns true with Alt attribute")
    func hasAltTextWithAltAttribute() {
        let figure = FigureNode(
            attributes: ["Alt": .string("Description")]
        )
        #expect(figure.hasAltText)
    }

    @Test("hasAltText returns true with ActualText attribute")
    func hasAltTextWithActualText() {
        let figure = FigureNode(
            attributes: ["ActualText": .string("Replacement")]
        )
        #expect(figure.hasAltText)
    }

    @Test("hasAltText returns false when no alt")
    func hasAltTextFalseWhenNoAlt() {
        let figure = FigureNode()
        #expect(!figure.hasAltText)
    }

    @Test("hasAltText returns false when alt is empty")
    func hasAltTextFalseWhenEmpty() {
        let figure = FigureNode(
            attributes: ["Alt": .string("")]
        )
        #expect(!figure.hasAltText)
    }

    // MARK: - Decorative Tests

    @Test("appearsDecorative returns true without alt or children")
    func appearsDecorativeTrue() {
        // Empty figure with no visual content is decorative
        let figure = FigureNode()
        #expect(figure.appearsDecorative)
    }

    @Test("appearsDecorative returns false with alt text")
    func appearsDecorativeFalseWithAlt() {
        let figure = FigureNode(
            attributes: ["Alt": .string("Description")],
            imageChunks: [makeImageChunk()]
        )
        #expect(!figure.appearsDecorative)
    }

    @Test("appearsDecorative returns false with children")
    func appearsDecorativeFalseWithChildren() {
        let caption = makeCaption()
        let figure = FigureNode(
            children: [caption],
            imageChunks: [makeImageChunk()]
        )
        #expect(!figure.appearsDecorative)
    }

    // MARK: - Caption Tests

    @Test("caption returns caption child node")
    func captionFound() {
        let captionNode = makeCaption(text: "My Caption")
        let figure = FigureNode(
            children: [captionNode],
            imageChunks: [makeImageChunk()]
        )

        #expect(figure.caption != nil)
        #expect(figure.caption?.type == .caption)
    }

    @Test("caption returns nil when no caption")
    func captionNotFound() {
        let figure = FigureNode(imageChunks: [makeImageChunk()])
        #expect(figure.caption == nil)
    }

    @Test("hasCaption returns true with caption")
    func hasCaptionTrue() {
        let captionNode = makeCaption()
        let figure = FigureNode(children: [captionNode])
        #expect(figure.hasCaption)
    }

    @Test("hasCaption returns false without caption")
    func hasCaptionFalse() {
        let figure = FigureNode()
        #expect(!figure.hasCaption)
    }

    @Test("captionText returns caption's text content")
    func captionTextContent() {
        let captionNode = makeCaption(text: "Test Caption Text")
        let figure = FigureNode(children: [captionNode])
        #expect(figure.captionText == "Test Caption Text")
    }

    // MARK: - Bounding Box Tests

    @Test("computedBoundingBox returns explicit box when set")
    func computedBoundingBoxExplicit() {
        let box = makeBoundingBox(page: 5)
        let figure = FigureNode(boundingBox: box)
        #expect(figure.computedBoundingBox == box)
    }

    @Test("computedBoundingBox computes union of visual elements")
    func computedBoundingBoxComputed() {
        let box1 = BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 50, height: 50))
        let box2 = BoundingBox(pageIndex: 0, rect: CGRect(x: 100, y: 100, width: 50, height: 50))
        let image1 = ImageChunk(boundingBox: box1, pixelWidth: 100, pixelHeight: 100)
        let image2 = ImageChunk(boundingBox: box2, pixelWidth: 100, pixelHeight: 100)

        let figure = FigureNode(imageChunks: [image1, image2])
        let computed = figure.computedBoundingBox

        #expect(computed != nil)
        #expect(computed?.rect.minX == 0)
        #expect(computed?.rect.minY == 0)
        #expect(computed?.rect.maxX == 150)
        #expect(computed?.rect.maxY == 150)
    }

    @Test("computedBoundingBox returns nil when no visual content")
    func computedBoundingBoxNil() {
        let figure = FigureNode()
        #expect(figure.computedBoundingBox == nil)
    }

    // MARK: - Pixel Count Tests

    @Test("totalPixelCount sums all image pixels")
    func totalPixelCountSums() {
        let image1 = ImageChunk(boundingBox: makeBoundingBox(), pixelWidth: 100, pixelHeight: 100)
        let image2 = ImageChunk(boundingBox: makeBoundingBox(), pixelWidth: 200, pixelHeight: 200)
        let figure = FigureNode(imageChunks: [image1, image2])

        #expect(figure.totalPixelCount == 10000 + 40000)
    }

    // MARK: - Image/LineArt Alt Text Tests

    @Test("anyImageHasAltText returns true when image has alt")
    func anyImageHasAltTextTrue() {
        let image = makeImageChunk(altText: "Image description")
        let figure = FigureNode(imageChunks: [image])
        #expect(figure.anyImageHasAltText)
    }

    @Test("anyImageHasAltText returns false when no image has alt")
    func anyImageHasAltTextFalse() {
        let image = makeImageChunk()
        let figure = FigureNode(imageChunks: [image])
        #expect(!figure.anyImageHasAltText)
    }

    @Test("anyLineArtHasAltText returns true when line art has alt")
    func anyLineArtHasAltTextTrue() {
        let art = makeLineArtChunk(altText: "Diagram")
        let figure = FigureNode(lineArtChunks: [art])
        #expect(figure.anyLineArtHasAltText)
    }

    // MARK: - Best Description Tests

    @Test("bestDescription prefers figure alt text")
    func bestDescriptionPrefersAlt() {
        let image = makeImageChunk(altText: "Image alt")
        let caption = makeCaption(text: "Caption text")
        let figure = FigureNode(
            children: [caption],
            attributes: ["Alt": .string("Figure alt")],
            imageChunks: [image]
        )

        #expect(figure.bestDescription == "Figure alt")
    }

    @Test("bestDescription falls back to caption")
    func bestDescriptionFallsBackToCaption() {
        let image = makeImageChunk()
        let caption = makeCaption(text: "Caption text")
        let figure = FigureNode(
            children: [caption],
            imageChunks: [image]
        )

        #expect(figure.bestDescription == "Caption text")
    }

    @Test("bestDescription falls back to image alt")
    func bestDescriptionFallsBackToImage() {
        let image = makeImageChunk(altText: "Image alt")
        let figure = FigureNode(imageChunks: [image])

        #expect(figure.bestDescription == "Image alt")
    }

    @Test("bestDescription falls back to line art alt")
    func bestDescriptionFallsBackToLineArt() {
        let art = makeLineArtChunk(altText: "Diagram alt")
        let figure = FigureNode(lineArtChunks: [art])

        #expect(figure.bestDescription == "Diagram alt")
    }

    @Test("bestDescription returns nil when nothing available")
    func bestDescriptionNil() {
        let figure = FigureNode(imageChunks: [makeImageChunk()])
        #expect(figure.bestDescription == nil)
    }

    // MARK: - Validation Tests

    @Test("validateAccessibility reports missing alt text")
    func validateReportsMissingAlt() {
        let figure = FigureNode(imageChunks: [makeImageChunk()])
        let errors = figure.validateAccessibility()
        #expect(errors.contains(.figureMissingAltText))
    }

    @Test("validateAccessibility does not report error when alt exists")
    func validateNoErrorWithAlt() {
        let figure = FigureNode(
            attributes: ["Alt": .string("Description")],
            imageChunks: [makeImageChunk()]
        )
        let errors = figure.validateAccessibility()
        #expect(!errors.contains(.figureMissingAltText))
    }

    @Test("validateAccessibility does not report error for decorative")
    func validateNoErrorForDecorative() {
        // Empty figure is decorative
        let figure = FigureNode()
        let errors = figure.validateAccessibility()
        #expect(!errors.contains(.figureMissingAltText))
    }

    // MARK: - Hashable Tests

    @Test("FigureNode is Hashable by ID")
    func hashableById() {
        let id = UUID()
        let fig1 = FigureNode(id: id)
        let fig2 = FigureNode(id: id, depth: 5)

        var set: Set<FigureNode> = []
        set.insert(fig1)
        set.insert(fig2)

        #expect(set.count == 1)
    }

    // MARK: - Equatable Tests

    @Test("FigureNode equality is by ID")
    func equalityById() {
        let id = UUID()
        let fig1 = FigureNode(id: id, depth: 1)
        let fig2 = FigureNode(id: id, depth: 2)
        let fig3 = FigureNode()

        #expect(fig1 == fig2)
        #expect(fig1 != fig3)
    }

    // MARK: - Codable Tests

    @Test("FigureNode encodes and decodes correctly")
    func codableRoundTrip() throws {
        let image = makeImageChunk()
        let lineArt = makeLineArtChunk()
        let original = FigureNode(
            boundingBox: makeBoundingBox(),
            attributes: ["Alt": .string("Description")],
            depth: 2,
            errorCodes: [.figureMissingAltText],
            imageChunks: [image],
            lineArtChunks: [lineArt]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FigureNode.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.type == .figure)
        #expect(decoded.depth == original.depth)
        #expect(decoded.imageChunks.count == 1)
        #expect(decoded.lineArtChunks.count == 1)
        #expect(decoded.errorCodes == original.errorCodes)
    }

    // MARK: - CustomStringConvertible Tests

    @Test("description shows image count")
    func descriptionWithImages() {
        let figure = FigureNode(
            imageChunks: [makeImageChunk(), makeImageChunk()]
        )
        let desc = figure.description
        #expect(desc.contains("Figure"))
        #expect(desc.contains("2 image"))
    }

    @Test("description shows line art count when no images")
    func descriptionWithLineArt() {
        let figure = FigureNode(
            lineArtChunks: [makeLineArtChunk()]
        )
        let desc = figure.description
        #expect(desc.contains("1 line art"))
    }

    @Test("description shows has alt indicator")
    func descriptionWithAlt() {
        let figure = FigureNode(
            attributes: ["Alt": .string("Description")],
            imageChunks: [makeImageChunk()]
        )
        let desc = figure.description
        #expect(desc.contains("[has alt]"))
    }

    @Test("description shows empty for no content")
    func descriptionEmpty() {
        let figure = FigureNode()
        let desc = figure.description
        #expect(desc.contains("empty"))
    }
}

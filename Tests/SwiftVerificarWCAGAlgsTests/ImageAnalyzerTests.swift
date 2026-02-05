import Testing
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
@testable import SwiftVerificarWCAGAlgs

@Suite("ImageAnalyzer Tests")
struct ImageAnalyzerTests {

    // MARK: - Initialization Tests

    @Test("Analyzer initializes with default settings")
    func testInitializationDefaults() {
        let analyzer = ImageAnalyzer()
        #expect(analyzer.minimumResolution == 1.0)
        #expect(analyzer.minimumNonDecorativeSize == 10)
        #expect(analyzer.maximumPixelCount == 10_000_000)
    }

    @Test("Analyzer initializes with custom settings")
    func testInitializationCustom() {
        let analyzer = ImageAnalyzer(
            minimumResolution: 2.0,
            minimumNonDecorativeSize: 20,
            maximumPixelCount: 5_000_000
        )
        #expect(analyzer.minimumResolution == 2.0)
        #expect(analyzer.minimumNonDecorativeSize == 20)
        #expect(analyzer.maximumPixelCount == 5_000_000)
    }

    // MARK: - Decorative Detection Tests

    @Test("Decorative detection: 1x1 pixel spacer")
    func testDecorativeDetection1x1() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 10, height: 10))
        let image = ImageChunk(boundingBox: bbox, pixelWidth: 1, pixelHeight: 1)

        let isDecorative = analyzer.checkIfDecorative(image)
        #expect(isDecorative)
    }

    @Test("Decorative detection: small icon (5x5)")
    func testDecorativeDetectionSmallIcon() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 10, height: 10))
        let image = ImageChunk(boundingBox: bbox, pixelWidth: 5, pixelHeight: 5)

        let isDecorative = analyzer.checkIfDecorative(image)
        #expect(isDecorative)
    }

    @Test("Decorative detection: thin horizontal divider")
    func testDecorativeDetectionHorizontalDivider() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 500, height: 2))
        let image = ImageChunk(boundingBox: bbox, pixelWidth: 500, pixelHeight: 1)

        let isDecorative = analyzer.checkIfDecorative(image)
        #expect(isDecorative)
    }

    @Test("Decorative detection: thin vertical divider")
    func testDecorativeDetectionVerticalDivider() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 2, height: 500))
        let image = ImageChunk(boundingBox: bbox, pixelWidth: 1, pixelHeight: 500)

        let isDecorative = analyzer.checkIfDecorative(image)
        #expect(isDecorative)
    }

    @Test("Decorative detection: normal image not decorative")
    func testDecorativeDetectionNormalImage() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 200, height: 150))
        let image = ImageChunk(boundingBox: bbox, pixelWidth: 400, pixelHeight: 300)

        let isDecorative = analyzer.checkIfDecorative(image)
        #expect(!isDecorative)
    }

    @Test("Decorative detection: at threshold (10x10)")
    func testDecorativeDetectionAtThreshold() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 20, height: 20))
        let imageBelow = ImageChunk(boundingBox: bbox, pixelWidth: 9, pixelHeight: 9)
        let imageAt = ImageChunk(boundingBox: bbox, pixelWidth: 10, pixelHeight: 10)
        let imageAbove = ImageChunk(boundingBox: bbox, pixelWidth: 11, pixelHeight: 11)

        #expect(analyzer.checkIfDecorative(imageBelow))
        #expect(!analyzer.checkIfDecorative(imageAt))
        #expect(!analyzer.checkIfDecorative(imageAbove))
    }

    // MARK: - Quality Analysis Tests

    @Test("Quality check: normal resolution image")
    func testQualityCheckNormalResolution() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 100,
            pixelHeight: 100,
            colorSpaceName: "DeviceRGB"
        )

        let issues = analyzer.checkQuality(image)
        #expect(issues.isEmpty)
    }

    @Test("Quality check: low resolution image")
    func testQualityCheckLowResolution() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 200, height: 200))
        // 100 pixels displayed at 200 points = 0.5 pixels per point (low)
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 100,
            pixelHeight: 100,
            colorSpaceName: "DeviceRGB"
        )

        let issues = analyzer.checkQuality(image)
        #expect(issues.contains(.lowResolution))
    }

    @Test("Quality check: excessive size")
    func testQualityCheckExcessiveSize() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 1000, height: 1000))
        // 5000 x 5000 = 25,000,000 pixels (exceeds 10M default)
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 5000,
            pixelHeight: 5000,
            colorSpaceName: "DeviceRGB"
        )

        let issues = analyzer.checkQuality(image)
        #expect(issues.contains(.excessiveSize))
    }

    @Test("Quality check: missing color space")
    func testQualityCheckMissingColorSpace() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 100,
            pixelHeight: 100,
            colorSpaceName: ""
        )

        let issues = analyzer.checkQuality(image)
        #expect(issues.contains(.missingColorSpace))
    }

    @Test("Quality check: unusual bit depth")
    func testQualityCheckUnusualBitDepth() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 100,
            pixelHeight: 100,
            bitsPerComponent: 32,  // Unusual
            colorSpaceName: "DeviceRGB"
        )

        let issues = analyzer.checkQuality(image)
        #expect(issues.contains(.unusualBitDepth))
    }

    @Test("Quality check: multiple issues")
    func testQualityCheckMultipleIssues() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 500, height: 500))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 5000,  // Excessive size
            pixelHeight: 5000,
            bitsPerComponent: 32,  // Unusual bit depth
            colorSpaceName: ""  // Missing color space
        )

        let issues = analyzer.checkQuality(image)
        #expect(issues.contains(.excessiveSize))
        #expect(issues.contains(.unusualBitDepth))
        #expect(issues.contains(.missingColorSpace))
        #expect(issues.count == 3)
    }

    // MARK: - Resolution Analysis Tests

    @Test("Resolution analysis: high resolution (Retina)")
    func testResolutionAnalysisHigh() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        // 200 pixels at 100 points = 2.0 pixels per point (Retina)
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 200,
            pixelHeight: 200,
            colorSpaceName: "DeviceRGB"
        )

        let analysis = analyzer.analyzeResolution(image)
        #expect(analysis.quality == .high)
        #expect(analysis.averageResolution == 2.0)
    }

    @Test("Resolution analysis: normal resolution")
    func testResolutionAnalysisNormal() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        // 100 pixels at 100 points = 1.0 pixels per point
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 100,
            pixelHeight: 100,
            colorSpaceName: "DeviceRGB"
        )

        let analysis = analyzer.analyzeResolution(image)
        #expect(analysis.quality == .normal)
        #expect(analysis.averageResolution == 1.0)
    }

    @Test("Resolution analysis: low resolution")
    func testResolutionAnalysisLow() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        // 75 pixels at 100 points = 0.75 pixels per point
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 75,
            pixelHeight: 75,
            colorSpaceName: "DeviceRGB"
        )

        let analysis = analyzer.analyzeResolution(image)
        #expect(analysis.quality == .low)
        #expect(analysis.averageResolution == 0.75)
    }

    @Test("Resolution analysis: very low resolution")
    func testResolutionAnalysisVeryLow() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        // 25 pixels at 100 points = 0.25 pixels per point
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 25,
            pixelHeight: 25,
            colorSpaceName: "DeviceRGB"
        )

        let analysis = analyzer.analyzeResolution(image)
        #expect(analysis.quality == .veryLow)
        #expect(analysis.averageResolution == 0.25)
    }

    // MARK: - Image Analysis Tests

    @Test("Analyze image: with alt text and good quality")
    func testAnalyzeImageWithAltTextGoodQuality() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 200,
            pixelHeight: 200,
            colorSpaceName: "DeviceRGB",
            altText: "Description of image"
        )

        let result = analyzer.analyze(image)
        #expect(result.hasAlternativeText)
        #expect(!result.isLikelyDecorative)
        #expect(result.qualityIssues.isEmpty)
        #expect(result.resolutionAnalysis.quality == .high)
        #expect(result.passesAltTextRequirement)
        #expect(!result.hasQualityConcerns)
    }

    @Test("Analyze image: missing alt text but decorative")
    func testAnalyzeImageNoAltTextButDecorative() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 5, height: 5))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 5,
            pixelHeight: 5,
            colorSpaceName: "DeviceRGB"
        )

        let result = analyzer.analyze(image)
        #expect(!result.hasAlternativeText)
        #expect(result.isLikelyDecorative)
        #expect(result.passesAltTextRequirement)  // Passes because decorative
    }

    @Test("Analyze image: missing alt text and not decorative - fails")
    func testAnalyzeImageNoAltTextNotDecorative() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 200, height: 150))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 400,
            pixelHeight: 300,
            colorSpaceName: "DeviceRGB"
        )

        let result = analyzer.analyze(image)
        #expect(!result.hasAlternativeText)
        #expect(!result.isLikelyDecorative)
        #expect(!result.passesAltTextRequirement)  // Fails
    }

    @Test("Analyze image: with quality issues")
    func testAnalyzeImageWithQualityIssues() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 200, height: 200))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 50,  // Low resolution
            pixelHeight: 50,
            colorSpaceName: ""  // Missing color space
        )

        let result = analyzer.analyze(image)
        #expect(!result.qualityIssues.isEmpty)
        #expect(result.hasQualityConcerns)
    }

    // MARK: - Figure Analysis Tests

    @Test("Analyze figure: with alt text at figure level")
    func testAnalyzeFigureWithAltText() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 200, height: 150))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 400,
            pixelHeight: 300,
            colorSpaceName: "DeviceRGB"
        )

        let figure = FigureNode(
            boundingBox: bbox,
            attributes: ["Alt": .string("Figure description")],
            imageChunks: [image]
        )

        let result = analyzer.analyzeFigure(figure)
        #expect(result.hasAlternativeText)
        #expect(result.imageCount == 1)
        #expect(result.lineArtCount == 0)
        #expect(result.passesRequirements)
    }

    @Test("Analyze figure: with alt text at image level")
    func testAnalyzeFigureImageAltText() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 200, height: 150))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 400,
            pixelHeight: 300,
            colorSpaceName: "DeviceRGB",
            altText: "Image description"
        )

        let figure = FigureNode(
            boundingBox: bbox,
            imageChunks: [image]
        )

        let result = analyzer.analyzeFigure(figure)
        #expect(result.hasAlternativeText)
        #expect(result.passesRequirements)
    }

    @Test("Analyze figure: without alt text")
    func testAnalyzeFigureNoAltText() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 200, height: 150))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 400,
            pixelHeight: 300,
            colorSpaceName: "DeviceRGB"
        )

        let figure = FigureNode(
            boundingBox: bbox,
            imageChunks: [image]
        )

        let result = analyzer.analyzeFigure(figure)
        #expect(!result.hasAlternativeText)
        #expect(!result.passesRequirements)
    }

    @Test("Analyze figure: multiple images with quality issues")
    func testAnalyzeFigureMultipleImagesQualityIssues() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 200, height: 150))

        let goodImage = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 400,
            pixelHeight: 300,
            colorSpaceName: "DeviceRGB",
            altText: "Good image"
        )

        let poorImage = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 50,  // Low resolution
            pixelHeight: 50,
            colorSpaceName: "DeviceRGB",
            altText: "Poor image"
        )

        let figure = FigureNode(
            boundingBox: bbox,
            attributes: ["Alt": .string("Figure with mixed quality")],
            imageChunks: [goodImage, poorImage]
        )

        let result = analyzer.analyzeFigure(figure)
        #expect(result.imageCount == 2)
        #expect(result.hasQualityIssues)
        #expect(result.passesRequirements)  // Has alt text
    }

    // MARK: - Batch Analysis Tests

    @Test("Batch analysis: empty array")
    func testBatchAnalysisEmpty() {
        let analyzer = ImageAnalyzer()
        let result = analyzer.analyzeImages([])

        #expect(result.totalImages == 0)
        #expect(result.altTextCoverage == 0)
        #expect(result.wcagComplianceRate == 0)
    }

    @Test("Batch analysis: all images with alt text")
    func testBatchAnalysisAllWithAltText() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))

        let images = (1...5).map { i in
            ImageChunk(
                boundingBox: bbox,
                pixelWidth: 200,
                pixelHeight: 200,
                colorSpaceName: "DeviceRGB",
                altText: "Image \(i)"
            )
        }

        let result = analyzer.analyzeImages(images)
        #expect(result.totalImages == 5)
        #expect(result.missingAltTextCount == 0)
        #expect(result.altTextCoverage == 100)
        #expect(result.wcagComplianceRate == 100)
    }

    @Test("Batch analysis: mixed alt text coverage")
    func testBatchAnalysisMixedAltText() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))

        let withAlt = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 200,
            pixelHeight: 200,
            colorSpaceName: "DeviceRGB",
            altText: "Has alt text"
        )

        let withoutAlt = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 200,
            pixelHeight: 200,
            colorSpaceName: "DeviceRGB"
        )

        let decorative = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 1,
            pixelHeight: 1,
            colorSpaceName: "DeviceRGB"
        )

        let images = [withAlt, withoutAlt, decorative]
        let result = analyzer.analyzeImages(images)

        #expect(result.totalImages == 3)
        #expect(result.missingAltTextCount == 2)
        #expect(result.likelyDecorativeCount == 1)
        #expect(result.altTextCoverage < 100)
        // WCAG compliance: 1 with alt + 1 decorative = 2/3 = 66.67%
        #expect(result.wcagComplianceRate > 65)
        #expect(result.wcagComplianceRate < 68)
    }

    @Test("Batch analysis: quality issue distribution")
    func testBatchAnalysisQualityDistribution() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 200, height: 200))

        let lowRes1 = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 50,
            pixelHeight: 50,
            colorSpaceName: "DeviceRGB"
        )

        let lowRes2 = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 75,
            pixelHeight: 75,
            colorSpaceName: "DeviceRGB"
        )

        let missingColorSpace = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 200,
            pixelHeight: 200,
            colorSpaceName: ""
        )

        let images = [lowRes1, lowRes2, missingColorSpace]
        let result = analyzer.analyzeImages(images)

        #expect(result.withQualityIssuesCount == 3)
        #expect(result.issueDistribution[.lowResolution] == 2)
        #expect(result.issueDistribution[.missingColorSpace] == 1)
    }

    // MARK: - Quality Issue Enum Tests

    @Test("Image quality issue: all cases")
    func testImageQualityIssueAllCases() {
        #expect(ImageQualityIssue.allCases.count == 4)
        #expect(ImageQualityIssue.allCases.contains(.lowResolution))
        #expect(ImageQualityIssue.allCases.contains(.excessiveSize))
        #expect(ImageQualityIssue.allCases.contains(.missingColorSpace))
        #expect(ImageQualityIssue.allCases.contains(.unusualBitDepth))
    }

    @Test("Resolution quality: all cases")
    func testResolutionQualityAllCases() {
        #expect(ResolutionQuality.allCases.count == 4)
        #expect(ResolutionQuality.allCases.contains(.high))
        #expect(ResolutionQuality.allCases.contains(.normal))
        #expect(ResolutionQuality.allCases.contains(.low))
        #expect(ResolutionQuality.allCases.contains(.veryLow))
    }

    // MARK: - Codable Tests

    @Test("Image analyzer is codable")
    func testImageAnalyzerCodable() throws {
        let analyzer = ImageAnalyzer(
            minimumResolution: 1.5,
            minimumNonDecorativeSize: 15,
            maximumPixelCount: 8_000_000
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(analyzer)
        let decoded = try decoder.decode(ImageAnalyzer.self, from: data)

        #expect(decoded.minimumResolution == analyzer.minimumResolution)
        #expect(decoded.minimumNonDecorativeSize == analyzer.minimumNonDecorativeSize)
        #expect(decoded.maximumPixelCount == analyzer.maximumPixelCount)
    }

    @Test("Image analysis result is codable")
    func testImageAnalysisResultCodable() throws {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 200,
            pixelHeight: 200,
            colorSpaceName: "DeviceRGB",
            altText: "Test"
        )

        let analyzer = ImageAnalyzer()
        let result = analyzer.analyze(image)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(result)
        let decoded = try decoder.decode(ImageAnalysisResult.self, from: data)

        #expect(decoded.hasAlternativeText == result.hasAlternativeText)
        #expect(decoded.isLikelyDecorative == result.isLikelyDecorative)
        #expect(decoded.pixelWidth == result.pixelWidth)
        #expect(decoded.pixelHeight == result.pixelHeight)
    }

    @Test("Figure analysis result is codable")
    func testFigureAnalysisResultCodable() throws {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 200,
            pixelHeight: 200,
            colorSpaceName: "DeviceRGB",
            altText: "Test"
        )

        let figure = FigureNode(boundingBox: bbox, attributes: ["Alt": .string("Figure")], imageChunks: [image])
        let analyzer = ImageAnalyzer()
        let result = analyzer.analyzeFigure(figure)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(result)
        let decoded = try decoder.decode(FigureAnalysisResult.self, from: data)

        #expect(decoded.hasAlternativeText == result.hasAlternativeText)
        #expect(decoded.imageCount == result.imageCount)
        #expect(decoded.lineArtCount == result.lineArtCount)
    }

    @Test("Batch analysis result is codable")
    func testBatchAnalysisResultCodable() throws {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 200,
            pixelHeight: 200,
            colorSpaceName: "DeviceRGB",
            altText: "Test"
        )

        let result = analyzer.analyzeImages([image])

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(result)
        let decoded = try decoder.decode(ImageBatchAnalysisResult.self, from: data)

        #expect(decoded.totalImages == result.totalImages)
        #expect(decoded.altTextCoverage == result.altTextCoverage)
        #expect(decoded.wcagComplianceRate == result.wcagComplianceRate)
    }

    // MARK: - Edge Cases

    @Test("Analyze image with zero-width bounding box")
    func testAnalyzeImageZeroWidthBoundingBox() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 0, height: 100))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 100,
            pixelHeight: 100,
            colorSpaceName: "DeviceRGB"
        )

        let result = analyzer.analyze(image)
        // Should handle gracefully, resolution will be nil/0
        #expect(result.resolutionAnalysis.averageResolution >= 0)
    }

    @Test("Batch analysis with single image")
    func testBatchAnalysisSingleImage() {
        let analyzer = ImageAnalyzer()
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let image = ImageChunk(
            boundingBox: bbox,
            pixelWidth: 200,
            pixelHeight: 200,
            colorSpaceName: "DeviceRGB",
            altText: "Test"
        )

        let result = analyzer.analyzeImages([image])
        #expect(result.totalImages == 1)
        #expect(result.altTextCoverage == 100)
        #expect(result.wcagComplianceRate == 100)
    }
}

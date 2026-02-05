import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Analyzes image properties for WCAG accessibility compliance.
///
/// `ImageAnalyzer` provides utilities for validating image accessibility,
/// including alternative text presence, image quality checks, and decorative
/// image detection. This is essential for WCAG 2.1 Success Criterion 1.1.1
/// (Non-text Content).
///
/// ## WCAG Requirements
///
/// Per WCAG 2.1 SC 1.1.1, all non-text content must have a text alternative:
/// - **Informative images**: Alt text describing the image content
/// - **Decorative images**: Empty alt text (`alt=""`) or marked as artifact
/// - **Functional images**: Alt text describing the function (e.g., "Search")
/// - **Complex images**: Short alt text plus long description
///
/// ## Image Quality Checks
///
/// The analyzer also checks for:
/// - Extremely low resolution (pixelated when scaled)
/// - Extremely small images (< 10x10 pixels, likely decorative)
/// - Very large images (potential performance issues)
/// - Missing color space information
///
/// ## Example
///
/// ```swift
/// let analyzer = ImageAnalyzer()
/// let image = ImageChunk(boundingBox: bbox, pixelWidth: 100, pixelHeight: 100)
///
/// let result = analyzer.analyze(image)
/// if !result.hasAlternativeText {
///     print("Warning: Image missing alt text")
/// }
/// if result.isLikelyDecorative {
///     print("Info: Image appears decorative")
/// }
/// ```
///
/// - Note: Ported from veraPDF-wcag-algs image analysis utilities.
public struct ImageAnalyzer: Sendable, Hashable, Codable {

    // MARK: - Configuration

    /// Minimum resolution (pixels per point) considered acceptable.
    ///
    /// Images with resolution below this threshold are flagged as low quality.
    /// Default: 1.0 (72 DPI at 1:1 scale).
    public let minimumResolution: CGFloat

    /// Minimum pixel size to be considered non-decorative.
    ///
    /// Images smaller than this (in both dimensions) are likely decorative
    /// icons or spacers. Default: 10x10 pixels.
    public let minimumNonDecorativeSize: Int

    /// Maximum pixel count to avoid performance issues.
    ///
    /// Images larger than this are flagged for potential performance problems.
    /// Default: 10,000,000 pixels (e.g., 3162x3162).
    public let maximumPixelCount: Int

    // MARK: - Initialization

    /// Creates a new image analyzer with the specified quality thresholds.
    ///
    /// - Parameters:
    ///   - minimumResolution: Minimum acceptable resolution (default: 1.0).
    ///   - minimumNonDecorativeSize: Minimum size for non-decorative images (default: 10).
    ///   - maximumPixelCount: Maximum pixel count before flagging (default: 10,000,000).
    public init(
        minimumResolution: CGFloat = 1.0,
        minimumNonDecorativeSize: Int = 10,
        maximumPixelCount: Int = 10_000_000
    ) {
        self.minimumResolution = minimumResolution
        self.minimumNonDecorativeSize = minimumNonDecorativeSize
        self.maximumPixelCount = maximumPixelCount
    }

    // MARK: - Public API

    /// Analyzes an image chunk for accessibility compliance.
    ///
    /// This performs comprehensive checks including alt text presence,
    /// decorative detection, and quality validation.
    ///
    /// - Parameter image: The image chunk to analyze.
    /// - Returns: An analysis result with all findings.
    public func analyze(_ image: ImageChunk) -> ImageAnalysisResult {
        let hasAltText = image.hasAlternativeText
        let isLikelyDecorative = checkIfDecorative(image)
        let qualityIssues = checkQuality(image)
        let resolutionAnalysis = analyzeResolution(image)

        return ImageAnalysisResult(
            hasAlternativeText: hasAltText,
            isLikelyDecorative: isLikelyDecorative,
            qualityIssues: qualityIssues,
            resolutionAnalysis: resolutionAnalysis,
            pixelWidth: image.pixelWidth,
            pixelHeight: image.pixelHeight,
            colorSpaceName: image.colorSpaceName
        )
    }

    /// Analyzes a figure node for accessibility compliance.
    ///
    /// This checks both the figure's alt text and analyzes any embedded images.
    ///
    /// - Parameter figure: The figure node to analyze.
    /// - Returns: An analysis result for the figure.
    public func analyzeFigure(_ figure: FigureNode) -> FigureAnalysisResult {
        let hasAltText = figure.hasAltText
        let imageAnalyses = figure.imageChunks.map { analyze($0) }

        let allImagesHaveAltText = imageAnalyses.allSatisfy(\.hasAlternativeText)
        let anyQualityIssues = imageAnalyses.contains { !$0.qualityIssues.isEmpty }

        return FigureAnalysisResult(
            hasAlternativeText: hasAltText || allImagesHaveAltText,
            imageCount: figure.imageChunks.count,
            lineArtCount: figure.lineArtChunks.count,
            imageAnalyses: imageAnalyses,
            hasQualityIssues: anyQualityIssues
        )
    }

    // MARK: - Decorative Detection

    /// Determines if an image is likely decorative based on size and context.
    ///
    /// An image is considered decorative if:
    /// - It is very small (e.g., 1x1 spacer, small icon)
    /// - It has a simple color (single-color or very low variation)
    /// - It is used purely for visual spacing or borders
    ///
    /// - Parameter image: The image chunk to check.
    /// - Returns: `true` if the image appears decorative, `false` otherwise.
    public func checkIfDecorative(_ image: ImageChunk) -> Bool {
        // Very small images are likely spacers or icons
        if image.pixelWidth < minimumNonDecorativeSize
            && image.pixelHeight < minimumNonDecorativeSize {
            return true
        }

        // 1x1 images are always decorative (spacers)
        if image.pixelWidth == 1 || image.pixelHeight == 1 {
            return true
        }

        // Extremely thin images (borders, dividers)
        let aspectRatio = image.aspectRatio ?? 1.0
        if aspectRatio > 20 || aspectRatio < 0.05 {
            return true
        }

        return false
    }

    // MARK: - Quality Analysis

    /// Checks for image quality issues.
    ///
    /// - Parameter image: The image chunk to check.
    /// - Returns: A set of detected quality issues.
    public func checkQuality(_ image: ImageChunk) -> Set<ImageQualityIssue> {
        var issues: Set<ImageQualityIssue> = []

        // Check for very low resolution
        if let hRes = image.horizontalResolution, hRes < minimumResolution {
            issues.insert(.lowResolution)
        }
        if let vRes = image.verticalResolution, vRes < minimumResolution {
            issues.insert(.lowResolution)
        }

        // Check for excessively large images
        if image.pixelCount > maximumPixelCount {
            issues.insert(.excessiveSize)
        }

        // Check for missing color space
        if image.colorSpaceName.isEmpty {
            issues.insert(.missingColorSpace)
        }

        // Check for unusual bit depth
        if image.bitsPerComponent < 1 || image.bitsPerComponent > 16 {
            issues.insert(.unusualBitDepth)
        }

        return issues
    }

    /// Analyzes the resolution of an image relative to its display size.
    ///
    /// - Parameter image: The image chunk to analyze.
    /// - Returns: A resolution analysis result.
    public func analyzeResolution(_ image: ImageChunk) -> ResolutionAnalysis {
        let hRes = image.horizontalResolution ?? 0
        let vRes = image.verticalResolution ?? 0
        let avgRes = (hRes + vRes) / 2

        let quality: ResolutionQuality
        if avgRes >= 2.0 {
            quality = .high      // 2x or better (Retina)
        } else if avgRes >= 1.0 {
            quality = .normal    // 1x (standard)
        } else if avgRes >= 0.5 {
            quality = .low       // < 1x (scaled up, may be pixelated)
        } else {
            quality = .veryLow   // Severely scaled up
        }

        return ResolutionAnalysis(
            horizontalResolution: hRes,
            verticalResolution: vRes,
            averageResolution: avgRes,
            quality: quality
        )
    }

    // MARK: - Batch Analysis

    /// Analyzes multiple images and returns aggregate statistics.
    ///
    /// - Parameter images: The image chunks to analyze.
    /// - Returns: Aggregate analysis results.
    public func analyzeImages(_ images: [ImageChunk]) -> ImageBatchAnalysisResult {
        let analyses = images.map { analyze($0) }

        let totalImages = images.count
        let missingAltText = analyses.filter { !$0.hasAlternativeText }.count
        let likelyDecorative = analyses.filter(\.isLikelyDecorative).count
        let withQualityIssues = analyses.filter { !$0.qualityIssues.isEmpty }.count

        var issueDistribution: [ImageQualityIssue: Int] = [:]
        for analysis in analyses {
            for issue in analysis.qualityIssues {
                issueDistribution[issue, default: 0] += 1
            }
        }

        return ImageBatchAnalysisResult(
            totalImages: totalImages,
            missingAltTextCount: missingAltText,
            likelyDecorativeCount: likelyDecorative,
            withQualityIssuesCount: withQualityIssues,
            issueDistribution: issueDistribution,
            analyses: analyses
        )
    }
}

// MARK: - Supporting Types

/// Result of analyzing a single image chunk.
public struct ImageAnalysisResult: Sendable, Hashable, Codable {

    /// Whether the image has alternative text.
    public let hasAlternativeText: Bool

    /// Whether the image is likely decorative (may not need alt text).
    public let isLikelyDecorative: Bool

    /// Quality issues detected in the image.
    public let qualityIssues: Set<ImageQualityIssue>

    /// Resolution analysis results.
    public let resolutionAnalysis: ResolutionAnalysis

    /// The pixel width of the image.
    public let pixelWidth: Int

    /// The pixel height of the image.
    public let pixelHeight: Int

    /// The color space name.
    public let colorSpaceName: String

    /// Whether this image passes WCAG alt text requirements.
    ///
    /// An image passes if it has alt text OR is likely decorative.
    public var passesAltTextRequirement: Bool {
        hasAlternativeText || isLikelyDecorative
    }

    /// Whether this image has any quality concerns.
    public var hasQualityConcerns: Bool {
        !qualityIssues.isEmpty || resolutionAnalysis.quality == .low || resolutionAnalysis.quality == .veryLow
    }
}

/// Result of analyzing a figure node.
public struct FigureAnalysisResult: Sendable, Hashable, Codable {

    /// Whether the figure has alternative text (at figure level or all images).
    public let hasAlternativeText: Bool

    /// Number of image chunks in the figure.
    public let imageCount: Int

    /// Number of line art chunks in the figure.
    public let lineArtCount: Int

    /// Individual image analyses.
    public let imageAnalyses: [ImageAnalysisResult]

    /// Whether any images have quality issues.
    public let hasQualityIssues: Bool

    /// Whether this figure passes WCAG requirements.
    public var passesRequirements: Bool {
        hasAlternativeText
    }
}

/// Result of batch image analysis.
public struct ImageBatchAnalysisResult: Sendable, Hashable, Codable {

    /// Total number of images analyzed.
    public let totalImages: Int

    /// Number of images missing alt text.
    public let missingAltTextCount: Int

    /// Number of images likely decorative.
    public let likelyDecorativeCount: Int

    /// Number of images with quality issues.
    public let withQualityIssuesCount: Int

    /// Distribution of quality issues.
    public let issueDistribution: [ImageQualityIssue: Int]

    /// Individual image analyses.
    public let analyses: [ImageAnalysisResult]

    /// Percentage of images with alt text.
    public var altTextCoverage: Double {
        guard totalImages > 0 else { return 0 }
        let withAltText = totalImages - missingAltTextCount
        return Double(withAltText) / Double(totalImages) * 100
    }

    /// Percentage of images that pass WCAG requirements.
    public var wcagComplianceRate: Double {
        guard totalImages > 0 else { return 0 }
        let passing = analyses.filter(\.passesAltTextRequirement).count
        return Double(passing) / Double(totalImages) * 100
    }
}

/// Image quality issues detected during analysis.
public enum ImageQualityIssue: String, Sendable, Hashable, Codable, CaseIterable {
    /// Image resolution is below acceptable threshold (may appear pixelated).
    case lowResolution = "low_resolution"

    /// Image is excessively large (potential performance issue).
    case excessiveSize = "excessive_size"

    /// Image is missing color space information.
    case missingColorSpace = "missing_color_space"

    /// Image has unusual bit depth (not 8 or 16).
    case unusualBitDepth = "unusual_bit_depth"
}

/// Resolution analysis for an image.
public struct ResolutionAnalysis: Sendable, Hashable, Codable {

    /// Horizontal resolution (pixels per point).
    public let horizontalResolution: CGFloat

    /// Vertical resolution (pixels per point).
    public let verticalResolution: CGFloat

    /// Average resolution.
    public let averageResolution: CGFloat

    /// Overall resolution quality rating.
    public let quality: ResolutionQuality
}

/// Resolution quality rating.
public enum ResolutionQuality: String, Sendable, Hashable, Codable, CaseIterable {
    /// High resolution (2x or better, Retina quality).
    case high = "high"

    /// Normal resolution (1x, standard quality).
    case normal = "normal"

    /// Low resolution (< 1x, may appear pixelated).
    case low = "low"

    /// Very low resolution (severely scaled up).
    case veryLow = "very_low"
}

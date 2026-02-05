import Testing
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
@testable import SwiftVerificarWCAGAlgs

@Suite("ColorContrastCalculator Tests")
struct ColorContrastCalculatorTests {

    let calculator = ColorContrastCalculator()

    // MARK: - Initialization Tests

    @Test("Calculator initializes successfully")
    func testInitialization() {
        let calc = ColorContrastCalculator()
        #expect(calc != nil)
    }

    // MARK: - Relative Luminance Tests

    @Test("Relative luminance: black")
    func testRelativeLuminanceBlack() {
        let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        let luminance = calculator.relativeLuminance(of: black)
        #expect(abs(luminance - 0.0) < 0.001)
    }

    @Test("Relative luminance: white")
    func testRelativeLuminanceWhite() {
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let luminance = calculator.relativeLuminance(of: white)
        #expect(abs(luminance - 1.0) < 0.001)
    }

    @Test("Relative luminance: red")
    func testRelativeLuminanceRed() {
        let red = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
        let luminance = calculator.relativeLuminance(of: red)
        // Red luminance coefficient is 0.2126
        #expect(abs(luminance - 0.2126) < 0.001)
    }

    @Test("Relative luminance: green")
    func testRelativeLuminanceGreen() {
        let green = CGColor(red: 0, green: 1, blue: 0, alpha: 1)
        let luminance = calculator.relativeLuminance(of: green)
        // Green luminance coefficient is 0.7152
        #expect(abs(luminance - 0.7152) < 0.001)
    }

    @Test("Relative luminance: blue")
    func testRelativeLuminanceBlue() {
        let blue = CGColor(red: 0, green: 0, blue: 1, alpha: 1)
        let luminance = calculator.relativeLuminance(of: blue)
        // Blue luminance coefficient is 0.0722
        #expect(abs(luminance - 0.0722) < 0.001)
    }

    @Test("Relative luminance: medium gray")
    func testRelativeLuminanceMediumGray() {
        let gray = CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        let luminance = calculator.relativeLuminance(of: gray)
        // For 0.5 sRGB: (0.5 + 0.055) / 1.055 ^ 2.4 ≈ 0.2140
        #expect(luminance > 0.2)
        #expect(luminance < 0.25)
    }

    @Test("Relative luminance: dark color")
    func testRelativeLuminanceDark() {
        let dark = CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        let luminance = calculator.relativeLuminance(of: dark)
        #expect(luminance > 0)
        #expect(luminance < 0.05)
    }

    // MARK: - Contrast Ratio Tests

    @Test("Contrast ratio: black on white")
    func testContrastRatioBlackOnWhite() {
        let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let ratio = calculator.contrastRatio(foreground: black, background: white)
        // Maximum contrast is 21:1
        #expect(abs(ratio - 21.0) < 0.1)
    }

    @Test("Contrast ratio: white on black")
    func testContrastRatioWhiteOnBlack() {
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        let ratio = calculator.contrastRatio(foreground: white, background: black)
        // Order shouldn't matter for contrast ratio
        #expect(abs(ratio - 21.0) < 0.1)
    }

    @Test("Contrast ratio: same color")
    func testContrastRatioSameColor() {
        let red = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
        let ratio = calculator.contrastRatio(foreground: red, background: red)
        // Same color has minimum contrast of 1:1
        #expect(abs(ratio - 1.0) < 0.001)
    }

    @Test("Contrast ratio: black on dark gray")
    func testContrastRatioBlackOnDarkGray() {
        let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        let darkGray = CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        let ratio = calculator.contrastRatio(foreground: black, background: darkGray)
        // Low contrast (both are dark)
        #expect(ratio < 3.0)
        #expect(ratio > 1.0)
    }

    @Test("Contrast ratio: blue on yellow")
    func testContrastRatioBlueOnYellow() {
        let blue = CGColor(red: 0, green: 0, blue: 1, alpha: 1)
        let yellow = CGColor(red: 1, green: 1, blue: 0, alpha: 1)
        let ratio = calculator.contrastRatio(foreground: blue, background: yellow)
        // Should have decent contrast (dark vs light)
        #expect(ratio > 5.0)
    }

    @Test("Contrast ratio: WCAG example - medium gray on white")
    func testContrastRatioWCAGExample() {
        // WCAG documentation example: #767676 on white
        let gray = CGColor(red: 0x76/255.0, green: 0x76/255.0, blue: 0x76/255.0, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let ratio = calculator.contrastRatio(foreground: gray, background: white)
        // This should be approximately 4.54:1
        #expect(ratio > 4.5)
        #expect(ratio < 4.6)
    }

    // MARK: - Required Ratio Tests

    @Test("Required ratio: regular text AA")
    func testRequiredRatioRegularAA() {
        let required = calculator.requiredRatio(for: .regular, level: .aa)
        #expect(required == 4.5)
    }

    @Test("Required ratio: regular text AAA")
    func testRequiredRatioRegularAAA() {
        let required = calculator.requiredRatio(for: .regular, level: .aaa)
        #expect(required == 7.0)
    }

    @Test("Required ratio: large text AA")
    func testRequiredRatioLargeAA() {
        let required = calculator.requiredRatio(for: .large, level: .aa)
        #expect(required == 3.0)
    }

    @Test("Required ratio: large text AAA")
    func testRequiredRatioLargeAAA() {
        let required = calculator.requiredRatio(for: .large, level: .aaa)
        #expect(required == 4.5)
    }

    @Test("Required ratio: logo text")
    func testRequiredRatioLogo() {
        let requiredAA = calculator.requiredRatio(for: .logo, level: .aa)
        let requiredAAA = calculator.requiredRatio(for: .logo, level: .aaa)
        #expect(requiredAA == 1.0)
        #expect(requiredAAA == 1.0)
    }

    // MARK: - Requirement Checking Tests

    @Test("Meets requirement: black on white, regular AA - passes")
    func testMeetsRequirementBlackOnWhiteRegularAA() {
        let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let ratio = calculator.contrastRatio(foreground: black, background: white)
        let passes = calculator.meetsRequirement(ratio: ratio, textType: .regular, level: .aa)
        #expect(passes)
    }

    @Test("Meets requirement: black on white, regular AAA - passes")
    func testMeetsRequirementBlackOnWhiteRegularAAA() {
        let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let ratio = calculator.contrastRatio(foreground: black, background: white)
        let passes = calculator.meetsRequirement(ratio: ratio, textType: .regular, level: .aaa)
        #expect(passes)
    }

    @Test("Meets requirement: low contrast, regular AA - fails")
    func testMeetsRequirementLowContrastRegularAA() {
        let lightGray = CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let ratio = calculator.contrastRatio(foreground: lightGray, background: white)
        let passes = calculator.meetsRequirement(ratio: ratio, textType: .regular, level: .aa)
        #expect(!passes)
    }

    @Test("Meets requirement: moderate contrast, large AA - passes")
    func testMeetsRequirementModerateContrastLargeAA() {
        // 3.5:1 contrast - fails regular AA but passes large AA
        let mediumGray = CGColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let ratio = calculator.contrastRatio(foreground: mediumGray, background: white)

        let passesRegularAA = calculator.meetsRequirement(ratio: ratio, textType: .regular, level: .aa)
        let passesLargeAA = calculator.meetsRequirement(ratio: ratio, textType: .large, level: .aa)

        // Should fail regular AA (needs 4.5:1) but pass large AA (needs 3.0:1)
        #expect(!passesRegularAA)
        #expect(passesLargeAA)
    }

    @Test("Meets requirement: logo always passes")
    func testMeetsRequirementLogoAlwaysPasses() {
        let veryLowContrast = CGColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        let ratio = calculator.contrastRatio(foreground: veryLowContrast, background: white)

        let passesAA = calculator.meetsRequirement(ratio: ratio, textType: .logo, level: .aa)
        let passesAAA = calculator.meetsRequirement(ratio: ratio, textType: .logo, level: .aaa)

        #expect(passesAA)
        #expect(passesAAA)
    }

    // MARK: - Text Chunk Analysis Tests

    @Test("Analyze text chunk: with background and good contrast")
    func testAnalyzeTextChunkGoodContrast() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))
        let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

        let chunk = TextChunk(
            boundingBox: bbox,
            value: "Test",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: black,
            backgroundColor: white
        )

        let result = calculator.analyzeTextChunk(chunk, level: .aa)
        #expect(result != nil)
        #expect(result?.passes == true)
        #expect(result?.ratio ?? 0 > 20.0)
    }

    @Test("Analyze text chunk: with background and poor contrast")
    func testAnalyzeTextChunkPoorContrast() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))
        let lightGray = CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

        let chunk = TextChunk(
            boundingBox: bbox,
            value: "Test",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: lightGray,
            backgroundColor: white
        )

        let result = calculator.analyzeTextChunk(chunk, level: .aa)
        #expect(result != nil)
        #expect(result?.passes == false)
        #expect(result?.ratio ?? 0 < 4.5)
    }

    @Test("Analyze text chunk: without background")
    func testAnalyzeTextChunkNoBackground() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 20))
        let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)

        let chunk = TextChunk(
            boundingBox: bbox,
            value: "Test",
            fontName: "Helvetica",
            fontSize: 12,
            fontWeight: 400,
            italicAngle: 0,
            textColor: black,
            backgroundColor: nil
        )

        let result = calculator.analyzeTextChunk(chunk, level: .aa)
        #expect(result == nil)
    }

    @Test("Analyze text chunk: large text with moderate contrast AAA")
    func testAnalyzeTextChunkLargeTextAAA() {
        let bbox = BoundingBox(pageIndex: 1, rect: CGRect(x: 0, y: 0, width: 100, height: 30))
        let mediumGray = CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

        // Large text (18pt)
        let chunk = TextChunk(
            boundingBox: bbox,
            value: "Heading",
            fontName: "Helvetica-Bold",
            fontSize: 18,
            fontWeight: 700,
            italicAngle: 0,
            textColor: mediumGray,
            backgroundColor: white
        )

        let resultAA = calculator.analyzeTextChunk(chunk, level: .aa)
        let resultAAA = calculator.analyzeTextChunk(chunk, level: .aaa)

        // Should pass AA (needs 3.0:1) but might fail AAA (needs 4.5:1)
        #expect(resultAA?.passes == true)
    }

    // MARK: - Contrast Analysis Result Tests

    @Test("Contrast analysis result: required ratio")
    func testContrastAnalysisResultRequiredRatio() {
        let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

        let result = ContrastAnalysisResult(
            foregroundColor: black,
            backgroundColor: white,
            ratio: 21.0,
            textType: .regular,
            level: .aa,
            passes: true
        )

        #expect(result.requiredRatio == 4.5)
    }

    @Test("Contrast analysis result: margin positive")
    func testContrastAnalysisResultMarginPositive() {
        let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

        let result = ContrastAnalysisResult(
            foregroundColor: black,
            backgroundColor: white,
            ratio: 7.0,
            textType: .regular,
            level: .aa,
            passes: true
        )

        // Margin = 7.0 - 4.5 = 2.5
        #expect(abs(result.margin - 2.5) < 0.1)
    }

    @Test("Contrast analysis result: margin negative")
    func testContrastAnalysisResultMarginNegative() {
        let lightGray = CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

        let result = ContrastAnalysisResult(
            foregroundColor: lightGray,
            backgroundColor: white,
            ratio: 2.0,
            textType: .regular,
            level: .aa,
            passes: false
        )

        // Margin = 2.0 - 4.5 = -2.5
        #expect(result.margin < 0)
    }

    @Test("Contrast analysis result: color reconstruction")
    func testContrastAnalysisResultColorReconstruction() {
        let red = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

        let result = ContrastAnalysisResult(
            foregroundColor: red,
            backgroundColor: white,
            ratio: 5.0,
            textType: .regular,
            level: .aa,
            passes: true
        )

        let reconstructedFg = result.foregroundColor
        let reconstructedBg = result.backgroundColor

        #expect(reconstructedFg != nil)
        #expect(reconstructedBg != nil)
    }

    // MARK: - WCAG Level Tests

    @Test("WCAG level: AA raw value")
    func testWCAGLevelAARawValue() {
        #expect(WCAGLevel.aa.rawValue == "AA")
    }

    @Test("WCAG level: AAA raw value")
    func testWCAGLevelAAARawValue() {
        #expect(WCAGLevel.aaa.rawValue == "AAA")
    }

    @Test("WCAG level: all cases")
    func testWCAGLevelAllCases() {
        #expect(WCAGLevel.allCases.count == 2)
        #expect(WCAGLevel.allCases.contains(.aa))
        #expect(WCAGLevel.allCases.contains(.aaa))
    }

    // MARK: - Codable Tests

    @Test("Calculator is codable")
    func testCalculatorCodable() throws {
        let calc = ColorContrastCalculator()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(calc)
        let decoded = try decoder.decode(ColorContrastCalculator.self, from: data)

        #expect(decoded == calc)
    }

    @Test("Contrast analysis result is codable")
    func testContrastAnalysisResultCodable() throws {
        let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

        let result = ContrastAnalysisResult(
            foregroundColor: black,
            backgroundColor: white,
            ratio: 21.0,
            textType: .regular,
            level: .aa,
            passes: true
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(result)
        let decoded = try decoder.decode(ContrastAnalysisResult.self, from: data)

        #expect(decoded.ratio == result.ratio)
        #expect(decoded.textType == result.textType)
        #expect(decoded.level == result.level)
        #expect(decoded.passes == result.passes)
    }

    // MARK: - Edge Cases

    @Test("Contrast ratio: transparent colors")
    func testContrastRatioTransparentColors() {
        let transparentBlack = CGColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        // Should still calculate based on RGB components
        let ratio = calculator.contrastRatio(foreground: transparentBlack, background: white)
        #expect(ratio > 1.0)
    }

    @Test("Relative luminance: normalized component threshold")
    func testRelativeLuminanceNormalizedThreshold() {
        // Test the 0.03928 threshold in normalization
        let justBelow = CGColor(red: 0.03, green: 0.03, blue: 0.03, alpha: 1)
        let justAbove = CGColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1)

        let lumBelow = calculator.relativeLuminance(of: justBelow)
        let lumAbove = calculator.relativeLuminance(of: justAbove)

        #expect(lumBelow > 0)
        #expect(lumAbove > 0)
        #expect(lumAbove > lumBelow)
    }
}

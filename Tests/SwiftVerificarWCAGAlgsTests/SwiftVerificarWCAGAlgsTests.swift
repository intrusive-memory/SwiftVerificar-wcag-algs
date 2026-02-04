import Testing
@testable import SwiftVerificarWCAGAlgs

@Suite("SwiftVerificarWCAGAlgs Tests")
struct SwiftVerificarWCAGAlgsTests {

    @Test("Library version is set correctly")
    func versionIsSet() {
        #expect(SwiftVerificarWCAGAlgs.version == "0.1.0")
    }

    @Test("WCAG Algs can be instantiated")
    func canInstantiate() {
        let algs = SwiftVerificarWCAGAlgs()
        #expect(algs != nil)
    }
}

@Suite("ContrastRatioCalculator Tests")
struct ContrastRatioCalculatorTests {

    let calculator = ContrastRatioCalculator()

    @Test("Black on white has maximum contrast")
    func blackOnWhite() {
        let ratio = calculator.contrastRatio(
            foreground: (r: 0, g: 0, b: 0),
            background: (r: 1, g: 1, b: 1)
        )
        #expect(ratio > 20.0)  // Should be ~21:1
    }

    @Test("White on white has minimum contrast")
    func whiteOnWhite() {
        let ratio = calculator.contrastRatio(
            foreground: (r: 1, g: 1, b: 1),
            background: (r: 1, g: 1, b: 1)
        )
        #expect(ratio == 1.0)  // Should be exactly 1:1
    }

    @Test("WCAG AA normal text requires 4.5:1")
    func wcagAANormalText() {
        #expect(calculator.meetsWCAGAA(ratio: 4.5) == true)
        #expect(calculator.meetsWCAGAA(ratio: 4.4) == false)
    }

    @Test("WCAG AA large text requires 3:1")
    func wcagAALargeText() {
        #expect(calculator.meetsWCAGAALargeText(ratio: 3.0) == true)
        #expect(calculator.meetsWCAGAALargeText(ratio: 2.9) == false)
    }

    @Test("WCAG AAA normal text requires 7:1")
    func wcagAAANormalText() {
        #expect(calculator.meetsWCAGAAA(ratio: 7.0) == true)
        #expect(calculator.meetsWCAGAAA(ratio: 6.9) == false)
    }
}

@Suite("StructureTreeValidator Tests")
struct StructureTreeValidatorTests {

    let validator = StructureTreeValidator()

    @Test("Valid heading hierarchy has no issues")
    func validHeadingHierarchy() {
        let issues = validator.validateHeadingHierarchy(headingLevels: [1, 2, 3, 2, 3])
        #expect(issues.isEmpty)
    }

    @Test("Skipped heading level is detected")
    func skippedHeadingLevel() {
        let issues = validator.validateHeadingHierarchy(headingLevels: [1, 3])  // Skips H2
        #expect(issues.count == 1)
        #expect(issues.first?.type == .skippedHeadingLevel)
    }

    @Test("Missing H1 is detected")
    func missingH1() {
        let issues = validator.validateHeadingHierarchy(headingLevels: [2, 3])  // Starts with H2
        #expect(issues.contains { $0.type == .missingH1 })
    }
}

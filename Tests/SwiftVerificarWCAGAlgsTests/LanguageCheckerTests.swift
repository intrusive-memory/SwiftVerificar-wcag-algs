import Testing
import Foundation
@testable import SwiftVerificarWCAGAlgs

/// Tests for the LanguageChecker implementation.
@Suite("LanguageChecker Tests")
struct LanguageCheckerTests {

    // MARK: - Basic Functionality Tests

    @Test("LanguageChecker criterion")
    func testCheckerCriterion() {
        let checker = LanguageChecker()
        #expect(checker.criterion == .languageOfPage)
    }

    @Test("LanguageChecker default initialization")
    func testDefaultInitialization() {
        let checker = LanguageChecker()
        #expect(checker.strictValidation == true)
        #expect(checker.checkAllNodes == false)
    }

    @Test("LanguageChecker custom initialization")
    func testCustomInitialization() {
        let checker = LanguageChecker(
            strictValidation: false,
            checkAllNodes: true
        )

        #expect(checker.strictValidation == false)
        #expect(checker.checkAllNodes == true)
    }

    // MARK: - Document Node Tests

    @Test("Document with valid language passes")
    func testDocumentWithValidLanguage() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("en")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(result.passed)
        #expect(result.violations.isEmpty)
    }

    @Test("Document with language including region passes")
    func testDocumentWithLanguageRegion() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("en-US")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(result.passed)
    }

    @Test("Document with language including script passes")
    func testDocumentWithLanguageScript() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("zh-Hans")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(result.passed)
    }

    @Test("Document without language fails")
    func testDocumentWithoutLanguage() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: [:],
            depth: 0
        )

        let result = checker.check(document)
        #expect(!result.passed)
        #expect(result.violations.count == 1)
        #expect(result.violations[0].severity == .critical)
        #expect(result.violations[0].description.contains("lacks language attribute"))
    }

    @Test("Document with empty language fails")
    func testDocumentWithEmptyLanguage() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(!result.passed)
        #expect(result.violations[0].description.contains("empty or whitespace-only"))
    }

    @Test("Document with whitespace language fails")
    func testDocumentWithWhitespaceLanguage() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("   \n\t   ")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(!result.passed)
    }

    // MARK: - Non-Document Node Tests

    @Test("Non-document node without language passes in document-only mode")
    func testNonDocumentNodeDocumentOnlyMode() {
        let checker = LanguageChecker(checkAllNodes: false)
        let paragraph = ContentNode(
            type: .paragraph,
            attributes: [:],
            depth: 1
        )

        let result = checker.check(paragraph)
        #expect(result.passed)
    }

    @Test("Non-document node ignored in document-only mode")
    func testIgnoresNonDocumentInDocumentMode() {
        let checker = LanguageChecker.documentOnly
        let heading = ContentNode(
            type: .heading,
            attributes: [:],
            depth: 1
        )

        let result = checker.check(heading)
        #expect(result.passed)
    }

    // MARK: - Language Code Validation Tests

    @Test("Two-letter language code passes")
    func testTwoLetterLanguageCode() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("fr")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(result.passed)
    }

    @Test("Three-letter language code passes")
    func testThreeLetterLanguageCode() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("fra")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(result.passed)
    }

    @Test("Invalid single-letter language code fails")
    func testInvalidSingleLetterCode() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("e")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(!result.passed)
        #expect(result.violations[0].description.contains("must be 2-3 letters"))
    }

    @Test("Invalid four-letter primary language fails")
    func testInvalidFourLetterPrimary() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("engl")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(!result.passed)
    }

    @Test("Language with numeric primary tag fails")
    func testLanguageWithNumericPrimary() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("12")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(!result.passed)
        #expect(result.violations[0].description.contains("must contain only letters"))
    }

    // MARK: - Region Subtag Tests

    @Test("Language with two-letter region passes")
    func testLanguageWithTwoLetterRegion() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("en-GB")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(result.passed)
    }

    @Test("Language with three-digit region passes")
    func testLanguageWithThreeDigitRegion() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("es-419")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(result.passed)
    }

    // MARK: - Script Subtag Tests

    @Test("Language with script passes")
    func testLanguageWithScript() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("zh-Hant")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(result.passed)
    }

    @Test("Language with script and region passes")
    func testLanguageWithScriptAndRegion() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("zh-Hans-CN")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(result.passed)
    }

    // MARK: - Lenient Mode Tests

    @Test("Lenient mode does not validate format")
    func testLenientMode() {
        let checker = LanguageChecker.lenient
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("invalid123")],
            depth: 0
        )

        let result = checker.check(document)
        // Lenient mode only checks for non-empty, not format
        #expect(result.passed)
    }

    @Test("Lenient mode still fails on empty language")
    func testLenientModeFailsOnEmpty() {
        let checker = LanguageChecker.lenient
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(!result.passed)
    }

    // MARK: - Check All Nodes Tests

    @Test("All elements mode checks paragraphs")
    func testAllElementsModeChecksParagraphs() {
        let checker = LanguageChecker.allElements
        let paragraph = ContentNode(
            type: .paragraph,
            attributes: ["Lang": .string("fr")],
            depth: 1
        )

        let result = checker.check(paragraph)
        #expect(result.passed)
    }

    @Test("All elements mode checks headings")
    func testAllElementsModeChecksHeadings() {
        let checker = LanguageChecker.allElements
        let heading = ContentNode(
            type: .heading,
            attributes: ["Lang": .string("de")],
            depth: 1
        )

        let result = checker.check(heading)
        #expect(result.passed)
    }

    // MARK: - Multiple Nodes Tests

    @Test("Multiple documents with valid languages pass")
    func testMultipleDocumentsWithLanguages() {
        let checker = LanguageChecker()

        let documents: [ContentNode] = [
            ContentNode(type: .document, attributes: ["Lang": .string("en")], depth: 0),
            ContentNode(type: .document, attributes: ["Lang": .string("fr")], depth: 0),
            ContentNode(type: .document, attributes: ["Lang": .string("de")], depth: 0)
        ]

        let result = checker.check(documents)
        #expect(result.passed)
    }

    @Test("Multiple documents with some missing languages fail")
    func testMultipleDocumentsSomeMissingLanguages() {
        let checker = LanguageChecker()

        let documents: [ContentNode] = [
            ContentNode(type: .document, attributes: ["Lang": .string("en")], depth: 0),
            ContentNode(type: .document, attributes: [:], depth: 0)
        ]

        let result = checker.check(documents)
        #expect(!result.passed)
        #expect(result.violations.count >= 1)
    }

    // MARK: - Preset Checker Tests

    @Test("Document-only preset")
    func testDocumentOnlyPreset() {
        let checker = LanguageChecker.documentOnly
        #expect(checker.strictValidation == true)
        #expect(checker.checkAllNodes == false)
    }

    @Test("All elements preset")
    func testAllElementsPreset() {
        let checker = LanguageChecker.allElements
        #expect(checker.strictValidation == true)
        #expect(checker.checkAllNodes == true)
    }

    @Test("Lenient preset")
    func testLenientPreset() {
        let checker = LanguageChecker.lenient
        #expect(checker.strictValidation == false)
        #expect(checker.checkAllNodes == false)
    }

    // MARK: - Common Language Codes Tests

    @Test("Common language codes set contains expected languages")
    func testCommonLanguageCodes() {
        #expect(LanguageChecker.commonLanguages.contains("en"))
        #expect(LanguageChecker.commonLanguages.contains("es"))
        #expect(LanguageChecker.commonLanguages.contains("fr"))
        #expect(LanguageChecker.commonLanguages.contains("de"))
        #expect(LanguageChecker.commonLanguages.contains("zh"))
    }

    @Test("Is common language recognizes common codes")
    func testIsCommonLanguage() {
        #expect(LanguageChecker.isCommonLanguage("en"))
        #expect(LanguageChecker.isCommonLanguage("fr"))
        #expect(LanguageChecker.isCommonLanguage("de"))
    }

    @Test("Is common language recognizes common codes with regions")
    func testIsCommonLanguageWithRegions() {
        #expect(LanguageChecker.isCommonLanguage("en-US"))
        #expect(LanguageChecker.isCommonLanguage("fr-CA"))
        #expect(LanguageChecker.isCommonLanguage("de-DE"))
    }

    @Test("Is common language rejects uncommon codes")
    func testIsCommonLanguageRejectsUncommon() {
        #expect(!LanguageChecker.isCommonLanguage("xxx"))
        #expect(!LanguageChecker.isCommonLanguage("zzz"))
    }

    // MARK: - Complex Language Codes Tests

    @Test("Language with variant passes")
    func testLanguageWithVariant() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("en-US-posix")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(result.passed)
    }

    @Test("Real-world language codes pass")
    func testRealWorldLanguageCodes() {
        let checker = LanguageChecker()

        let languageCodes = [
            "en", "en-US", "en-GB",
            "fr", "fr-FR", "fr-CA",
            "es", "es-ES", "es-MX", "es-419",
            "de", "de-DE", "de-AT",
            "zh", "zh-Hans", "zh-Hant", "zh-CN", "zh-TW",
            "ja", "ko", "ar", "ru", "pt", "pt-BR"
        ]

        for code in languageCodes {
            let document = ContentNode(
                type: .document,
                attributes: ["Lang": .string(code)],
                depth: 0
            )

            let result = checker.check(document)
            #expect(result.passed, "Language code '\(code)' should pass validation")
        }
    }

    // MARK: - Edge Cases

    @Test("Case sensitivity in validation")
    func testCaseSensitivity() {
        let checker = LanguageChecker()

        // Language codes are case-insensitive, but conventionally lowercase-UPPERCASE
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("EN-us")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(result.passed)
    }

    @Test("Violation includes node type information")
    func testViolationIncludesNodeType() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: [:],
            depth: 0
        )

        let result = checker.check(document)
        #expect(!result.passed)
        #expect(result.violations[0].nodeType == .document)
    }

    @Test("Mixed valid and invalid language codes")
    func testMixedValidInvalidCodes() {
        let checker = LanguageChecker()

        let documents: [ContentNode] = [
            ContentNode(type: .document, attributes: ["Lang": .string("en")], depth: 0),
            ContentNode(type: .document, attributes: ["Lang": .string("x")], depth: 0),
            ContentNode(type: .document, attributes: ["Lang": .string("fr-FR")], depth: 0)
        ]

        let result = checker.check(documents)
        #expect(!result.passed)
        #expect(result.violations.count == 1)
    }

    // MARK: - Invalid Subtag Tests

    @Test("Invalid subtag fails validation")
    func testInvalidSubtag() {
        let checker = LanguageChecker()
        let document = ContentNode(
            type: .document,
            attributes: ["Lang": .string("en-X")],
            depth: 0
        )

        let result = checker.check(document)
        #expect(!result.passed)
        #expect(result.violations[0].description.contains("Invalid subtag"))
    }
}

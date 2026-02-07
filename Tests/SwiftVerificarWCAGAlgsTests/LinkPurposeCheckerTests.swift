import Testing
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
@testable import SwiftVerificarWCAGAlgs

/// Tests for the LinkPurposeChecker implementation.
@Suite("LinkPurposeChecker Tests")
struct LinkPurposeCheckerTests {

    // MARK: - Basic Functionality Tests

    @Test("LinkPurposeChecker criterion")
    func testCheckerCriterion() {
        let checker = LinkPurposeChecker()
        #expect(checker.criterion == .linkPurpose)
    }

    @Test("LinkPurposeChecker default initialization")
    func testDefaultInitialization() {
        let checker = LinkPurposeChecker()
        #expect(checker.minimumLinkTextLength == 1)
        #expect(checker.checkForGenericText == true)
        #expect(checker.requireDistinctText == false)
    }

    @Test("LinkPurposeChecker custom initialization")
    func testCustomInitialization() {
        let checker = LinkPurposeChecker(
            minimumLinkTextLength: 5,
            checkForGenericText: false,
            genericPatterns: ["custom"],
            requireDistinctText: true
        )

        #expect(checker.minimumLinkTextLength == 5)
        #expect(checker.checkForGenericText == false)
        #expect(checker.requireDistinctText == true)
    }

    // MARK: - Non-Link Node Tests

    @Test("LinkPurposeChecker ignores non-link nodes")
    func testIgnoresNonLinkNodes() {
        let checker = LinkPurposeChecker()
        let paragraph = ContentNode(type: .paragraph, depth: 1)

        let result = checker.check(paragraph)
        #expect(result.passed)
        #expect(result.violations.isEmpty)
    }

    @Test("LinkPurposeChecker ignores multiple non-link nodes")
    func testIgnoresMultipleNonLinkNodes() {
        let checker = LinkPurposeChecker()
        let nodes: [any SemanticNode] = [
            ContentNode(type: .paragraph, depth: 1),
            ContentNode(type: .heading, depth: 1),
            FigureNode(depth: 1)
        ]

        let result = checker.check(nodes)
        #expect(result.passed)
    }

    // MARK: - Link with Text Tests

    @Test("Link with text content passes")
    func testLinkWithTextContent() {
        let checker = LinkPurposeChecker()

        let linkText = [
            TextBlock(
                boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 20)),
                lines: [
                    TextLine(
                        boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 20)),
                        chunks: [
                            TextChunk(
                                boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 20)),
                                value: "Visit our homepage",
                                fontName: "Helvetica",
                                fontSize: 12,
                                fontWeight: 400,
                                italicAngle: 0,
                                textColor: CGColor(gray: 0, alpha: 1)
                            )
                        ]
                    )
                ]
            )
        ]

        let link = ContentNode(
            type: .link,
            depth: 1,
            textBlocks: linkText
        )

        let result = checker.check(link)
        #expect(result.passed)
        #expect(result.violations.isEmpty)
    }

    @Test("Link with Alt text passes")
    func testLinkWithAltText() {
        let checker = LinkPurposeChecker()
        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("Homepage link")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(result.passed)
    }

    @Test("Link with ActualText passes")
    func testLinkWithActualText() {
        let checker = LinkPurposeChecker()
        let link = ContentNode(
            type: .link,
            attributes: ["ActualText": .string("Go to homepage")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(result.passed)
    }

    // MARK: - Empty Link Tests

    @Test("Link without text fails")
    func testLinkWithoutText() {
        let checker = LinkPurposeChecker()
        let link = ContentNode(
            type: .link,
            attributes: [:],
            depth: 1
        )

        let result = checker.check(link)
        #expect(!result.passed)
        #expect(result.violations.count == 1)
        #expect(result.violations[0].severity == .critical)
        #expect(result.violations[0].description.contains("no text content"))
    }

    @Test("Link with whitespace-only text fails")
    func testLinkWithWhitespaceOnlyText() {
        let checker = LinkPurposeChecker()
        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("   \n\t   ")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(!result.passed)
        #expect(result.violations.contains { $0.description.contains("whitespace-only") })
    }

    @Test("Link with punctuation-only text fails")
    func testLinkWithPunctuationOnlyText() {
        let checker = LinkPurposeChecker()
        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("...>>")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(!result.passed)
        #expect(result.violations.contains { $0.description.contains("punctuation or special characters") })
    }

    // MARK: - Minimum Length Tests

    @Test("Link text below minimum length fails")
    func testLinkTextBelowMinimumLength() {
        let checker = LinkPurposeChecker(minimumLinkTextLength: 10)
        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("Go")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(!result.passed)
        #expect(result.violations.contains { $0.description.contains("too short") })
    }

    @Test("Link text meeting minimum length passes")
    func testLinkTextMeetsMinimumLength() {
        let checker = LinkPurposeChecker(minimumLinkTextLength: 10)
        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("Visit our homepage")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(result.passed)
    }

    // MARK: - Generic Text Tests

    @Test("Link with 'click here' fails")
    func testLinkWithClickHere() {
        let checker = LinkPurposeChecker()
        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("click here")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(!result.passed)
        #expect(result.violations.contains { $0.description.contains("generic text") })
    }

    @Test("Link with 'here' fails")
    func testLinkWithHere() {
        let checker = LinkPurposeChecker()
        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("here")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(!result.passed)
    }

    @Test("Link with 'read more' fails")
    func testLinkWithReadMore() {
        let checker = LinkPurposeChecker()
        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("read more")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(!result.passed)
    }

    @Test("Link with 'link' fails")
    func testLinkWithLinkText() {
        let checker = LinkPurposeChecker()
        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("link")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(!result.passed)
    }

    @Test("Generic text check can be disabled")
    func testGenericTextCheckDisabled() {
        let checker = LinkPurposeChecker(checkForGenericText: false)
        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("click here")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(result.passed)
    }

    @Test("Case-insensitive generic text detection")
    func testCaseInsensitiveGenericText() {
        let checker = LinkPurposeChecker()
        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("CLICK HERE")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(!result.passed)
    }

    @Test("Generic text with whitespace is detected")
    func testGenericTextWithWhitespace() {
        let checker = LinkPurposeChecker()
        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("  click here  ")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(!result.passed)
    }

    // MARK: - Custom Generic Patterns Tests

    @Test("Custom generic patterns are respected")
    func testCustomGenericPatterns() {
        let customPatterns: Set<String> = ["custom", "pattern"]
        let checker = LinkPurposeChecker.withCustomPatterns(customPatterns)

        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("custom")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(!result.passed)
    }

    @Test("Non-custom pattern passes with custom patterns")
    func testNonCustomPatternPasses() {
        let customPatterns: Set<String> = ["custom"]
        let checker = LinkPurposeChecker.withCustomPatterns(customPatterns)

        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("click here")],
            depth: 1
        )

        // "click here" is not in custom patterns, so it should pass
        let result = checker.check(link)
        #expect(result.passed)
    }

    // MARK: - Multiple Links Tests

    @Test("Multiple links with distinct text pass")
    func testMultipleLinksWithDistinctText() {
        let checker = LinkPurposeChecker()

        let links: [ContentNode] = [
            ContentNode(type: .link, attributes: ["Alt": .string("Homepage")], depth: 1),
            ContentNode(type: .link, attributes: ["Alt": .string("About Us")], depth: 1),
            ContentNode(type: .link, attributes: ["Alt": .string("Contact")], depth: 1)
        ]

        let result = checker.check(links)
        #expect(result.passed)
    }

    @Test("Multiple links with some generic text fail")
    func testMultipleLinksSomeGeneric() {
        let checker = LinkPurposeChecker()

        let links: [ContentNode] = [
            ContentNode(type: .link, attributes: ["Alt": .string("Homepage")], depth: 1),
            ContentNode(type: .link, attributes: ["Alt": .string("click here")], depth: 1)
        ]

        let result = checker.check(links)
        #expect(!result.passed)
        #expect(result.violations.count >= 1)
    }

    @Test("Duplicate link text flagged when requireDistinctText is true")
    func testDuplicateLinkTextFlagged() {
        let checker = LinkPurposeChecker(requireDistinctText: true)

        let links: [ContentNode] = [
            ContentNode(type: .link, attributes: ["Alt": .string("Learn more")], depth: 1),
            ContentNode(type: .link, attributes: ["Alt": .string("Learn more")], depth: 1)
        ]

        let result = checker.check(links)
        #expect(!result.passed)
        #expect(result.violations.contains { $0.description.contains("share the same text") })
    }

    @Test("Duplicate link text allowed when requireDistinctText is false")
    func testDuplicateLinkTextAllowed() {
        // Use non-generic text to avoid generic text detection; only test distinct text logic
        let checker = LinkPurposeChecker(requireDistinctText: false)

        let links: [ContentNode] = [
            ContentNode(type: .link, attributes: ["Alt": .string("Visit the documentation portal")], depth: 1),
            ContentNode(type: .link, attributes: ["Alt": .string("Visit the documentation portal")], depth: 1)
        ]

        let result = checker.check(links)
        #expect(result.passed)
    }

    // MARK: - Text Extraction Priority Tests

    @Test("Alt text takes priority over ActualText")
    func testAltTextPriority() {
        let checker = LinkPurposeChecker()
        let link = ContentNode(
            type: .link,
            attributes: [
                "Alt": .string("Alt text"),
                "ActualText": .string("Actual text")
            ],
            depth: 1
        )

        let result = checker.check(link)
        #expect(result.passed)
    }

    @Test("ActualText used when Alt is missing")
    func testActualTextWhenAltMissing() {
        let checker = LinkPurposeChecker()
        let link = ContentNode(
            type: .link,
            attributes: ["ActualText": .string("Actual text")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(result.passed)
    }

    @Test("Title used when Alt and ActualText missing")
    func testTitleWhenOthersMissing() {
        let checker = LinkPurposeChecker()
        let link = ContentNode(
            type: .link,
            attributes: ["Title": .string("Title text")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(result.passed)
    }

    // MARK: - Preset Checker Tests

    @Test("Strict checker preset")
    func testStrictChecker() {
        let checker = LinkPurposeChecker.strict
        #expect(checker.minimumLinkTextLength == 5)
        #expect(checker.checkForGenericText == true)
        #expect(checker.requireDistinctText == true)
    }

    @Test("Lenient checker preset")
    func testLenientChecker() {
        let checker = LinkPurposeChecker.lenient
        #expect(checker.minimumLinkTextLength == 1)
        #expect(checker.checkForGenericText == false)
        #expect(checker.requireDistinctText == false)
    }

    @Test("Strict checker enforces minimum length")
    func testStrictCheckerEnforcesMinimum() {
        let checker = LinkPurposeChecker.strict
        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("Go")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(!result.passed)
    }

    // MARK: - Edge Cases

    @Test("Link with children content nodes")
    func testLinkWithChildrenContent() {
        let checker = LinkPurposeChecker()

        let linkText = [
            TextBlock(
                boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 20)),
                lines: [
                    TextLine(
                        boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 20)),
                        chunks: [
                            TextChunk(
                                boundingBox: BoundingBox(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 100, height: 20)),
                                value: "Homepage",
                                fontName: "Helvetica",
                                fontSize: 12,
                                fontWeight: 400,
                                italicAngle: 0,
                                textColor: CGColor(gray: 0, alpha: 1)
                            )
                        ]
                    )
                ]
            )
        ]

        let childContent = ContentNode(
            type: .span,
            depth: 2,
            textBlocks: linkText
        )

        let link = ContentNode(
            type: .link,
            children: [childContent],
            attributes: [:],
            depth: 1
        )

        let result = checker.check(link)
        #expect(result.passed)
    }

    @Test("Violation includes location information")
    func testViolationIncludesLocation() {
        let checker = LinkPurposeChecker()
        let bbox = BoundingBox(pageIndex: 0, rect: CGRect(x: 10, y: 20, width: 100, height: 20))
        let link = ContentNode(
            type: .link,
            boundingBox: bbox,
            attributes: [:],
            depth: 1
        )

        let result = checker.check(link)
        #expect(!result.passed)
        #expect(result.violations[0].location == bbox)
    }

    @Test("Multiple violations for same link")
    func testMultipleViolationsSameLink() {
        let checker = LinkPurposeChecker(minimumLinkTextLength: 10)
        let link = ContentNode(
            type: .link,
            attributes: ["Alt": .string("here")],
            depth: 1
        )

        let result = checker.check(link)
        #expect(!result.passed)
        // Should have violations for both generic text and short length
        #expect(result.violations.count >= 2)
    }

    // MARK: - Real-World Examples

    @Test("Good link text examples pass")
    func testGoodLinkTextExamples() {
        let checker = LinkPurposeChecker()

        let goodTexts = [
            "Download the annual report (PDF, 2MB)",
            "View our privacy policy",
            "Contact customer support",
            "Shop for running shoes",
            "Read the full article about climate change"
        ]

        for text in goodTexts {
            let link = ContentNode(
                type: .link,
                attributes: ["Alt": .string(text)],
                depth: 1
            )

            let result = checker.check(link)
            #expect(result.passed, "Link text '\(text)' should pass")
        }
    }

    @Test("Bad link text examples fail")
    func testBadLinkTextExamples() {
        let checker = LinkPurposeChecker()

        let badTexts = [
            "click here",
            "here",
            "more",
            "link",
            "..."
        ]

        for text in badTexts {
            let link = ContentNode(
                type: .link,
                attributes: ["Alt": .string(text)],
                depth: 1
            )

            let result = checker.check(link)
            #expect(!result.passed, "Link text '\(text)' should fail")
        }
    }
}

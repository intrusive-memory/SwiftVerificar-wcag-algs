import Testing
import Foundation
@testable import SwiftVerificarWCAGAlgs

/// Tests for `TextType` enum.
@Suite("TextType Tests")
struct TextTypeTests {

    // MARK: - Case Count

    @Test("TextType has exactly 3 cases")
    func caseCount() {
        #expect(TextType.allCases.count == 3)
    }

    // MARK: - Raw Values

    @Test("Regular raw value")
    func regularRawValue() {
        #expect(TextType.regular.rawValue == "regular")
    }

    @Test("Large raw value")
    func largeRawValue() {
        #expect(TextType.large.rawValue == "large")
    }

    @Test("Logo raw value")
    func logoRawValue() {
        #expect(TextType.logo.rawValue == "logo")
    }

    // MARK: - Contrast Requirements AA

    @Test("Regular text requires 4.5:1 for AA")
    func regularAARequirement() {
        #expect(TextType.regular.minimumContrastRatioAA == 4.5)
    }

    @Test("Large text requires 3.0:1 for AA")
    func largeAARequirement() {
        #expect(TextType.large.minimumContrastRatioAA == 3.0)
    }

    @Test("Logo text requires 1.0:1 for AA")
    func logoAARequirement() {
        #expect(TextType.logo.minimumContrastRatioAA == 1.0)
    }

    // MARK: - Contrast Requirements AAA

    @Test("Regular text requires 7.0:1 for AAA")
    func regularAAARequirement() {
        #expect(TextType.regular.minimumContrastRatioAAA == 7.0)
    }

    @Test("Large text requires 4.5:1 for AAA")
    func largeAAARequirement() {
        #expect(TextType.large.minimumContrastRatioAAA == 4.5)
    }

    @Test("Logo text requires 1.0:1 for AAA")
    func logoAAARequirement() {
        #expect(TextType.logo.minimumContrastRatioAAA == 1.0)
    }

    // MARK: - CaseIterable

    @Test("All cases are iterable")
    func allCases() {
        let cases = TextType.allCases
        #expect(cases.contains(.regular))
        #expect(cases.contains(.large))
        #expect(cases.contains(.logo))
    }

    // MARK: - Codable

    @Test("TextType roundtrips through Codable")
    func codableRoundtrip() throws {
        for textType in TextType.allCases {
            let data = try JSONEncoder().encode(textType)
            let decoded = try JSONDecoder().decode(TextType.self, from: data)
            #expect(decoded == textType)
        }
    }

    @Test("TextType decodes from raw string")
    func decodesFromRawString() throws {
        let json = Data("\"large\"".utf8)
        let decoded = try JSONDecoder().decode(TextType.self, from: json)
        #expect(decoded == .large)
    }
}

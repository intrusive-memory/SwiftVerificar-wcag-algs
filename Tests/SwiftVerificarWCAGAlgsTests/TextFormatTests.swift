import Testing
import Foundation
@testable import SwiftVerificarWCAGAlgs

/// Tests for `TextFormat` enum.
@Suite("TextFormat Tests")
struct TextFormatTests {

    // MARK: - Case Count

    @Test("TextFormat has exactly 3 cases")
    func caseCount() {
        #expect(TextFormat.allCases.count == 3)
    }

    // MARK: - Raw Values

    @Test("Normal raw value")
    func normalRawValue() {
        #expect(TextFormat.normal.rawValue == "normal")
    }

    @Test("Subscript raw value")
    func subscriptRawValue() {
        #expect(TextFormat.subscript.rawValue == "subscript")
    }

    @Test("Superscript raw value")
    func superscriptRawValue() {
        #expect(TextFormat.superscript.rawValue == "superscript")
    }

    // MARK: - CaseIterable

    @Test("All cases are iterable")
    func allCases() {
        let cases = TextFormat.allCases
        #expect(cases.contains(.normal))
        #expect(cases.contains(.subscript))
        #expect(cases.contains(.superscript))
    }

    // MARK: - Codable

    @Test("TextFormat roundtrips through Codable")
    func codableRoundtrip() throws {
        for format in TextFormat.allCases {
            let data = try JSONEncoder().encode(format)
            let decoded = try JSONDecoder().decode(TextFormat.self, from: data)
            #expect(decoded == format)
        }
    }

    @Test("TextFormat decodes from raw string")
    func decodesFromRawString() throws {
        let json = Data("\"superscript\"".utf8)
        let decoded = try JSONDecoder().decode(TextFormat.self, from: json)
        #expect(decoded == .superscript)
    }

    // MARK: - Equatable

    @Test("TextFormat cases are equatable")
    func equatable() {
        #expect(TextFormat.normal == TextFormat.normal)
        #expect(TextFormat.subscript == TextFormat.subscript)
        #expect(TextFormat.superscript == TextFormat.superscript)
        #expect(TextFormat.normal != TextFormat.subscript)
        #expect(TextFormat.subscript != TextFormat.superscript)
    }
}

import Testing
import Foundation
@testable import SwiftVerificarWCAGAlgs

/// Tests for the SemanticType enum.
@Suite("SemanticType Tests")
struct SemanticTypeTests {

    // MARK: - CaseIterable Tests

    @Test("SemanticType has expected number of cases")
    func caseCount() {
        // The enum should have at least 44 cases per the TODO.md spec
        #expect(SemanticType.allCases.count >= 44)
    }

    // MARK: - Raw Value Tests

    @Test("Document type has correct raw value")
    func documentRawValue() {
        #expect(SemanticType.document.rawValue == "Document")
    }

    @Test("Paragraph type has correct raw value")
    func paragraphRawValue() {
        #expect(SemanticType.paragraph.rawValue == "P")
    }

    @Test("Heading levels have correct raw values")
    func headingRawValues() {
        #expect(SemanticType.heading.rawValue == "H")
        #expect(SemanticType.h1.rawValue == "H1")
        #expect(SemanticType.h2.rawValue == "H2")
        #expect(SemanticType.h3.rawValue == "H3")
        #expect(SemanticType.h4.rawValue == "H4")
        #expect(SemanticType.h5.rawValue == "H5")
        #expect(SemanticType.h6.rawValue == "H6")
    }

    @Test("List types have correct raw values")
    func listRawValues() {
        #expect(SemanticType.list.rawValue == "L")
        #expect(SemanticType.listItem.rawValue == "LI")
        #expect(SemanticType.listLabel.rawValue == "Lbl")
        #expect(SemanticType.listBody.rawValue == "LBody")
    }

    @Test("Table types have correct raw values")
    func tableRawValues() {
        #expect(SemanticType.table.rawValue == "Table")
        #expect(SemanticType.tableRow.rawValue == "TR")
        #expect(SemanticType.tableHeader.rawValue == "TH")
        #expect(SemanticType.tableCell.rawValue == "TD")
        #expect(SemanticType.tableHead.rawValue == "THead")
        #expect(SemanticType.tableBody.rawValue == "TBody")
        #expect(SemanticType.tableFoot.rawValue == "TFoot")
    }

    @Test("Figure type has correct raw value")
    func figureRawValue() {
        #expect(SemanticType.figure.rawValue == "Figure")
    }

    // MARK: - isHeading Tests

    @Test("isHeading returns true for all heading types")
    func isHeadingTrue() {
        #expect(SemanticType.heading.isHeading)
        #expect(SemanticType.h1.isHeading)
        #expect(SemanticType.h2.isHeading)
        #expect(SemanticType.h3.isHeading)
        #expect(SemanticType.h4.isHeading)
        #expect(SemanticType.h5.isHeading)
        #expect(SemanticType.h6.isHeading)
    }

    @Test("isHeading returns false for non-heading types")
    func isHeadingFalse() {
        #expect(!SemanticType.paragraph.isHeading)
        #expect(!SemanticType.document.isHeading)
        #expect(!SemanticType.figure.isHeading)
        #expect(!SemanticType.table.isHeading)
        #expect(!SemanticType.list.isHeading)
    }

    // MARK: - headingLevel Tests

    @Test("headingLevel returns correct values for H1-H6")
    func headingLevelCorrect() {
        #expect(SemanticType.h1.headingLevel == 1)
        #expect(SemanticType.h2.headingLevel == 2)
        #expect(SemanticType.h3.headingLevel == 3)
        #expect(SemanticType.h4.headingLevel == 4)
        #expect(SemanticType.h5.headingLevel == 5)
        #expect(SemanticType.h6.headingLevel == 6)
    }

    @Test("headingLevel returns nil for generic heading and non-headings")
    func headingLevelNil() {
        #expect(SemanticType.heading.headingLevel == nil)
        #expect(SemanticType.paragraph.headingLevel == nil)
        #expect(SemanticType.document.headingLevel == nil)
    }

    // MARK: - isList Tests

    @Test("isList returns true for list-related types")
    func isListTrue() {
        #expect(SemanticType.list.isList)
        #expect(SemanticType.listItem.isList)
        #expect(SemanticType.listLabel.isList)
        #expect(SemanticType.listBody.isList)
    }

    @Test("isList returns false for non-list types")
    func isListFalse() {
        #expect(!SemanticType.paragraph.isList)
        #expect(!SemanticType.table.isList)
        #expect(!SemanticType.figure.isList)
    }

    // MARK: - isTable Tests

    @Test("isTable returns true for table-related types")
    func isTableTrue() {
        #expect(SemanticType.table.isTable)
        #expect(SemanticType.tableRow.isTable)
        #expect(SemanticType.tableHeader.isTable)
        #expect(SemanticType.tableCell.isTable)
        #expect(SemanticType.tableHead.isTable)
        #expect(SemanticType.tableBody.isTable)
        #expect(SemanticType.tableFoot.isTable)
    }

    @Test("isTable returns false for non-table types")
    func isTableFalse() {
        #expect(!SemanticType.paragraph.isTable)
        #expect(!SemanticType.list.isTable)
        #expect(!SemanticType.figure.isTable)
    }

    // MARK: - isBlockLevel Tests

    @Test("isBlockLevel returns true for block-level types")
    func isBlockLevelTrue() {
        #expect(SemanticType.document.isBlockLevel)
        #expect(SemanticType.paragraph.isBlockLevel)
        #expect(SemanticType.heading.isBlockLevel)
        #expect(SemanticType.h1.isBlockLevel)
        #expect(SemanticType.blockQuote.isBlockLevel)
        #expect(SemanticType.list.isBlockLevel)
        #expect(SemanticType.table.isBlockLevel)
        #expect(SemanticType.figure.isBlockLevel)
    }

    @Test("isBlockLevel returns false for inline types")
    func isBlockLevelFalse() {
        #expect(!SemanticType.span.isBlockLevel)
        #expect(!SemanticType.link.isBlockLevel)
    }

    // MARK: - isInline Tests

    @Test("isInline returns true for inline types")
    func isInlineTrue() {
        #expect(SemanticType.span.isInline)
        #expect(SemanticType.link.isInline)
        #expect(SemanticType.annotation.isInline)
        #expect(SemanticType.listLabel.isInline)
    }

    @Test("isInline returns false for block types")
    func isInlineFalse() {
        #expect(!SemanticType.paragraph.isInline)
        #expect(!SemanticType.document.isInline)
        #expect(!SemanticType.table.isInline)
    }

    // MARK: - isPresentational Tests

    @Test("isPresentational returns true for presentational types")
    func isPresentationalTrue() {
        #expect(SemanticType.artifact.isPresentational)
        #expect(SemanticType.nonStruct.isPresentational)
        #expect(SemanticType.privateElement.isPresentational)
        #expect(SemanticType.documentHeader.isPresentational)
        #expect(SemanticType.documentFooter.isPresentational)
    }

    @Test("isPresentational returns false for structural types")
    func isPresentationalFalse() {
        #expect(!SemanticType.paragraph.isPresentational)
        #expect(!SemanticType.figure.isPresentational)
        #expect(!SemanticType.table.isPresentational)
    }

    // MARK: - requiresAlternativeText Tests

    @Test("requiresAlternativeText returns true for figure and formula")
    func requiresAltTextTrue() {
        #expect(SemanticType.figure.requiresAlternativeText)
        #expect(SemanticType.formula.requiresAlternativeText)
    }

    @Test("requiresAlternativeText returns false for text elements")
    func requiresAltTextFalse() {
        #expect(!SemanticType.paragraph.requiresAlternativeText)
        #expect(!SemanticType.heading.requiresAlternativeText)
        #expect(!SemanticType.table.requiresAlternativeText)
    }

    // MARK: - isGrouping Tests

    @Test("isGrouping returns true for container types")
    func isGroupingTrue() {
        #expect(SemanticType.document.isGrouping)
        #expect(SemanticType.div.isGrouping)
        #expect(SemanticType.section.isGrouping)
        #expect(SemanticType.list.isGrouping)
        #expect(SemanticType.table.isGrouping)
        #expect(SemanticType.tableRow.isGrouping)
    }

    @Test("isGrouping returns false for content types")
    func isGroupingFalse() {
        #expect(!SemanticType.paragraph.isGrouping)
        #expect(!SemanticType.span.isGrouping)
    }

    // MARK: - Initializer from Structure Type Name Tests

    @Test("init(structureTypeName:) returns correct type for exact match")
    func initFromExactName() {
        #expect(SemanticType(structureTypeName: "Document") == .document)
        #expect(SemanticType(structureTypeName: "P") == .paragraph)
        #expect(SemanticType(structureTypeName: "H1") == .h1)
        #expect(SemanticType(structureTypeName: "Table") == .table)
    }

    @Test("init(structureTypeName:) handles case-insensitive matching")
    func initCaseInsensitive() {
        #expect(SemanticType(structureTypeName: "document") == .document)
        #expect(SemanticType(structureTypeName: "DOCUMENT") == .document)
        #expect(SemanticType(structureTypeName: "table") == .table)
        #expect(SemanticType(structureTypeName: "TABLE") == .table)
    }

    @Test("init(structureTypeName:) returns nil for unknown types")
    func initFromUnknownName() {
        #expect(SemanticType(structureTypeName: "Unknown") == nil)
        #expect(SemanticType(structureTypeName: "Custom") == nil)
        #expect(SemanticType(structureTypeName: "") == nil)
    }

    // MARK: - Codable Tests

    @Test("SemanticType encodes and decodes correctly")
    func codableRoundTrip() throws {
        let original = SemanticType.paragraph
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SemanticType.self, from: data)
        #expect(decoded == original)
    }

    @Test("All semantic types can be encoded and decoded")
    func allTypesCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for semanticType in SemanticType.allCases {
            let data = try encoder.encode(semanticType)
            let decoded = try decoder.decode(SemanticType.self, from: data)
            #expect(decoded == semanticType, "Failed for \(semanticType)")
        }
    }

    // MARK: - Sendable Tests

    @Test("SemanticType is Sendable")
    func isSendable() {
        let type: SemanticType = .paragraph
        let sendable: any Sendable = type
        #expect(sendable is SemanticType)
    }

    // MARK: - CustomStringConvertible Tests

    @Test("description returns raw value")
    func description() {
        #expect(SemanticType.document.description == "Document")
        #expect(SemanticType.paragraph.description == "P")
        #expect(SemanticType.h1.description == "H1")
    }

    // MARK: - Comparable Tests

    @Test("SemanticType is Comparable")
    func comparable() {
        // Comparison is based on raw value alphabetically
        #expect(SemanticType.document < SemanticType.table)
        #expect(SemanticType.h1 < SemanticType.h2)
    }

    // MARK: - Ruby and Warichu Tests

    @Test("Ruby annotation types have correct raw values")
    func rubyTypes() {
        #expect(SemanticType.ruby.rawValue == "Ruby")
        #expect(SemanticType.rubyBase.rawValue == "RB")
        #expect(SemanticType.rubyText.rawValue == "RT")
        #expect(SemanticType.rubyPunctuation.rawValue == "RP")
    }

    @Test("Warichu types have correct raw values")
    func warichuTypes() {
        #expect(SemanticType.warichu.rawValue == "Warichu")
        #expect(SemanticType.warichuText.rawValue == "WT")
        #expect(SemanticType.warichuPunctuation.rawValue == "WP")
    }

    // MARK: - Navigation Types Tests

    @Test("Navigation types have correct raw values")
    func navigationTypes() {
        #expect(SemanticType.toc.rawValue == "TOC")
        #expect(SemanticType.tocItem.rawValue == "TOCI")
        #expect(SemanticType.bibliography.rawValue == "BibEntry")
    }

    // MARK: - Special Content Types Tests

    @Test("Special content types have correct raw values")
    func specialContentTypes() {
        #expect(SemanticType.caption.rawValue == "Caption")
        #expect(SemanticType.formula.rawValue == "Formula")
        #expect(SemanticType.form.rawValue == "Form")
        #expect(SemanticType.code.rawValue == "Code")
        #expect(SemanticType.note.rawValue == "Note")
        #expect(SemanticType.quote.rawValue == "Quote")
    }
}

import Foundation

/// All PDF/UA semantic structure types supported by WCAG accessibility analysis.
///
/// This enum represents the complete set of standard structure elements defined
/// in PDF 1.7 and ISO 14289-1 (PDF/UA-1) that are relevant for accessibility
/// validation. Each case corresponds to a specific role in the document's
/// logical structure tree.
///
/// `SemanticType` is the primary mechanism for type discrimination in the
/// consolidated semantic node system, replacing the Java class hierarchy
/// with a single enum. The raw values match the standard PDF structure
/// type names (e.g., "P" for paragraph, "H1" for heading level 1).
///
/// ## Categories
///
/// - **Document level**: `document`, `part`, `article`, `section`, `div`
/// - **Block structure**: `paragraph`, `span`, `blockQuote`, `index`
/// - **Headings**: `heading`, `h1`-`h6`
/// - **Lists**: `list`, `listItem`, `listLabel`, `listBody`
/// - **Tables**: `table`, `tableRow`, `tableHeader`, `tableCell`, etc.
/// - **Special content**: `figure`, `caption`, `formula`, `form`
/// - **Links and annotations**: `link`, `annotation`, `reference`
/// - **Navigation**: `toc`, `tocItem`, `bibliography`, `bibEntry`
/// - **Ruby**: `ruby`, `rubyBase`, `rubyText`, `rubyPunctuation`
/// - **Warichu**: `warichu`, `warichuText`, `warichuPunctuation`
/// - **Presentational**: `artifact`, `nonStruct`, `private`
///
/// - Note: Ported from veraPDF-wcag-algs `SemanticType` Java enum.
///   This Swift enum consolidates 20+ Java semantic node subclasses
///   into a single type-safe discriminator.
public enum SemanticType: String, CaseIterable, Sendable, Codable {

    // MARK: - Document Level

    /// The root element of the structure tree, representing the entire document.
    case document = "Document"

    /// A large division of a document, such as a chapter or major section.
    case part = "Part"

    /// A self-contained article or story.
    case article = "Art"

    /// A generic division or section of content.
    case section = "Sect"

    /// A generic container element with no specific semantic meaning.
    case div = "Div"

    // MARK: - Block Structure

    /// A paragraph of text content.
    case paragraph = "P"

    /// An inline span of text with distinct styling or semantics.
    case span = "Span"

    /// A block quotation.
    case blockQuote = "BlockQuote"

    /// An index section.
    case index = "Index"

    // MARK: - Headings

    /// A generic heading (level unspecified).
    case heading = "H"

    /// Heading level 1 (highest level).
    case h1 = "H1"

    /// Heading level 2.
    case h2 = "H2"

    /// Heading level 3.
    case h3 = "H3"

    /// Heading level 4.
    case h4 = "H4"

    /// Heading level 5.
    case h5 = "H5"

    /// Heading level 6 (lowest level).
    case h6 = "H6"

    // MARK: - Lists

    /// A list container.
    case list = "L"

    /// An item in a list.
    case listItem = "LI"

    /// The label or marker of a list item (e.g., bullet, number).
    case listLabel = "Lbl"

    /// The body content of a list item.
    case listBody = "LBody"

    // MARK: - Tables

    /// A table container.
    case table = "Table"

    /// A row in a table.
    case tableRow = "TR"

    /// A header cell in a table.
    case tableHeader = "TH"

    /// A data cell in a table.
    case tableCell = "TD"

    /// A table header row group.
    case tableHead = "THead"

    /// A table body row group.
    case tableBody = "TBody"

    /// A table footer row group.
    case tableFoot = "TFoot"

    // MARK: - Special Content

    /// A figure or illustration.
    case figure = "Figure"

    /// A caption for a figure, table, or other content.
    case caption = "Caption"

    /// A mathematical formula.
    case formula = "Formula"

    /// An interactive form element.
    case form = "Form"

    /// A preformatted code block.
    case code = "Code"

    /// A document title.
    case title = "Title"

    // MARK: - Links and Annotations

    /// A hyperlink.
    case link = "Link"

    /// An annotation.
    case annotation = "Annot"

    /// A reference to content elsewhere in the document.
    case reference = "Reference"

    /// A footnote or endnote.
    case note = "Note"

    // MARK: - Navigation

    /// A table of contents.
    case toc = "TOC"

    /// An entry in a table of contents.
    case tocItem = "TOCI"

    /// A bibliography section.
    case bibliography = "BibEntry"

    /// A quote (inline quotation).
    case quote = "Quote"

    // MARK: - Ruby Annotations (for East Asian text)

    /// A ruby annotation container (for pronunciation guides).
    case ruby = "Ruby"

    /// The base text being annotated in a ruby structure.
    case rubyBase = "RB"

    /// The annotation text in a ruby structure.
    case rubyText = "RT"

    /// Ruby punctuation.
    case rubyPunctuation = "RP"

    // MARK: - Warichu (for East Asian inline annotations)

    /// A warichu inline annotation container.
    case warichu = "Warichu"

    /// The text portion of a warichu annotation.
    case warichuText = "WT"

    /// Punctuation in a warichu annotation.
    case warichuPunctuation = "WP"

    // MARK: - Presentational Elements

    /// Content that is purely presentational (pagination artifacts, decorations).
    case artifact = "Artifact"

    /// Non-structural element (presentational grouping).
    case nonStruct = "NonStruct"

    /// A private structure type (application-specific).
    case privateElement = "Private"

    // MARK: - Document Headers and Footers

    /// A document header region (running header).
    case documentHeader = "Header"

    /// A document footer region (running footer).
    case documentFooter = "Footer"

    // MARK: - Computed Properties

    /// Whether this type represents a heading element (H, H1-H6).
    public var isHeading: Bool {
        switch self {
        case .heading, .h1, .h2, .h3, .h4, .h5, .h6:
            return true
        default:
            return false
        }
    }

    /// The heading level, if this is a specific heading (H1-H6).
    ///
    /// Returns `nil` for non-heading types and for the generic `heading` type.
    public var headingLevel: Int? {
        switch self {
        case .h1: return 1
        case .h2: return 2
        case .h3: return 3
        case .h4: return 4
        case .h5: return 5
        case .h6: return 6
        default: return nil
        }
    }

    /// Whether this type represents a list element (L, LI, Lbl, LBody).
    public var isList: Bool {
        switch self {
        case .list, .listItem, .listLabel, .listBody:
            return true
        default:
            return false
        }
    }

    /// Whether this type represents a table element.
    public var isTable: Bool {
        switch self {
        case .table, .tableRow, .tableHeader, .tableCell,
             .tableHead, .tableBody, .tableFoot:
            return true
        default:
            return false
        }
    }

    /// Whether this type is a block-level element.
    public var isBlockLevel: Bool {
        switch self {
        case .document, .part, .article, .section, .div,
             .paragraph, .blockQuote, .index,
             .heading, .h1, .h2, .h3, .h4, .h5, .h6,
             .list, .listItem, .listBody,
             .table, .tableRow, .tableHead, .tableBody, .tableFoot,
             .figure, .formula, .form, .code,
             .toc, .tocItem, .bibliography:
            return true
        default:
            return false
        }
    }

    /// Whether this type is an inline element.
    public var isInline: Bool {
        switch self {
        case .span, .link, .annotation, .reference, .note, .quote,
             .listLabel, .tableHeader, .tableCell,
             .ruby, .rubyBase, .rubyText, .rubyPunctuation,
             .warichu, .warichuText, .warichuPunctuation:
            return true
        default:
            return false
        }
    }

    /// Whether this type represents content that is typically presentational
    /// and not part of the document's logical structure.
    public var isPresentational: Bool {
        switch self {
        case .artifact, .nonStruct, .privateElement,
             .documentHeader, .documentFooter:
            return true
        default:
            return false
        }
    }

    /// Whether this type requires alternative text per WCAG requirements.
    ///
    /// Figures and formulas are non-text content that typically need
    /// alternative text (Alt or ActualText attribute).
    public var requiresAlternativeText: Bool {
        switch self {
        case .figure, .formula:
            return true
        default:
            return false
        }
    }

    /// Whether this is a grouping/container element with no direct content.
    public var isGrouping: Bool {
        switch self {
        case .document, .part, .article, .section, .div,
             .list, .listItem, .table, .tableRow,
             .tableHead, .tableBody, .tableFoot,
             .toc, .ruby, .warichu, .form:
            return true
        default:
            return false
        }
    }

    /// Creates a SemanticType from a PDF structure type name.
    ///
    /// This initializer performs case-insensitive matching and handles
    /// common variations in structure type naming.
    ///
    /// - Parameter structureTypeName: The structure type name from the PDF.
    /// - Returns: The matching SemanticType, or `nil` if not recognized.
    public init?(structureTypeName: String) {
        // First try exact match via raw value
        if let type = SemanticType(rawValue: structureTypeName) {
            self = type
            return
        }

        // Try case-insensitive match
        let lowercased = structureTypeName.lowercased()
        for type in SemanticType.allCases {
            if type.rawValue.lowercased() == lowercased {
                self = type
                return
            }
        }

        // Handle common aliases
        switch lowercased {
        case "header":
            self = .documentHeader
        case "footer":
            self = .documentFooter
        case "nonstruct":
            self = .nonStruct
        default:
            return nil
        }
    }
}

// MARK: - CustomStringConvertible

extension SemanticType: CustomStringConvertible {
    /// A human-readable description of the semantic type.
    public var description: String {
        rawValue
    }
}

// MARK: - Comparable

extension SemanticType: Comparable {
    /// Compares semantic types for ordering.
    ///
    /// This is primarily useful for sorting headings by level.
    public static func < (lhs: SemanticType, rhs: SemanticType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Error codes that can be associated with semantic nodes during validation.
///
/// These codes indicate specific accessibility issues detected during
/// WCAG validation of the document structure.
///
/// - Note: Error codes are organized by category:
///   - 1000-1099: General structure errors
///   - 1100-1199: Table-specific errors
///   - 1200-1299: List-specific errors
///   - 1300-1399: Heading-specific errors
///   - 1400-1499: Figure-specific errors
public enum SemanticErrorCode: Int, Sendable, Codable, CaseIterable {

    // MARK: - General Structure Errors (1000-1099)

    /// Missing required alternative text.
    case missingAltText = 1000

    /// Empty structure element with no content.
    case emptyElement = 1001

    /// Invalid nesting of structure elements.
    case invalidNesting = 1002

    /// Missing required child element.
    case missingRequiredChild = 1003

    /// Unexpected child element type.
    case unexpectedChild = 1004

    /// Invalid attribute value.
    case invalidAttribute = 1005

    /// Missing required attribute.
    case missingAttribute = 1006

    /// Duplicate ID in structure tree.
    case duplicateId = 1007

    // MARK: - Table Errors (1100-1199)

    /// Table cell positioned below the next row.
    case tableCellBelowNextRow = 1100

    /// Table cell positioned above the previous row.
    case tableCellAbovePreviousRow = 1101

    /// Table cell positioned right of the next column.
    case tableCellRightOfNextColumn = 1102

    /// Table cell positioned left of the previous column.
    case tableCellLeftOfPreviousColumn = 1103

    /// Visual and semantic row counts do not match.
    case tableRowCountMismatch = 1104

    /// Visual and semantic column counts do not match.
    case tableColumnCountMismatch = 1105

    /// Row span does not match visual layout.
    case tableRowSpanMismatch = 1106

    /// Column span does not match visual layout.
    case tableColSpanMismatch = 1107

    /// Table missing header cells.
    case tableMissingHeaders = 1108

    /// Table has irregular structure (gaps or overlaps).
    case tableIrregularStructure = 1109

    // MARK: - List Errors (1200-1299)

    /// List item missing label.
    case listItemMissingLabel = 1200

    /// List item missing body.
    case listItemMissingBody = 1201

    /// Inconsistent list label pattern.
    case listInconsistentLabels = 1202

    /// List labels not in expected sequence.
    case listLabelsOutOfSequence = 1203

    /// Nested list level too deep.
    case listNestingTooDeep = 1204

    // MARK: - Heading Errors (1300-1399)

    /// Heading level skipped (e.g., H1 to H3).
    case headingLevelSkipped = 1300

    /// Multiple H1 headings in document.
    case multipleH1Headings = 1301

    /// Empty heading element.
    case emptyHeading = 1302

    /// Heading hierarchy not logical.
    case headingHierarchyInvalid = 1303

    // MARK: - Figure Errors (1400-1499)

    /// Figure missing alternative text (Alt or ActualText).
    case figureMissingAltText = 1400

    /// Figure caption not properly associated.
    case figureCaptionNotAssociated = 1401

    /// Decorative figure not marked as artifact.
    case decorativeFigureNotArtifact = 1402

    /// Figure has insufficient contrast.
    case figureInsufficientContrast = 1403
}

// MARK: - Attributes Dictionary

/// A type alias for a dictionary of semantic node attributes.
///
/// Attributes are key-value pairs from the PDF structure element's
/// attribute dictionary, such as `Alt`, `ActualText`, `Lang`, etc.
public typealias AttributesDictionary = [String: AttributeValue]

/// A value that can be stored in a semantic node's attributes dictionary.
///
/// This enum supports the common value types found in PDF structure
/// element attributes.
public enum AttributeValue: Sendable, Codable, Hashable {
    /// A string value.
    case string(String)

    /// A boolean value.
    case bool(Bool)

    /// An integer value.
    case int(Int)

    /// A floating-point value.
    case double(Double)

    /// An array of attribute values.
    case array([AttributeValue])

    /// A null/missing value.
    case null

    /// Convenience accessor for string values.
    public var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    /// Convenience accessor for boolean values.
    public var boolValue: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }

    /// Convenience accessor for integer values.
    public var intValue: Int? {
        if case .int(let value) = self {
            return value
        }
        return nil
    }

    /// Convenience accessor for double values.
    public var doubleValue: Double? {
        if case .double(let value) = self {
            return value
        }
        return nil
    }

    /// Convenience accessor for array values.
    public var arrayValue: [AttributeValue]? {
        if case .array(let value) = self {
            return value
        }
        return nil
    }
}

// MARK: - SemanticNode Protocol

/// Protocol for all semantic nodes in the PDF structure tree.
///
/// `SemanticNode` is the base protocol for representing elements in
/// the logical structure tree of a PDF document. It provides a
/// unified interface for navigating, querying, and validating the
/// accessibility structure.
///
/// ## Consolidation
///
/// This protocol, along with four concrete struct implementations
/// (`ContentNode`, `FigureNode`, `TableNode`, `ListNode`), replaces
/// the 20+ Java semantic node subclasses in veraPDF-wcag-algs.
/// The `SemanticType` enum carries the type identity that was
/// previously encoded in the class hierarchy.
///
/// ## Thread Safety
///
/// All conforming types must be `Sendable`. Parent references should
/// use weak or unowned semantics to avoid retain cycles, but since
/// we use structs, parent tracking is handled differently (see
/// individual node implementations).
///
/// - Note: Ported from veraPDF-wcag-algs `SemanticNode` Java class hierarchy.
public protocol SemanticNode: Sendable, Identifiable where ID == UUID {

    /// The unique identifier for this node.
    var id: UUID { get }

    /// The semantic type of this node (e.g., paragraph, heading, figure).
    var type: SemanticType { get }

    /// The bounding box of this node, if it has a spatial location.
    ///
    /// Some nodes (like the document root or grouping elements) may
    /// not have a meaningful bounding box.
    var boundingBox: BoundingBox? { get }

    /// The child nodes of this node, in document order.
    var children: [any SemanticNode] { get }

    /// The attributes dictionary from the PDF structure element.
    var attributes: AttributesDictionary { get }

    /// The depth of this node in the structure tree (root = 0).
    var depth: Int { get }

    /// Error codes detected during validation of this node.
    var errorCodes: Set<SemanticErrorCode> { get set }
}

// MARK: - Default Implementations

extension SemanticNode {

    /// The page index of this node, if it has a bounding box.
    public var pageIndex: Int? {
        boundingBox?.pageIndex
    }

    /// Whether this node has any children.
    public var hasChildren: Bool {
        !children.isEmpty
    }

    /// The number of direct children of this node.
    public var childCount: Int {
        children.count
    }

    /// Whether this node has any validation errors.
    public var hasErrors: Bool {
        !errorCodes.isEmpty
    }

    /// The alternative text (Alt attribute) for this node, if present.
    public var altText: String? {
        attributes["Alt"]?.stringValue
    }

    /// The actual text (ActualText attribute) for this node, if present.
    public var actualText: String? {
        attributes["ActualText"]?.stringValue
    }

    /// The language (Lang attribute) for this node, if present.
    public var language: String? {
        attributes["Lang"]?.stringValue
    }

    /// The title (Title attribute) for this node, if present.
    public var title: String? {
        attributes["Title"]?.stringValue
    }

    /// Whether this node has any form of text alternative (Alt or ActualText).
    public var hasTextAlternative: Bool {
        (altText != nil && altText?.isEmpty == false)
            || (actualText != nil && actualText?.isEmpty == false)
    }

    /// The best available text description for this node.
    ///
    /// Prefers `altText` over `actualText` over `title`.
    public var textDescription: String? {
        if let alt = altText, !alt.isEmpty {
            return alt
        }
        if let actual = actualText, !actual.isEmpty {
            return actual
        }
        if let nodeTitle = title, !nodeTitle.isEmpty {
            return nodeTitle
        }
        return nil
    }

    /// All descendant nodes of this node (including self), in DFS order.
    public var allDescendants: [any SemanticNode] {
        var result: [any SemanticNode] = [self]
        for child in children {
            result.append(contentsOf: child.allDescendants)
        }
        return result
    }

    /// All descendant nodes of a specific type.
    ///
    /// - Parameter nodeType: The semantic type to filter by.
    /// - Returns: All descendants matching the specified type.
    public func descendants(ofType nodeType: SemanticType) -> [any SemanticNode] {
        allDescendants.filter { $0.type == nodeType }
    }

    /// Finds the first descendant matching a predicate.
    ///
    /// - Parameter predicate: The condition to match.
    /// - Returns: The first matching descendant, or `nil`.
    public func firstDescendant(
        where predicate: (any SemanticNode) -> Bool
    ) -> (any SemanticNode)? {
        if predicate(self) {
            return self
        }
        for child in children {
            if let found = child.firstDescendant(where: predicate) {
                return found
            }
        }
        return nil
    }

    /// Counts all descendant nodes (including self).
    public var descendantCount: Int {
        1 + children.reduce(0) { $0 + $1.descendantCount }
    }

    /// The maximum depth in the subtree rooted at this node.
    public var maxDepth: Int {
        if children.isEmpty {
            return depth
        }
        return children.map(\.maxDepth).max() ?? depth
    }

    /// Adds an error code to this node.
    ///
    /// - Parameter code: The error code to add.
    public mutating func addError(_ code: SemanticErrorCode) {
        errorCodes.insert(code)
    }

    /// Removes an error code from this node.
    ///
    /// - Parameter code: The error code to remove.
    public mutating func removeError(_ code: SemanticErrorCode) {
        errorCodes.remove(code)
    }

    /// Clears all error codes from this node.
    public mutating func clearErrors() {
        errorCodes.removeAll()
    }
}

// MARK: - Hashable Conformance Helper

/// Extension to provide default Hashable behavior for SemanticNode conformers.
extension SemanticNode where Self: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Equatable Conformance Helper

/// Extension to provide default Equatable behavior for SemanticNode conformers.
extension SemanticNode where Self: Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

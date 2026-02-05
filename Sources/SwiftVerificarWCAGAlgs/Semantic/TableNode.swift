import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// A semantic node representing a table in the document structure.
///
/// `TableNode` is specialized for tabular data, providing properties and
/// methods for table structure validation. It tracks the semantic table
/// structure (rows, header/body/footer groups) and optionally a visual
/// border structure detected from line graphics.
///
/// ## WCAG Requirements
///
/// Tables have specific accessibility requirements:
/// - Header cells must be properly identified (TH elements)
/// - Data cells must be properly associated with headers
/// - Table structure must be regular (no gaps or overlapping cells)
/// - Complex tables may need additional `headers` attributes
///
/// ## Structure
///
/// A table typically contains:
/// - `THead` (optional): Header row group containing header cells
/// - `TBody`: Body row group(s) containing data rows
/// - `TFoot` (optional): Footer row group
/// - `TR`: Table rows within groups
/// - `TH` / `TD`: Header and data cells within rows
///
/// ## Visual Comparison
///
/// The `visualBorder` property stores a detected visual table structure
/// from line graphics. This allows comparison between the semantic and
/// visual structures to detect mismatches.
///
/// - Note: Ported from veraPDF-wcag-algs `SemanticTable` Java class.
public struct TableNode: SemanticNode, Sendable, Hashable {

    // MARK: - SemanticNode Conformance

    /// The unique identifier for this node.
    public let id: UUID

    /// The semantic type is always `.table` for TableNode.
    public var type: SemanticType { .table }

    /// The bounding box of this table.
    public let boundingBox: BoundingBox?

    /// The child nodes (THead, TBody, TFoot, or directly TR elements).
    public let children: [any SemanticNode]

    /// The attributes dictionary from the PDF structure element.
    public let attributes: AttributesDictionary

    /// The depth of this node in the structure tree.
    public let depth: Int

    /// Error codes detected during validation.
    public var errorCodes: Set<SemanticErrorCode>

    // MARK: - Table-Specific Properties

    /// The summary text for this table, if provided.
    ///
    /// A summary provides additional context about the table's purpose
    /// and structure, especially useful for complex tables.
    public let summary: String?

    /// Visual border structure detected from line graphics.
    ///
    /// This is set during the table border detection phase and allows
    /// comparison between semantic and visual table structures.
    public let visualBorderXCoordinates: [CGFloat]

    /// Y coordinates of visual border lines.
    public let visualBorderYCoordinates: [CGFloat]

    // MARK: - Initialization

    /// Creates a new table node with all properties.
    ///
    /// - Parameters:
    ///   - id: The unique identifier (defaults to a new UUID).
    ///   - boundingBox: The spatial location, if any.
    ///   - children: The child nodes (row groups or rows).
    ///   - attributes: The PDF structure element attributes.
    ///   - depth: The depth in the structure tree.
    ///   - errorCodes: Initial error codes (defaults to empty).
    ///   - summary: The table summary text.
    ///   - visualBorderXCoordinates: X coordinates of visual borders.
    ///   - visualBorderYCoordinates: Y coordinates of visual borders.
    public init(
        id: UUID = UUID(),
        boundingBox: BoundingBox? = nil,
        children: [any SemanticNode] = [],
        attributes: AttributesDictionary = [:],
        depth: Int = 1,
        errorCodes: Set<SemanticErrorCode> = [],
        summary: String? = nil,
        visualBorderXCoordinates: [CGFloat] = [],
        visualBorderYCoordinates: [CGFloat] = []
    ) {
        self.id = id
        self.boundingBox = boundingBox
        self.children = children
        self.attributes = attributes
        self.depth = depth
        self.errorCodes = errorCodes
        self.summary = summary ?? attributes["Summary"]?.stringValue
        self.visualBorderXCoordinates = visualBorderXCoordinates
        self.visualBorderYCoordinates = visualBorderYCoordinates
    }

    /// Creates a simple table node with minimal properties.
    ///
    /// - Parameter depth: The depth in the structure tree.
    public init(depth: Int = 1) {
        self.init(
            id: UUID(),
            boundingBox: nil,
            children: [],
            attributes: [:],
            depth: depth
        )
    }

    // MARK: - Row Group Accessors

    /// The table header row group (THead), if present.
    public var tableHead: ContentNode? {
        for child in children {
            if let content = child as? ContentNode, content.type == .tableHead {
                return content
            }
        }
        return nil
    }

    /// The table body row groups (TBody).
    ///
    /// A table may have multiple TBody elements.
    public var tableBodies: [ContentNode] {
        children.compactMap { child in
            guard let content = child as? ContentNode,
                  content.type == .tableBody else {
                return nil
            }
            return content
        }
    }

    /// The table footer row group (TFoot), if present.
    public var tableFoot: ContentNode? {
        for child in children {
            if let content = child as? ContentNode, content.type == .tableFoot {
                return content
            }
        }
        return nil
    }

    /// Whether this table has explicit row groups (THead/TBody/TFoot).
    public var hasExplicitRowGroups: Bool {
        tableHead != nil || !tableBodies.isEmpty || tableFoot != nil
    }

    // MARK: - Row Accessors

    /// All table rows (TR elements), regardless of which group they're in.
    ///
    /// Returns rows from THead, then TBody groups, then TFoot, then any
    /// direct TR children.
    public var allRows: [ContentNode] {
        var rows: [ContentNode] = []

        // Rows from THead
        if let head = tableHead {
            rows.append(contentsOf: head.children.compactMap { $0 as? ContentNode }
                .filter { $0.type == .tableRow })
        }

        // Rows from TBody groups
        for body in tableBodies {
            rows.append(contentsOf: body.children.compactMap { $0 as? ContentNode }
                .filter { $0.type == .tableRow })
        }

        // Rows from TFoot
        if let foot = tableFoot {
            rows.append(contentsOf: foot.children.compactMap { $0 as? ContentNode }
                .filter { $0.type == .tableRow })
        }

        // Direct TR children (tables without explicit groups)
        rows.append(contentsOf: children.compactMap { $0 as? ContentNode }
            .filter { $0.type == .tableRow })

        return rows
    }

    /// The number of rows in this table.
    public var rowCount: Int {
        allRows.count
    }

    /// The header rows (first rows from THead, or rows containing only TH cells).
    public var headerRows: [ContentNode] {
        if let head = tableHead {
            return head.children.compactMap { $0 as? ContentNode }
                .filter { $0.type == .tableRow }
        }

        // Fallback: rows with all header cells
        return allRows.filter { row in
            let cells = cellsInRow(row)
            return !cells.isEmpty && cells.allSatisfy { $0.type == .tableHeader }
        }
    }

    // MARK: - Cell Accessors

    /// All cells in a given row.
    ///
    /// - Parameter row: The table row node.
    /// - Returns: Array of cells (TH and TD elements).
    public func cellsInRow(_ row: ContentNode) -> [ContentNode] {
        guard row.type == .tableRow else { return [] }
        return row.children.compactMap { $0 as? ContentNode }
            .filter { $0.type == .tableHeader || $0.type == .tableCell }
    }

    /// All cells in this table, in row order.
    public var allCells: [ContentNode] {
        allRows.flatMap { cellsInRow($0) }
    }

    /// All header cells (TH elements) in this table.
    public var headerCells: [ContentNode] {
        allCells.filter { $0.type == .tableHeader }
    }

    /// All data cells (TD elements) in this table.
    public var dataCells: [ContentNode] {
        allCells.filter { $0.type == .tableCell }
    }

    /// The total number of cells in this table.
    public var cellCount: Int {
        allCells.count
    }

    // MARK: - Structure Analysis

    /// Whether this table has any header cells.
    public var hasHeaders: Bool {
        !headerCells.isEmpty
    }

    /// The maximum number of cells in any row (approximate column count).
    ///
    /// Note: This does not account for column spans.
    public var maxCellsPerRow: Int {
        allRows.map { cellsInRow($0).count }.max() ?? 0
    }

    /// Whether all rows have the same number of cells.
    ///
    /// Note: This simple check does not account for row/column spans.
    public var hasConsistentColumnCount: Bool {
        let counts = allRows.map { cellsInRow($0).count }
        guard let first = counts.first else { return true }
        return counts.allSatisfy { $0 == first }
    }

    /// Whether visual border data is available.
    public var hasVisualBorder: Bool {
        !visualBorderXCoordinates.isEmpty && !visualBorderYCoordinates.isEmpty
    }

    /// The number of visual columns based on border X coordinates.
    public var visualColumnCount: Int {
        max(0, visualBorderXCoordinates.count - 1)
    }

    /// The number of visual rows based on border Y coordinates.
    public var visualRowCount: Int {
        max(0, visualBorderYCoordinates.count - 1)
    }

    // MARK: - Validation

    /// Performs basic structural validation on this table.
    ///
    /// Checks for:
    /// - Missing header cells
    /// - Irregular structure (inconsistent column counts)
    /// - Visual/semantic mismatch
    ///
    /// - Returns: A set of error codes for any issues found.
    public func validateStructure() -> Set<SemanticErrorCode> {
        var errors = Set<SemanticErrorCode>()

        // Check for missing headers
        if !hasHeaders && rowCount > 1 {
            errors.insert(.tableMissingHeaders)
        }

        // Check for irregular structure
        if !hasConsistentColumnCount {
            errors.insert(.tableIrregularStructure)
        }

        // Visual/semantic comparison
        if hasVisualBorder {
            if visualRowCount != rowCount {
                errors.insert(.tableRowCountMismatch)
            }
            if visualColumnCount != maxCellsPerRow && maxCellsPerRow > 0 {
                errors.insert(.tableColumnCountMismatch)
            }
        }

        return errors
    }

    /// Creates a new table node with updated visual border data.
    ///
    /// - Parameters:
    ///   - xCoordinates: The X coordinates of column borders.
    ///   - yCoordinates: The Y coordinates of row borders.
    /// - Returns: A new table node with the visual border set.
    public func withVisualBorder(
        xCoordinates: [CGFloat],
        yCoordinates: [CGFloat]
    ) -> TableNode {
        TableNode(
            id: id,
            boundingBox: boundingBox,
            children: children,
            attributes: attributes,
            depth: depth,
            errorCodes: errorCodes,
            summary: summary,
            visualBorderXCoordinates: xCoordinates,
            visualBorderYCoordinates: yCoordinates
        )
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Equatable

    public static func == (lhs: TableNode, rhs: TableNode) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable

extension TableNode: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case boundingBox
        case attributes
        case depth
        case errorCodes
        case summary
        case visualBorderXCoordinates
        case visualBorderYCoordinates
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.boundingBox = try container.decodeIfPresent(BoundingBox.self, forKey: .boundingBox)
        self.attributes = try container.decode(AttributesDictionary.self, forKey: .attributes)
        self.depth = try container.decode(Int.self, forKey: .depth)
        self.errorCodes = try container.decode(Set<SemanticErrorCode>.self, forKey: .errorCodes)
        self.summary = try container.decodeIfPresent(String.self, forKey: .summary)
        self.visualBorderXCoordinates = try container.decode([CGFloat].self, forKey: .visualBorderXCoordinates)
        self.visualBorderYCoordinates = try container.decode([CGFloat].self, forKey: .visualBorderYCoordinates)
        // Children are not encoded
        self.children = []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(boundingBox, forKey: .boundingBox)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(depth, forKey: .depth)
        try container.encode(errorCodes, forKey: .errorCodes)
        try container.encodeIfPresent(summary, forKey: .summary)
        try container.encode(visualBorderXCoordinates, forKey: .visualBorderXCoordinates)
        try container.encode(visualBorderYCoordinates, forKey: .visualBorderYCoordinates)
    }
}

// MARK: - CustomStringConvertible

extension TableNode: CustomStringConvertible {

    public var description: String {
        let indent = String(repeating: "  ", count: depth)
        let structure = "\(rowCount) rows, \(maxCellsPerRow) cols"
        let headers = hasHeaders ? " [has headers]" : ""
        return "\(indent)<Table>\(structure)\(headers)</Table>"
    }
}

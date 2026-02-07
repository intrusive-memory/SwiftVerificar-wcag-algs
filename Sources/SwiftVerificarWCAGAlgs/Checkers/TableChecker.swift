import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Validates table accessibility according to PDF/UA requirements.
///
/// This checker validates that tables meet PDF/UA table requirements:
/// - Tables must have header cells (TH elements)
/// - Table structure must be regular (no gaps or overlapping cells)
/// - Header cells must be properly associated with data cells
/// - Row and column spans must be valid
/// - Visual and semantic table structures should match
///
/// ## PDF/UA Requirements
///
/// - **7.5**: Tables must have headers
/// - **7.5.1**: Table structure must be regular
/// - **7.5.2**: Table cells must be properly associated with headers
///
/// ## Table Structure
///
/// A proper table structure includes:
/// ```
/// Table
///   ├── THead (optional)
///   │   └── TR (table row)
///   │       ├── TH (header cell)
///   │       └── TH
///   ├── TBody
///   │   └── TR
///   │       ├── TD (data cell)
///   │       └── TD
///   └── TFoot (optional)
///       └── TR
///           ├── TD
///           └── TD
/// ```
///
/// ## Usage
///
/// ```swift
/// let checker = TableChecker()
/// let result = checker.check(tableNode)
/// if !result.passed {
///     for violation in result.violations {
///         print(violation.description)
///     }
/// }
/// ```
///
/// - Note: Ported from veraPDF-wcag-algs table validation logic.
public struct TableChecker: PDFUAChecker {

    /// The PDF/UA requirement validated by this checker.
    public let requirement: PDFUARequirement = .tablesMustHaveHeaders

    /// Whether to require at least one header cell.
    public let requireHeaders: Bool

    /// Whether to validate table regularity (no gaps/overlaps).
    public let validateRegularity: Bool

    /// Whether to validate visual/semantic structure match.
    public let validateVisualMatch: Bool

    /// Tolerance for visual coordinate matching (in points).
    public let visualMatchTolerance: CGFloat

    /// Creates a new table checker.
    ///
    /// - Parameters:
    ///   - requireHeaders: Require at least one header cell (default: true).
    ///   - validateRegularity: Validate regular structure (default: true).
    ///   - validateVisualMatch: Validate visual/semantic match (default: true).
    ///   - visualMatchTolerance: Tolerance for coordinate matching (default: 2.0).
    public init(
        requireHeaders: Bool = true,
        validateRegularity: Bool = true,
        validateVisualMatch: Bool = true,
        visualMatchTolerance: CGFloat = 2.0
    ) {
        self.requireHeaders = requireHeaders
        self.validateRegularity = validateRegularity
        self.validateVisualMatch = validateVisualMatch
        self.visualMatchTolerance = visualMatchTolerance
    }

    /// Checks if a semantic node represents a valid accessible table.
    ///
    /// - Parameter node: The semantic node to check (should be a TableNode).
    /// - Returns: A check result indicating table accessibility compliance.
    public func check(_ node: any SemanticNode) -> PDFUACheckResult {
        var violations: [PDFUAViolation] = []

        // Only check table nodes
        guard node.type == .table else {
            // Not a table, skip
            return .passing(
                requirement: requirement,
                context: "Node is not a table"
            )
        }

        // Cast to TableNode for table-specific properties
        guard let tableNode = node as? TableNode else {
            // Can't validate without TableNode
            return .passing(
                requirement: requirement,
                context: "Node is not a TableNode instance"
            )
        }

        // Check 1: Table must have headers
        if requireHeaders {
            violations.append(contentsOf: checkTableHeaders(tableNode))
        }

        // Check 2: Validate table regularity
        if validateRegularity {
            violations.append(contentsOf: checkTableRegularity(tableNode))
        }

        // Check 3: Validate visual/semantic match
        if validateVisualMatch && tableNode.hasVisualBorder {
            violations.append(contentsOf: checkVisualMatch(tableNode))
        }

        // Check 4: Validate cell structure
        violations.append(contentsOf: checkCellStructure(tableNode))

        // Check 5: Check for error codes from TableNode validation
        violations.append(contentsOf: checkErrorCodes(tableNode))

        // Return result
        // Only fail if there are error-severity violations; warnings and info
        // are informational and should not cause the check to fail.
        let hasErrorViolations = violations.contains { $0.severity == .error }
        if hasErrorViolations {
            return .failing(
                requirement: requirement,
                violations: violations,
                context: "Found \(violations.count) table violation(s)"
            )
        } else if violations.isEmpty {
            return .passing(
                requirement: requirement,
                context: "Table is properly structured with \(tableNode.rowCount) rows"
            )
        } else {
            // Only warnings/info -- still passing but include violations
            return PDFUACheckResult(
                requirement: requirement,
                passed: true,
                violations: violations,
                context: "Table is properly structured with \(tableNode.rowCount) rows (\(violations.count) informational note(s))"
            )
        }
    }

    // MARK: - Private Validation Methods

    /// Checks if table has proper headers.
    private func checkTableHeaders(_ table: TableNode) -> [PDFUAViolation] {
        var violations: [PDFUAViolation] = []

        // Table must have at least one header cell
        if !table.hasHeaders {
            violations.append(
                PDFUAViolation(
                    nodeId: table.id,
                    nodeType: .table,
                    description: "Table has no header cells (TH elements) - all tables must have headers",
                    severity: .error,
                    location: table.boundingBox
                )
            )
        }

        // Tables with more than 1 row should have headers
        if table.rowCount > 1 && table.headerCells.isEmpty {
            violations.append(
                PDFUAViolation(
                    nodeId: table.id,
                    nodeType: .table,
                    description: "Table with \(table.rowCount) rows has no header cells",
                    severity: .error,
                    location: table.boundingBox
                )
            )
        }

        // Check if headers are in a THead element (best practice)
        if table.hasHeaders && table.tableHead == nil {
            violations.append(
                PDFUAViolation(
                    nodeId: table.id,
                    nodeType: .table,
                    description: "Table has header cells but no THead element (recommended for clarity)",
                    severity: .warning,
                    location: table.boundingBox
                )
            )
        }

        return violations
    }

    /// Checks table regularity (consistent column count, no gaps).
    private func checkTableRegularity(_ table: TableNode) -> [PDFUAViolation] {
        var violations: [PDFUAViolation] = []

        // Check for consistent column count
        if !table.hasConsistentColumnCount {
            violations.append(
                PDFUAViolation(
                    nodeId: table.id,
                    nodeType: .table,
                    description: "Table has inconsistent column counts across rows - structure is irregular",
                    severity: .error,
                    location: table.boundingBox
                )
            )
        }

        // Check for empty rows
        for row in table.allRows {
            let cells = table.cellsInRow(row)
            if cells.isEmpty {
                violations.append(
                    PDFUAViolation(
                        nodeId: row.id,
                        nodeType: .tableRow,
                        description: "Table row has no cells",
                        severity: .error,
                        location: row.boundingBox
                    )
                )
            }
        }

        return violations
    }

    /// Checks visual and semantic table structure match.
    private func checkVisualMatch(_ table: TableNode) -> [PDFUAViolation] {
        var violations: [PDFUAViolation] = []

        // Check row count match
        if table.visualRowCount != table.rowCount {
            violations.append(
                PDFUAViolation(
                    nodeId: table.id,
                    nodeType: .table,
                    description: "Visual table has \(table.visualRowCount) rows but semantic table has \(table.rowCount) rows",
                    severity: .warning,
                    location: table.boundingBox
                )
            )
        }

        // Check column count match
        if table.visualColumnCount != table.maxCellsPerRow && table.maxCellsPerRow > 0 {
            violations.append(
                PDFUAViolation(
                    nodeId: table.id,
                    nodeType: .table,
                    description: "Visual table has \(table.visualColumnCount) columns but semantic table has \(table.maxCellsPerRow) columns",
                    severity: .warning,
                    location: table.boundingBox
                )
            )
        }

        return violations
    }

    /// Checks individual cell structure.
    private func checkCellStructure(_ table: TableNode) -> [PDFUAViolation] {
        var violations: [PDFUAViolation] = []

        // Check each row
        for row in table.allRows {
            let cells = table.cellsInRow(row)

            // Check for mixed TH/TD in non-header rows
            let hasHeaders = cells.contains { $0.type == .tableHeader }
            let hasCells = cells.contains { $0.type == .tableCell }

            if hasHeaders && hasCells {
                // Mixed header and data cells in same row
                // This is valid in some cases (row headers), but flag as info
                violations.append(
                    PDFUAViolation(
                        nodeId: row.id,
                        nodeType: .tableRow,
                        description: "Table row contains both header cells (TH) and data cells (TD)",
                        severity: .info,
                        location: row.boundingBox
                    )
                )
            }

            // Check ALL children for invalid cell types (not just those returned by cellsInRow)
            let allChildren = row.children.compactMap { $0 as? ContentNode }
            for child in allChildren {
                if child.type != .tableHeader && child.type != .tableCell {
                    violations.append(
                        PDFUAViolation(
                            nodeId: child.id,
                            nodeType: child.type,
                            description: "Invalid cell type '\(child.type.rawValue)' in table row (expected TH or TD)",
                            severity: .error,
                            location: child.boundingBox
                        )
                    )
                }
            }
        }

        return violations
    }

    /// Checks error codes from TableNode validation.
    private func checkErrorCodes(_ table: TableNode) -> [PDFUAViolation] {
        var violations: [PDFUAViolation] = []

        // Run TableNode's own validation
        let errorCodes = table.validateStructure()

        // Convert error codes to violations
        for errorCode in errorCodes {
            let (description, severity) = descriptionForErrorCode(errorCode)
            violations.append(
                PDFUAViolation(
                    nodeId: table.id,
                    nodeType: .table,
                    description: description,
                    severity: severity,
                    location: table.boundingBox
                )
            )
        }

        return violations
    }

    /// Gets description and severity for an error code.
    private func descriptionForErrorCode(_ code: SemanticErrorCode) -> (String, PDFUASeverity) {
        switch code {
        case .tableMissingHeaders:
            return ("Table is missing header cells", .error)
        case .tableIrregularStructure:
            return ("Table has irregular structure (inconsistent columns or gaps)", .error)
        case .tableRowCountMismatch:
            return ("Visual and semantic row counts do not match", .warning)
        case .tableColumnCountMismatch:
            return ("Visual and semantic column counts do not match", .warning)
        case .tableCellBelowNextRow:
            return ("Table cell positioned below the next row", .error)
        case .tableCellAbovePreviousRow:
            return ("Table cell positioned above the previous row", .error)
        case .tableCellRightOfNextColumn:
            return ("Table cell positioned right of the next column", .error)
        case .tableCellLeftOfPreviousColumn:
            return ("Table cell positioned left of the previous column", .error)
        case .tableRowSpanMismatch:
            return ("Row span does not match visual layout", .warning)
        case .tableColSpanMismatch:
            return ("Column span does not match visual layout", .warning)
        default:
            return ("Table validation error: \(code.rawValue)", .error)
        }
    }
}

// MARK: - Convenience Initializers

extension TableChecker {

    /// Creates a strict table checker with all validations enabled.
    public static var strict: TableChecker {
        TableChecker(
            requireHeaders: true,
            validateRegularity: true,
            validateVisualMatch: true,
            visualMatchTolerance: 1.0
        )
    }

    /// Creates a lenient table checker with relaxed requirements.
    public static var lenient: TableChecker {
        TableChecker(
            requireHeaders: false,
            validateRegularity: false,
            validateVisualMatch: false,
            visualMatchTolerance: 5.0
        )
    }

    /// Creates a basic table checker that only checks for headers.
    public static var basic: TableChecker {
        TableChecker(
            requireHeaders: true,
            validateRegularity: false,
            validateVisualMatch: false,
            visualMatchTolerance: 2.0
        )
    }
}

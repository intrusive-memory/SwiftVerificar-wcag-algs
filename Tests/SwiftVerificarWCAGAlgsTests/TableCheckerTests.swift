import Testing
import Foundation
@testable import SwiftVerificarWCAGAlgs

@Suite("TableChecker Tests")
struct TableCheckerTests {

    // MARK: - Initialization Tests

    @Test("TableChecker default initialization")
    func testDefaultInitialization() {
        let checker = TableChecker()

        #expect(checker.requirement == .tablesMustHaveHeaders)
        #expect(checker.requireHeaders == true)
        #expect(checker.validateRegularity == true)
        #expect(checker.validateVisualMatch == true)
        #expect(checker.visualMatchTolerance == 2.0)
    }

    @Test("TableChecker custom initialization")
    func testCustomInitialization() {
        let checker = TableChecker(
            requireHeaders: false,
            validateRegularity: false,
            validateVisualMatch: false,
            visualMatchTolerance: 5.0
        )

        #expect(checker.requireHeaders == false)
        #expect(checker.validateRegularity == false)
        #expect(checker.validateVisualMatch == false)
        #expect(checker.visualMatchTolerance == 5.0)
    }

    @Test("TableChecker strict preset")
    func testStrictPreset() {
        let checker = TableChecker.strict

        #expect(checker.requireHeaders == true)
        #expect(checker.validateRegularity == true)
        #expect(checker.validateVisualMatch == true)
        #expect(checker.visualMatchTolerance == 1.0)
    }

    @Test("TableChecker lenient preset")
    func testLenientPreset() {
        let checker = TableChecker.lenient

        #expect(checker.requireHeaders == false)
        #expect(checker.validateRegularity == false)
        #expect(checker.validateVisualMatch == false)
        #expect(checker.visualMatchTolerance == 5.0)
    }

    @Test("TableChecker basic preset")
    func testBasicPreset() {
        let checker = TableChecker.basic

        #expect(checker.requireHeaders == true)
        #expect(checker.validateRegularity == false)
        #expect(checker.validateVisualMatch == false)
        #expect(checker.visualMatchTolerance == 2.0)
    }

    // MARK: - Non-Table Node Tests

    @Test("Check non-table node returns passing")
    func testNonTableNode() {
        let checker = TableChecker()

        let paragraph = ContentNode(type: .paragraph, depth: 1)
        let result = checker.check(paragraph)

        #expect(result.passed == true)
        #expect(result.context?.contains("not a table") == true)
    }

    @Test("Check document node")
    func testDocumentNode() {
        let checker = TableChecker()

        let document = ContentNode(type: .document, depth: 1)
        let result = checker.check(document)

        #expect(result.passed == true)
    }

    // MARK: - Valid Table Tests

    @Test("Check valid table with headers")
    func testValidTableWithHeaders() {
        let checker = TableChecker()

        let headerCell1 = ContentNode(type: .tableHeader, depth: 3)
        let headerCell2 = ContentNode(type: .tableHeader, depth: 3)
        let headerRow = ContentNode(type: .tableRow, children: [headerCell1, headerCell2], depth: 2)

        let dataCell1 = ContentNode(type: .tableCell, depth: 3)
        let dataCell2 = ContentNode(type: .tableCell, depth: 3)
        let dataRow = ContentNode(type: .tableRow, children: [dataCell1, dataCell2], depth: 2)

        let table = TableNode(children: [headerRow, dataRow], depth: 1)

        let result = checker.check(table)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    @Test("Check table with THead structure")
    func testTableWithTHead() {
        let checker = TableChecker()

        let headerCell = ContentNode(type: .tableHeader, depth: 4)
        let headerRow = ContentNode(type: .tableRow, children: [headerCell], depth: 3)
        let thead = ContentNode(type: .tableHead, children: [headerRow], depth: 2)

        let dataCell = ContentNode(type: .tableCell, depth: 4)
        let dataRow = ContentNode(type: .tableRow, children: [dataCell], depth: 3)
        let tbody = ContentNode(type: .tableBody, children: [dataRow], depth: 2)

        let table = TableNode(children: [thead, tbody], depth: 1)

        let result = checker.check(table)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    @Test("Check table with THead, TBody, and TFoot")
    func testCompleteTableStructure() {
        let checker = TableChecker()

        let headerCell = ContentNode(type: .tableHeader, depth: 4)
        let headerRow = ContentNode(type: .tableRow, children: [headerCell], depth: 3)
        let thead = ContentNode(type: .tableHead, children: [headerRow], depth: 2)

        let dataCell = ContentNode(type: .tableCell, depth: 4)
        let dataRow = ContentNode(type: .tableRow, children: [dataCell], depth: 3)
        let tbody = ContentNode(type: .tableBody, children: [dataRow], depth: 2)

        let footerCell = ContentNode(type: .tableCell, depth: 4)
        let footerRow = ContentNode(type: .tableRow, children: [footerCell], depth: 3)
        let tfoot = ContentNode(type: .tableFoot, children: [footerRow], depth: 2)

        let table = TableNode(children: [thead, tbody, tfoot], depth: 1)

        let result = checker.check(table)

        #expect(result.passed == true)
    }

    // MARK: - Missing Headers Tests

    @Test("Check table with no headers - strict mode")
    func testTableNoHeadersStrict() {
        let checker = TableChecker.strict

        let dataCell1 = ContentNode(type: .tableCell, depth: 3)
        let dataCell2 = ContentNode(type: .tableCell, depth: 3)
        let dataRow1 = ContentNode(type: .tableRow, children: [dataCell1, dataCell2], depth: 2)

        let dataCell3 = ContentNode(type: .tableCell, depth: 3)
        let dataCell4 = ContentNode(type: .tableCell, depth: 3)
        let dataRow2 = ContentNode(type: .tableRow, children: [dataCell3, dataCell4], depth: 2)

        let table = TableNode(children: [dataRow1, dataRow2], depth: 1)

        let result = checker.check(table)

        #expect(result.passed == false)
        #expect(result.violations.count >= 1)

        let hasHeaderViolation = result.violations.contains { violation in
            violation.description.contains("header")
        }
        #expect(hasHeaderViolation)
    }

    @Test("Check table with no headers - lenient mode")
    func testTableNoHeadersLenient() {
        let checker = TableChecker.lenient

        let dataCell = ContentNode(type: .tableCell, depth: 3)
        let dataRow = ContentNode(type: .tableRow, children: [dataCell], depth: 2)
        let table = TableNode(children: [dataRow], depth: 1)

        let result = checker.check(table)

        // Lenient mode doesn't require headers
        #expect(result.passed == true)
    }

    @Test("Check table with headers but no THead - warning")
    func testTableHeadersNoTHead() {
        let checker = TableChecker()

        let headerCell = ContentNode(type: .tableHeader, depth: 3)
        let headerRow = ContentNode(type: .tableRow, children: [headerCell], depth: 2)

        let dataCell = ContentNode(type: .tableCell, depth: 3)
        let dataRow = ContentNode(type: .tableRow, children: [dataCell], depth: 2)

        let table = TableNode(children: [headerRow, dataRow], depth: 1)

        let result = checker.check(table)

        // Should have a warning about missing THead
        let hasTheadWarning = result.violations.contains { violation in
            violation.description.contains("THead") && violation.severity == .warning
        }
        #expect(hasTheadWarning)
    }

    // MARK: - Table Regularity Tests

    @Test("Check table with irregular structure")
    func testIrregularTable() {
        let checker = TableChecker.strict

        let row1Cell1 = ContentNode(type: .tableCell, depth: 3)
        let row1Cell2 = ContentNode(type: .tableCell, depth: 3)
        let row1 = ContentNode(type: .tableRow, children: [row1Cell1, row1Cell2], depth: 2)

        let row2Cell1 = ContentNode(type: .tableCell, depth: 3)
        let row2 = ContentNode(type: .tableRow, children: [row2Cell1], depth: 2) // Only 1 cell

        let table = TableNode(children: [row1, row2], depth: 1)

        let result = checker.check(table)

        #expect(result.passed == false)

        let hasIrregularViolation = result.violations.contains { violation in
            violation.description.contains("inconsistent") || violation.description.contains("irregular")
        }
        #expect(hasIrregularViolation)
    }

    @Test("Check table with empty row")
    func testTableWithEmptyRow() {
        let checker = TableChecker()

        let dataCell = ContentNode(type: .tableCell, depth: 3)
        let normalRow = ContentNode(type: .tableRow, children: [dataCell], depth: 2)
        let emptyRow = ContentNode(type: .tableRow, children: [], depth: 2)

        let table = TableNode(children: [normalRow, emptyRow], depth: 1)

        let result = checker.check(table)

        #expect(result.passed == false)

        let hasEmptyRowViolation = result.violations.contains { violation in
            violation.description.contains("no cells")
        }
        #expect(hasEmptyRowViolation)
    }

    @Test("Check regular table structure")
    func testRegularTableStructure() {
        let checker = TableChecker()

        var rows: [any SemanticNode] = []
        for _ in 0..<3 {
            let cell1 = ContentNode(type: .tableCell, depth: 3)
            let cell2 = ContentNode(type: .tableCell, depth: 3)
            let cell3 = ContentNode(type: .tableCell, depth: 3)
            rows.append(ContentNode(type: .tableRow, children: [cell1, cell2, cell3], depth: 2))
        }

        // Add header row
        let headerCell1 = ContentNode(type: .tableHeader, depth: 3)
        let headerCell2 = ContentNode(type: .tableHeader, depth: 3)
        let headerCell3 = ContentNode(type: .tableHeader, depth: 3)
        let headerRow = ContentNode(type: .tableRow, children: [headerCell1, headerCell2, headerCell3], depth: 2)

        rows.insert(headerRow, at: 0)

        let table = TableNode(children: rows, depth: 1)

        let result = checker.check(table)

        #expect(result.passed == true)
    }

    // MARK: - Visual Border Matching Tests

    @Test("Check visual and semantic row count match")
    func testVisualSemanticRowMatch() {
        let checker = TableChecker()

        let dataCell = ContentNode(type: .tableCell, depth: 3)
        let dataRow1 = ContentNode(type: .tableRow, children: [dataCell], depth: 2)
        let dataRow2 = ContentNode(type: .tableRow, children: [dataCell], depth: 2)

        let headerCell = ContentNode(type: .tableHeader, depth: 3)
        let headerRow = ContentNode(type: .tableRow, children: [headerCell], depth: 2)

        let table = TableNode(
            children: [headerRow, dataRow1, dataRow2],
            depth: 1,
            visualBorderXCoordinates: [0, 100],
            visualBorderYCoordinates: [0, 30, 60, 90] // 3 rows
        )

        let result = checker.check(table)

        #expect(result.passed == true)
    }

    @Test("Check visual and semantic row count mismatch")
    func testVisualSemanticRowMismatch() {
        let checker = TableChecker()

        let headerCell = ContentNode(type: .tableHeader, depth: 3)
        let headerRow = ContentNode(type: .tableRow, children: [headerCell], depth: 2)

        let dataCell = ContentNode(type: .tableCell, depth: 3)
        let dataRow = ContentNode(type: .tableRow, children: [dataCell], depth: 2)

        let table = TableNode(
            children: [headerRow, dataRow], // 2 rows
            depth: 1,
            visualBorderXCoordinates: [0, 100],
            visualBorderYCoordinates: [0, 30, 60, 90] // 3 visual rows
        )

        let result = checker.check(table)

        #expect(result.passed == false)

        let hasRowMismatch = result.violations.contains { violation in
            violation.description.contains("row") && violation.description.contains("Visual")
        }
        #expect(hasRowMismatch)
    }

    @Test("Check visual and semantic column count mismatch")
    func testVisualSemanticColumnMismatch() {
        let checker = TableChecker()

        let headerCell = ContentNode(type: .tableHeader, depth: 3)
        let headerRow = ContentNode(type: .tableRow, children: [headerCell, headerCell], depth: 2)

        let table = TableNode(
            children: [headerRow], // 2 columns
            depth: 1,
            visualBorderXCoordinates: [0, 50, 100, 150], // 3 visual columns
            visualBorderYCoordinates: [0, 30]
        )

        let result = checker.check(table)

        #expect(result.passed == false)

        let hasColumnMismatch = result.violations.contains { violation in
            violation.description.contains("column") && violation.description.contains("Visual")
        }
        #expect(hasColumnMismatch)
    }

    @Test("Check table without visual border data")
    func testTableWithoutVisualBorder() {
        let checker = TableChecker()

        let headerCell = ContentNode(type: .tableHeader, depth: 3)
        let headerRow = ContentNode(type: .tableRow, children: [headerCell], depth: 2)

        let table = TableNode(children: [headerRow], depth: 1)

        let result = checker.check(table)

        // Should pass if other validations pass, visual matching is skipped
        #expect(result.passed == true)
    }

    // MARK: - Cell Structure Tests

    @Test("Check row with mixed TH and TD cells")
    func testMixedCellTypes() {
        let checker = TableChecker()

        let headerCell = ContentNode(type: .tableHeader, depth: 3)
        let dataCell = ContentNode(type: .tableCell, depth: 3)
        let mixedRow = ContentNode(type: .tableRow, children: [headerCell, dataCell], depth: 2)

        let table = TableNode(children: [mixedRow], depth: 1)

        let result = checker.check(table)

        // Should have info violation about mixed cells
        let hasMixedCellInfo = result.violations.contains { violation in
            violation.description.contains("both header cells") && violation.severity == .info
        }
        #expect(hasMixedCellInfo)
    }

    @Test("Check row with invalid cell type")
    func testInvalidCellType() {
        let checker = TableChecker()

        let invalidCell = ContentNode(type: .paragraph, depth: 3) // Should be TH or TD
        let row = ContentNode(type: .tableRow, children: [invalidCell], depth: 2)

        let table = TableNode(children: [row], depth: 1)

        let result = checker.check(table)

        #expect(result.passed == false)

        let hasInvalidCellViolation = result.violations.contains { violation in
            violation.description.contains("Invalid cell type")
        }
        #expect(hasInvalidCellViolation)
    }

    @Test("Check table with all valid cells")
    func testAllValidCells() {
        let checker = TableChecker()

        let headerCell1 = ContentNode(type: .tableHeader, depth: 3)
        let headerCell2 = ContentNode(type: .tableHeader, depth: 3)
        let headerRow = ContentNode(type: .tableRow, children: [headerCell1, headerCell2], depth: 2)

        let dataCell1 = ContentNode(type: .tableCell, depth: 3)
        let dataCell2 = ContentNode(type: .tableCell, depth: 3)
        let dataRow = ContentNode(type: .tableRow, children: [dataCell1, dataCell2], depth: 2)

        let table = TableNode(children: [headerRow, dataRow], depth: 1)

        let result = checker.check(table)

        #expect(result.passed == true)
    }

    // MARK: - Error Code Conversion Tests

    @Test("Check TableNode error codes are converted to violations")
    func testErrorCodeConversion() {
        let checker = TableChecker()

        var table = TableNode(depth: 1)
        table.errorCodes.insert(.tableMissingHeaders)
        table.errorCodes.insert(.tableIrregularStructure)

        let result = checker.check(table)

        #expect(result.passed == false)
        #expect(result.violations.count >= 2)

        let descriptions = result.violations.map { $0.description }
        #expect(descriptions.contains { $0.contains("missing header") })
        #expect(descriptions.contains { $0.contains("irregular") })
    }

    @Test("Check various table error codes")
    func testVariousErrorCodes() {
        let checker = TableChecker()

        let errorCodes: [SemanticErrorCode] = [
            .tableRowCountMismatch,
            .tableColumnCountMismatch,
            .tableCellBelowNextRow,
            .tableRowSpanMismatch
        ]

        for errorCode in errorCodes {
            var table = TableNode(depth: 1)
            table.errorCodes.insert(errorCode)

            let result = checker.check(table)

            #expect(result.passed == false)
            #expect(!result.violations.isEmpty)
        }
    }

    // MARK: - Multi-Node Checking Tests

    @Test("Check multiple valid tables")
    func testMultipleValidTables() {
        let checker = TableChecker()

        let headerCell = ContentNode(type: .tableHeader, depth: 3)
        let headerRow = ContentNode(type: .tableRow, children: [headerCell], depth: 2)

        let table1 = TableNode(children: [headerRow], depth: 1)
        let table2 = TableNode(children: [headerRow], depth: 1)

        let result = checker.check([table1, table2])

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    @Test("Check multiple tables with mixed results")
    func testMultipleTablesMixedResults() {
        let checker = TableChecker()

        let headerCell = ContentNode(type: .tableHeader, depth: 3)
        let headerRow = ContentNode(type: .tableRow, children: [headerCell], depth: 2)
        let validTable = TableNode(children: [headerRow], depth: 1)

        let dataCell = ContentNode(type: .tableCell, depth: 3)
        let dataRow = ContentNode(type: .tableRow, children: [dataCell], depth: 2)
        let invalidTable = TableNode(children: [dataRow], depth: 1) // No headers

        let result = checker.check([validTable, invalidTable])

        #expect(result.passed == false)
        #expect(result.violations.count >= 1)
    }

    // MARK: - Edge Cases

    @Test("Check table with single header cell")
    func testSingleHeaderCell() {
        let checker = TableChecker()

        let headerCell = ContentNode(type: .tableHeader, depth: 3)
        let headerRow = ContentNode(type: .tableRow, children: [headerCell], depth: 2)

        let table = TableNode(children: [headerRow], depth: 1)

        let result = checker.check(table)

        #expect(result.passed == true)
    }

    @Test("Check large table")
    func testLargeTable() {
        let checker = TableChecker()

        var rows: [any SemanticNode] = []

        // Add header row
        var headerCells: [any SemanticNode] = []
        for _ in 0..<10 {
            headerCells.append(ContentNode(type: .tableHeader, depth: 3))
        }
        rows.append(ContentNode(type: .tableRow, children: headerCells, depth: 2))

        // Add data rows
        for _ in 0..<50 {
            var dataCells: [any SemanticNode] = []
            for _ in 0..<10 {
                dataCells.append(ContentNode(type: .tableCell, depth: 3))
            }
            rows.append(ContentNode(type: .tableRow, children: dataCells, depth: 2))
        }

        let table = TableNode(children: rows, depth: 1)

        let result = checker.check(table)

        #expect(result.passed == true)
    }

    @Test("Check violation includes location")
    func testViolationLocation() {
        let checker = TableChecker()

        let location = BoundingBox(pageIndex: 1, rect: CGRect(x: 50, y: 100, width: 300, height: 200))
        let dataCell = ContentNode(type: .tableCell, depth: 3)
        let dataRow = ContentNode(type: .tableRow, children: [dataCell], depth: 2)

        let table = TableNode(
            boundingBox: location,
            children: [dataRow],
            depth: 1
        )

        let result = checker.check(table)

        #expect(result.passed == false)

        if let violation = result.violations.first {
            #expect(violation.location == location)
        }
    }

    @Test("Check result context includes row count")
    func testResultContextRowCount() {
        let checker = TableChecker()

        let headerCell = ContentNode(type: .tableHeader, depth: 3)
        let headerRow = ContentNode(type: .tableRow, children: [headerCell], depth: 2)

        let dataCell = ContentNode(type: .tableCell, depth: 3)
        let dataRow = ContentNode(type: .tableRow, children: [dataCell], depth: 2)

        let table = TableNode(children: [headerRow, dataRow], depth: 1)

        let result = checker.check(table)

        #expect(result.passed == true)
        #expect(result.context?.contains("2 rows") == true)
    }

    // MARK: - Requirement Tests

    @Test("Verify requirement is tablesMustHaveHeaders")
    func testRequirement() {
        let checker = TableChecker()
        #expect(checker.requirement == .tablesMustHaveHeaders)
    }

    @Test("Check empty nodes array")
    func testEmptyNodesArray() {
        let checker = TableChecker()
        let result = checker.check([])

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }
}

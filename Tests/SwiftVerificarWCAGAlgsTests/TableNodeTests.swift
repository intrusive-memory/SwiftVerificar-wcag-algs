import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

/// Tests for the TableNode struct.
@Suite("TableNode Tests")
struct TableNodeTests {

    // MARK: - Test Helpers

    func makeBoundingBox(page: Int = 0) -> BoundingBox {
        BoundingBox(pageIndex: page, rect: CGRect(x: 0, y: 0, width: 400, height: 200))
    }

    func makeCell(type: SemanticType = .tableCell) -> ContentNode {
        ContentNode(type: type, depth: 3)
    }

    func makeRow(cells: [ContentNode]) -> ContentNode {
        ContentNode(type: .tableRow, children: cells, depth: 2)
    }

    func makeRowGroup(type: SemanticType, rows: [ContentNode]) -> ContentNode {
        ContentNode(type: type, children: rows, depth: 1)
    }

    // MARK: - Initialization Tests

    @Test("TableNode initializes with default values")
    func initWithDefaults() {
        let table = TableNode()
        #expect(table.type == .table)
        #expect(table.boundingBox == nil)
        #expect(table.children.isEmpty)
        #expect(table.summary == nil)
        #expect(table.visualBorderXCoordinates.isEmpty)
        #expect(table.visualBorderYCoordinates.isEmpty)
    }

    @Test("TableNode initializes with depth")
    func initWithDepth() {
        let table = TableNode(depth: 3)
        #expect(table.depth == 3)
    }

    @Test("TableNode initializes with all properties")
    func initWithAllProperties() {
        let id = UUID()
        let box = makeBoundingBox()
        let attrs: AttributesDictionary = ["Summary": .string("Test table")]
        let xCoords: [CGFloat] = [0, 100, 200]
        let yCoords: [CGFloat] = [0, 50, 100]

        let table = TableNode(
            id: id,
            boundingBox: box,
            children: [],
            attributes: attrs,
            depth: 1,
            errorCodes: [.tableMissingHeaders],
            summary: "Test table",
            visualBorderXCoordinates: xCoords,
            visualBorderYCoordinates: yCoords
        )

        #expect(table.id == id)
        #expect(table.type == .table)
        #expect(table.boundingBox == box)
        #expect(table.summary == "Test table")
        #expect(table.visualBorderXCoordinates == xCoords)
        #expect(table.visualBorderYCoordinates == yCoords)
        #expect(table.errorCodes.contains(.tableMissingHeaders))
    }

    @Test("TableNode gets summary from attributes if not provided")
    func summaryFromAttributes() {
        let table = TableNode(
            attributes: ["Summary": .string("From attributes")]
        )
        #expect(table.summary == "From attributes")
    }

    // MARK: - SemanticNode Protocol Conformance Tests

    @Test("TableNode type is always table")
    func typeIsTable() {
        let table = TableNode()
        #expect(table.type == .table)
    }

    @Test("TableNode conforms to SemanticNode")
    func conformsToSemanticNode() {
        let table: any SemanticNode = TableNode()
        #expect(table.type == .table)
    }

    @Test("TableNode is Sendable")
    func sendable() {
        let table = TableNode()
        let sendable: any Sendable = table
        #expect(sendable is TableNode)
    }

    // MARK: - Row Group Tests

    @Test("tableHead returns THead child")
    func tableHeadFound() {
        let headerRow = makeRow(cells: [makeCell(type: .tableHeader)])
        let thead = makeRowGroup(type: .tableHead, rows: [headerRow])
        let table = TableNode(children: [thead])

        #expect(table.tableHead != nil)
        #expect(table.tableHead?.type == .tableHead)
    }

    @Test("tableHead returns nil when not present")
    func tableHeadNotFound() {
        let table = TableNode()
        #expect(table.tableHead == nil)
    }

    @Test("tableBodies returns TBody children")
    func tableBodiesFound() {
        let row = makeRow(cells: [makeCell()])
        let tbody1 = makeRowGroup(type: .tableBody, rows: [row])
        let tbody2 = makeRowGroup(type: .tableBody, rows: [row])
        let table = TableNode(children: [tbody1, tbody2])

        #expect(table.tableBodies.count == 2)
    }

    @Test("tableFoot returns TFoot child")
    func tableFootFound() {
        let footerRow = makeRow(cells: [makeCell()])
        let tfoot = makeRowGroup(type: .tableFoot, rows: [footerRow])
        let table = TableNode(children: [tfoot])

        #expect(table.tableFoot != nil)
        #expect(table.tableFoot?.type == .tableFoot)
    }

    @Test("hasExplicitRowGroups returns true with THead")
    func hasExplicitRowGroupsWithTHead() {
        let headerRow = makeRow(cells: [makeCell(type: .tableHeader)])
        let thead = makeRowGroup(type: .tableHead, rows: [headerRow])
        let table = TableNode(children: [thead])

        #expect(table.hasExplicitRowGroups)
    }

    @Test("hasExplicitRowGroups returns true with TBody")
    func hasExplicitRowGroupsWithTBody() {
        let row = makeRow(cells: [makeCell()])
        let tbody = makeRowGroup(type: .tableBody, rows: [row])
        let table = TableNode(children: [tbody])

        #expect(table.hasExplicitRowGroups)
    }

    @Test("hasExplicitRowGroups returns false with direct rows")
    func hasExplicitRowGroupsFalseWithDirectRows() {
        let row = makeRow(cells: [makeCell()])
        let table = TableNode(children: [row])

        #expect(!table.hasExplicitRowGroups)
    }

    // MARK: - Row Accessor Tests

    @Test("allRows collects rows from all groups")
    func allRowsFromAllGroups() {
        let headerRow = makeRow(cells: [makeCell(type: .tableHeader)])
        let bodyRow1 = makeRow(cells: [makeCell()])
        let bodyRow2 = makeRow(cells: [makeCell()])
        let footerRow = makeRow(cells: [makeCell()])

        let thead = makeRowGroup(type: .tableHead, rows: [headerRow])
        let tbody = makeRowGroup(type: .tableBody, rows: [bodyRow1, bodyRow2])
        let tfoot = makeRowGroup(type: .tableFoot, rows: [footerRow])

        let table = TableNode(children: [thead, tbody, tfoot])

        #expect(table.allRows.count == 4)
    }

    @Test("allRows includes direct TR children")
    func allRowsIncludesDirectRows() {
        let row1 = makeRow(cells: [makeCell()])
        let row2 = makeRow(cells: [makeCell()])
        let table = TableNode(children: [row1, row2])

        #expect(table.allRows.count == 2)
    }

    @Test("rowCount returns correct count")
    func rowCountCorrect() {
        let row1 = makeRow(cells: [makeCell()])
        let row2 = makeRow(cells: [makeCell()])
        let tbody = makeRowGroup(type: .tableBody, rows: [row1, row2])
        let table = TableNode(children: [tbody])

        #expect(table.rowCount == 2)
    }

    @Test("headerRows returns rows from THead")
    func headerRowsFromTHead() {
        let headerRow1 = makeRow(cells: [makeCell(type: .tableHeader)])
        let headerRow2 = makeRow(cells: [makeCell(type: .tableHeader)])
        let thead = makeRowGroup(type: .tableHead, rows: [headerRow1, headerRow2])
        let table = TableNode(children: [thead])

        #expect(table.headerRows.count == 2)
    }

    @Test("headerRows identifies rows with only TH cells")
    func headerRowsIdentifiesAllThRows() {
        let headerRow = makeRow(cells: [makeCell(type: .tableHeader), makeCell(type: .tableHeader)])
        let dataRow = makeRow(cells: [makeCell(), makeCell()])
        let table = TableNode(children: [headerRow, dataRow])

        #expect(table.headerRows.count == 1)
    }

    // MARK: - Cell Accessor Tests

    @Test("cellsInRow returns TH and TD cells")
    func cellsInRowReturnsCells() {
        let th = makeCell(type: .tableHeader)
        let td1 = makeCell()
        let td2 = makeCell()
        let row = makeRow(cells: [th, td1, td2])
        let table = TableNode(children: [row])

        let cells = table.cellsInRow(row)
        #expect(cells.count == 3)
    }

    @Test("cellsInRow returns empty for non-row")
    func cellsInRowEmptyForNonRow() {
        let cell = makeCell()
        let table = TableNode()

        let cells = table.cellsInRow(cell)
        #expect(cells.isEmpty)
    }

    @Test("allCells returns all cells in order")
    func allCellsReturnsAll() {
        let row1 = makeRow(cells: [makeCell(), makeCell()])
        let row2 = makeRow(cells: [makeCell(), makeCell()])
        let table = TableNode(children: [row1, row2])

        #expect(table.allCells.count == 4)
    }

    @Test("headerCells returns only TH cells")
    func headerCellsOnlyTH() {
        let row = makeRow(cells: [
            makeCell(type: .tableHeader),
            makeCell(),
            makeCell(type: .tableHeader)
        ])
        let table = TableNode(children: [row])

        #expect(table.headerCells.count == 2)
    }

    @Test("dataCells returns only TD cells")
    func dataCellsOnlyTD() {
        let row = makeRow(cells: [
            makeCell(type: .tableHeader),
            makeCell(),
            makeCell()
        ])
        let table = TableNode(children: [row])

        #expect(table.dataCells.count == 2)
    }

    @Test("cellCount returns total cell count")
    func cellCountTotal() {
        let row1 = makeRow(cells: [makeCell(), makeCell()])
        let row2 = makeRow(cells: [makeCell(), makeCell(), makeCell()])
        let table = TableNode(children: [row1, row2])

        #expect(table.cellCount == 5)
    }

    // MARK: - Structure Analysis Tests

    @Test("hasHeaders returns true when TH cells exist")
    func hasHeadersTrue() {
        let row = makeRow(cells: [makeCell(type: .tableHeader), makeCell()])
        let table = TableNode(children: [row])

        #expect(table.hasHeaders)
    }

    @Test("hasHeaders returns false when no TH cells")
    func hasHeadersFalse() {
        let row = makeRow(cells: [makeCell(), makeCell()])
        let table = TableNode(children: [row])

        #expect(!table.hasHeaders)
    }

    @Test("maxCellsPerRow returns maximum cell count")
    func maxCellsPerRowCorrect() {
        let row1 = makeRow(cells: [makeCell(), makeCell()])
        let row2 = makeRow(cells: [makeCell(), makeCell(), makeCell()])
        let row3 = makeRow(cells: [makeCell()])
        let table = TableNode(children: [row1, row2, row3])

        #expect(table.maxCellsPerRow == 3)
    }

    @Test("hasConsistentColumnCount returns true when all rows same")
    func hasConsistentColumnCountTrue() {
        let row1 = makeRow(cells: [makeCell(), makeCell()])
        let row2 = makeRow(cells: [makeCell(), makeCell()])
        let table = TableNode(children: [row1, row2])

        #expect(table.hasConsistentColumnCount)
    }

    @Test("hasConsistentColumnCount returns false when rows differ")
    func hasConsistentColumnCountFalse() {
        let row1 = makeRow(cells: [makeCell(), makeCell()])
        let row2 = makeRow(cells: [makeCell(), makeCell(), makeCell()])
        let table = TableNode(children: [row1, row2])

        #expect(!table.hasConsistentColumnCount)
    }

    // MARK: - Visual Border Tests

    @Test("hasVisualBorder returns true when both coordinates present")
    func hasVisualBorderTrue() {
        let table = TableNode(
            visualBorderXCoordinates: [0, 100, 200],
            visualBorderYCoordinates: [0, 50, 100]
        )
        #expect(table.hasVisualBorder)
    }

    @Test("hasVisualBorder returns false when X coords empty")
    func hasVisualBorderFalseNoX() {
        let table = TableNode(
            visualBorderYCoordinates: [0, 50, 100]
        )
        #expect(!table.hasVisualBorder)
    }

    @Test("hasVisualBorder returns false when Y coords empty")
    func hasVisualBorderFalseNoY() {
        let table = TableNode(
            visualBorderXCoordinates: [0, 100, 200]
        )
        #expect(!table.hasVisualBorder)
    }

    @Test("visualColumnCount returns correct count")
    func visualColumnCountCorrect() {
        let table = TableNode(
            visualBorderXCoordinates: [0, 100, 200, 300]  // 3 columns
        )
        #expect(table.visualColumnCount == 3)
    }

    @Test("visualRowCount returns correct count")
    func visualRowCountCorrect() {
        let table = TableNode(
            visualBorderYCoordinates: [0, 50, 100]  // 2 rows
        )
        #expect(table.visualRowCount == 2)
    }

    // MARK: - Validation Tests

    @Test("validateStructure reports missing headers")
    func validateReportsMissingHeaders() {
        let row1 = makeRow(cells: [makeCell(), makeCell()])
        let row2 = makeRow(cells: [makeCell(), makeCell()])
        let table = TableNode(children: [row1, row2])

        let errors = table.validateStructure()
        #expect(errors.contains(.tableMissingHeaders))
    }

    @Test("validateStructure does not report missing headers for single row")
    func validateNoMissingHeadersSingleRow() {
        let row = makeRow(cells: [makeCell()])
        let table = TableNode(children: [row])

        let errors = table.validateStructure()
        #expect(!errors.contains(.tableMissingHeaders))
    }

    @Test("validateStructure reports irregular structure")
    func validateReportsIrregularStructure() {
        let row1 = makeRow(cells: [makeCell(), makeCell()])
        let row2 = makeRow(cells: [makeCell()])
        let table = TableNode(children: [row1, row2])

        let errors = table.validateStructure()
        #expect(errors.contains(.tableIrregularStructure))
    }

    @Test("validateStructure reports row count mismatch")
    func validateReportsRowCountMismatch() {
        let row = makeRow(cells: [makeCell(type: .tableHeader)])
        let table = TableNode(
            children: [row],
            visualBorderXCoordinates: [0, 100],
            visualBorderYCoordinates: [0, 50, 100, 150]  // 3 visual rows
        )

        let errors = table.validateStructure()
        #expect(errors.contains(.tableRowCountMismatch))
    }

    @Test("validateStructure reports column count mismatch")
    func validateReportsColumnCountMismatch() {
        let row = makeRow(cells: [makeCell(type: .tableHeader), makeCell()])  // 2 cells
        let table = TableNode(
            children: [row],
            visualBorderXCoordinates: [0, 100, 200, 300],  // 3 visual columns
            visualBorderYCoordinates: [0, 50]
        )

        let errors = table.validateStructure()
        #expect(errors.contains(.tableColumnCountMismatch))
    }

    // MARK: - withVisualBorder Tests

    @Test("withVisualBorder creates new table with border data")
    func withVisualBorderCreatesNew() {
        let original = TableNode(depth: 2)
        let updated = original.withVisualBorder(
            xCoordinates: [0, 100],
            yCoordinates: [0, 50]
        )

        #expect(updated.id == original.id)
        #expect(updated.depth == original.depth)
        #expect(updated.visualBorderXCoordinates == [0, 100])
        #expect(updated.visualBorderYCoordinates == [0, 50])
        #expect(original.visualBorderXCoordinates.isEmpty)  // Original unchanged
    }

    // MARK: - Hashable Tests

    @Test("TableNode is Hashable by ID")
    func hashableById() {
        let id = UUID()
        let table1 = TableNode(id: id)
        let table2 = TableNode(id: id, depth: 5)

        var set: Set<TableNode> = []
        set.insert(table1)
        set.insert(table2)

        #expect(set.count == 1)
    }

    // MARK: - Equatable Tests

    @Test("TableNode equality is by ID")
    func equalityById() {
        let id = UUID()
        let table1 = TableNode(id: id, depth: 1)
        let table2 = TableNode(id: id, depth: 2)
        let table3 = TableNode()

        #expect(table1 == table2)
        #expect(table1 != table3)
    }

    // MARK: - Codable Tests

    @Test("TableNode encodes and decodes correctly")
    func codableRoundTrip() throws {
        let original = TableNode(
            boundingBox: makeBoundingBox(),
            attributes: ["Summary": .string("Test")],
            depth: 1,
            errorCodes: [.tableMissingHeaders],
            summary: "Test table",
            visualBorderXCoordinates: [0, 100, 200],
            visualBorderYCoordinates: [0, 50, 100]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TableNode.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.type == .table)
        #expect(decoded.depth == original.depth)
        #expect(decoded.summary == original.summary)
        #expect(decoded.visualBorderXCoordinates == original.visualBorderXCoordinates)
        #expect(decoded.visualBorderYCoordinates == original.visualBorderYCoordinates)
        #expect(decoded.errorCodes == original.errorCodes)
    }

    // MARK: - CustomStringConvertible Tests

    @Test("description shows row and column count")
    func descriptionShowsStructure() {
        let row1 = makeRow(cells: [makeCell(), makeCell()])
        let row2 = makeRow(cells: [makeCell(), makeCell()])
        let table = TableNode(children: [row1, row2])

        let desc = table.description
        #expect(desc.contains("Table"))
        #expect(desc.contains("2 rows"))
        #expect(desc.contains("2 cols"))
    }

    @Test("description shows has headers indicator")
    func descriptionShowsHeaders() {
        let row = makeRow(cells: [makeCell(type: .tableHeader)])
        let table = TableNode(children: [row])

        let desc = table.description
        #expect(desc.contains("[has headers]"))
    }
}

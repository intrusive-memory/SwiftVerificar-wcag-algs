import Testing
import Foundation
@testable import SwiftVerificarWCAGAlgs

@Suite("PDFUAChecker Protocol Tests")
struct PDFUACheckerTests {

    // MARK: - PDFUACheckResult Tests

    @Test("PDFUACheckResult initialization")
    func testCheckResultInitialization() {
        let result = PDFUACheckResult(
            requirement: .documentMustBeTagged,
            passed: true,
            violations: [],
            context: "Test context"
        )

        #expect(result.requirement == .documentMustBeTagged)
        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
        #expect(result.context == "Test context")
    }

    @Test("PDFUACheckResult passing factory method")
    func testCheckResultPassing() {
        let result = PDFUACheckResult.passing(
            requirement: .documentMustBeTagged,
            context: "All checks passed"
        )

        #expect(result.requirement == .documentMustBeTagged)
        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
        #expect(result.context == "All checks passed")
    }

    @Test("PDFUACheckResult failing factory method")
    func testCheckResultFailing() {
        let violation = PDFUAViolation(
            description: "Test violation",
            severity: .error
        )

        let result = PDFUACheckResult.failing(
            requirement: .documentMustBeTagged,
            violations: [violation],
            context: "Found errors"
        )

        #expect(result.requirement == .documentMustBeTagged)
        #expect(result.passed == false)
        #expect(result.violations.count == 1)
        #expect(result.context == "Found errors")
    }

    @Test("PDFUACheckResult equatability")
    func testCheckResultEquatable() {
        let result1 = PDFUACheckResult.passing(requirement: .documentMustBeTagged)
        let result2 = PDFUACheckResult.passing(requirement: .documentMustBeTagged)
        let result3 = PDFUACheckResult.passing(requirement: .tablesMustHaveHeaders)

        #expect(result1 == result2)
        #expect(result1 != result3)
    }

    // MARK: - PDFUAViolation Tests

    @Test("PDFUAViolation initialization with all parameters")
    func testViolationFullInitialization() {
        let nodeId = UUID()
        let location = BoundingBox(pageIndex: 1, rect: CGRect(x: 10, y: 10, width: 100, height: 50))

        let violation = PDFUAViolation(
            nodeId: nodeId,
            nodeType: .table,
            description: "Table missing headers",
            severity: .error,
            location: location
        )

        #expect(violation.nodeId == nodeId)
        #expect(violation.nodeType == .table)
        #expect(violation.description == "Table missing headers")
        #expect(violation.severity == .error)
        #expect(violation.location == location)
    }

    @Test("PDFUAViolation initialization with minimal parameters")
    func testViolationMinimalInitialization() {
        let violation = PDFUAViolation(
            description: "Test violation",
            severity: .warning
        )

        #expect(violation.nodeId == nil)
        #expect(violation.nodeType == nil)
        #expect(violation.description == "Test violation")
        #expect(violation.severity == .warning)
        #expect(violation.location == nil)
    }

    @Test("PDFUAViolation equatability")
    func testViolationEquatable() {
        let id = UUID()
        let violation1 = PDFUAViolation(
            id: id,
            description: "Test",
            severity: .error
        )
        let violation2 = PDFUAViolation(
            id: id,
            description: "Test",
            severity: .error
        )
        let violation3 = PDFUAViolation(
            description: "Different",
            severity: .error
        )

        #expect(violation1 == violation2)
        #expect(violation1 != violation3)
    }

    // MARK: - PDFUASeverity Tests

    @Test("PDFUASeverity all cases")
    func testSeverityAllCases() {
        let allCases = PDFUASeverity.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.error))
        #expect(allCases.contains(.warning))
        #expect(allCases.contains(.info))
    }

    @Test("PDFUASeverity raw values")
    func testSeverityRawValues() {
        #expect(PDFUASeverity.error.rawValue == "error")
        #expect(PDFUASeverity.warning.rawValue == "warning")
        #expect(PDFUASeverity.info.rawValue == "info")
    }

    @Test("PDFUASeverity codable")
    func testSeverityCodable() throws {
        let severity = PDFUASeverity.error
        let encoded = try JSONEncoder().encode(severity)
        let decoded = try JSONDecoder().decode(PDFUASeverity.self, from: encoded)
        #expect(decoded == severity)
    }

    // MARK: - PDFUARequirement Tests

    @Test("PDFUARequirement all cases")
    func testRequirementAllCases() {
        let allCases = PDFUARequirement.allCases
        #expect(allCases.count == 10)
    }

    @Test("PDFUARequirement structure requirements")
    func testStructureRequirements() {
        #expect(PDFUARequirement.documentMustBeTagged.category == .structure)
        #expect(PDFUARequirement.structureElementsNeedRoleMapping.category == .structure)
        #expect(PDFUARequirement.logicalReadingOrder.category == .structure)
    }

    @Test("PDFUARequirement table requirements")
    func testTableRequirements() {
        #expect(PDFUARequirement.tablesMustHaveHeaders.category == .tables)
        #expect(PDFUARequirement.tableStructureMustBeRegular.category == .tables)
        #expect(PDFUARequirement.tableCellHeaderAssociation.category == .tables)
    }

    @Test("PDFUARequirement list requirements")
    func testListRequirements() {
        #expect(PDFUARequirement.listItemsMustHaveLabels.category == .lists)
        #expect(PDFUARequirement.listStructureMustBeProper.category == .lists)
    }

    @Test("PDFUARequirement content requirements")
    func testContentRequirements() {
        #expect(PDFUARequirement.alternativeDescriptions.category == .content)
        #expect(PDFUARequirement.actualTextRequired.category == .content)
    }

    @Test("PDFUARequirement raw values")
    func testRequirementRawValues() {
        #expect(PDFUARequirement.documentMustBeTagged.rawValue == "7.1")
        #expect(PDFUARequirement.structureElementsNeedRoleMapping.rawValue == "7.2")
        #expect(PDFUARequirement.tablesMustHaveHeaders.rawValue == "7.5")
    }

    @Test("PDFUARequirement names")
    func testRequirementNames() {
        #expect(PDFUARequirement.documentMustBeTagged.name == "Document Must Be Tagged")
        #expect(PDFUARequirement.tablesMustHaveHeaders.name == "Tables Must Have Headers")
        #expect(PDFUARequirement.listItemsMustHaveLabels.name == "List Items Must Have Labels")
    }

    // MARK: - PDFUACategory Tests

    @Test("PDFUACategory all cases")
    func testCategoryAllCases() {
        let allCases = PDFUACategory.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.structure))
        #expect(allCases.contains(.tables))
        #expect(allCases.contains(.lists))
        #expect(allCases.contains(.content))
    }

    @Test("PDFUACategory raw values")
    func testCategoryRawValues() {
        #expect(PDFUACategory.structure.rawValue == "Structure")
        #expect(PDFUACategory.tables.rawValue == "Tables")
        #expect(PDFUACategory.lists.rawValue == "Lists")
        #expect(PDFUACategory.content.rawValue == "Content")
    }

    // MARK: - Mock PDFUAChecker Implementation

    struct MockPDFUAChecker: PDFUAChecker {
        let requirement: PDFUARequirement = .documentMustBeTagged
        let shouldPass: Bool

        func check(_ node: any SemanticNode) -> PDFUACheckResult {
            if shouldPass {
                return .passing(requirement: requirement)
            } else {
                let violation = PDFUAViolation(
                    nodeId: node.id,
                    nodeType: node.type,
                    description: "Mock violation",
                    severity: .error
                )
                return .failing(requirement: requirement, violations: [violation])
            }
        }
    }

    @Test("PDFUAChecker default multi-node check with passing results")
    func testDefaultMultiNodeCheckPassing() {
        let checker = MockPDFUAChecker(shouldPass: true)
        let nodes: [any SemanticNode] = [
            ContentNode(type: .paragraph, depth: 1),
            ContentNode(type: .paragraph, depth: 1),
            ContentNode(type: .paragraph, depth: 1)
        ]

        let result = checker.check(nodes)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
        #expect(result.context?.contains("3") == true)
    }

    @Test("PDFUAChecker default multi-node check with failures")
    func testDefaultMultiNodeCheckFailing() {
        let checker = MockPDFUAChecker(shouldPass: false)
        let nodes: [any SemanticNode] = [
            ContentNode(type: .paragraph, depth: 1),
            ContentNode(type: .paragraph, depth: 1)
        ]

        let result = checker.check(nodes)

        #expect(result.passed == false)
        #expect(result.violations.count == 2)
        #expect(result.context?.contains("2") == true)
    }

    @Test("PDFUAChecker single node check")
    func testSingleNodeCheck() {
        let checker = MockPDFUAChecker(shouldPass: true)
        let node = ContentNode(type: .paragraph, depth: 1)

        let result = checker.check(node)

        #expect(result.passed == true)
        #expect(result.requirement == .documentMustBeTagged)
    }

    @Test("PDFUAChecker empty nodes array")
    func testEmptyNodesArray() {
        let checker = MockPDFUAChecker(shouldPass: true)
        let nodes: [any SemanticNode] = []

        let result = checker.check(nodes)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
        #expect(result.context?.contains("0") == true)
    }

    // MARK: - Integration Tests

    @Test("Multiple violations from different nodes")
    func testMultipleViolations() {
        let checker = MockPDFUAChecker(shouldPass: false)
        let nodes: [any SemanticNode] = [
            ContentNode(type: .paragraph, depth: 1),
            ContentNode(type: .heading, depth: 1),
            ContentNode(type: .figure, depth: 1)
        ]

        let result = checker.check(nodes)

        #expect(result.passed == false)
        #expect(result.violations.count == 3)

        // Each violation should have different node IDs
        let nodeIds = Set(result.violations.compactMap { $0.nodeId })
        #expect(nodeIds.count == 3)
    }

    @Test("Violation with location information")
    func testViolationWithLocation() {
        let location = BoundingBox(pageIndex: 2, rect: CGRect(x: 50, y: 100, width: 200, height: 150))
        let violation = PDFUAViolation(
            nodeId: UUID(),
            nodeType: .table,
            description: "Test",
            severity: .error,
            location: location
        )

        #expect(violation.location?.pageIndex == 2)
        #expect(violation.location?.rect.origin.x == 50)
        #expect(violation.location?.rect.size.width == 200)
    }

    @Test("PDFUACheckResult with multiple violation severities")
    func testMultipleSeverities() {
        let violations = [
            PDFUAViolation(description: "Critical error", severity: .error),
            PDFUAViolation(description: "Warning", severity: .warning),
            PDFUAViolation(description: "Info", severity: .info)
        ]

        let result = PDFUACheckResult.failing(
            requirement: .documentMustBeTagged,
            violations: violations
        )

        #expect(result.violations.count == 3)
        #expect(result.violations.contains { $0.severity == .error })
        #expect(result.violations.contains { $0.severity == .warning })
        #expect(result.violations.contains { $0.severity == .info })
    }

    @Test("Requirement categories grouping")
    func testRequirementCategoriesGrouping() {
        let structureReqs = PDFUARequirement.allCases.filter { $0.category == .structure }
        let tableReqs = PDFUARequirement.allCases.filter { $0.category == .tables }
        let listReqs = PDFUARequirement.allCases.filter { $0.category == .lists }
        let contentReqs = PDFUARequirement.allCases.filter { $0.category == .content }

        #expect(structureReqs.count == 3)
        #expect(tableReqs.count == 3)
        #expect(listReqs.count == 2)
        #expect(contentReqs.count == 2)
    }
}

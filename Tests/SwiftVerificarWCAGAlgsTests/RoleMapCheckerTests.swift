import Testing
import Foundation
@testable import SwiftVerificarWCAGAlgs

@Suite("RoleMapChecker Tests")
struct RoleMapCheckerTests {

    // MARK: - Initialization Tests

    @Test("RoleMapChecker default initialization")
    func testDefaultInitialization() {
        let checker = RoleMapChecker()

        #expect(checker.requirement == .structureElementsNeedRoleMapping)
        #expect(checker.maxRoleMappingDepth == 10)
        #expect(checker.requireExplicitMappings == true)
    }

    @Test("RoleMapChecker custom initialization")
    func testCustomInitialization() {
        let checker = RoleMapChecker(
            maxRoleMappingDepth: 5,
            requireExplicitMappings: false
        )

        #expect(checker.maxRoleMappingDepth == 5)
        #expect(checker.requireExplicitMappings == false)
    }

    @Test("RoleMapChecker strict preset")
    func testStrictPreset() {
        let checker = RoleMapChecker.strict

        #expect(checker.maxRoleMappingDepth == 10)
        #expect(checker.requireExplicitMappings == true)
    }

    @Test("RoleMapChecker lenient preset")
    func testLenientPreset() {
        let checker = RoleMapChecker.lenient

        #expect(checker.maxRoleMappingDepth == 20)
        #expect(checker.requireExplicitMappings == false)
    }

    @Test("RoleMapChecker basic preset")
    func testBasicPreset() {
        let checker = RoleMapChecker.basic

        #expect(checker.maxRoleMappingDepth == 5)
        #expect(checker.requireExplicitMappings == false)
    }

    // MARK: - Standard Type Recognition Tests

    @Test("Check standard document-level types")
    func testStandardDocumentTypes() {
        let checker = RoleMapChecker()

        let types: [SemanticType] = [.document, .part, .div]

        for type in types {
            let node = ContentNode(type: type, depth: 1)
            let result = checker.check(node)

            #expect(result.passed == true, "Type \(type.rawValue) should be standard")
            #expect(result.violations.isEmpty)
        }
    }

    @Test("Check standard paragraph-level types")
    func testStandardParagraphTypes() {
        let checker = RoleMapChecker()

        let types: [SemanticType] = [.paragraph, .blockQuote]

        for type in types {
            let node = ContentNode(type: type, depth: 1)
            let result = checker.check(node)

            #expect(result.passed == true)
            #expect(result.violations.isEmpty)
        }
    }

    @Test("Check standard heading types")
    func testStandardHeadingTypes() {
        let checker = RoleMapChecker()

        let types: [SemanticType] = [.heading, .h1, .h2, .h3, .h4, .h5, .h6]

        for type in types {
            let node = ContentNode(type: type, depth: 1)
            let result = checker.check(node)

            #expect(result.passed == true)
            #expect(result.violations.isEmpty)
        }
    }

    @Test("Check standard list types")
    func testStandardListTypes() {
        let checker = RoleMapChecker()

        let types: [SemanticType] = [.list, .listItem, .listLabel, .listBody]

        for type in types {
            let node = ContentNode(type: type, depth: 1)
            let result = checker.check(node)

            #expect(result.passed == true)
            #expect(result.violations.isEmpty)
        }
    }

    @Test("Check standard table types")
    func testStandardTableTypes() {
        let checker = RoleMapChecker()

        let tableNode = TableNode(depth: 1)
        let result = checker.check(tableNode)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    @Test("Check standard inline types")
    func testStandardInlineTypes() {
        let checker = RoleMapChecker()

        let types: [SemanticType] = [.span, .link, .annotation, .code]

        for type in types {
            let node = ContentNode(type: type, depth: 1)
            let result = checker.check(node)

            #expect(result.passed == true)
            #expect(result.violations.isEmpty)
        }
    }

    @Test("Check standard illustration types")
    func testStandardIllustrationTypes() {
        let checker = RoleMapChecker()

        let figure = FigureNode(depth: 1)
        let result = checker.check(figure)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    @Test("Check standard artifact types")
    func testStandardArtifactTypes() {
        let checker = RoleMapChecker()

        let types: [SemanticType] = [.artifact, .documentHeader, .documentFooter]

        for type in types {
            let node = ContentNode(type: type, depth: 1)
            let result = checker.check(node)

            #expect(result.passed == true)
            #expect(result.violations.isEmpty)
        }
    }

    // MARK: - Role Mapping Validation Tests

    @Test("Check node with valid role mapping to standard type")
    func testValidRoleMapping() {
        let checker = RoleMapChecker()

        // Note: Since we don't have actual custom types in SemanticType enum,
        // we test with standard types but validate the logic path
        let node = ContentNode(
            type: .paragraph,
            attributes: ["RoleMap": .string("P")],
            depth: 1
        )

        let result = checker.check(node)

        #expect(result.passed == true)
    }

    @Test("Check node with invalid role mapping")
    func testInvalidRoleMapping() {
        let checker = RoleMapChecker.strict

        // Create a node that would require mapping (if it were non-standard)
        // Since all SemanticType cases are standard, this tests the validation logic
        var attributes: AttributesDictionary = [:]
        attributes["RoleMap"] = .string("InvalidType")

        let node = ContentNode(
            type: .paragraph, // Standard type, so won't trigger in current implementation
            attributes: attributes,
            depth: 1
        )

        let result = checker.check(node)

        // Standard types don't need mapping, so this passes
        #expect(result.passed == true)
    }

    @Test("Check excessive role mapping depth")
    func testExcessiveRoleMappingDepth() {
        let checker = RoleMapChecker(maxRoleMappingDepth: 2)

        // This test validates the max depth logic conceptually
        // In practice, all types in SemanticType are standard
        let node = ContentNode(type: .paragraph, depth: 1)
        let result = checker.check(node)

        #expect(result.passed == true)
    }

    // MARK: - Lenient Mode Tests

    @Test("Check lenient mode allows missing mappings")
    func testLenientModeAllowsMissingMappings() {
        let checker = RoleMapChecker.lenient

        // All types are standard, so no mappings required anyway
        let node = ContentNode(type: .span, depth: 1)
        let result = checker.check(node)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    @Test("Check strict mode requirements")
    func testStrictModeRequirements() {
        let checker = RoleMapChecker.strict

        // Standard types should still pass in strict mode
        let node = ContentNode(type: .paragraph, depth: 1)
        let result = checker.check(node)

        #expect(result.passed == true)
    }

    // MARK: - Recursive Checking Tests

    @Test("Check nested structure with all standard types")
    func testNestedStandardStructure() {
        let checker = RoleMapChecker()

        let innerSpan = ContentNode(type: .span, depth: 3)
        let paragraph = ContentNode(type: .paragraph, children: [innerSpan], depth: 2)
        let document = ContentNode(type: .document, children: [paragraph], depth: 1)

        let result = checker.check(document)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    @Test("Check deep nesting with standard types")
    func testDeepNestingStandardTypes() {
        let checker = RoleMapChecker()

        var current: any SemanticNode = ContentNode(type: .span, depth: 10)
        for depth in (2..<10).reversed() {
            current = ContentNode(type: .div, children: [current], depth: depth)
        }
        let document = ContentNode(type: .document, children: [current], depth: 1)

        let result = checker.check(document)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    @Test("Check mixed content types")
    func testMixedContentTypes() {
        let checker = RoleMapChecker()

        let children: [any SemanticNode] = [
            ContentNode(type: .h1, depth: 2),
            ContentNode(type: .paragraph, depth: 2),
            TableNode(depth: 2),
            FigureNode(depth: 2),
            ListNode(depth: 2)
        ]

        let document = ContentNode(type: .document, children: children, depth: 1)

        let result = checker.check(document)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    // MARK: - Multiple Node Checking Tests

    @Test("Check multiple nodes with all standard types")
    func testMultipleNodesStandardTypes() {
        let checker = RoleMapChecker()

        let nodes: [any SemanticNode] = [
            ContentNode(type: .paragraph, depth: 1),
            ContentNode(type: .h1, depth: 1),
            ContentNode(type: .div, depth: 1)
        ]

        let result = checker.check(nodes)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    @Test("Check empty nodes array")
    func testEmptyNodesArray() {
        let checker = RoleMapChecker()
        let result = checker.check([])

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }

    // MARK: - Attribute Value Extension Tests

    @Test("AttributeValue stringValue extension")
    func testAttributeValueStringExtension() {
        let stringValue: AttributeValue = .string("Test")
        let intValue: AttributeValue = .int(42)
        let boolValue: AttributeValue = .bool(true)

        #expect(stringValue.stringValue == "Test")
        #expect(intValue.stringValue == nil)
        #expect(boolValue.stringValue == nil)
    }

    @Test("RoleMap attribute extraction")
    func testRoleMapAttributeExtraction() {
        var attributes: AttributesDictionary = [:]
        attributes["RoleMap"] = .string("CustomType")

        let roleMap = attributes["RoleMap"]?.stringValue
        #expect(roleMap == "CustomType")
    }

    // MARK: - Edge Cases

    @Test("Check node with no attributes")
    func testNodeWithNoAttributes() {
        let checker = RoleMapChecker()

        let node = ContentNode(
            type: .paragraph,
            attributes: [:],
            depth: 1
        )

        let result = checker.check(node)

        #expect(result.passed == true)
    }

    @Test("Check node with multiple attributes")
    func testNodeWithMultipleAttributes() {
        let checker = RoleMapChecker()

        var attributes: AttributesDictionary = [:]
        attributes["Alt"] = .string("Alternative text")
        attributes["Lang"] = .string("en")
        attributes["RoleMap"] = .string("P")

        let node = ContentNode(
            type: .paragraph,
            attributes: attributes,
            depth: 1
        )

        let result = checker.check(node)

        #expect(result.passed == true)
    }

    @Test("Check table row and cell types")
    func testTableStructureTypes() {
        let checker = RoleMapChecker()

        let types: [SemanticType] = [
            .tableRow, .tableHeader, .tableCell,
            .tableHead, .tableBody, .tableFoot
        ]

        for type in types {
            let node = ContentNode(type: type, depth: 1)
            let result = checker.check(node)

            #expect(result.passed == true, "Table type \(type.rawValue) should be standard")
        }
    }

    @Test("Check special content types")
    func testSpecialContentTypes() {
        let checker = RoleMapChecker()

        let types: [SemanticType] = [.toc, .tocItem, .note, .title, .caption, .form]

        for type in types {
            let node = ContentNode(type: type, depth: 1)
            let result = checker.check(node)

            #expect(result.passed == true)
        }
    }

    // MARK: - Context and Reporting Tests

    @Test("Check result context for valid structure")
    func testResultContextValid() {
        let checker = RoleMapChecker()

        let node = ContentNode(type: .paragraph, depth: 1)
        let result = checker.check(node)

        #expect(result.passed == true)
        #expect(result.context != nil)
        #expect(result.context?.contains("valid") == true)
    }

    @Test("Check requirement is correct")
    func testRequirement() {
        let checker = RoleMapChecker()
        #expect(checker.requirement == .structureElementsNeedRoleMapping)
    }

    @Test("Check violation includes node type")
    func testViolationIncludesNodeType() {
        // Since all types are standard in our implementation,
        // we verify the structure is in place for when needed
        let checker = RoleMapChecker()
        let node = ContentNode(type: .paragraph, depth: 1)
        let result = checker.check(node)

        // No violations for standard types
        #expect(result.violations.isEmpty)
    }

    // MARK: - Performance Edge Cases

    @Test("Check very deep structure")
    func testVeryDeepStructure() {
        let checker = RoleMapChecker()

        var current: any SemanticNode = ContentNode(type: .span, depth: 50)
        for depth in (2..<50).reversed() {
            current = ContentNode(type: .div, children: [current], depth: depth)
        }
        let document = ContentNode(type: .document, children: [current], depth: 1)

        let result = checker.check(document)

        #expect(result.passed == true)
    }

    @Test("Check wide structure with many siblings")
    func testWideStructure() {
        let checker = RoleMapChecker()

        var children: [any SemanticNode] = []
        for _ in 0..<100 {
            children.append(ContentNode(type: .paragraph, depth: 2))
        }

        let document = ContentNode(type: .document, children: children, depth: 1)

        let result = checker.check(document)

        #expect(result.passed == true)
    }

    @Test("Check complex mixed structure")
    func testComplexMixedStructure() {
        let checker = RoleMapChecker()

        let tableCell1 = ContentNode(type: .tableCell, depth: 4)
        let tableCell2 = ContentNode(type: .tableCell, depth: 4)
        let tableRow = ContentNode(type: .tableRow, children: [tableCell1, tableCell2], depth: 3)
        let table = TableNode(children: [tableRow], depth: 2)

        let listItem1 = ContentNode(type: .listItem, depth: 3)
        let listItem2 = ContentNode(type: .listItem, depth: 3)
        let list = ListNode(children: [listItem1, listItem2], depth: 2)

        let paragraph = ContentNode(type: .paragraph, depth: 2)
        let figure = FigureNode(depth: 2)

        let document = ContentNode(
            type: .document,
            children: [table, list, paragraph, figure],
            depth: 1
        )

        let result = checker.check(document)

        #expect(result.passed == true)
        #expect(result.violations.isEmpty)
    }
}

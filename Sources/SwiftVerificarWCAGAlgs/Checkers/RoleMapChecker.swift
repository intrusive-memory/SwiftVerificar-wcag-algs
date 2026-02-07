import Foundation

/// Validates that structure elements have appropriate role mappings.
///
/// PDF/UA requires all structure elements to have a role that maps to
/// a standard structure type. This checker validates:
/// - All structure elements use standard types or have role mappings
/// - Role mappings are valid and point to standard types
/// - No circular role mappings exist
/// - Custom roles are properly defined
///
/// ## PDF/UA Requirements
///
/// - **7.2**: Structure elements shall use standard structure types
///   or have a RoleMap entry mapping to a standard type
/// - Custom structure types must be mapped to standard types
/// - The mapping chain must eventually reach a standard type
///
/// ## Standard Structure Types
///
/// PDF/UA recognizes these standard types (PDF 1.7 spec):
/// - Document-level: Document, Part, Art, Sect, Div
/// - Paragraph-level: P, H, H1-H6
/// - List: L, LI, Lbl, LBody
/// - Table: Table, TR, TH, TD, THead, TBody, TFoot
/// - Inline: Span, Quote, Note, Reference, BibEntry, Code, Link, Annot
/// - Illustration: Figure, Formula, Form
/// - Artifact: Header, Footer, Watermark, Artifact
///
/// ## Usage
///
/// ```swift
/// let checker = RoleMapChecker()
/// let result = checker.check(node)
/// if !result.passed {
///     for violation in result.violations {
///         print(violation.description)
///     }
/// }
/// ```
///
/// - Note: Ported from veraPDF-wcag-algs role mapping validation logic.
public struct RoleMapChecker: PDFUAChecker {

    /// The PDF/UA requirement validated by this checker.
    public let requirement: PDFUARequirement = .structureElementsNeedRoleMapping

    /// Maximum depth for role mapping chains to prevent infinite loops.
    public let maxRoleMappingDepth: Int

    /// Whether to require explicit role mappings for all custom types.
    public let requireExplicitMappings: Bool

    /// Creates a new role map checker.
    ///
    /// - Parameters:
    ///   - maxRoleMappingDepth: Maximum role mapping chain depth (default: 10).
    ///   - requireExplicitMappings: Require mappings for custom types (default: true).
    public init(
        maxRoleMappingDepth: Int = 10,
        requireExplicitMappings: Bool = true
    ) {
        self.maxRoleMappingDepth = maxRoleMappingDepth
        self.requireExplicitMappings = requireExplicitMappings
    }

    /// Checks if a semantic node has valid role mapping.
    ///
    /// - Parameter node: The semantic node to check.
    /// - Returns: A check result indicating role mapping validity.
    public func check(_ node: any SemanticNode) -> PDFUACheckResult {
        var violations: [PDFUAViolation] = []

        // Check this node
        violations.append(contentsOf: checkNodeRoleMapping(node))

        // Recursively check all children
        for child in node.children {
            let childResult = check(child)
            violations.append(contentsOf: childResult.violations)
        }

        // Return result
        if violations.isEmpty {
            return .passing(
                requirement: requirement,
                context: "All structure elements have valid role mappings"
            )
        } else {
            return .failing(
                requirement: requirement,
                violations: violations,
                context: "Found \(violations.count) role mapping violation(s)"
            )
        }
    }

    // MARK: - Private Helper Methods

    /// Checks role mapping for a single node.
    private func checkNodeRoleMapping(_ node: any SemanticNode) -> [PDFUAViolation] {
        var violations: [PDFUAViolation] = []

        // Check if type is a standard type
        if isStandardType(node.type) {
            // Standard types don't need role mapping
            return []
        }

        // For non-standard types, check for role mapping
        if requireExplicitMappings {
            guard let roleMapping = node.attributes["RoleMap"]?.stringValue else {
                violations.append(
                    PDFUAViolation(
                        nodeId: node.id,
                        nodeType: node.type,
                        description: "Non-standard structure type '\(node.type.rawValue)' requires a RoleMap entry",
                        severity: .error,
                        location: node.boundingBox
                    )
                )
                return violations
            }

            // Validate the role mapping
            violations.append(contentsOf: validateRoleMapping(
                node: node,
                roleMapping: roleMapping,
                depth: 0
            ))
        }

        return violations
    }

    /// Validates a role mapping chain.
    private func validateRoleMapping(
        node: any SemanticNode,
        roleMapping: String,
        depth: Int
    ) -> [PDFUAViolation] {
        var violations: [PDFUAViolation] = []

        // Check for excessive depth (potential circular mapping)
        if depth >= maxRoleMappingDepth {
            violations.append(
                PDFUAViolation(
                    nodeId: node.id,
                    nodeType: node.type,
                    description: "Role mapping chain exceeds maximum depth (\(maxRoleMappingDepth)), possible circular reference",
                    severity: .error,
                    location: node.boundingBox
                )
            )
            return violations
        }

        // Try to parse the mapped type
        guard let mappedType = SemanticType(rawValue: roleMapping) else {
            violations.append(
                PDFUAViolation(
                    nodeId: node.id,
                    nodeType: node.type,
                    description: "RoleMap entry '\(roleMapping)' is not a valid structure type",
                    severity: .error,
                    location: node.boundingBox
                )
            )
            return violations
        }

        // Check if mapped type is standard
        if isStandardType(mappedType) {
            // Valid mapping to standard type
            return []
        }

        // If mapped type is also non-standard, it should have its own mapping
        // This would require access to the document-level RoleMap, which we
        // don't have at the node level. For now, warn about this.
        violations.append(
            PDFUAViolation(
                nodeId: node.id,
                nodeType: node.type,
                description: "RoleMap entry '\(roleMapping)' maps to another non-standard type",
                severity: .warning,
                location: node.boundingBox
            )
        )

        return violations
    }

    /// Checks if a semantic type is a standard PDF structure type.
    private func isStandardType(_ type: SemanticType) -> Bool {
        // Standard types from PDF 1.7 specification (Table 10.20)
        let standardTypes: Set<SemanticType> = [
            // Grouping elements
            .document, .part, .div, .article, .section,

            // Block-level structure elements
            .paragraph, .blockQuote, .index,

            // Headings
            .heading, .h1, .h2, .h3, .h4, .h5, .h6,

            // Lists
            .list, .listItem, .listLabel, .listBody,

            // Tables
            .table, .tableRow, .tableHeader, .tableCell,
            .tableHead, .tableBody, .tableFoot,

            // Inline-level structure elements
            .span, .link, .annotation, .code, .quote, .reference,

            // Illustration elements
            .figure, .caption, .form, .formula,

            // Special elements
            .toc, .tocItem, .note, .title, .bibliography,

            // Ruby and Warichu
            .ruby, .rubyBase, .rubyText, .rubyPunctuation,
            .warichu, .warichuText, .warichuPunctuation,

            // Artifacts
            .artifact, .documentHeader, .documentFooter, .nonStruct, .privateElement
        ]

        return standardTypes.contains(type)
    }

    /// Checks if a node requires a role mapping.
    private func requiresRoleMapping(_ node: any SemanticNode) -> Bool {
        // Standard types don't need role mapping
        if isStandardType(node.type) {
            return false
        }

        // Non-standard types need role mapping if required
        return requireExplicitMappings
    }

    /// Gets all nodes that require role mappings.
    private func getNodesRequiringMapping(_ node: any SemanticNode) -> [any SemanticNode] {
        var nodes: [any SemanticNode] = []

        if requiresRoleMapping(node) {
            nodes.append(node)
        }

        for child in node.children {
            nodes.append(contentsOf: getNodesRequiringMapping(child))
        }

        return nodes
    }
}

// MARK: - Convenience Initializers

extension RoleMapChecker {

    /// Creates a strict role map checker with all validations enabled.
    public static var strict: RoleMapChecker {
        RoleMapChecker(
            maxRoleMappingDepth: 10,
            requireExplicitMappings: true
        )
    }

    /// Creates a lenient role map checker with relaxed requirements.
    public static var lenient: RoleMapChecker {
        RoleMapChecker(
            maxRoleMappingDepth: 20,
            requireExplicitMappings: false
        )
    }

    /// Creates a basic role map checker for standard types only.
    public static var basic: RoleMapChecker {
        RoleMapChecker(
            maxRoleMappingDepth: 5,
            requireExplicitMappings: false
        )
    }
}

// AttributeValue extension for stringValue is already defined in SemanticNode.swift

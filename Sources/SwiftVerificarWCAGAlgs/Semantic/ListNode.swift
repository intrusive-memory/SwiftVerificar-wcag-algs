import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// The type of list based on its label pattern.
///
/// Determines whether a list is ordered (numbered) or unordered (bulleted),
/// and for ordered lists, the numbering system used.
public enum ListKind: String, Sendable, Codable, CaseIterable {
    /// An unordered list with bullets, dashes, or other markers.
    case unordered

    /// An ordered list with Arabic numerals (1, 2, 3...).
    case orderedArabic

    /// An ordered list with uppercase Roman numerals (I, II, III...).
    case orderedRomanUpper

    /// An ordered list with lowercase Roman numerals (i, ii, iii...).
    case orderedRomanLower

    /// An ordered list with uppercase letters (A, B, C...).
    case orderedAlphaUpper

    /// An ordered list with lowercase letters (a, b, c...).
    case orderedAlphaLower

    /// An ordered list with circled numbers.
    case orderedCircled

    /// List type could not be determined.
    case unknown

    /// Whether this is an ordered list type.
    public var isOrdered: Bool {
        switch self {
        case .unordered, .unknown:
            return false
        default:
            return true
        }
    }

    /// Whether this is an unordered list type.
    public var isUnordered: Bool {
        self == .unordered
    }
}

/// A semantic node representing a list in the document structure.
///
/// `ListNode` is specialized for list content, providing properties and
/// methods for analyzing list structure, label patterns, and nesting.
/// It supports both ordered (numbered) and unordered (bulleted) lists.
///
/// ## WCAG Requirements
///
/// Lists have specific accessibility requirements:
/// - List items (LI) must contain label (Lbl) and body (LBody) elements
/// - Labels should follow a consistent pattern
/// - Nesting should be logical and not excessively deep
///
/// ## Structure
///
/// A list (L) contains:
/// - `LI`: List items
///   - `Lbl`: The label/marker (bullet, number)
///   - `LBody`: The content of the item
///
/// Lists can be nested: an LBody may contain another L element.
///
/// - Note: Ported from veraPDF-wcag-algs `SemanticList` Java class.
public struct ListNode: SemanticNode, Sendable, Hashable {

    // MARK: - SemanticNode Conformance

    /// The unique identifier for this node.
    public let id: UUID

    /// The semantic type is always `.list` for ListNode.
    public var type: SemanticType { .list }

    /// The bounding box of this list.
    public let boundingBox: BoundingBox?

    /// The child nodes (LI elements and nested content).
    public let children: [any SemanticNode]

    /// The attributes dictionary from the PDF structure element.
    public let attributes: AttributesDictionary

    /// The depth of this node in the structure tree.
    public let depth: Int

    /// Error codes detected during validation.
    public var errorCodes: Set<SemanticErrorCode>

    // MARK: - List-Specific Properties

    /// The detected kind of list (ordered/unordered and numbering style).
    public let listKind: ListKind

    /// The starting number for ordered lists.
    ///
    /// For example, if a list starts at "3.", this would be 3.
    public let startNumber: Int?

    /// The nesting level of this list (0 for top-level lists).
    public let nestingLevel: Int

    // MARK: - Initialization

    /// Creates a new list node with all properties.
    ///
    /// - Parameters:
    ///   - id: The unique identifier (defaults to a new UUID).
    ///   - boundingBox: The spatial location, if any.
    ///   - children: The child nodes (list items).
    ///   - attributes: The PDF structure element attributes.
    ///   - depth: The depth in the structure tree.
    ///   - errorCodes: Initial error codes (defaults to empty).
    ///   - listKind: The detected list kind.
    ///   - startNumber: The starting number for ordered lists.
    ///   - nestingLevel: The nesting level (0 for top-level).
    public init(
        id: UUID = UUID(),
        boundingBox: BoundingBox? = nil,
        children: [any SemanticNode] = [],
        attributes: AttributesDictionary = [:],
        depth: Int = 1,
        errorCodes: Set<SemanticErrorCode> = [],
        listKind: ListKind = .unknown,
        startNumber: Int? = nil,
        nestingLevel: Int = 0
    ) {
        self.id = id
        self.boundingBox = boundingBox
        self.children = children
        self.attributes = attributes
        self.depth = depth
        self.errorCodes = errorCodes
        self.listKind = listKind
        self.startNumber = startNumber
        self.nestingLevel = nestingLevel
    }

    /// Creates a simple list node with minimal properties.
    ///
    /// - Parameters:
    ///   - listKind: The kind of list.
    ///   - depth: The depth in the structure tree.
    public init(listKind: ListKind = .unknown, depth: Int = 1) {
        self.init(
            id: UUID(),
            boundingBox: nil,
            children: [],
            attributes: [:],
            depth: depth,
            listKind: listKind
        )
    }

    // MARK: - Item Accessors

    /// All list items (LI elements) in this list.
    public var items: [ContentNode] {
        children.compactMap { child in
            guard let content = child as? ContentNode,
                  content.type == .listItem else {
                return nil
            }
            return content
        }
    }

    /// The number of list items.
    public var itemCount: Int {
        items.count
    }

    /// Whether this list has any items.
    public var hasItems: Bool {
        !items.isEmpty
    }

    /// Gets the label node (Lbl) from a list item.
    ///
    /// - Parameter item: The list item node.
    /// - Returns: The label node, if present.
    public func label(for item: ContentNode) -> ContentNode? {
        guard item.type == .listItem else { return nil }
        return item.children.compactMap { $0 as? ContentNode }
            .first { $0.type == .listLabel }
    }

    /// Gets the body node (LBody) from a list item.
    ///
    /// - Parameter item: The list item node.
    /// - Returns: The body node, if present.
    public func body(for item: ContentNode) -> ContentNode? {
        guard item.type == .listItem else { return nil }
        return item.children.compactMap { $0 as? ContentNode }
            .first { $0.type == .listBody }
    }

    /// All label nodes in this list.
    public var labels: [ContentNode] {
        items.compactMap { label(for: $0) }
    }

    /// All body nodes in this list.
    public var bodies: [ContentNode] {
        items.compactMap { body(for: $0) }
    }

    /// The label texts in order.
    public var labelTexts: [String] {
        labels.map(\.text)
    }

    // MARK: - Structure Analysis

    /// Whether all list items have labels.
    public var allItemsHaveLabels: Bool {
        items.allSatisfy { label(for: $0) != nil }
    }

    /// Whether all list items have bodies.
    public var allItemsHaveBodies: Bool {
        items.allSatisfy { body(for: $0) != nil }
    }

    /// Whether this list has proper structure (all items have label and body).
    public var hasProperStructure: Bool {
        allItemsHaveLabels && allItemsHaveBodies
    }

    /// Items that are missing labels.
    public var itemsMissingLabels: [ContentNode] {
        items.filter { label(for: $0) == nil }
    }

    /// Items that are missing bodies.
    public var itemsMissingBodies: [ContentNode] {
        items.filter { body(for: $0) == nil }
    }

    /// Whether this is an ordered list.
    public var isOrdered: Bool {
        listKind.isOrdered
    }

    /// Whether this is an unordered list.
    public var isUnordered: Bool {
        listKind.isUnordered
    }

    // MARK: - Nested Lists

    /// Nested lists found within list item bodies.
    public var nestedLists: [ListNode] {
        var nested: [ListNode] = []
        for item in items {
            if let bodyNode = body(for: item) {
                for child in bodyNode.children {
                    if let listNode = child as? ListNode {
                        nested.append(listNode)
                    }
                }
            }
        }
        return nested
    }

    /// Whether this list contains nested lists.
    public var hasNestedLists: Bool {
        !nestedLists.isEmpty
    }

    /// The maximum nesting depth in this list's subtree.
    public var maxNestedDepth: Int {
        if nestedLists.isEmpty {
            return nestingLevel
        }
        return nestedLists.map(\.maxNestedDepth).max() ?? nestingLevel
    }

    // MARK: - Validation

    /// Performs structural validation on this list.
    ///
    /// Checks for:
    /// - Missing labels or bodies
    /// - Inconsistent label patterns
    /// - Excessive nesting depth
    ///
    /// - Returns: A set of error codes for any issues found.
    public func validateStructure() -> Set<SemanticErrorCode> {
        var errors = Set<SemanticErrorCode>()

        // Check for missing labels
        if !itemsMissingLabels.isEmpty {
            errors.insert(.listItemMissingLabel)
        }

        // Check for missing bodies
        if !itemsMissingBodies.isEmpty {
            errors.insert(.listItemMissingBody)
        }

        // Check for excessive nesting
        if nestingLevel > 5 {
            errors.insert(.listNestingTooDeep)
        }

        return errors
    }

    /// Creates a new list node with a detected list kind.
    ///
    /// - Parameters:
    ///   - kind: The detected list kind.
    ///   - start: The starting number for ordered lists.
    /// - Returns: A new list node with the kind set.
    public func withDetectedKind(
        _ kind: ListKind,
        startNumber start: Int? = nil
    ) -> ListNode {
        ListNode(
            id: id,
            boundingBox: boundingBox,
            children: children,
            attributes: attributes,
            depth: depth,
            errorCodes: errorCodes,
            listKind: kind,
            startNumber: start,
            nestingLevel: nestingLevel
        )
    }

    /// Creates a new list node with updated nesting level.
    ///
    /// - Parameter level: The new nesting level.
    /// - Returns: A new list node with the nesting level set.
    public func withNestingLevel(_ level: Int) -> ListNode {
        ListNode(
            id: id,
            boundingBox: boundingBox,
            children: children,
            attributes: attributes,
            depth: depth,
            errorCodes: errorCodes,
            listKind: listKind,
            startNumber: startNumber,
            nestingLevel: level
        )
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Equatable

    public static func == (lhs: ListNode, rhs: ListNode) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable

extension ListNode: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case boundingBox
        case attributes
        case depth
        case errorCodes
        case listKind
        case startNumber
        case nestingLevel
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.boundingBox = try container.decodeIfPresent(BoundingBox.self, forKey: .boundingBox)
        self.attributes = try container.decode(AttributesDictionary.self, forKey: .attributes)
        self.depth = try container.decode(Int.self, forKey: .depth)
        self.errorCodes = try container.decode(Set<SemanticErrorCode>.self, forKey: .errorCodes)
        self.listKind = try container.decode(ListKind.self, forKey: .listKind)
        self.startNumber = try container.decodeIfPresent(Int.self, forKey: .startNumber)
        self.nestingLevel = try container.decode(Int.self, forKey: .nestingLevel)
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
        try container.encode(listKind, forKey: .listKind)
        try container.encodeIfPresent(startNumber, forKey: .startNumber)
        try container.encode(nestingLevel, forKey: .nestingLevel)
    }
}

// MARK: - CustomStringConvertible

extension ListNode: CustomStringConvertible {

    public var description: String {
        let indent = String(repeating: "  ", count: depth)
        let kindStr = listKind == .unknown ? "" : " [\(listKind.rawValue)]"
        let nestedStr = nestingLevel > 0 ? " (level \(nestingLevel))" : ""
        return "\(indent)<List>\(itemCount) items\(kindStr)\(nestedStr)</List>"
    }
}

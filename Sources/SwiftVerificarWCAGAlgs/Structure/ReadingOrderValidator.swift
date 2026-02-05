import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Result of reading order validation.
///
/// Contains findings from analyzing the reading order of a PDF
/// document's structure tree for WCAG compliance.
///
/// - Note: WCAG 1.3.2 (Meaningful Sequence) requires content to be
///   presented in a meaningful sequence that affects the meaning
///   conveyed to the user.
public struct ReadingOrderValidationResult: Sendable, Equatable {

    /// Issues detected during reading order validation.
    public let issues: [ReadingOrderIssue]

    /// The total number of nodes checked.
    public let totalNodeCount: Int

    /// The number of pages analyzed.
    public let pageCount: Int

    /// Whether the reading order is valid.
    public var isValid: Bool {
        issues.isEmpty
    }

    /// Issues grouped by severity.
    public var issuesBySeverity: [ReadingOrderIssue.Severity: [ReadingOrderIssue]] {
        Dictionary(grouping: issues) { $0.severity }
    }

    /// The number of critical issues found.
    public var criticalIssueCount: Int {
        issues.filter { $0.severity == .critical }.count
    }

    /// The number of warning issues found.
    public var warningIssueCount: Int {
        issues.filter { $0.severity == .warning }.count
    }

    /// Creates a new reading order validation result.
    ///
    /// - Parameters:
    ///   - issues: The validation issues found.
    ///   - totalNodeCount: The total number of nodes checked.
    ///   - pageCount: The number of pages analyzed.
    public init(
        issues: [ReadingOrderIssue],
        totalNodeCount: Int,
        pageCount: Int
    ) {
        self.issues = issues
        self.totalNodeCount = totalNodeCount
        self.pageCount = pageCount
    }
}

/// An issue found during reading order validation.
///
/// Records problems with the logical reading sequence that may affect
/// accessibility and comprehension.
public struct ReadingOrderIssue: Sendable, Equatable, Identifiable {

    /// Severity level of the reading order issue.
    public enum Severity: String, Sendable, Equatable, CaseIterable {
        /// Critical issue that significantly impacts accessibility.
        case critical

        /// Warning about potential reading order problems.
        case warning

        /// Informational note about reading order.
        case info
    }

    /// The type of reading order issue.
    public enum IssueType: String, Sendable, Equatable, CaseIterable {
        /// Content appears out of logical order.
        case outOfOrder

        /// Content positioned incorrectly relative to structure.
        case mispositioned

        /// Content overlaps in reading sequence.
        case overlapping

        /// Content in reverse reading direction.
        case reverseDirection

        /// Content significantly out of vertical alignment.
        case verticalMisalignment

        /// Content jumps across columns incorrectly.
        case columnJump

        /// Content reading order doesn't match visual order.
        case visualMismatch
    }

    /// Unique identifier for this issue instance.
    public let id: UUID

    /// The type of issue.
    public let type: IssueType

    /// The severity of the issue.
    public let severity: Severity

    /// The ID of the first node involved in the issue.
    public let nodeId1: UUID

    /// The ID of the second node involved in the issue (if applicable).
    public let nodeId2: UUID?

    /// A human-readable description of the issue.
    public let message: String

    /// The page index where the issue occurred.
    public let pageIndex: Int

    /// Additional context about the issue.
    public let context: [String: String]

    /// Creates a new reading order issue.
    ///
    /// - Parameters:
    ///   - type: The type of issue.
    ///   - severity: The severity level.
    ///   - nodeId1: The first affected node ID.
    ///   - nodeId2: The second affected node ID (optional).
    ///   - message: A description of the issue.
    ///   - pageIndex: The page where the issue occurred.
    ///   - context: Additional contextual information.
    public init(
        type: IssueType,
        severity: Severity,
        nodeId1: UUID,
        nodeId2: UUID? = nil,
        message: String,
        pageIndex: Int,
        context: [String: String] = [:]
    ) {
        self.id = UUID()
        self.type = type
        self.severity = severity
        self.nodeId1 = nodeId1
        self.nodeId2 = nodeId2
        self.message = message
        self.pageIndex = pageIndex
        self.context = context
    }
}

/// Validates the reading order of a PDF document's structure tree.
///
/// The `ReadingOrderValidator` checks that the logical structure tree
/// order matches the expected visual reading order, ensuring compliance
/// with WCAG 1.3.2 (Meaningful Sequence).
///
/// ## Validation Checks
///
/// - **Spatial ordering**: Content should flow top-to-bottom, left-to-right
///   (or right-to-left for RTL languages)
/// - **Column detection**: Multi-column layouts should read within columns
///   before jumping to the next column
/// - **Visual-logical alignment**: The structure tree order should match
///   the visual presentation order
/// - **Overlap detection**: Content should not overlap in a confusing way
///
/// ## Example Usage
///
/// ```swift
/// let validator = ReadingOrderValidator()
/// let result = validator.validate(rootNode)
///
/// if result.isValid {
///     print("Reading order is valid")
/// } else {
///     print("Found \(result.issues.count) reading order issues")
///     for issue in result.issues {
///         print("[\(issue.severity)] \(issue.message)")
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// `ReadingOrderValidator` is `Sendable` and can be used concurrently.
///
/// - Note: Ported from veraPDF-wcag-algs reading order validation concepts.
public struct ReadingOrderValidator: Sendable {

    /// Options for reading order validation.
    public struct Options: Sendable, Equatable {

        /// The reading direction (LTR or RTL).
        public let readingDirection: ReadingDirection

        /// Whether to validate column order.
        public let validateColumns: Bool

        /// Whether to check for overlapping content.
        public let checkOverlaps: Bool

        /// The tolerance for vertical alignment (in points).
        public let verticalTolerance: CGFloat

        /// The tolerance for horizontal position (in points).
        public let horizontalTolerance: CGFloat

        /// Minimum overlap percentage to trigger a warning (0.0-1.0).
        public let overlapThreshold: CGFloat

        /// Creates default reading order validation options.
        public init(
            readingDirection: ReadingDirection = .leftToRight,
            validateColumns: Bool = true,
            checkOverlaps: Bool = true,
            verticalTolerance: CGFloat = 5.0,
            horizontalTolerance: CGFloat = 10.0,
            overlapThreshold: CGFloat = 0.1
        ) {
            self.readingDirection = readingDirection
            self.validateColumns = validateColumns
            self.checkOverlaps = checkOverlaps
            self.verticalTolerance = verticalTolerance
            self.horizontalTolerance = horizontalTolerance
            self.overlapThreshold = overlapThreshold
        }

        /// Standard left-to-right validation.
        public static let standard = Options()

        /// Right-to-left validation.
        public static let rightToLeft = Options(readingDirection: .rightToLeft)

        /// Strict validation with lower tolerances.
        public static let strict = Options(
            verticalTolerance: 2.0,
            horizontalTolerance: 5.0,
            overlapThreshold: 0.05
        )
    }

    /// Reading direction for text flow.
    public enum ReadingDirection: String, Sendable, Equatable {
        /// Left-to-right reading (English, etc.).
        case leftToRight

        /// Right-to-left reading (Arabic, Hebrew, etc.).
        case rightToLeft
    }

    /// Validation options.
    public let options: Options

    /// Creates a new validator with the specified options.
    ///
    /// - Parameter options: Validation configuration options.
    public init(options: Options = .standard) {
        self.options = options
    }

    /// Validates the reading order of a structure tree.
    ///
    /// - Parameter root: The root node of the structure tree.
    /// - Returns: The validation result containing any issues found.
    public func validate(_ root: any SemanticNode) -> ReadingOrderValidationResult {
        var issues: [ReadingOrderIssue] = []
        var nodeCount = 0
        var pageIndices: Set<Int> = []

        // Collect all nodes with bounding boxes, grouped by page
        let nodesByPage = collectNodesByPage(root)

        for (pageIndex, nodes) in nodesByPage.sorted(by: { $0.key < $1.key }) {
            pageIndices.insert(pageIndex)

            // Validate reading order within this page
            issues.append(contentsOf: validatePageReadingOrder(
                nodes: nodes,
                pageIndex: pageIndex
            ))

            nodeCount += nodes.count
        }

        return ReadingOrderValidationResult(
            issues: issues,
            totalNodeCount: nodeCount,
            pageCount: pageIndices.count
        )
    }

    // MARK: - Private Validation Methods

    private func collectNodesByPage(
        _ root: any SemanticNode
    ) -> [Int: [(node: any SemanticNode, box: BoundingBox)]] {
        var result: [Int: [(node: any SemanticNode, box: BoundingBox)]] = [:]

        func collect(_ node: any SemanticNode) {
            if let box = node.boundingBox {
                result[box.pageIndex, default: []].append((node, box))
            }

            for child in node.children {
                collect(child)
            }
        }

        collect(root)
        return result
    }

    private func validatePageReadingOrder(
        nodes: [(node: any SemanticNode, box: BoundingBox)],
        pageIndex: Int
    ) -> [ReadingOrderIssue] {
        guard nodes.count > 1 else { return [] }

        var issues: [ReadingOrderIssue] = []

        // Validate sequential order
        for i in 0..<(nodes.count - 1) {
            let current = nodes[i]
            let next = nodes[i + 1]

            // Check for logical spatial ordering
            if let issue = checkSpatialOrder(
                current: current,
                next: next,
                pageIndex: pageIndex
            ) {
                issues.append(issue)
            }

            // Check for overlaps
            if options.checkOverlaps,
               let issue = checkOverlap(
                   current: current,
                   next: next,
                   pageIndex: pageIndex
               ) {
                issues.append(issue)
            }
        }

        // Check for column ordering if enabled
        if options.validateColumns {
            issues.append(contentsOf: validateColumnOrder(
                nodes: nodes,
                pageIndex: pageIndex
            ))
        }

        return issues
    }

    private func checkSpatialOrder(
        current: (node: any SemanticNode, box: BoundingBox),
        next: (node: any SemanticNode, box: BoundingBox),
        pageIndex: Int
    ) -> ReadingOrderIssue? {
        let currentBox = current.box.rect
        let nextBox = next.box.rect

        // In PDF coordinates, Y increases upward from bottom-left origin
        // Reading order is top to bottom, so we expect:
        // - current.maxY (top of current) >= next.maxY (top of next)
        // If next.maxY > current.minY, next is significantly above current (wrong order)

        let verticalGap = nextBox.maxY - currentBox.minY
        let horizontalDistance: CGFloat

        switch options.readingDirection {
        case .leftToRight:
            horizontalDistance = nextBox.minX - currentBox.maxX
        case .rightToLeft:
            horizontalDistance = currentBox.minX - nextBox.maxX
        }

        // If next is significantly above current (next.maxY > current.minY + tolerance), it's out of order
        if verticalGap > options.verticalTolerance {
            return ReadingOrderIssue(
                type: .outOfOrder,
                severity: .critical,
                nodeId1: current.node.id,
                nodeId2: next.node.id,
                message: "Content appears out of vertical order",
                pageIndex: pageIndex,
                context: [
                    "verticalGap": String(format: "%.2f", verticalGap),
                    "currentBottom": String(format: "%.2f", currentBox.minY),
                    "nextTop": String(format: "%.2f", nextBox.maxY)
                ]
            )
        }

        // Check if roughly same vertical position (same line)
        let sameLineThreshold = min(currentBox.height, nextBox.height) * 0.5
        let verticalOverlap = min(currentBox.maxY, nextBox.maxY)
            - max(currentBox.minY, nextBox.minY)

        if verticalOverlap > sameLineThreshold {
            // On same line - check horizontal order
            if horizontalDistance < -options.horizontalTolerance {
                return ReadingOrderIssue(
                    type: .reverseDirection,
                    severity: .warning,
                    nodeId1: current.node.id,
                    nodeId2: next.node.id,
                    message: "Content appears in reverse reading direction",
                    pageIndex: pageIndex,
                    context: [
                        "horizontalDistance": String(format: "%.2f", horizontalDistance),
                        "readingDirection": options.readingDirection.rawValue
                    ]
                )
            }
        }

        return nil
    }

    private func checkOverlap(
        current: (node: any SemanticNode, box: BoundingBox),
        next: (node: any SemanticNode, box: BoundingBox),
        pageIndex: Int
    ) -> ReadingOrderIssue? {
        let overlapPct = current.box.overlapPercentage(with: next.box)

        if overlapPct > options.overlapThreshold {
            return ReadingOrderIssue(
                type: .overlapping,
                severity: .warning,
                nodeId1: current.node.id,
                nodeId2: next.node.id,
                message: "Content overlaps in reading sequence",
                pageIndex: pageIndex,
                context: [
                    "overlapPercentage": String(format: "%.1f%%", overlapPct * 100)
                ]
            )
        }

        return nil
    }

    private func validateColumnOrder(
        nodes: [(node: any SemanticNode, box: BoundingBox)],
        pageIndex: Int
    ) -> [ReadingOrderIssue] {
        guard nodes.count > 2 else { return [] }

        var issues: [ReadingOrderIssue] = []

        // Detect columns by clustering horizontal positions
        let columns = detectColumns(nodes: nodes)

        if columns.count > 1 {
            // Validate that reading order respects column boundaries
            for i in 0..<(nodes.count - 1) {
                let current = nodes[i]
                let next = nodes[i + 1]

                let currentColumn = findColumn(for: current.box, in: columns)
                let nextColumn = findColumn(for: next.box, in: columns)

                // Check for invalid column jumps
                if let curCol = currentColumn,
                   let nextCol = nextColumn,
                   nextCol < curCol {
                    issues.append(ReadingOrderIssue(
                        type: .columnJump,
                        severity: .warning,
                        nodeId1: current.node.id,
                        nodeId2: next.node.id,
                        message: "Reading order jumps backward across columns",
                        pageIndex: pageIndex,
                        context: [
                            "fromColumn": "\(curCol)",
                            "toColumn": "\(nextCol)"
                        ]
                    ))
                }
            }
        }

        return issues
    }

    private func detectColumns(
        nodes: [(node: any SemanticNode, box: BoundingBox)]
    ) -> [CGFloat] {
        // Simple column detection based on horizontal clustering
        let xPositions = nodes.map { $0.box.rect.minX }
        let sortedX = xPositions.sorted()

        var columns: [CGFloat] = []
        var lastX: CGFloat?

        for x in sortedX {
            if let last = lastX {
                // If gap is significant, it's a new column
                if x - last > 50.0 { // 50 points threshold for column gap
                    columns.append(x)
                }
            } else {
                columns.append(x)
            }
            lastX = x
        }

        return columns
    }

    private func findColumn(
        for box: BoundingBox,
        in columns: [CGFloat]
    ) -> Int? {
        let x = box.rect.minX

        for (index, columnX) in columns.enumerated() {
            if abs(x - columnX) < 50.0 {
                return index
            }
        }

        return columns.isEmpty ? nil : columns.count - 1
    }
}

# SwiftVerificar-wcag-algs Porting TODO

## Source Repository

**Source:** [veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs)
**Branch:** `integration`
**License:** GPLv3+ / MPLv2+ (dual-licensed)

---

## Overview

This document provides a comprehensive porting plan for converting veraPDF-wcag-algs (~140+ Java classes) to Swift. This module implements WCAG accessibility algorithms for PDF validation.

### Key Capabilities

1. **Contrast Ratio Calculation** - WCAG 2.1 luminosity and contrast formulas
2. **Structure Tree Validation** - Heading hierarchy, reading order
3. **Table Accessibility** - Header cells, cell positions, spans
4. **List Structure** - List label detection, numbering patterns
5. **TOC Validation** - Table of contents structure
6. **Semantic Analysis** - Content accumulation, figure/caption detection

### Swift Advantages to Leverage

- **CoreGraphics** for color calculations and rendering
- **PDFKit** for page rendering (contrast analysis)
- **Accelerate** framework for image processing
- **Actors** for thread-safe document state
- **Async sequences** for streaming content analysis
- **Value types** for immutable semantic nodes

---

## Phase 1: Geometry and Content Primitives

### 1.1 Geometry Types

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `BoundingBox` | `BoundingBox` (struct) | Use `CGRect` internally |
| `MultiBoundingBox` | `MultiBoundingBox` (struct) | Multi-page support |
| `Vertex` | `CGPoint` | Use stdlib |

**Swift Implementation:**
```swift
/// Bounding box for PDF content with page tracking
public struct BoundingBox: Equatable, Sendable {
    public let pageNumber: Int
    public let rect: CGRect

    public var leftX: CGFloat { rect.minX }
    public var bottomY: CGFloat { rect.minY }
    public var rightX: CGFloat { rect.maxX }
    public var topY: CGFloat { rect.maxY }
    public var width: CGFloat { rect.width }
    public var height: CGFloat { rect.height }
    public var area: CGFloat { rect.width * rect.height }

    /// Union of two bounding boxes (must be same page)
    public func union(with other: BoundingBox) -> BoundingBox? {
        guard pageNumber == other.pageNumber else { return nil }
        return BoundingBox(pageNumber: pageNumber, rect: rect.union(other.rect))
    }

    /// Intersection of two bounding boxes
    public func intersection(with other: BoundingBox) -> BoundingBox? {
        guard pageNumber == other.pageNumber,
              rect.intersects(other.rect) else { return nil }
        return BoundingBox(pageNumber: pageNumber, rect: rect.intersection(other.rect))
    }

    /// Check if this box contains another
    public func contains(_ other: BoundingBox) -> Bool {
        pageNumber == other.pageNumber && rect.contains(other.rect)
    }

    /// Overlap percentage with another box
    public func overlapPercentage(with other: BoundingBox) -> CGFloat {
        guard let intersection = intersection(with: other) else { return 0 }
        let minArea = min(area, other.area)
        guard minArea > 0 else { return 0 }
        return intersection.area / minArea
    }
}
```

### 1.2 Content Chunks

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `IChunk` (interface) | `ContentChunk` (protocol) | Base chunk protocol |
| `InfoChunk` | Part of protocol | Consolidate |
| `TextInfoChunk` | Part of `TextChunk` | Consolidate |
| `TextChunk` | `TextChunk` (struct) | Core text content |
| `TextLine` | `TextLine` (struct) | Line of text |
| `TextBlock` | `TextBlock` (struct) | Block of lines |
| `TextColumn` | `TextColumn` (struct) | Column of blocks |
| `ImageChunk` | `ImageChunk` (struct) | Image content |
| `LineChunk` | `LineChunk` (struct) | Line/path graphics |
| `LineArtChunk` | `LineArtChunk` (struct) | Vector graphics |
| `LinesCollection` | `LinesCollection` (struct) | Line collection |

**Swift Implementation:**
```swift
/// Protocol for all content chunks
public protocol ContentChunk: Sendable {
    var boundingBox: BoundingBox { get }
    var pageNumber: Int { get }
}

/// Text content chunk with full styling information
public struct TextChunk: ContentChunk, Sendable {
    public let boundingBox: BoundingBox
    public var pageNumber: Int { boundingBox.pageNumber }

    // Text content
    public let value: String
    public let symbolPositions: [CGPoint]

    // Font properties
    public let fontName: String
    public let fontSize: CGFloat
    public let fontWeight: CGFloat
    public let italicAngle: CGFloat

    // Color properties
    public let textColor: CGColor
    public let backgroundColor: CGColor?
    public let contrastRatio: CGFloat?

    // Formatting
    public let isUnderlined: Bool
    public let baseline: CGFloat
    public let slantDegree: CGFloat

    // Computed properties
    public var isItalic: Bool { abs(italicAngle) > 0 || slantDegree > 10 }
    public var isBold: Bool { fontWeight >= 600 }
    public var textType: TextType {
        if fontSize >= 18 || (fontSize >= 14 && isBold) {
            return .large
        }
        return .regular
    }
}

/// Text size classification for contrast requirements
public enum TextType: Sendable {
    case regular    // Normal text: 4.5:1 required
    case large      // Large text (18pt or 14pt bold): 3.0:1 required
    case logo       // Logo/brand text: no requirement
}

/// Line of text content
public struct TextLine: ContentChunk, Sendable {
    public let boundingBox: BoundingBox
    public var pageNumber: Int { boundingBox.pageNumber }
    public let chunks: [TextChunk]
    public let isLineStart: Bool
    public let isLineEnd: Bool

    public var text: String {
        chunks.map(\.value).joined()
    }
}

/// Block of text lines (paragraph-like unit)
public struct TextBlock: ContentChunk, Sendable {
    public let boundingBox: BoundingBox
    public var pageNumber: Int { boundingBox.pageNumber }
    public let lines: [TextLine]

    public var text: String {
        lines.map(\.text).joined(separator: "\n")
    }
}
```

---

## Phase 2: Semantic Node System

### 2.1 Semantic Types

| Java Enum/Class | Swift Equivalent |
|-----------------|-----------------|
| `SemanticType` (enum) | `SemanticType` (enum) |
| `TextFormat` (enum) | `TextFormat` (enum) |
| `TextAlignment` (enum) | Part of `TextFormat` |

```swift
/// All PDF/UA semantic structure types
public enum SemanticType: String, CaseIterable, Sendable {
    // Document level
    case document = "Document"
    case part = "Part"

    // Block structure
    case paragraph = "P"
    case span = "Span"
    case div = "Div"
    case blockQuote = "BlockQuote"

    // Headings
    case heading = "H"
    case h1, h2, h3, h4, h5, h6

    // Lists
    case list = "L"
    case listItem = "LI"
    case listLabel = "Lbl"
    case listBody = "LBody"

    // Tables
    case table = "Table"
    case tableRow = "TR"
    case tableHeader = "TH"
    case tableCell = "TD"
    case tableHeaders = "THead"
    case tableBody = "TBody"
    case tableFooter = "TFoot"

    // Special content
    case figure = "Figure"
    case caption = "Caption"
    case link = "Link"
    case annot = "Annot"
    case form = "Form"
    case note = "Note"

    // Navigation
    case toc = "TOC"
    case toci = "TOCI"

    // Text formatting
    case code = "Code"
    case title = "Title"

    // Artifacts
    case header = "Header"
    case footer = "Footer"
    case artifact = "Artifact"
}

/// Text formatting attributes
public enum TextFormat: Sendable {
    case normal
    case subscript
    case superscript
}
```

### 2.2 Semantic Node Hierarchy (Consolidation)

**Java has 20+ SemanticNode subclasses. Consolidate to protocol + struct:**

| Java Classes (Consolidate) | Swift Equivalent |
|---------------------------|-----------------|
| `SemanticNode` (base) | `SemanticNode` (protocol) |
| `SemanticTextNode`, `SemanticSpan`, `SemanticParagraph`, etc. | `ContentNode` (struct with type) |
| `SemanticFigure` | `FigureNode` (struct) |
| `SemanticTable` | `TableNode` (struct) |
| `SemanticList` | `ListNode` (struct) |

```swift
/// Protocol for all semantic nodes
public protocol SemanticNode: Sendable, Identifiable {
    var id: UUID { get }
    var type: SemanticType { get }
    var boundingBox: BoundingBox? { get }
    var parent: (any SemanticNode)? { get }
    var children: [any SemanticNode] { get }
    var attributes: AttributesDictionary { get }
    var depth: Int { get }
    var errorCodes: Set<ErrorCode> { get set }
}

/// Generic content node (paragraphs, spans, headings, etc.)
public struct ContentNode: SemanticNode {
    public let id = UUID()
    public let type: SemanticType
    public let boundingBox: BoundingBox?
    public weak var parent: (any SemanticNode)?
    public var children: [any SemanticNode]
    public let attributes: AttributesDictionary
    public var depth: Int
    public var errorCodes: Set<ErrorCode> = []

    // Text-specific properties
    public let textBlocks: [TextBlock]
    public let dominantFontSize: CGFloat?
    public let dominantFontWeight: CGFloat?
    public let dominantColor: CGColor?
}

/// Figure node with images and line art
public struct FigureNode: SemanticNode {
    public let id = UUID()
    public var type: SemanticType { .figure }
    public let boundingBox: BoundingBox?
    public weak var parent: (any SemanticNode)?
    public var children: [any SemanticNode]
    public let attributes: AttributesDictionary
    public var depth: Int
    public var errorCodes: Set<ErrorCode> = []

    // Figure-specific
    public let imageChunks: [ImageChunk]
    public let lineArtChunks: [LineArtChunk]
    public let altText: String?
    public let actualText: String?

    public var hasAltText: Bool {
        altText != nil || actualText != nil
    }
}

/// Table node with structure validation
public struct TableNode: SemanticNode {
    public let id = UUID()
    public var type: SemanticType { .table }
    public let boundingBox: BoundingBox?
    public weak var parent: (any SemanticNode)?
    public var children: [any SemanticNode]
    public let attributes: AttributesDictionary
    public var depth: Int
    public var errorCodes: Set<ErrorCode> = []

    // Table-specific
    public let rows: [TableRow]
    public let visualBorder: TableBorder?
    public var isRegular: Bool { validateRegularity() }

    private func validateRegularity() -> Bool {
        // Check for gaps, overlaps, consistent column count
        // ...
    }
}
```

### 2.3 Semantic Tree

| Java Class | Swift Equivalent |
|------------|-----------------|
| `ITree` (interface) | `SemanticTree` (struct) |
| `SemanticTree` | `SemanticTree` (struct) |
| `DFSTreeNodeIterator` | `SemanticTreeIterator` (struct) |
| `IDocument` (interface) | `SemanticDocument` (protocol) |
| `Document` | `SemanticDocumentImpl` (struct) |

```swift
/// Iterable semantic tree structure
public struct SemanticTree: Sequence {
    public let root: any SemanticNode

    public func makeIterator() -> SemanticTreeIterator {
        SemanticTreeIterator(root: root)
    }
}

/// Depth-first tree iterator
public struct SemanticTreeIterator: IteratorProtocol {
    private var stack: [any SemanticNode]

    init(root: any SemanticNode) {
        self.stack = [root]
    }

    public mutating func next() -> (any SemanticNode)? {
        guard !stack.isEmpty else { return nil }
        let node = stack.removeLast()
        // Add children in reverse order for DFS
        stack.append(contentsOf: node.children.reversed())
        return node
    }
}
```

---

## Phase 3: Contrast Ratio Calculation

### 3.1 WCAG Contrast Algorithm

| Java Class | Swift Equivalent |
|------------|-----------------|
| `ContrastRatioChecker` | `ContrastCalculator` (struct) |
| `ContrastRatioConsumer` | `ContrastAnalyzer` (struct) |

```swift
/// WCAG 2.1 contrast ratio calculator
public struct ContrastCalculator: Sendable {
    /// Calculate contrast ratio between two colors
    /// Returns value between 1.0 and 21.0
    public func contrastRatio(foreground: CGColor, background: CGColor) -> CGFloat {
        let l1 = relativeLuminance(of: foreground)
        let l2 = relativeLuminance(of: background)

        let lighter = max(l1, l2)
        let darker = min(l1, l2)

        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Calculate relative luminance per WCAG 2.1
    /// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
    public func relativeLuminance(of color: CGColor) -> CGFloat {
        guard let components = color.converted(
            to: CGColorSpace(name: CGColorSpace.sRGB)!,
            intent: .defaultIntent,
            options: nil
        )?.components, components.count >= 3 else {
            return 0
        }

        let r = normalizeColorComponent(components[0])
        let g = normalizeColorComponent(components[1])
        let b = normalizeColorComponent(components[2])

        // WCAG luminance formula
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Normalize sRGB color component for luminance calculation
    private func normalizeColorComponent(_ c: CGFloat) -> CGFloat {
        if c <= 0.03928 {
            return c / 12.92
        } else {
            return pow((c + 0.055) / 1.055, 2.4)
        }
    }

    /// Check if contrast meets WCAG requirements
    public func meetsRequirement(
        ratio: CGFloat,
        textType: TextType,
        level: WCAGLevel
    ) -> Bool {
        let required = requiredRatio(for: textType, level: level)
        return ratio >= required
    }

    /// Get required contrast ratio for text type and level
    public func requiredRatio(for textType: TextType, level: WCAGLevel) -> CGFloat {
        switch (textType, level) {
        case (.logo, _):
            return 1.0  // No requirement
        case (.large, .aa):
            return 3.0
        case (.large, .aaa):
            return 4.5
        case (.regular, .aa):
            return 4.5
        case (.regular, .aaa):
            return 7.0
        }
    }
}

/// WCAG conformance levels
public enum WCAGLevel: Sendable {
    case aa   // Level AA (standard)
    case aaa  // Level AAA (enhanced)
}
```

### 3.2 Page Rendering for Contrast Analysis

```swift
/// Analyzes contrast by rendering PDF pages
public struct ContrastAnalyzer {
    private let calculator = ContrastCalculator()

    /// Analyze contrast for text chunks on a page
    public func analyzeContrast(
        for chunks: [TextChunk],
        on page: PDFPage,
        scale: CGFloat = 2.0
    ) async throws -> [TextChunk] {
        // Render page to image
        let image = try await renderPage(page, scale: scale)
        let cgImage = image.cgImage!

        // Analyze each chunk
        return chunks.map { chunk in
            var updatedChunk = chunk
            if let backgroundColor = extractBackgroundColor(
                for: chunk.boundingBox,
                from: cgImage,
                scale: scale
            ) {
                let ratio = calculator.contrastRatio(
                    foreground: chunk.textColor,
                    background: backgroundColor
                )
                // Create new chunk with contrast info
                updatedChunk = TextChunk(
                    // ... copy properties ...
                    contrastRatio: ratio
                )
            }
            return updatedChunk
        }
    }

    private func renderPage(_ page: PDFPage, scale: CGFloat) async throws -> NSImage {
        let bounds = page.bounds(for: .mediaBox)
        let size = CGSize(
            width: bounds.width * scale,
            height: bounds.height * scale
        )

        let image = NSImage(size: size)
        image.lockFocus()

        if let context = NSGraphicsContext.current?.cgContext {
            context.scaleBy(x: scale, y: scale)
            context.setFillColor(.white)
            context.fill(CGRect(origin: .zero, size: bounds.size))
            page.draw(with: .mediaBox, to: context)
        }

        image.unlockFocus()
        return image
    }

    private func extractBackgroundColor(
        for box: BoundingBox,
        from image: CGImage,
        scale: CGFloat
    ) -> CGColor? {
        // Sample pixels behind text to determine background
        // Use histogram analysis to find dominant background color
        // ...
    }
}
```

---

## Phase 4: Table Validation

### 4.1 Table Structure Types

| Java Class | Swift Equivalent |
|------------|-----------------|
| `Table` | `Table` (struct) |
| `TableRow` | `TableRow` (struct) |
| `TableCell` | `TableCell` (struct) |
| `TableToken` | `TableToken` (struct) |
| `TableBorder` | `TableBorder` (struct) |
| `TableBorderBuilder` | `TableBorderBuilder` (struct) |
| `TableBorderCell` | `TableBorderCell` (struct) |
| `TableBorderRow` | `TableBorderRow` (struct) |

```swift
/// Validated table structure
public struct Table: Sendable {
    public let rows: [TableRow]
    public let visualBorder: TableBorder?
    public var validationScore: Double = 0

    /// Validate table regularity
    public func validateRegularity() -> [TableError] {
        var errors: [TableError] = []

        // Check for gaps in cell matrix
        // Check for overlapping cells
        // Check header identification
        // Compare with visual border if available

        return errors
    }

    /// Check if table has proper headers
    public var hasHeaders: Bool {
        guard let firstRow = rows.first else { return false }
        return firstRow.cells.contains { $0.isHeader }
    }
}

/// Table row
public struct TableRow: Sendable {
    public let cells: [TableCell]
    public let rowIndex: Int
}

/// Table cell with span information
public struct TableCell: Sendable {
    public let content: [TableToken]
    public let rowSpan: Int
    public let colSpan: Int
    public let isHeader: Bool
    public let boundingBox: BoundingBox?

    // Position in cell matrix
    public let rowIndex: Int
    public let colIndex: Int
}

/// Visual table border detected from lines
public struct TableBorder: Sendable {
    public let xCoordinates: [CGFloat]
    public let yCoordinates: [CGFloat]
    public let cellMatrix: [[TableBorderCell?]]

    /// Compare with semantic table structure
    public func compare(with table: Table) -> TableComparisonResult {
        var result = TableComparisonResult()

        // Compare row counts
        result.rowCountMatch = cellMatrix.count == table.rows.count

        // Compare column counts
        if let firstRow = cellMatrix.first {
            let semanticCols = table.rows.first?.cells.count ?? 0
            result.columnCountMatch = firstRow.count == semanticCols
        }

        // Check cell positions
        // Check span consistency

        return result
    }
}

/// Error codes for table validation
public enum TableError: Int, Sendable {
    case cellBelowNextRow = 1100
    case cellAbovePreviousRow = 1101
    case cellRightOfNextColumn = 1102
    case cellLeftOfPreviousColumn = 1103
    case rowCountMismatch = 1104
    case columnCountMismatch = 1105
    case rowSpanMismatch = 1106
    case colSpanMismatch = 1107
}
```

### 4.2 Table Checker

| Java Class | Swift Equivalent |
|------------|-----------------|
| `TableChecker` | `TableValidator` (struct) |
| `TableRecognizer` | `TableRecognizer` (struct) |
| `TableRecognitionArea` | Part of `TableRecognizer` |
| `TableCluster` | `TableCluster` (struct) |

```swift
/// Validates table accessibility structure
public struct TableValidator {
    /// Validate a semantic table node
    public func validate(_ table: TableNode) -> [TableError] {
        var errors: [TableError] = []

        // 1. Extract semantic table structure
        let semanticTable = extractTable(from: table)

        // 2. Validate regularity (no gaps/overlaps)
        errors.append(contentsOf: validateRegularity(semanticTable))

        // 3. Validate headers
        errors.append(contentsOf: validateHeaders(semanticTable))

        // 4. If visual border available, compare
        if let visualBorder = table.visualBorder {
            errors.append(contentsOf: compareWithVisual(semanticTable, border: visualBorder))
        }

        return errors
    }

    private func validateRegularity(_ table: Table) -> [TableError] {
        // Check that cells don't overlap
        // Check that there are no gaps in the grid
        // ...
    }

    private func validateHeaders(_ table: Table) -> [TableError] {
        // Check that header cells exist
        // Check that headers are properly marked
        // ...
    }

    private func compareWithVisual(_ table: Table, border: TableBorder) -> [TableError] {
        let comparison = border.compare(with: table)
        var errors: [TableError] = []

        if !comparison.rowCountMatch {
            errors.append(.rowCountMismatch)
        }
        if !comparison.columnCountMatch {
            errors.append(.columnCountMismatch)
        }
        // ... more checks

        return errors
    }
}
```

---

## Phase 5: List Validation

### 5.1 List Types

| Java Class | Swift Equivalent |
|------------|-----------------|
| `PDFList` | `PDFList` (struct) |
| `ListItem` | `ListItem` (struct) |
| `ListLabel` | `ListLabel` (struct) |
| `ListBody` | `ListBody` (struct) |
| `ListInterval` | `ListInterval` (struct) |
| `ListItemTextInfo` | `ListItemInfo` (enum) |

```swift
/// Detected list structure
public struct PDFList: Sendable {
    public let items: [ListItem]
    public let intervals: [ListInterval]
    public let listType: ListType
}

/// List type based on label pattern
public enum ListType: Sendable {
    case unordered           // Bullets, dashes
    case orderedArabic       // 1, 2, 3...
    case orderedRomanUpper   // I, II, III...
    case orderedRomanLower   // i, ii, iii...
    case orderedAlphaUpper   // A, B, C...
    case orderedAlphaLower   // a, b, c...
    case orderedCircled      // ①, ②, ③...
    case unknown
}

/// Interval of consecutive list items
public struct ListInterval: Sendable {
    public let startIndex: Int
    public let endIndex: Int
    public let increment: Int
    public let listType: ListType
}
```

### 5.2 List Label Detection (Consolidation)

**Java has 12 label detection algorithm classes. Consolidate to one with configuration:**

| Java Classes (Consolidate) | Swift Equivalent |
|---------------------------|-----------------|
| `ListLabelsDetectionAlgorithm` (abstract) | `ListLabelDetector` (struct) |
| `ArabicNumbersListLabelsDetectionAlgorithm` | Configuration enum case |
| `RomanNumbersListLabelsDetectionAlgorithm` | Configuration enum case |
| All other `*ListLabelsDetectionAlgorithm` | Configuration enum cases |

```swift
/// Detects list labels from text content
public struct ListLabelDetector {
    /// All supported label patterns
    private let patterns: [LabelPattern] = [
        .arabicNumbers,
        .romanUppercase,
        .romanLowercase,
        .alphaUppercase,
        .alphaLowercase,
        .circledNumbers,
        .bullets
    ]

    /// Detect label type and extract number
    public func detectLabel(_ text: String) -> DetectedLabel? {
        for pattern in patterns {
            if let match = pattern.match(text) {
                return match
            }
        }
        return nil
    }
}

/// Label pattern configuration
public enum LabelPattern: Sendable {
    case arabicNumbers      // 1., 2., 3.
    case romanUppercase     // I., II., III.
    case romanLowercase     // i., ii., iii.
    case alphaUppercase     // A., B., C.
    case alphaLowercase     // a., b., c.
    case circledNumbers     // ①, ②, ③
    case bullets            // •, -, *, ◦

    /// Try to match text against this pattern
    func match(_ text: String) -> DetectedLabel? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)

        switch self {
        case .arabicNumbers:
            let regex = /^(\d+)[\.\)\:]?\s*/
            if let match = trimmed.firstMatch(of: regex) {
                return DetectedLabel(
                    type: .orderedArabic,
                    number: Int(match.1),
                    prefix: "",
                    suffix: String(match.0.dropFirst(match.1.count))
                )
            }

        case .romanUppercase:
            let regex = /^([IVXLCDM]+)[\.\)\:]?\s*/
            if let match = trimmed.firstMatch(of: regex),
               let number = romanToInt(String(match.1)) {
                return DetectedLabel(
                    type: .orderedRomanUpper,
                    number: number,
                    prefix: "",
                    suffix: String(match.0.dropFirst(match.1.count))
                )
            }

        // ... other patterns

        case .bullets:
            if let first = trimmed.first,
               ["•", "-", "*", "◦", "▪", "▸"].contains(String(first)) {
                return DetectedLabel(
                    type: .unordered,
                    number: nil,
                    prefix: "",
                    suffix: String(trimmed.dropFirst())
                )
            }
        }

        return nil
    }

    private func romanToInt(_ s: String) -> Int? {
        // Roman numeral conversion
        let values: [Character: Int] = [
            "I": 1, "V": 5, "X": 10, "L": 50,
            "C": 100, "D": 500, "M": 1000
        ]
        // ... implementation
    }
}

/// Result of label detection
public struct DetectedLabel: Sendable {
    public let type: ListType
    public let number: Int?
    public let prefix: String
    public let suffix: String
}
```

---

## Phase 6: Main Semantic Checker

### 6.1 Consumer Pipeline (Consolidation)

**Java has 10+ consumer classes forming a pipeline. Consolidate to a single orchestrator:**

| Java Classes (Pipeline) | Swift Equivalent |
|------------------------|-----------------|
| `AccumulatedNodeSemanticChecker` | `SemanticChecker` (struct) |
| `LinesPreprocessingConsumer` | Phase method |
| `SemanticDocumentPreprocessingConsumer` | Phase method |
| `ContrastRatioConsumer` | Phase method |
| `AccumulatedNodeConsumer` | Phase method |
| `HeadingCaptionConsumer` | Phase method |
| `TOCDetectionConsumer` | Phase method |
| `ListDetectionConsumer` | Phase method |
| `TableBorderConsumer` | Phase method |
| `TableChecker` | Phase method |
| `ClusterTableConsumer` | Phase method |
| `SemanticDocumentPostprocessingConsumer` | Phase method |

```swift
/// Main orchestrator for semantic document checking
public struct SemanticChecker {
    private let contrastAnalyzer = ContrastAnalyzer()
    private let tableValidator = TableValidator()
    private let listDetector = ListLabelDetector()

    /// Check a semantic document for WCAG compliance
    public func check(
        _ document: SemanticDocument,
        fileName: String,
        progress: ((CheckingPhase, Double) -> Void)? = nil
    ) async throws -> SemanticCheckResult {

        var context = CheckingContext(document: document, fileName: fileName)

        // Phase 1: Preprocess lines for table detection
        progress?(.linesPreprocessing, 0.0)
        await preprocessLines(&context)

        // Phase 2: Document preprocessing
        progress?(.documentPreprocessing, 0.1)
        await preprocessDocument(&context)

        // Phase 3: Contrast ratio analysis
        progress?(.contrastAnalysis, 0.2)
        await analyzeContrast(&context)

        // Phase 4: Node accumulation
        progress?(.nodeAccumulation, 0.4)
        await accumulateNodes(&context)

        // Phase 5: Heading/caption detection
        progress?(.headingDetection, 0.5)
        await detectHeadingsAndCaptions(&context)

        // Phase 6: TOC detection
        progress?(.tocDetection, 0.6)
        await detectTOC(&context)

        // Phase 7: List detection
        progress?(.listDetection, 0.7)
        await detectLists(&context)

        // Phase 8: Table border detection
        progress?(.tableBorderDetection, 0.8)
        await detectTableBorders(&context)

        // Phase 9: Table validation
        progress?(.tableValidation, 0.9)
        await validateTables(&context)

        // Phase 10: Post-processing
        progress?(.postprocessing, 0.95)
        await postprocess(&context)

        progress?(.complete, 1.0)
        return context.result
    }

    // Phase implementations...
}

/// Checking progress phases
public enum CheckingPhase: Sendable {
    case linesPreprocessing
    case documentPreprocessing
    case contrastAnalysis
    case nodeAccumulation
    case headingDetection
    case tocDetection
    case listDetection
    case tableBorderDetection
    case tableValidation
    case postprocessing
    case complete
}
```

### 6.2 Static Containers → Actor

| Java Class | Swift Equivalent |
|------------|-----------------|
| `StaticContainers` (ThreadLocal) | `WCAGContext` (actor) |

```swift
/// Thread-safe context for WCAG validation
public actor WCAGContext {
    public var document: SemanticDocument?
    public var fileName: String = ""
    public var nodeMapper: AccumulatedNodeMapper = .init()
    public var tableBorders: TableBordersCollection = .init()
    public var lines: LinesCollection = .init()
    public var lists: ListsCollection = .init()
    public var validationInfo: WCAGValidationInfo = .init()

    public func reset() {
        document = nil
        fileName = ""
        nodeMapper = .init()
        tableBorders = .init()
        lines = .init()
        lists = .init()
        validationInfo = .init()
    }
}
```

---

## Testing Strategy

### Unit Tests

1. **Contrast Calculation Tests**
   - Test luminance calculation
   - Test contrast ratio calculation
   - Test WCAG threshold compliance

2. **Geometry Tests**
   - Test bounding box operations
   - Test intersection/union
   - Test containment

3. **Table Validation Tests**
   - Test regularity detection
   - Test header identification
   - Test visual comparison

4. **List Detection Tests**
   - Test all label patterns
   - Test interval detection
   - Test Roman numeral conversion

5. **Semantic Tree Tests**
   - Test DFS iteration
   - Test node relationships

### Integration Tests

1. **Full Document Analysis**
   - Process reference PDFs
   - Compare with veraPDF results

2. **Contrast Analysis**
   - Render and analyze pages
   - Verify contrast calculations

### Performance Tests

1. **Large Document Performance**
   - Memory usage
   - Processing time

2. **Page Rendering Performance**
   - Rendering speed
   - Memory for images

---

## Phased Implementation

### Phase 1: Core Primitives (MVP)
1. Geometry types (BoundingBox)
2. Content chunks (TextChunk, etc.)
3. Semantic types and nodes
4. Semantic tree iteration

### Phase 2: Contrast Analysis
1. Contrast calculator
2. Page rendering
3. Background color extraction

### Phase 3: Structure Validation
1. Table structure types
2. Table validator
3. Visual border detection

### Phase 4: List Analysis
1. List types
2. Label detection (all patterns)
3. Interval detection

### Phase 5: Full Semantic Checker
1. Checker orchestrator
2. All validation phases
3. Result aggregation

---

## Performance Optimizations

1. **Accelerate Framework**
   - Use vDSP for luminance calculations
   - Use vImage for image processing

2. **Parallel Processing**
   - Process pages concurrently
   - Parallel contrast analysis

3. **Lazy Rendering**
   - Only render pages when needed
   - Cache rendered images

4. **Memory Management**
   - Stream large documents
   - Release page images after analysis

---

## Class Count Summary

| Category | Java Classes | Swift Types | Reduction |
|----------|-------------|-------------|-----------|
| Geometry | 3 | 2 | 33% |
| Content Chunks | 10 | 8 | 20% |
| Semantic Nodes | 20+ | 5 | 75% |
| Table Types | 10 | 8 | 20% |
| List Types | 15 | 5 | 67% |
| Consumers | 12 | 1 (orchestrator) | 92% |
| Utilities | 15 | 8 | 47% |
| **Total** | **~140** | **~45** | **68%** |

Major consolidations:
- 20+ semantic node classes → 1 protocol + 5 concrete types
- 12 list label algorithms → 1 configurable detector
- 12 consumer classes → 1 orchestrator with phase methods

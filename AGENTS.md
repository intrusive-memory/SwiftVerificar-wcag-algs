# SwiftVerificarWCAGAlgs -- Agent Instructions

## What This Library Does

SwiftVerificarWCAGAlgs provides WCAG accessibility algorithms for PDF validation. It implements contrast ratio calculation per WCAG 2.1, structure tree analysis, heading hierarchy validation, reading order validation, alt text checking, and PDF/UA compliance checking. It is part of the SwiftVerificar suite and has no external dependencies.

- **Module name**: `SwiftVerificarWCAGAlgs`
- **Swift version**: 6.0 (strict concurrency; all types are Sendable)
- **Test framework**: Swift Testing
- **Stats**: 72+ public types, 1222 tests, 92.22% code coverage
- **Platforms**: macOS 14.0+, iOS 17.0+

## Build and Test

**CRITICAL: NEVER use `swift build` or `swift test`. Always use `xcodebuild`.**

```bash
# Build
cd /Users/stovak/Projects/SwiftVerificar/SwiftVerificar-wcag-algs
xcodebuild build -scheme SwiftVerificarWCAGAlgs -destination 'platform=macOS'

# Test
cd /Users/stovak/Projects/SwiftVerificar/SwiftVerificar-wcag-algs
xcodebuild test -scheme SwiftVerificarWCAGAlgs -destination 'platform=macOS'
```

## Key Public Types

### SemanticType (enum, 53 cases)

All PDF/UA semantic structure types. Raw values match standard PDF structure type names.

**Categories**: document-level (`document`, `part`, `article`, `section`, `div`), block structure (`paragraph`, `span`, `blockQuote`, `index`), headings (`heading`, `h1`-`h6`), lists (`list`, `listItem`, `listLabel`, `listBody`), tables (`table`, `tableRow`, `tableHeader`, `tableCell`, `tableHead`, `tableBody`, `tableFoot`), special content (`figure`, `caption`, `formula`, `form`, `code`, `title`), links/annotations (`link`, `annotation`, `reference`, `note`), navigation (`toc`, `tocItem`, `bibliography`, `quote`), ruby (`ruby`, `rubyBase`, `rubyText`, `rubyPunctuation`), warichu (`warichu`, `warichuText`, `warichuPunctuation`), presentational (`artifact`, `nonStruct`, `privateElement`, `documentHeader`, `documentFooter`).

**Computed properties**: `isHeading`, `headingLevel` (Int?), `isList`, `isTable`, `isBlockLevel`, `isInline`, `isPresentational`, `requiresAlternativeText`, `isGrouping`.

```swift
let type = SemanticType.h2
type.isHeading       // true
type.headingLevel    // 2
type.isBlockLevel    // true
type.requiresAlternativeText // false

let figure = SemanticType.figure
figure.requiresAlternativeText // true
```

### ColorContrastCalculator (struct)

WCAG 2.1 contrast ratio calculation using CGColor inputs with sRGB conversion.

```swift
import CoreGraphics

let calc = ColorContrastCalculator()
let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

let ratio = calc.contrastRatio(foreground: black, background: white)
// ratio == 21.0 (maximum contrast)

let luminance = calc.relativeLuminance(of: white)
// luminance == 1.0

let passes = calc.meetsRequirement(ratio: ratio, textType: .regular, level: .aa)
// passes == true (21.0 >= 4.5)

let required = calc.requiredRatio(for: .large, level: .aa)
// required == 3.0
```

There is also a simpler `ContrastRatioCalculator` that takes RGB tuples (Double, 0-1 range) without CGColor:

```swift
let simple = ContrastRatioCalculator()
let ratio = simple.contrastRatio(
    foreground: (r: 0, g: 0, b: 0),
    background: (r: 1, g: 1, b: 1)
)
// ratio == 21.0

simple.meetsWCAGAA(ratio: ratio)           // true (>= 4.5)
simple.meetsWCAGAALargeText(ratio: ratio)  // true (>= 3.0)
simple.meetsWCAGAAA(ratio: ratio)          // true (>= 7.0)
```

### WCAGLevel (enum)

WCAG conformance levels: `.a`, `.aa`, `.aaa`. Raw values: "A", "AA", "AAA".

### TextType (enum)

Text classification for contrast requirements: `.regular`, `.large`, `.logo`.

### Content Types

- **TextChunk** -- A chunk of text content with color, font size, bounding box, and text type classification.
- **TextLine** -- A line of text composed of TextChunks.
- **TextBlock** -- A block of text composed of TextLines.
- **TextColumn** -- A column of text composed of TextBlocks.
- **ImageChunk** -- An image with pixel dimensions, resolution, color space, and alt text.
- **LineChunk** -- A geometric line (path segment).
- **LineArtChunk** -- A collection of lines forming line art.

### Geometry

- **BoundingBox** -- Rectangle on a specific PDF page (pageIndex + CGRect). Supports union, intersection, containment, overlap percentage.
- **MultiBoundingBox** -- A collection of BoundingBoxes spanning multiple pages.

### Structure Analysis

- **StructureTreeAnalyzer** -- Analyzes the tagged PDF structure tree.
- **HeadingHierarchyChecker** -- Validates heading nesting rules (H1 -> H2 -> H3, no skips, single H1, non-empty headings). Returns `HeadingHierarchyValidationResult`.
- **ReadingOrderValidator** -- Validates document reading order (top-to-bottom, left-to-right or RTL, column detection, overlap detection). Returns `ReadingOrderValidationResult`.

```swift
// Heading hierarchy validation
let checker = HeadingHierarchyChecker()  // or HeadingHierarchyChecker(options: .strict)
let result = checker.validate(rootNode)  // takes any SemanticNode

if result.isValid {
    print("Valid: \(result.totalHeadingCount) headings")
} else {
    for issue in result.issues {
        print("H\(issue.headingLevel): \(issue.message) [\(issue.severity)]")
    }
}

// Reading order validation
let validator = ReadingOrderValidator()  // or ReadingOrderValidator(options: .rightToLeft)
let orderResult = validator.validate(rootNode)

if !orderResult.isValid {
    print("\(orderResult.criticalIssueCount) critical issues on \(orderResult.pageCount) pages")
}
```

### WCAG Checkers (AccessibilityChecker protocol)

Protocol requiring `criterion: WCAGSuccessCriterion` and `check(_: any SemanticNode) -> AccessibilityCheckResult`.

**Implementations**:
- **AltTextChecker** -- Checks WCAG 1.1.1 (Non-text Content). Validates figures and images have alt text.
- **LanguageChecker** -- Checks WCAG 3.1.1/3.1.2 (Language of Page/Parts).
- **LinkPurposeChecker** -- Checks WCAG 2.4.4 (Link Purpose in Context).

### PDF/UA Checkers (PDFUAChecker protocol)

Protocol requiring `requirement: PDFUARequirement` and `check(_: any SemanticNode) -> PDFUACheckResult`.

**Implementations**:
- **TaggedPDFChecker** -- Checks PDF/UA 7.1 (Document Must Be Tagged).
- **RoleMapChecker** -- Checks PDF/UA 7.2 (Structure Elements Need Role Mapping).
- **TableChecker** -- Checks PDF/UA 7.5 (Tables Must Have Headers).

### WCAGValidator (struct)

High-level validator combining all checkers. Provides preset profiles for Level A, AA, AAA, or by WCAG principle.

```swift
let validator = WCAGValidator.levelAA()
let report = validator.validate(semanticTree)

if report.allPassed {
    print("WCAG 2.1 Level AA compliant")
} else {
    print("\(report.failedCount) failures")
    print(report.detailedReport)
}

// Or validate specific criteria
let contrastReport = validator.validate(tree, criteria: [.contrastMinimum, .contrastEnhanced])

// Or validate at a specific level
let levelAReport = validator.validate(tree, level: .a)
```

### Reference Enums

- **WCAGSuccessCriterion** -- WCAG 2.1 success criteria (e.g., `.nonTextContent` = "1.1.1", `.contrastMinimum` = "1.4.3"). Properties: `level`, `principle`, `name`.
- **WCAGPrinciple** -- The four WCAG principles: `.perceivable`, `.operable`, `.understandable`, `.robust`.
- **PDFUARequirement** -- PDF/UA requirements (e.g., `.documentMustBeTagged` = "7.1"). Properties: `category`, `name`.
- **PDFUACategory** -- PDF/UA categories: `.structure`, `.tables`, `.lists`, `.content`.

### ImageAnalyzer (struct)

Analyzes image accessibility: resolution, alt text presence, decorative image detection, quality issues.

```swift
let analyzer = ImageAnalyzer()
let result = analyzer.analyze(imageChunk)

result.hasAlternativeText    // Bool
result.isLikelyDecorative    // Bool
result.passesAltTextRequirement  // true if has alt OR is decorative
result.qualityIssues         // Set<ImageQualityIssue>

// Batch analysis
let batch = analyzer.analyzeImages(allImages)
batch.altTextCoverage        // percentage
batch.wcagComplianceRate     // percentage
```

### Semantic Nodes (protocol hierarchy)

- **SemanticNode** (protocol) -- Base for all nodes in the structure tree. Properties: `id`, `type` (SemanticType), `children`, `boundingBox`, `attributes`, `pageIndex`, `hasChildren`, `hasTextAlternative`, `textDescription`.
- **ContentNode** -- Node with content chunks (text, images, lines).
- **TableNode** -- Table-specific node with rows, headers, cells.
- **ListNode** -- List-specific node with items and labels.
- **FigureNode** -- Figure-specific node with image and line art chunks.

## Architecture Notes

- All types conform to `Sendable` for Swift 6 strict concurrency.
- Value types (structs/enums) are preferred over classes throughout.
- The `SemanticType` enum replaces the Java class hierarchy with a single type-safe discriminator.
- Checker protocols (`AccessibilityChecker`, `PDFUAChecker`) enable extensibility -- implement the protocol to add custom checks.
- `WCAGValidator` composes checkers via `ValidationProfile` for flexible configuration.
- No external dependencies; uses only Foundation and CoreGraphics.

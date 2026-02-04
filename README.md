# SwiftVerificar-wcag-algs

Swift port of [veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs).

## Overview

SwiftVerificar-wcag-algs provides WCAG accessibility algorithms for PDF validation, including:

- Contrast ratio calculation (WCAG 2.1 AA/AAA)
- Structure tree validation (heading hierarchy, nesting)
- Alt text validation
- Table accessibility checks

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/intrusive-memory/SwiftVerificar-wcag-algs.git", from: "0.1.0")
]
```

## Usage

### Contrast Ratio

```swift
import SwiftVerificarWCAGAlgs

let calculator = ContrastRatioCalculator()
let ratio = calculator.contrastRatio(
    foreground: (r: 0, g: 0, b: 0),      // Black
    background: (r: 1, g: 1, b: 1)       // White
)
// ratio ≈ 21:1

if calculator.meetsWCAGAA(ratio: ratio) {
    print("Meets WCAG AA for normal text")
}
```

### Heading Hierarchy

```swift
let validator = StructureTreeValidator()
let issues = validator.validateHeadingHierarchy(headingLevels: [1, 2, 4])  // Skips H3
// issues contains: skippedHeadingLevel
```

## WCAG Compliance Levels

| Level | Normal Text | Large Text |
|-------|-------------|------------|
| AA    | 4.5:1       | 3:1        |
| AAA   | 7:1         | 4.5:1      |

## Source Reference

- **Original**: [veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs)
- **Language**: Java → Swift
- **License**: GPLv3+ / MPLv2+

## Development

See the parent [SwiftVerificar/AGENTS.md](../AGENTS.md) for development guidelines.

### Building

```bash
xcodebuild build -scheme SwiftVerificarWCAGAlgs -destination 'platform=macOS'
```

### Testing

```bash
xcodebuild test -scheme SwiftVerificarWCAGAlgs -destination 'platform=macOS'
```

# SwiftVerificar-wcag-algs

Swift port of [veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs).

## Overview

SwiftVerificar-wcag-algs provides WCAG accessibility algorithms for PDF validation. It is part of the SwiftVerificar suite and includes:

- Contrast ratio calculation per WCAG 2.1 (AA and AAA levels)
- Structure tree analysis for tagged PDF documents
- Heading hierarchy validation (proper nesting, no skipped levels)
- Reading order checking (spatial ordering, column detection)
- Alt text validation for figures and images
- PDF/UA compliance checking (tagging, role mapping, table structure)

## Requirements

- Swift 6.0+
- macOS 14.0+
- iOS 17.0+

## Stats

- 72+ public types
- 1222 tests
- 92.22% code coverage
- 10 implementation sprints
- No external dependencies

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
// ratio == 21.0

if calculator.meetsWCAGAA(ratio: ratio) {
    print("Meets WCAG AA for normal text")
}
```

### Heading Hierarchy

```swift
let checker = HeadingHierarchyChecker()
let result = checker.validate(rootNode)

if result.isValid {
    print("Heading hierarchy is valid")
} else {
    for issue in result.issues {
        print("H\(issue.headingLevel): \(issue.message)")
    }
}
```

### WCAG Validation

```swift
let validator = WCAGValidator.levelAA()
let report = validator.validate(semanticTree)

if report.allPassed {
    print("Document is WCAG 2.1 Level AA compliant!")
} else {
    print("Found \(report.failedCount) failures")
}
```

## WCAG Compliance Levels

| Level | Normal Text | Large Text |
|-------|-------------|------------|
| AA    | 4.5:1       | 3:1        |
| AAA   | 7:1         | 4.5:1      |

## Porting Process

This library was ported from its Java source using a structured, AI-assisted methodology. The original veraPDF Java codebase was analyzed to extract type hierarchies, public APIs, and behavioral contracts. An execution plan decomposed the port into sequential sprints, each targeting a cohesive set of types with explicit entry/exit criteria (build must pass, all tests must pass, 90%+ coverage). AI coding agents (Claude) executed each sprint autonomously -- translating Java patterns to idiomatic Swift (enums for sealed hierarchies, structs for value types, actors for thread-safe singletons, async/await for concurrency), writing Swift Testing framework tests, and verifying builds with xcodebuild. A supervisor process coordinated sprint sequencing, tracked cross-package dependencies, and performed reconciliation passes to ensure type agreement across the five-package ecosystem. The result is a clean-room Swift implementation that preserves the original's validation semantics while embracing Swift 6 strict concurrency, value semantics, and protocol-oriented design.

## Source Reference

- **Original**: [veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs)
- **Language**: Java -> Swift
- **License**: GPLv3+ / MPLv2+

## Development

See [AGENTS.md](AGENTS.md) for the full public API reference and agent instructions.

### Building

```bash
xcodebuild build -scheme SwiftVerificarWCAGAlgs -destination 'platform=macOS'
```

### Testing

```bash
xcodebuild test -scheme SwiftVerificarWCAGAlgs -destination 'platform=macOS'
```

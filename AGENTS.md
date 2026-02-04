# SwiftVerificar-wcag-algs — Agent Instructions

Swift port of [veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs).

See the parent [SwiftVerificar/AGENTS.md](../AGENTS.md) for ecosystem overview, implementation roadmap, and general guidelines.

## Purpose

WCAG accessibility algorithms providing:

- Contrast ratio calculation
- Structure tree validation
- Alt text validation
- Table accessibility checks

## Source Reference

- **Original**: [veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs)
- **Language**: Java → Swift
- **License**: GPLv3+ / MPLv2+

## Algorithms Implemented

### From Original veraPDF-wcag-algs

1. **Contrast Ratio Calculation**
   - Relative luminance computation (WCAG 2.1 formula)
   - Contrast ratio calculation
   - AA/AAA threshold checking

2. **Structure Tree Validation**
   - Heading hierarchy validation
   - Proper nesting checks
   - Reading order validation

## Key Types to Implement

```swift
// Contrast
struct ContrastRatioCalculator

// Structure
struct StructureTreeValidator
struct HeadingValidator
struct TableValidator

// Issues
struct AccessibilityIssue
enum AccessibilityIssueType
```

## WCAG References

- [WCAG 2.1 Contrast (Minimum)](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html) — 1.4.3
- [WCAG 2.1 Contrast (Enhanced)](https://www.w3.org/WAI/WCAG21/Understanding/contrast-enhanced.html) — 1.4.6
- [WCAG 2.1 Headings and Labels](https://www.w3.org/WAI/WCAG21/Understanding/headings-and-labels.html) — 2.4.6
- [WCAG 2.1 Info and Relationships](https://www.w3.org/WAI/WCAG21/Understanding/info-and-relationships.html) — 1.3.1

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-07

### Added
- Initial release of SwiftVerificarWCAGAlgs
- SemanticType enum with 53 PDF/UA structure type cases
- ColorContrastCalculator with WCAG 2.1 contrast ratio algorithms
- WCAGLevel enum (A, AA, AAA) with threshold checking
- Content extraction: TextChunk, ImageChunk, LineChunk, TextBlock, TextLine, TextColumn
- Geometry: BoundingBox, MultiBoundingBox
- Structure analysis: StructureTreeAnalyzer, HeadingHierarchyChecker, ReadingOrderValidator
- WCAG checkers: AltTextChecker, LanguageChecker, LinkPurposeChecker
- PDF/UA checkers: TaggedPDFChecker, RoleMapChecker, TableChecker
- ImageAnalyzer for image accessibility analysis
- WCAGValidator high-level validation coordinator
- WCAGSuccessCriterion and WCAGPrinciple reference enums
- 1222 tests with 92.22% coverage

[0.1.0]: https://github.com/intrusive-memory/SwiftVerificar-wcag-algs/releases/tag/v0.1.0

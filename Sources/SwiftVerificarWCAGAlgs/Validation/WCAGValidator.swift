import Foundation

/// High-level API for WCAG validation of PDF documents.
///
/// The WCAGValidator provides a convenient interface for validating
/// semantic document structures against WCAG 2.1 success criteria.
/// It manages checker configuration and provides preset validation
/// profiles for common use cases.
///
/// ## Example
///
/// ```swift
/// // Validate at Level AA
/// let validator = WCAGValidator.levelAA()
/// let report = validator.validate(semanticTree)
///
/// if report.allPassed {
///     print("Document is WCAG 2.1 Level AA compliant!")
/// } else {
///     print("Found \(report.failedCount) failures")
///     print(report.detailedReport)
/// }
/// ```
public struct WCAGValidator: Sendable {

    /// The validation runner that executes the checks.
    private let runner: ValidationRunner

    /// Creates a new WCAG validator.
    ///
    /// - Parameters:
    ///   - checkers: The accessibility checkers to use.
    ///   - options: Validation options (defaults to .default).
    public init(
        checkers: [any AccessibilityChecker],
        options: ValidationOptions = .default
    ) {
        self.runner = ValidationRunner(checkers: checkers, options: options)
    }

    /// Creates a validator from a validation profile.
    ///
    /// - Parameter profile: The validation profile to use.
    public init(profile: ValidationProfile) {
        self.runner = ValidationRunner(
            checkers: profile.checkers,
            options: profile.options
        )
    }

    // MARK: - Preset Validators

    /// A validator for WCAG 2.1 Level A conformance.
    ///
    /// Includes all Level A success criteria.
    public static func levelA(options: ValidationOptions = .default) -> WCAGValidator {
        WCAGValidator(profile: .levelA(options: options))
    }

    /// A validator for WCAG 2.1 Level AA conformance.
    ///
    /// Includes all Level A and AA success criteria.
    public static func levelAA(options: ValidationOptions = .default) -> WCAGValidator {
        WCAGValidator(profile: .levelAA(options: options))
    }

    /// A validator for WCAG 2.1 Level AAA conformance.
    ///
    /// Includes all Level A, AA, and AAA success criteria.
    public static func levelAAA(options: ValidationOptions = .default) -> WCAGValidator {
        WCAGValidator(profile: .levelAAA(options: options))
    }

    /// A validator that checks only perceivable criteria.
    ///
    /// WCAG Principle 1: Information and user interface components
    /// must be presentable to users in ways they can perceive.
    public static func perceivable(options: ValidationOptions = .default) -> WCAGValidator {
        WCAGValidator(profile: .perceivable(options: options))
    }

    /// A validator that checks only operable criteria.
    ///
    /// WCAG Principle 2: User interface components and navigation
    /// must be operable.
    public static func operable(options: ValidationOptions = .default) -> WCAGValidator {
        WCAGValidator(profile: .operable(options: options))
    }

    /// A validator that checks only understandable criteria.
    ///
    /// WCAG Principle 3: Information and the operation of user
    /// interface must be understandable.
    public static func understandable(options: ValidationOptions = .default) -> WCAGValidator {
        WCAGValidator(profile: .understandable(options: options))
    }

    /// A validator that checks only robust criteria.
    ///
    /// WCAG Principle 4: Content must be robust enough that it can
    /// be interpreted reliably by a wide variety of user agents.
    public static func robust(options: ValidationOptions = .default) -> WCAGValidator {
        WCAGValidator(profile: .robust(options: options))
    }

    // MARK: - Validation

    /// Validates a semantic tree.
    ///
    /// - Parameter tree: The semantic tree to validate.
    /// - Returns: A validation report with all results.
    public func validate(_ tree: any SemanticNode) -> ValidationReport {
        runner.run(on: tree)
    }

    /// Validates multiple semantic trees.
    ///
    /// - Parameter trees: The semantic trees to validate.
    /// - Returns: A validation report with all results.
    public func validate(_ trees: [any SemanticNode]) -> ValidationReport {
        runner.run(on: trees)
    }

    /// Validates a semantic tree against specific criteria.
    ///
    /// - Parameters:
    ///   - tree: The semantic tree to validate.
    ///   - criteria: The WCAG criteria to check.
    /// - Returns: A validation report with results for the specified criteria.
    public func validate(
        _ tree: any SemanticNode,
        criteria: Set<WCAGSuccessCriterion>
    ) -> ValidationReport {
        runner.run(criteria: criteria, on: tree)
    }

    /// Validates a semantic tree at a specific WCAG level.
    ///
    /// - Parameters:
    ///   - tree: The semantic tree to validate.
    ///   - level: The WCAG level to check.
    /// - Returns: A validation report with results for the specified level.
    public func validate(
        _ tree: any SemanticNode,
        level: WCAGLevel
    ) -> ValidationReport {
        runner.run(level: level, on: tree)
    }

    // MARK: - Batch Validation

    /// Validates multiple semantic trees in batch.
    ///
    /// Returns individual reports for each tree, useful for
    /// validating multi-document collections.
    ///
    /// - Parameter trees: The semantic trees to validate.
    /// - Returns: An array of validation reports, one per tree.
    public func validateBatch(_ trees: [any SemanticNode]) -> [ValidationReport] {
        trees.map { validate($0) }
    }

    /// Validates multiple semantic trees and returns an aggregated report.
    ///
    /// Combines all trees into a single validation run and report.
    ///
    /// - Parameter trees: The semantic trees to validate.
    /// - Returns: A single aggregated validation report.
    public func validateAggregated(_ trees: [any SemanticNode]) -> ValidationReport {
        validate(trees)
    }
}

/// A validation profile defines a set of checkers and options.
///
/// Profiles provide convenient presets for common validation scenarios.
public struct ValidationProfile: Sendable {

    /// The checkers to use in this profile.
    public let checkers: [any AccessibilityChecker]

    /// The validation options to use.
    public let options: ValidationOptions

    /// The name of this profile.
    public let name: String

    /// Creates a new validation profile.
    ///
    /// - Parameters:
    ///   - name: The profile name.
    ///   - checkers: The checkers to include.
    ///   - options: The validation options.
    public init(
        name: String,
        checkers: [any AccessibilityChecker],
        options: ValidationOptions = .default
    ) {
        self.name = name
        self.checkers = checkers
        self.options = options
    }

    // MARK: - WCAG Level Profiles

    /// Profile for WCAG 2.1 Level A conformance.
    public static func levelA(options: ValidationOptions = .default) -> ValidationProfile {
        let checkers = allCheckers.filter { $0.criterion.level == .a }
        return ValidationProfile(name: "WCAG 2.1 Level A", checkers: checkers, options: options)
    }

    /// Profile for WCAG 2.1 Level AA conformance.
    public static func levelAA(options: ValidationOptions = .default) -> ValidationProfile {
        let checkers = allCheckers.filter { $0.criterion.level.rawValue <= WCAGLevel.aa.rawValue }
        return ValidationProfile(name: "WCAG 2.1 Level AA", checkers: checkers, options: options)
    }

    /// Profile for WCAG 2.1 Level AAA conformance.
    public static func levelAAA(options: ValidationOptions = .default) -> ValidationProfile {
        let checkers = allCheckers.filter { $0.criterion.level.rawValue <= WCAGLevel.aaa.rawValue }
        return ValidationProfile(name: "WCAG 2.1 Level AAA", checkers: checkers, options: options)
    }

    // MARK: - WCAG Principle Profiles

    /// Profile for Perceivable principle checks.
    public static func perceivable(options: ValidationOptions = .default) -> ValidationProfile {
        let checkers = allCheckers.filter { $0.criterion.principle == .perceivable }
        return ValidationProfile(name: "WCAG Perceivable", checkers: checkers, options: options)
    }

    /// Profile for Operable principle checks.
    public static func operable(options: ValidationOptions = .default) -> ValidationProfile {
        let checkers = allCheckers.filter { $0.criterion.principle == .operable }
        return ValidationProfile(name: "WCAG Operable", checkers: checkers, options: options)
    }

    /// Profile for Understandable principle checks.
    public static func understandable(options: ValidationOptions = .default) -> ValidationProfile {
        let checkers = allCheckers.filter { $0.criterion.principle == .understandable }
        return ValidationProfile(name: "WCAG Understandable", checkers: checkers, options: options)
    }

    /// Profile for Robust principle checks.
    public static func robust(options: ValidationOptions = .default) -> ValidationProfile {
        let checkers = allCheckers.filter { $0.criterion.principle == .robust }
        return ValidationProfile(name: "WCAG Robust", checkers: checkers, options: options)
    }

    // MARK: - Custom Profiles

    /// Profile for checking only critical accessibility issues.
    public static func critical(options: ValidationOptions = .default) -> ValidationProfile {
        // Focus on Level A criteria that are most critical
        let checkers = allCheckers.filter { $0.criterion.level == .a }
        return ValidationProfile(
            name: "Critical Accessibility",
            checkers: checkers,
            options: options
        )
    }

    /// Profile for a quick validation (essential checks only).
    public static func quick(options: ValidationOptions = .minimal) -> ValidationProfile {
        // Include only the most common and important checks
        let essentialCriteria: Set<WCAGSuccessCriterion> = [
            .nonTextContent,
            .infoAndRelationships,
            .contrastMinimum,
            .linkPurpose,
            .languageOfPage
        ]
        let checkers = allCheckers.filter { essentialCriteria.contains($0.criterion) }
        return ValidationProfile(name: "Quick Check", checkers: checkers, options: options)
    }

    // MARK: - All Available Checkers

    /// All available accessibility checkers.
    private static var allCheckers: [any AccessibilityChecker] {
        [
            AltTextChecker(),
            LanguageChecker(),
            LinkPurposeChecker(),
            // Additional checkers will be added here as they are implemented
        ]
    }
}

//
//  ReferenceView.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI

// MARK: - Data Models

struct ReferenceEntry: Identifiable {
    /// Stable within a section (used for lists / webview identity).
    var id: String { title }
    let title: String
    /// Plain-text fallback (shown when latex is nil, or used for accessibility / code readability)
    let formula: String?
    /// Full HTML fragment containing LaTeX delimited with \[…\] for rendered display
    let latex: String?
    let detail: String?
    let tag: EntryTag?

    enum EntryTag: String {
        case provided = "On Test"
        case memorize = "Memorize"
        case rule     = "Rule"
        case tip      = "Strategy"
    }

    init(_ title: String, formula: String? = nil, latex: String? = nil, detail: String? = nil, tag: EntryTag? = nil) {
        self.title   = title
        self.formula = formula
        self.latex   = latex
        self.detail  = detail
        self.tag     = tag
    }
}

struct ReferenceSection: Identifiable {
    /// Stable across search rebuilds so expansion / selection don’t reset every keystroke.
    var id: String { title }
    let title: String
    let icon: String
    let color: Color
    let entries: [ReferenceEntry]
}

// MARK: - Math Formula View

/// Renders a LaTeX fragment using the existing HTMLContentView (MathJax pipeline).
struct MathFormulaView: View {
    let latex: String       // e.g. "\\[ A = \\pi r^2 \\]"
    let accentColor: Color

    var body: some View {
        HTMLContentView(
            htmlContent: latex,
            isScrollable: false,
            allowInteraction: false
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accentColor.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Content Data

extension ReferenceSection {

    static var mathSections:   [ReferenceSection] { [.providedFormulas, .linearEquations, .quadratics, .exponentsRadicals, .exponentialFunctions, .functionsTransformations, .systemsInequalities, .statisticsData, .geometry, .trigonometry, .desmosPlaybook] }
    static var rwSections:     [ReferenceSection] { [.sentenceBoundaries, .commaRules, .apostrophes, .subjectVerbAgreement, .verbTense, .pronouns, .modifiers, .parallelStructure, .transitions, .wordsInContext, .rhetoricalSynthesis, .readingStrategies] }

    // ─────────────────────────────────────────────────────────── MATH ─────

    static let providedFormulas = ReferenceSection(title: "Formulas Provided on the Test", icon: "checkmark.shield.fill", color: .green, entries: [
        ReferenceEntry("Circle Area",
            formula: "A = πr²",
            latex: "\\[ A = \\pi r^2 \\]",
            tag: .provided),
        ReferenceEntry("Rectangle Area",
            formula: "A = lw",
            latex: "\\[ A = lw \\]",
            tag: .provided),
        ReferenceEntry("Triangle Area",
            formula: "A = ½bh",
            latex: "\\[ A = \\tfrac{1}{2}bh \\]",
            tag: .provided),
        ReferenceEntry("Circle Circumference",
            formula: "C = 2πr",
            latex: "\\[ C = 2\\pi r \\]",
            tag: .provided),
        ReferenceEntry("Pythagorean Theorem",
            formula: "a² + b² = c²",
            latex: "\\[ a^2 + b^2 = c^2 \\]",
            tag: .provided),
        ReferenceEntry("45-45-90 Triangle",
            formula: "Legs: x, x  |  Hypotenuse: x√2",
            latex: "\\[ \\text{legs: }x,\\ x \\qquad \\text{hypotenuse: }x\\sqrt{2} \\]",
            tag: .provided),
        ReferenceEntry("30-60-90 Triangle",
            formula: "Legs: x, x√3  |  Hypotenuse: 2x",
            latex: "\\[ \\text{legs: }x,\\ x\\sqrt{3} \\qquad \\text{hypotenuse: }2x \\]",
            tag: .provided),
        ReferenceEntry("Rectangular Prism Volume",
            formula: "V = lwh",
            latex: "\\[ V = lwh \\]",
            tag: .provided),
        ReferenceEntry("Cylinder Volume",
            formula: "V = πr²h",
            latex: "\\[ V = \\pi r^2 h \\]",
            tag: .provided),
        ReferenceEntry("Sphere Volume",
            formula: "V = (4/3)πr³",
            latex: "\\[ V = \\tfrac{4}{3}\\pi r^3 \\]",
            tag: .provided),
        ReferenceEntry("Cone Volume",
            formula: "V = (1/3)πr²h",
            latex: "\\[ V = \\tfrac{1}{3}\\pi r^2 h \\]",
            tag: .provided),
        ReferenceEntry("Pyramid Volume",
            formula: "V = (1/3)lwh",
            latex: "\\[ V = \\tfrac{1}{3}lwh \\]",
            tag: .provided),
        ReferenceEntry("Angle Facts",
            formula: "Circle = 360°  |  Triangle = 180°",
            latex: "\\[ \\text{circle} = 360^\\circ \\qquad \\text{triangle} = 180^\\circ \\]",
            tag: .provided),
    ])

    static let linearEquations = ReferenceSection(title: "Linear Equations & Graphs", icon: "chart.line.uptrend.xyaxis", color: .blue, entries: [
        ReferenceEntry("Slope",
            formula: "m = (y₂ − y₁) / (x₂ − x₁)",
            latex: "\\[ m = \\dfrac{y_2 - y_1}{x_2 - x_1} \\]",
            tag: .memorize),
        ReferenceEntry("Slope-Intercept Form",
            formula: "y = mx + b",
            latex: "\\[ y = mx + b \\]",
            detail: "m = slope, b = y-intercept",
            tag: .memorize),
        ReferenceEntry("Point-Slope Form",
            formula: "y − y₁ = m(x − x₁)",
            latex: "\\[ y - y_1 = m(x - x_1) \\]",
            tag: .memorize),
        ReferenceEntry("Standard Form",
            formula: "Ax + By = C",
            latex: "\\[ Ax + By = C \\]",
            tag: .memorize),
        ReferenceEntry("Parallel Lines",
            formula: "m₁ = m₂",
            latex: "\\[ m_1 = m_2 \\]",
            tag: .memorize),
        ReferenceEntry("Perpendicular Lines",
            formula: "m₁ × m₂ = −1",
            latex: "\\[ m_1 \\times m_2 = -1 \\]",
            tag: .memorize),
        ReferenceEntry("No Solution (system)",
            formula: "Parallel lines — same slope, different y-intercepts",
            tag: .tip),
        ReferenceEntry("Infinite Solutions (system)",
            formula: "Same line — same slope, same y-intercept",
            tag: .tip),
    ])

    static let quadratics = ReferenceSection(title: "Quadratics & Polynomials", icon: "function", color: .purple, entries: [
        ReferenceEntry("Standard Form",
            formula: "y = ax² + bx + c",
            latex: "\\[ y = ax^2 + bx + c \\]",
            detail: "a > 0 opens up (min), a < 0 opens down (max)",
            tag: .memorize),
        ReferenceEntry("Vertex Form",
            formula: "y = a(x − h)² + k",
            latex: "\\[ y = a(x-h)^2 + k \\quad \\text{vertex: }(h,\\,k) \\]",
            tag: .memorize),
        ReferenceEntry("Factored Form",
            formula: "y = a(x − r₁)(x − r₂)",
            latex: "\\[ y = a(x-r_1)(x-r_2) \\]",
            detail: "Roots / zeros = r₁ and r₂",
            tag: .memorize),
        ReferenceEntry("Quadratic Formula",
            formula: "x = [−b ± √(b² − 4ac)] / 2a",
            latex: "\\[ x = \\dfrac{-b \\pm \\sqrt{b^2 - 4ac}}{2a} \\]",
            tag: .memorize),
        ReferenceEntry("Vertex x-Coordinate",
            formula: "x = −b / 2a",
            latex: "\\[ x = -\\dfrac{b}{2a} \\]",
            detail: "Substitute back into the equation to find y.",
            tag: .memorize),
        ReferenceEntry("Discriminant (b² − 4ac)",
            formula: "> 0 → two roots  = 0 → one root  < 0 → no roots",
            latex: "\\[ b^2 - 4ac \\begin{cases} > 0 & \\Rightarrow \\text{two real roots} \\\\ = 0 & \\Rightarrow \\text{one real root} \\\\ < 0 & \\Rightarrow \\text{no real roots} \\end{cases} \\]",
            tag: .memorize),
        ReferenceEntry("Perfect Square (sum)",
            formula: "(a + b)² = a² + 2ab + b²",
            latex: "\\[ (a+b)^2 = a^2 + 2ab + b^2 \\]",
            tag: .memorize),
        ReferenceEntry("Perfect Square (difference)",
            formula: "(a − b)² = a² − 2ab + b²",
            latex: "\\[ (a-b)^2 = a^2 - 2ab + b^2 \\]",
            tag: .memorize),
        ReferenceEntry("Difference of Squares",
            formula: "a² − b² = (a + b)(a − b)",
            latex: "\\[ a^2 - b^2 = (a+b)(a-b) \\]",
            tag: .memorize),
        ReferenceEntry("Remainder Theorem",
            formula: "f(a) = remainder when f(x) ÷ (x − a)",
            tag: .memorize),
    ])

    static let exponentsRadicals = ReferenceSection(title: "Exponents & Radicals", icon: "xmark.circle", color: .orange, entries: [
        ReferenceEntry("Product Rule",
            formula: "xᵃ · xᵇ = xᵃ⁺ᵇ",
            latex: "\\[ x^a \\cdot x^b = x^{a+b} \\]",
            tag: .memorize),
        ReferenceEntry("Quotient Rule",
            formula: "xᵃ / xᵇ = xᵃ⁻ᵇ",
            latex: "\\[ \\dfrac{x^a}{x^b} = x^{a-b} \\]",
            tag: .memorize),
        ReferenceEntry("Power of Power",
            formula: "(xᵃ)ᵇ = xᵃᵇ",
            latex: "\\[ (x^a)^b = x^{ab} \\]",
            tag: .memorize),
        ReferenceEntry("Negative Exponent",
            formula: "x⁻ᵃ = 1 / xᵃ",
            latex: "\\[ x^{-a} = \\dfrac{1}{x^a} \\]",
            tag: .memorize),
        ReferenceEntry("Fractional Exponent",
            formula: "x^(m/n) = ⁿ√(xᵐ)",
            latex: "\\[ x^{m/n} = \\sqrt[n]{x^m} \\]",
            tag: .memorize),
        ReferenceEntry("Zero Exponent",
            formula: "x⁰ = 1  (x ≠ 0)",
            latex: "\\[ x^0 = 1 \\quad (x \\neq 0) \\]",
            tag: .memorize),
        ReferenceEntry("Radical Product",
            formula: "√(ab) = √a · √b",
            latex: "\\[ \\sqrt{ab} = \\sqrt{a}\\cdot\\sqrt{b} \\]",
            tag: .memorize),
        ReferenceEntry("Radical Quotient",
            formula: "√(a/b) = √a / √b",
            latex: "\\[ \\sqrt{\\dfrac{a}{b}} = \\dfrac{\\sqrt{a}}{\\sqrt{b}} \\]",
            tag: .memorize),
    ])

    static let exponentialFunctions = ReferenceSection(title: "Exponential Functions", icon: "arrow.up.right", color: .yellow, entries: [
        ReferenceEntry("Exponential Growth",
            formula: "f(t) = a(1 + r)ᵗ",
            latex: "\\[ f(t) = a(1+r)^t \\]",
            detail: "a = initial value, r = growth rate, t = time",
            tag: .memorize),
        ReferenceEntry("Exponential Decay",
            formula: "f(t) = a(1 − r)ᵗ",
            latex: "\\[ f(t) = a(1-r)^t \\]",
            detail: "a = initial value, r = decay rate, t = time",
            tag: .memorize),
        ReferenceEntry("Simple Interest",
            formula: "I = Prt",
            latex: "\\[ I = Prt \\]",
            detail: "P = principal, r = annual rate, t = time in years",
            tag: .memorize),
        ReferenceEntry("Exponential vs. Linear",
            formula: "Constant difference → linear  |  Constant ratio → exponential",
            tag: .tip),
    ])

    static let functionsTransformations = ReferenceSection(title: "Functions & Transformations", icon: "waveform.path.ecg", color: .mint, entries: [
        ReferenceEntry("Function Notation",
            formula: "f(x) = output for input x",
            detail: "Evaluate by substituting the given input into x.",
            tag: .memorize),
        ReferenceEntry("Average Rate of Change",
            formula: "(f(b) − f(a)) / (b − a)",
            latex: "\\[ \\dfrac{f(b)-f(a)}{b-a} \\]",
            detail: "Slope of the secant line from x = a to x = b.",
            tag: .memorize),
        ReferenceEntry("Vertical Shift",
            formula: "f(x) + k (up k),  f(x) − k (down k)",
            tag: .memorize),
        ReferenceEntry("Horizontal Shift",
            formula: "f(x − h) (right h),  f(x + h) (left h)",
            tag: .memorize),
        ReferenceEntry("Reflection",
            formula: "−f(x): reflect over x-axis   |   f(−x): reflect over y-axis",
            tag: .memorize),
        ReferenceEntry("Percent Growth/Decay Form",
            formula: "new = old(1 ± r)",
            detail: "Use +r for growth and −r for decay.",
            tag: .tip),
    ])

    static let systemsInequalities = ReferenceSection(title: "Systems & Inequalities", icon: "line.3.horizontal.decrease.circle", color: .indigo, entries: [
        ReferenceEntry("System by Graphing",
            formula: "Intersection point(s) are solution(s)",
            tag: .memorize),
        ReferenceEntry("Linear System Outcomes",
            formula: "One solution (intersect)  |  No solution (parallel)  |  Infinite solutions (same line)",
            tag: .memorize),
        ReferenceEntry("Substitution Method",
            formula: "Solve one equation for a variable, then substitute into the other",
            tag: .rule),
        ReferenceEntry("Elimination Method",
            formula: "Add/subtract equations to remove one variable",
            tag: .rule),
        ReferenceEntry("Inequality Flip Rule",
            formula: "Multiply or divide both sides by a negative → flip inequality sign",
            tag: .rule),
        ReferenceEntry("Interval Notation",
            formula: "( ) excludes endpoint  |  [ ] includes endpoint",
            tag: .memorize),
    ])

    static let statisticsData = ReferenceSection(title: "Statistics & Data Analysis", icon: "chart.bar.fill", color: .cyan, entries: [
        ReferenceEntry("Mean (Average)",
            formula: "Sum ÷ Count",
            latex: "\\[ \\bar{x} = \\dfrac{\\displaystyle\\sum x}{n} \\]",
            detail: "Sensitive to outliers.",
            tag: .memorize),
        ReferenceEntry("Percent of a Whole",
            formula: "Part / Whole × 100",
            latex: "\\[ \\% = \\dfrac{\\text{part}}{\\text{whole}} \\times 100 \\]",
            tag: .memorize),
        ReferenceEntry("Percent Change",
            formula: "(New − Old) / Old × 100",
            latex: "\\[ \\% \\text{ change} = \\dfrac{\\text{new} - \\text{old}}{\\text{old}} \\times 100 \\]",
            tag: .memorize),
        ReferenceEntry("Probability",
            formula: "P(A) = favorable / total",
            latex: "\\[ P(A) = \\dfrac{\\text{favorable outcomes}}{\\text{total outcomes}} \\]",
            tag: .memorize),
        ReferenceEntry("Complement Rule",
            formula: "P(not A) = 1 − P(A)",
            latex: "\\[ P(\\text{not }A) = 1 - P(A) \\]",
            tag: .memorize),
        ReferenceEntry("Skewed Distributions",
            formula: "Right-skewed → mean > median\nLeft-skewed → mean < median\nSymmetric → mean ≈ median",
            tag: .tip),
        ReferenceEntry("Causation vs. Correlation",
            formula: "Random-assignment experiment → causation\nObservational study → correlation only",
            tag: .tip),
    ])

    static let geometry = ReferenceSection(title: "Geometry", icon: "circle.circle", color: .red, entries: [
        ReferenceEntry("Interior Angles of Polygon",
            formula: "Sum = (n − 2) × 180°",
            latex: "\\[ \\text{sum} = (n-2) \\times 180^\\circ \\]",
            detail: "n = number of sides",
            tag: .memorize),
        ReferenceEntry("Exterior Angle (Polygon)",
            formula: "Each exterior angle in regular n-gon = 360°/n",
            latex: "\\[ \\text{exterior angle} = \\dfrac{360^\\circ}{n} \\]",
            tag: .memorize),
        ReferenceEntry("Triangle Angle + Exterior Rule",
            formula: "Interior sum = 180°; exterior angle = sum of two remote interior angles",
            tag: .memorize),
        ReferenceEntry("Triangle Inequality",
            formula: "For sides a, b, c:  |a−b| < c < a+b",
            tag: .memorize),
        ReferenceEntry("Arc Length",
            formula: "L = (θ/360) × 2πr",
            latex: "\\[ L = \\dfrac{\\theta}{360} \\times 2\\pi r \\]",
            tag: .memorize),
        ReferenceEntry("Sector Area",
            formula: "A = (θ/360) × πr²",
            latex: "\\[ A = \\dfrac{\\theta}{360} \\times \\pi r^2 \\]",
            tag: .memorize),
        ReferenceEntry("Inscribed Angle Rule",
            formula: "Inscribed angle = 1/2 of intercepted arc",
            tag: .memorize),
        ReferenceEntry("Tangent-Radius Rule",
            formula: "Radius is perpendicular to tangent at point of tangency",
            tag: .memorize),
        ReferenceEntry("Equation of a Circle",
            formula: "(x − h)² + (y − k)² = r²",
            latex: "\\[ (x-h)^2 + (y-k)^2 = r^2 \\]",
            detail: "Center = (h, k), radius = r",
            tag: .memorize),
        ReferenceEntry("Distance Formula",
            formula: "d = √[(x₂−x₁)² + (y₂−y₁)²]",
            latex: "\\[ d = \\sqrt{(x_2-x_1)^2 + (y_2-y_1)^2} \\]",
            tag: .memorize),
        ReferenceEntry("Midpoint Formula",
            formula: "M = ((x₁+x₂)/2, (y₁+y₂)/2)",
            latex: "\\[ M = \\left(\\dfrac{x_1+x_2}{2},\\;\\dfrac{y_1+y_2}{2}\\right) \\]",
            tag: .memorize),
        ReferenceEntry("Point-Slope + Perpendicular Slopes",
            formula: "y−y₁=m(x−x₁);  perpendicular slopes are negative reciprocals",
            tag: .memorize),
        ReferenceEntry("Area Formulas",
            formula: "Triangle: 1/2bh  |  Trapezoid: 1/2(b₁+b₂)h  |  Parallelogram: bh",
            tag: .memorize),
        ReferenceEntry("Volume + Surface Area",
            formula: "Prism: V=lwh, SA=2(lw+lh+wh)  |  Cylinder: V=πr²h, SA=2πr²+2πrh",
            tag: .memorize),
        ReferenceEntry("Sphere + Cone",
            formula: "Sphere: V=4/3πr³, SA=4πr²  |  Cone: V=1/3πr²h",
            tag: .memorize),
        ReferenceEntry("Parallel Lines + Transversal",
            formula: "Corresponding = equal\nAlternate interior = equal\nCo-interior = supplementary",
            tag: .memorize),
        ReferenceEntry("Similar Triangles",
            formula: "Proportional sides, equal corresponding angles",
            detail: "Similarity conditions: AA, SAS, SSS",
            tag: .memorize),
    ])

    static let trigonometry = ReferenceSection(title: "Trigonometry", icon: "dial.medium", color: .pink, entries: [
        ReferenceEntry("SOH-CAH-TOA",
            formula: "sin θ = opp/hyp  |  cos θ = adj/hyp  |  tan θ = opp/adj",
            latex: """
\\[ \\begin{aligned}
\\sin\\theta &= \\dfrac{\\text{opposite}}{\\text{hypotenuse}} \\\\[8pt]
\\cos\\theta &= \\dfrac{\\text{adjacent}}{\\text{hypotenuse}} \\\\[8pt]
\\tan\\theta &= \\dfrac{\\text{opposite}}{\\text{adjacent}}
\\end{aligned} \\]
""",
            tag: .memorize),
        ReferenceEntry("Cofunction Identity",
            formula: "sin θ = cos(90° − θ)",
            latex: "\\[ \\sin\\theta = \\cos(90^\\circ - \\theta) \\qquad \\cos\\theta = \\sin(90^\\circ - \\theta) \\]",
            detail: "The sine of an angle equals the cosine of its complement.",
            tag: .memorize),
        ReferenceEntry("Degrees → Radians",
            formula: "radians = degrees × π/180",
            latex: "\\[ \\text{radians} = \\text{degrees} \\times \\dfrac{\\pi}{180} \\]",
            tag: .memorize),
        ReferenceEntry("Radians → Degrees",
            formula: "degrees = radians × 180/π",
            latex: "\\[ \\text{degrees} = \\text{radians} \\times \\dfrac{180}{\\pi} \\]",
            tag: .memorize),
        ReferenceEntry("Key Radian Values",
            formula: "π/6=30°  π/4=45°  π/3=60°  π/2=90°  π=180°",
            latex: "\\[ \\dfrac{\\pi}{6}=30^\\circ \\quad \\dfrac{\\pi}{4}=45^\\circ \\quad \\dfrac{\\pi}{3}=60^\\circ \\quad \\dfrac{\\pi}{2}=90^\\circ \\quad \\pi=180^\\circ \\]",
            tag: .memorize),
    ])

    static let desmosPlaybook = ReferenceSection(title: "Desmos SAT Playbook", icon: "chart.xyaxis.line", color: .blue, entries: [
        ReferenceEntry("Equation Solve via Intersection",
            formula: "Graph y = left side and y = right side; x-value(s) of intersections solve the equation.",
            tag: .tip),
        ReferenceEntry("System Solve",
            formula: "Enter each equation on its own line and click intersection point(s).",
            tag: .tip),
        ReferenceEntry("Domain Restriction",
            formula: "Use curly braces: y=x^2 {x>=0} to show only needed interval.",
            detail: "Great for piecewise and geometry contexts.",
            tag: .tip),
        ReferenceEntry("Table + Regression",
            formula: "Add table, fill x1/y1, then use y1~mx1+b (or y1~ax1^2+bx1+c).",
            tag: .memorize),
        ReferenceEntry("Unknown Constant (Tilde Trick)",
            formula: "Use ~ with trial inputs to solve constants quickly.",
            detail: "Example: y1 ~ a(x1−2)^2 + 5 to estimate parameter a.",
            tag: .tip),
        ReferenceEntry("Sliders for Parameters",
            formula: "Type equation with a,b,k and use slider to match graph conditions fast.",
            tag: .tip),
        ReferenceEntry("Root / Intercepts / Vertex",
            formula: "Click graph points directly to read coordinates.",
            tag: .tip),
        ReferenceEntry("Inequality Regions",
            formula: "Enter y<..., y>=... and find overlap shading for solution set.",
            tag: .tip),
        ReferenceEntry("Statistics Helpers",
            formula: "mean(list), median(list), stdev(list), and sum(list).",
            tag: .memorize),
        ReferenceEntry("Desmos Syntax Essentials",
            formula: "abs(x), sqrt(x), nthroot(x,n), log(x), ln(x), pi, e, ^ for exponent.",
            tag: .memorize),
        ReferenceEntry("Angle Mode Check",
            formula: "Use wrench settings: Degrees for most SAT trig unless radians are explicit.",
            tag: .rule),
        ReferenceEntry("When NOT to Use Desmos",
            formula: "Skip Desmos for tiny arithmetic/algebra steps where mental math is faster.",
            detail: "Use it when graphing/visualization reduces risk and saves time.",
            tag: .tip),
    ])

    // ──────────────────────────────────────────────────────── R & W ────

    static let sentenceBoundaries = ReferenceSection(title: "Sentence Boundaries", icon: "text.alignleft", color: .blue, entries: [
        ReferenceEntry("Independent Clause (IC)",
            formula: "Has subject + verb + complete thought",
            detail: "Can stand alone as a sentence.",
            tag: .rule),
        ReferenceEntry("Dependent Clause (DC)",
            formula: "Has subject + verb but NOT a complete thought",
            detail: "Cannot stand alone. Introduced by: although, because, since, when, while, if, unless…",
            tag: .rule),
        ReferenceEntry("Comma Splice ✗ — NEVER correct",
            formula: "WRONG: [IC], [IC]",
            detail: "Two independent clauses joined only by a comma is always wrong.",
            tag: .rule),
        ReferenceEntry("Joining ICs — Period",      formula: "[IC]. [IC].", tag: .rule),
        ReferenceEntry("Joining ICs — Semicolon",   formula: "[IC]; [IC].",  detail: "Both sides must be independent clauses.", tag: .rule),
        ReferenceEntry("Joining ICs — FANBOYS",     formula: "[IC], [FANBOYS] [IC].", detail: "For · And · Nor · But · Or · Yet · So", tag: .rule),
        ReferenceEntry("Dependent Clause Placement",formula: "[DC], [IC].   or   [IC] [DC].", detail: "Comma after DC when it comes first; usually none when it follows.", tag: .rule),
    ])

    static let commaRules = ReferenceSection(title: "Commas", icon: "character", color: .orange, entries: [
        ReferenceEntry("After Introductory Element",
            formula: "[Intro phrase/clause], [IC].",
            detail: "E.g., 'After the game, we went home.'",
            tag: .rule),
        ReferenceEntry("Before FANBOYS (joining two ICs)",
            formula: "[IC], [FANBOYS] [IC].",
            detail: "Only use comma if BOTH sides are full independent clauses.",
            tag: .rule),
        ReferenceEntry("Nonessential Elements",
            formula: "Set off with commas: [IC, nonessential phrase, rest].",
            detail: "Remove the phrase → sentence still makes sense → use commas.\nE.g., 'My sister, who lives in Denver, is a doctor.'",
            tag: .rule),
        ReferenceEntry("Essential Elements — NO Comma",
            formula: "Do NOT add commas around essential (restrictive) modifiers.",
            detail: "E.g., 'The student who studied most got the highest grade.'",
            tag: .rule),
        ReferenceEntry("No Comma Between S + V ✗",    formula: "WRONG: 'The tall student, passed the test.'", tag: .rule),
        ReferenceEntry("No Comma Before Direct Object ✗", formula: "WRONG: 'She wrote, a letter.'",         tag: .rule),
    ])

    static let apostrophes = ReferenceSection(title: "Apostrophes & Possessives", icon: "quote.opening", color: .purple, entries: [
        ReferenceEntry("Plural — no apostrophe",      formula: "cats  |  students  |  years  (NEVER cat's for a plural)", tag: .rule),
        ReferenceEntry("Singular Possessive",          formula: "Add 's:  dog's bone  |  class's assignment", tag: .rule),
        ReferenceEntry("Plural Possessive (ends in s)", formula: "Add only ':  students'  |  teachers'", tag: .rule),
        ReferenceEntry("Irregular Plural Possessive",  formula: "Add 's:  children's  |  men's  |  women's", tag: .rule),
        ReferenceEntry("its  vs.  it's",               formula: "its = possessive  |  it's = it is", tag: .rule),
        ReferenceEntry("their / there / they're",      formula: "their = possessive  |  there = place  |  they're = they are", tag: .rule),
        ReferenceEntry("your  vs.  you're",            formula: "your = possessive  |  you're = you are", tag: .rule),
        ReferenceEntry("whose  vs.  who's",            formula: "whose = possessive  |  who's = who is", tag: .rule),
    ])

    static let subjectVerbAgreement = ReferenceSection(title: "Subject-Verb Agreement", icon: "arrow.left.arrow.right", color: .green, entries: [
        ReferenceEntry("Core Rule",                formula: "Singular subject → singular verb\nPlural subject → plural verb", tag: .rule),
        ReferenceEntry("Prepositional Phrase Trap", formula: "Subject ≠ the noun inside 'of the…' phrase\nE.g., 'The box of chocolates IS open.'", tag: .rule),
        ReferenceEntry("Collective Nouns",         formula: "Usually singular: team, group, committee, family, jury, audience", tag: .rule),
        ReferenceEntry("Singular Indefinite Pronouns", formula: "everyone, someone, anyone, nobody, each, either, neither, one → singular verb", tag: .rule),
        ReferenceEntry("Or / Nor Rule",            formula: "Verb agrees with the closest subject\nE.g., 'Neither the teacher nor the students WERE late.'", tag: .rule),
        ReferenceEntry("There Is / There Are",     formula: "Verb agrees with the real subject after 'there'\nE.g., 'There ARE many reasons.'", tag: .rule),
    ])

    static let verbTense = ReferenceSection(title: "Verb Tense & Form", icon: "clock.arrow.circlepath", color: .yellow, entries: [
        ReferenceEntry("Tense Consistency",    formula: "Maintain same tense unless a time shift is explicitly stated.", tag: .rule),
        ReferenceEntry("Simple Tenses",        formula: "Past: ran, wrote\nPresent: runs, writes\nFuture: will run, will write", tag: .rule),
        ReferenceEntry("Present Perfect",      formula: "has / have + past participle", detail: "Action started in the past and still relevant now.", tag: .rule),
        ReferenceEntry("Past Perfect",         formula: "had + past participle", detail: "Completed before another past action.", tag: .rule),
        ReferenceEntry("Progressive",          formula: "be + -ing  (is writing, was writing)", detail: "Ongoing / continuing action.", tag: .rule),
    ])

    static let pronouns = ReferenceSection(title: "Pronouns", icon: "person.fill", color: .red, entries: [
        ReferenceEntry("Subject Pronouns",     formula: "I, you, he, she, it, we, they, who", detail: "Used as the subject of a verb.", tag: .rule),
        ReferenceEntry("Object Pronouns",      formula: "me, you, him, her, it, us, them, whom", detail: "Used as object of a verb or preposition.", tag: .rule),
        ReferenceEntry("Who vs. Whom",         formula: "Who = subject  |  Whom = object", detail: "Test: substitute he/him. 'He' fits → who; 'him' fits → whom.", tag: .rule),
        ReferenceEntry("Reflexive Pronouns ✗", formula: "WRONG: 'Contact myself.'  RIGHT: 'Contact me.'", detail: "Only correct when subject and object are the same person.", tag: .rule),
        ReferenceEntry("Pronoun-Antecedent",   formula: "Singular antecedent → singular pronoun\nPlural antecedent → plural pronoun", tag: .rule),
    ])

    static let modifiers = ReferenceSection(title: "Modifiers", icon: "wand.and.stars", color: .teal, entries: [
        ReferenceEntry("Core Rule",            formula: "A modifier must sit immediately next to what it modifies.", tag: .rule),
        ReferenceEntry("Dangling Modifier ✗",  formula: "WRONG: 'Running to the bus, the rain started.'\nRIGHT: 'Running to the bus, she got caught in the rain.'", detail: "The subject of the main clause must be the doer of the opening phrase.", tag: .rule),
        ReferenceEntry("Misplaced Modifier ✗", formula: "WRONG: 'She almost drove her kids to school every day.'\nRIGHT: 'She drove her kids to school almost every day.'", tag: .rule),
    ])

    static let parallelStructure = ReferenceSection(title: "Parallel Structure", icon: "equal.square", color: .indigo, entries: [
        ReferenceEntry("Core Rule",            formula: "Items in a list or comparison must have the same grammatical form.", tag: .rule),
        ReferenceEntry("Lists ✗",              formula: "WRONG: 'She likes hiking, swimming, and to run.'\nRIGHT: 'She likes hiking, swimming, and running.'", tag: .rule),
        ReferenceEntry("Comparisons",          formula: "WRONG: 'He prefers reading to watch TV.'\nRIGHT: 'He prefers reading to watching TV.'", tag: .rule),
        ReferenceEntry("Correlative Conjunctions", formula: "both…and  |  either…or  |  neither…nor  |  not only…but also", detail: "Both sides must match in grammatical form.", tag: .rule),
        ReferenceEntry("Illogical Comparison ✗", formula: "WRONG: 'He scored higher than any student.'\nRIGHT: 'He scored higher than any OTHER student.'", detail: "Use 'other' or 'else' when comparing one to its own group.", tag: .rule),
    ])

    static let transitions = ReferenceSection(title: "Transitions", icon: "arrow.triangle.swap", color: .brown, entries: [
        ReferenceEntry("Addition",        formula: "furthermore  ·  moreover  ·  in addition  ·  additionally  ·  also  ·  likewise", tag: .rule),
        ReferenceEntry("Contrast",        formula: "however  ·  nevertheless  ·  nonetheless  ·  on the other hand  ·  in contrast  ·  although  ·  whereas  ·  despite", tag: .rule),
        ReferenceEntry("Cause / Result",  formula: "therefore  ·  thus  ·  consequently  ·  as a result  ·  hence  ·  for this reason", tag: .rule),
        ReferenceEntry("Example",         formula: "for example  ·  for instance  ·  specifically  ·  in particular  ·  to illustrate", tag: .rule),
        ReferenceEntry("Emphasis",        formula: "indeed  ·  in fact  ·  that is  ·  in other words  ·  to clarify", tag: .rule),
        ReferenceEntry("Sequence / Time", formula: "first  ·  then  ·  next  ·  finally  ·  subsequently  ·  afterward  ·  previously  ·  meanwhile", tag: .rule),
        ReferenceEntry("Similarity",      formula: "similarly  ·  likewise  ·  in the same way  ·  just as", tag: .rule),
        ReferenceEntry("Conclusion",      formula: "in summary  ·  in conclusion  ·  overall  ·  ultimately  ·  in short", tag: .rule),
        ReferenceEntry("Key Strategy",    formula: "Read BOTH sides of the blank, then match the logical relationship.", detail: "'However' ≠ 'therefore' ≠ 'furthermore' — they are not interchangeable.", tag: .tip),
    ])

    static let wordsInContext = ReferenceSection(title: "Words in Context", icon: "text.magnifyingglass", color: .cyan, entries: [
        ReferenceEntry("Core Approach",        formula: "Focus on HOW the word functions in context, not its dictionary definition.", tag: .tip),
        ReferenceEntry("Tone Check",           formula: "Positive / negative / neutral?  Formal / informal?  Intense / mild?", tag: .tip),
        ReferenceEntry("Connotation Matters",  formula: "'Curious' vs. 'nosy' — similar meaning, very different tone.", detail: "Choose the word that fits the specific nuance of the sentence.", tag: .tip),
        ReferenceEntry("Rhetorical Synthesis", formula: "Match the answer to the GOAL stated in the question:\nargue · compare · illustrate · introduce · contrast…", tag: .tip),
        ReferenceEntry("Best Evidence",        formula: "Most specific and direct quotation that supports the claim — not just related to the topic.", tag: .tip),
        ReferenceEntry("Inference Rule",       formula: "Most reasonable conclusion from the text. Not a leap. No outside knowledge.", tag: .tip),
        ReferenceEntry("Cross-Text",           formula: "Agree · Disagree · Support · Challenge · Qualify", detail: "Be specific — identify the exact claim that relates the two texts.", tag: .tip),
    ])

    static let rhetoricalSynthesis = ReferenceSection(title: "Rhetorical Synthesis", icon: "square.and.pencil", color: .mint, entries: [
        ReferenceEntry("Follow the Prompt Goal",
            formula: "Choose the option that best accomplishes the stated task.",
            detail: "Common goals: introduce, compare, support, qualify, conclude.",
            tag: .rule),
        ReferenceEntry("Use Relevant Notes Only",
            formula: "Select facts directly tied to the purpose; ignore extras.",
            tag: .rule),
        ReferenceEntry("Prioritize Precision",
            formula: "Prefer concise, direct wording over vague or flashy phrasing.",
            tag: .tip),
        ReferenceEntry("Maintain Formal Tone",
            formula: "SAT favors objective, neutral academic style.",
            tag: .rule),
    ])

    static let readingStrategies = ReferenceSection(title: "Reading Strategies", icon: "eyeglasses", color: .teal, entries: [
        ReferenceEntry("Line-Reference Questions",
            formula: "Read cited lines plus nearby context before choosing.",
            tag: .tip),
        ReferenceEntry("Best Evidence Pair",
            formula: "Answer claim first, then confirm with exact support lines.",
            tag: .tip),
        ReferenceEntry("Main Purpose",
            formula: "Identify what the author is doing: argue, explain, compare, qualify.",
            tag: .tip),
        ReferenceEntry("Eliminate Extreme Wording",
            formula: "Be cautious with always / never / completely choices.",
            tag: .tip),
        ReferenceEntry("Data Questions",
            formula: "Read title, axis labels, and units before evaluating claims.",
            tag: .tip),
    ])
}

// MARK: - Main View

struct ReferenceView: View {
    @State private var selectedSubject = 0
    @State private var searchText = ""
    @State private var expandedSections: Set<String> = []
    @State private var viewportWidth: CGFloat = 0

    private var isTwoColumn: Bool { viewportWidth >= 700 }

    private var currentSections: [ReferenceSection] {
        selectedSubject == 0 ? ReferenceSection.mathSections : ReferenceSection.rwSections
    }

    private func filtered(_ sections: [ReferenceSection]) -> [ReferenceSection] {
        guard !searchText.isEmpty else { return sections }
        return sections.compactMap { section in
            let hits = section.entries.filter { entry in
                entry.title.localizedCaseInsensitiveContains(searchText)
                || (entry.formula?.localizedCaseInsensitiveContains(searchText) ?? false)
                || (entry.detail?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
            guard !hits.isEmpty else { return nil }
            return ReferenceSection(title: section.title, icon: section.icon, color: section.color, entries: hits)
        }
    }

    private var filteredSections: [ReferenceSection] { filtered(currentSections) }
    private var filteredMathSections: [ReferenceSection] { filtered(ReferenceSection.mathSections) }
    private var filteredRWSections: [ReferenceSection] { filtered(ReferenceSection.rwSections) }

    var body: some View {
        NavigationStack {
            referenceMainScrollLayout
        }
        .navigationTitle("Reference")
        .navLargeTitle()
        .trackViewportWidth($viewportWidth)
        .onChange(of: searchText) { _, new in
            if !new.isEmpty {
                var t = Transaction()
                t.animation = nil
                withTransaction(t) {
                    if isTwoColumn {
                        expandedSections = Set(
                            (filteredMathSections + filteredRWSections).map(\.id)
                        )
                    } else {
                        expandedSections = Set(filteredSections.map(\.id))
                    }
                }
            }
        }
    }

    /// In-column search (same width as list/cards). `.searchable` on the tab often pins to the sidebar on iPad.
    private var referenceSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
            TextField("Search formulas and rules…", text: $searchText)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                #endif
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.secondary.opacity(0.14))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Search formulas and rules")
    }

    /// Chip strip + search + card accordion (shared on iOS, iPad, and macOS).
    private var referenceMainScrollLayout: some View {
        VStack(spacing: 0) {
            if !isTwoColumn {
                subjectChipStrip
                    .padding(.horizontal, referenceChipStripHorizontalPadding)
                    .padding(.vertical, referenceChipStripVerticalPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondarySystemGroupedBackground)
                    .onChange(of: selectedSubject) { _, _ in expandedSections.removeAll() }
            }

            referenceSearchBar
                .padding(.horizontal, referenceChipStripHorizontalPadding)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondarySystemGroupedBackground)

            if isTwoColumn {
                twoColumnScrollLayout
            } else {
                singleColumnScrollLayout
            }
        }
    }

    private var singleColumnScrollLayout: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredSections) { section in
                    sectionCard(section)
                }
                if filteredSections.isEmpty {
                    ContentUnavailableView {
                        Label("No matches", systemImage: "magnifyingglass")
                    } description: {
                        Text(searchText.isEmpty ? "Choose Math or Reading & Writing." : "Nothing matches \"\(searchText)\".")
                    }
                    .padding(.top, 24)
                }
            }
            .padding(referenceListOuterPadding)
            .readableContentFrame(maxWidth: LayoutMetrics.referenceReadableMaxWidth, alignment: .leading)
        }
        .background(Color.systemGroupedBackground)
    }

    private var twoColumnScrollLayout: some View {
        ScrollView {
            HStack(alignment: .top, spacing: referenceListOuterPadding) {
                referenceColumn(
                    title: "Math",
                    icon: "function",
                    sections: filteredMathSections
                )
                referenceColumn(
                    title: "Reading & Writing",
                    icon: "text.alignleft",
                    sections: filteredRWSections
                )
            }
            .padding(referenceListOuterPadding)
        }
        .background(Color.systemGroupedBackground)
    }

    private func referenceColumn(title: String, icon: String, sections: [ReferenceSection]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.bottom, 2)
            if sections.isEmpty {
                ContentUnavailableView {
                    Label("No matches", systemImage: "magnifyingglass")
                } description: {
                    Text("Nothing matches \"\(searchText)\".")
                }
                .padding(.top, 24)
            } else {
                ForEach(sections) { section in
                    sectionCard(section)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func sectionCard(_ section: ReferenceSection) -> some View {
        ReferenceSectionCard(
            section: section,
            isExpanded: expandedSections.contains(section.id),
            onToggle: {
                withAnimation(.easeOut(duration: 0.2)) {
                    if expandedSections.contains(section.id) {
                        expandedSections.remove(section.id)
                    } else {
                        expandedSections.insert(section.id)
                    }
                }
            }
        )
    }

    private var referenceChipStripHorizontalPadding: CGFloat {
        MacStudiumDesign.practiceMainPaddingH
    }

    private var referenceChipStripVerticalPadding: CGFloat { 12 }

    private var referenceListOuterPadding: CGFloat {
        MacStudiumDesign.practiceMainPaddingH
    }

    private var subjectChipStrip: some View {
        HStack(spacing: 8) {
            FilterChipButton(title: "Math", isSelected: selectedSubject == 0, accent: .blue, fillsGridCell: true) {
                selectedSubject = 0
            }
            FilterChipButton(title: "Reading & Writing", isSelected: selectedSubject == 1, accent: .blue, fillsGridCell: true) {
                selectedSubject = 1
            }
        }
    }
}

// MARK: - Section Card

struct ReferenceSectionCard: View {
    let section: ReferenceSection
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: section.icon)
                        .font(.subheadline)
                        .foregroundColor(section.color)
                        .frame(width: 30, height: 30)
                        .background(section.color.opacity(0.12))
                        .cornerRadius(8)

                    Text(section.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(section.entries.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.systemGray5)
                        .cornerRadius(8)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.horizontal, 14)
                ForEach(section.entries) { entry in
                    ReferenceEntryRow(entry: entry, accentColor: section.color)
                    if entry.id != section.entries.last?.id {
                        Divider().padding(.horizontal, 14)
                    }
                }
            }
        }
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(14)
    }
}

// MARK: - Entry Row

struct ReferenceEntryRow: View {
    let entry: ReferenceEntry
    let accentColor: Color

    @ViewBuilder
    private func referencePlainFormula(_ formula: String, accentColor: Color) -> some View {
        Text(formula)
            .font(.system(.callout, design: .monospaced))
            .foregroundColor(accentColor)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accentColor.opacity(0.07))
            .cornerRadius(10)
    }

    private var tagColor: Color {
        switch entry.tag {
        case .provided: return .green
        case .memorize: return .orange
        case .rule:     return .blue
        case .tip:      return .purple
        case .none:     return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(entry.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let tag = entry.tag {
                    FilterBadge(text: tag.rawValue, accent: tagColor)
                }
            }

            // Apple platforms except macOS: prefer plain `formula` so Reference doesn’t spawn dozens of MathJax webviews.
            #if os(macOS)
            if let latex = entry.latex {
                MathFormulaView(latex: latex, accentColor: accentColor)
            } else if let formula = entry.formula {
                referencePlainFormula(formula, accentColor: accentColor)
            }
            #else
            if let latex = entry.latex, entry.formula == nil {
                MathFormulaView(latex: latex, accentColor: accentColor)
            } else if let formula = entry.formula {
                referencePlainFormula(formula, accentColor: accentColor)
            }
            #endif

            if let detail = entry.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

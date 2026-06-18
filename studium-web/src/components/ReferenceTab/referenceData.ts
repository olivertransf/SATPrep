export type EntryTag = 'provided' | 'memorize' | 'rule' | 'tip'

export interface ReferenceEntry {
  title: string
  formula?: string
  latex?: string
  detail?: string
  tag?: EntryTag
}

export interface ReferenceSection {
  id: string
  title: string
  color: string   // CSS color string
  entries: ReferenceEntry[]
}

// ─────────────────────────────── MATH ──────────────────────────────────────

const providedFormulas: ReferenceSection = {
  id: 'provided-formulas',
  title: 'Formulas Provided on the Test',
  color: '#16a34a',
  entries: [
    { title: 'Circle Area',            formula: 'A = πr²',           latex: 'A = \\pi r^2',                                      tag: 'provided' },
    { title: 'Rectangle Area',         formula: 'A = lw',            latex: 'A = lw',                                             tag: 'provided' },
    { title: 'Triangle Area',          formula: 'A = ½bh',           latex: 'A = \\tfrac{1}{2}bh',                                tag: 'provided' },
    { title: 'Circle Circumference',   formula: 'C = 2πr',           latex: 'C = 2\\pi r',                                        tag: 'provided' },
    { title: 'Pythagorean Theorem',    formula: 'a² + b² = c²',      latex: 'a^2 + b^2 = c^2',                                   tag: 'provided' },
    { title: '45-45-90 Triangle',      formula: 'Legs: x, x  |  Hyp: x√2',  latex: '\\text{legs: }x,\\ x \\quad \\text{hyp: }x\\sqrt{2}', tag: 'provided' },
    { title: '30-60-90 Triangle',      formula: 'Legs: x, x√3  |  Hyp: 2x', latex: '\\text{legs: }x,\\ x\\sqrt{3} \\quad \\text{hyp: }2x', tag: 'provided' },
    { title: 'Rectangular Prism Vol.', formula: 'V = lwh',           latex: 'V = lwh',                                            tag: 'provided' },
    { title: 'Cylinder Volume',        formula: 'V = πr²h',          latex: 'V = \\pi r^2 h',                                    tag: 'provided' },
    { title: 'Sphere Volume',          formula: 'V = (4/3)πr³',      latex: 'V = \\tfrac{4}{3}\\pi r^3',                         tag: 'provided' },
    { title: 'Cone Volume',            formula: 'V = (1/3)πr²h',     latex: 'V = \\tfrac{1}{3}\\pi r^2 h',                       tag: 'provided' },
    { title: 'Pyramid Volume',         formula: 'V = (1/3)lwh',      latex: 'V = \\tfrac{1}{3}lwh',                               tag: 'provided' },
    { title: 'Angle Facts',            formula: 'Circle = 360°  |  Triangle = 180°', latex: '\\text{circle} = 360^\\circ \\quad \\text{triangle} = 180^\\circ', tag: 'provided' },
  ],
}

const linearEquations: ReferenceSection = {
  id: 'linear-equations',
  title: 'Linear Equations & Graphs',
  color: '#007aff',
  entries: [
    { title: 'Slope',              formula: 'm = (y₂ − y₁) / (x₂ − x₁)', latex: 'm = \\dfrac{y_2 - y_1}{x_2 - x_1}',    tag: 'memorize' },
    { title: 'Slope-Intercept',    formula: 'y = mx + b',                  latex: 'y = mx + b',    detail: 'm = slope, b = y-intercept', tag: 'memorize' },
    { title: 'Point-Slope Form',   formula: 'y − y₁ = m(x − x₁)',         latex: 'y - y_1 = m(x - x_1)',                  tag: 'memorize' },
    { title: 'Standard Form',      formula: 'Ax + By = C',                 latex: 'Ax + By = C',                           tag: 'memorize' },
    { title: 'Parallel Lines',     formula: 'm₁ = m₂',                    latex: 'm_1 = m_2',                             tag: 'memorize' },
    { title: 'Perpendicular Lines',formula: 'm₁ × m₂ = −1',               latex: 'm_1 \\times m_2 = -1',                  tag: 'memorize' },
    { title: 'No Solution',        formula: 'Parallel lines — same slope, different y-intercepts',                        tag: 'tip' },
    { title: 'Infinite Solutions',  formula: 'Same line — same slope, same y-intercept',                                  tag: 'tip' },
  ],
}

const quadratics: ReferenceSection = {
  id: 'quadratics',
  title: 'Quadratics & Polynomials',
  color: '#a855f7',
  entries: [
    { title: 'Standard Form',       formula: 'y = ax² + bx + c',        latex: 'y = ax^2 + bx + c',     detail: 'a > 0 opens up (min), a < 0 opens down (max)', tag: 'memorize' },
    { title: 'Vertex Form',         formula: 'y = a(x − h)² + k',       latex: 'y = a(x-h)^2 + k \\quad \\text{vertex: }(h,k)', tag: 'memorize' },
    { title: 'Factored Form',       formula: 'y = a(x − r₁)(x − r₂)',   latex: 'y = a(x-r_1)(x-r_2)',   detail: 'Roots / zeros = r₁ and r₂', tag: 'memorize' },
    { title: 'Quadratic Formula',   formula: 'x = [−b ± √(b² − 4ac)] / 2a', latex: 'x = \\dfrac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}', tag: 'memorize' },
    { title: 'Vertex x-coord',      formula: 'x = −b / 2a',             latex: 'x = -\\dfrac{b}{2a}',   detail: 'Sub back in to find y.', tag: 'memorize' },
    { title: 'Discriminant',        formula: '> 0 → two roots  = 0 → one root  < 0 → no roots', latex: 'b^2 - 4ac\\begin{cases}>0&\\text{two real roots}\\\\=0&\\text{one real root}\\\\<0&\\text{no real roots}\\end{cases}', tag: 'memorize' },
    { title: 'Perfect Square (sum)',formula: '(a + b)² = a² + 2ab + b²', latex: '(a+b)^2 = a^2 + 2ab + b^2', tag: 'memorize' },
    { title: 'Perfect Square (diff)',formula: '(a − b)² = a² − 2ab + b²', latex: '(a-b)^2 = a^2 - 2ab + b^2', tag: 'memorize' },
    { title: 'Difference of Squares',formula: 'a² − b² = (a + b)(a − b)', latex: 'a^2 - b^2 = (a+b)(a-b)', tag: 'memorize' },
    { title: 'Remainder Theorem',   formula: 'f(a) = remainder when f(x) ÷ (x − a)', tag: 'memorize' },
  ],
}

const exponentsRadicals: ReferenceSection = {
  id: 'exponents-radicals',
  title: 'Exponents & Radicals',
  color: '#f97316',
  entries: [
    { title: 'Product Rule',        formula: 'xᵃ · xᵇ = xᵃ⁺ᵇ',       latex: 'x^a \\cdot x^b = x^{a+b}',   tag: 'memorize' },
    { title: 'Quotient Rule',       formula: 'xᵃ / xᵇ = xᵃ⁻ᵇ',        latex: '\\dfrac{x^a}{x^b} = x^{a-b}', tag: 'memorize' },
    { title: 'Power of Power',      formula: '(xᵃ)ᵇ = xᵃᵇ',           latex: '(x^a)^b = x^{ab}',           tag: 'memorize' },
    { title: 'Negative Exponent',   formula: 'x⁻ᵃ = 1 / xᵃ',          latex: 'x^{-a} = \\dfrac{1}{x^a}',  tag: 'memorize' },
    { title: 'Fractional Exponent', formula: 'x^(m/n) = ⁿ√(xᵐ)',      latex: 'x^{m/n} = \\sqrt[n]{x^m}',  tag: 'memorize' },
    { title: 'Zero Exponent',       formula: 'x⁰ = 1  (x ≠ 0)',        latex: 'x^0 = 1 \\quad (x \\neq 0)', tag: 'memorize' },
    { title: 'Radical Product',     formula: '√(ab) = √a · √b',        latex: '\\sqrt{ab} = \\sqrt{a}\\cdot\\sqrt{b}', tag: 'memorize' },
    { title: 'Radical Quotient',    formula: '√(a/b) = √a / √b',       latex: '\\sqrt{\\dfrac{a}{b}} = \\dfrac{\\sqrt{a}}{\\sqrt{b}}', tag: 'memorize' },
  ],
}

const exponentialFunctions: ReferenceSection = {
  id: 'exponential-functions',
  title: 'Exponential Functions',
  color: '#eab308',
  entries: [
    { title: 'Exponential Growth',  formula: 'f(t) = a(1 + r)ᵗ', latex: 'f(t) = a(1+r)^t', detail: 'a = initial, r = growth rate, t = time', tag: 'memorize' },
    { title: 'Exponential Decay',   formula: 'f(t) = a(1 − r)ᵗ', latex: 'f(t) = a(1-r)^t', detail: 'a = initial, r = decay rate, t = time',  tag: 'memorize' },
    { title: 'Simple Interest',     formula: 'I = Prt',            latex: 'I = Prt',          detail: 'P = principal, r = annual rate, t = years', tag: 'memorize' },
    { title: 'Exp. vs. Linear',     formula: 'Constant difference → linear  |  Constant ratio → exponential', tag: 'tip' },
  ],
}

const functionsTransformations: ReferenceSection = {
  id: 'functions-transformations',
  title: 'Functions & Transformations',
  color: '#14b8a6',
  entries: [
    { title: 'Function Notation',       formula: 'f(x) = output for input x', detail: 'Evaluate by substituting the given input into x.', tag: 'memorize' },
    { title: 'Avg. Rate of Change',     formula: '(f(b) − f(a)) / (b − a)',   latex: '\\dfrac{f(b)-f(a)}{b-a}', detail: 'Slope of secant line from x = a to x = b.', tag: 'memorize' },
    { title: 'Vertical Shift',          formula: 'f(x) + k (up k),  f(x) − k (down k)', tag: 'memorize' },
    { title: 'Horizontal Shift',        formula: 'f(x − h) (right h),  f(x + h) (left h)', tag: 'memorize' },
    { title: 'Reflection',              formula: '−f(x): over x-axis  |  f(−x): over y-axis', tag: 'memorize' },
    { title: 'Percent Growth/Decay',    formula: 'new = old(1 ± r)', detail: 'Use +r for growth and −r for decay.', tag: 'tip' },
  ],
}

const systemsInequalities: ReferenceSection = {
  id: 'systems-inequalities',
  title: 'Systems & Inequalities',
  color: '#5856d6',
  entries: [
    { title: 'System by Graphing',     formula: 'Intersection point(s) are solution(s)', tag: 'memorize' },
    { title: 'Linear System Outcomes', formula: 'One (intersect)  |  None (parallel)  |  Infinite (same line)', tag: 'memorize' },
    { title: 'Substitution Method',    formula: 'Solve one equation for a variable, then substitute into the other', tag: 'rule' },
    { title: 'Elimination Method',     formula: 'Add/subtract equations to remove one variable', tag: 'rule' },
    { title: 'Inequality Flip Rule',   formula: 'Multiply or divide both sides by a negative → flip inequality sign', tag: 'rule' },
    { title: 'Interval Notation',      formula: '( ) excludes endpoint  |  [ ] includes endpoint', tag: 'memorize' },
  ],
}

const statisticsData: ReferenceSection = {
  id: 'statistics-data',
  title: 'Statistics & Data Analysis',
  color: '#06b6d4',
  entries: [
    { title: 'Mean (Average)',          formula: 'Sum ÷ Count',                latex: '\\bar{x} = \\dfrac{\\sum x}{n}',          detail: 'Sensitive to outliers.', tag: 'memorize' },
    { title: 'Percent of a Whole',      formula: 'Part / Whole × 100',         latex: '\\% = \\dfrac{\\text{part}}{\\text{whole}} \\times 100', tag: 'memorize' },
    { title: 'Percent Change',          formula: '(New − Old) / Old × 100',    latex: '\\%\\text{ change} = \\dfrac{\\text{new}-\\text{old}}{\\text{old}} \\times 100', tag: 'memorize' },
    { title: 'Probability',             formula: 'P(A) = favorable / total',   latex: 'P(A) = \\dfrac{\\text{favorable}}{\\text{total}}', tag: 'memorize' },
    { title: 'Complement Rule',         formula: 'P(not A) = 1 − P(A)',        latex: 'P(\\text{not }A) = 1 - P(A)',             tag: 'memorize' },
    { title: 'Skewed Distributions',    formula: 'Right-skewed → mean > median\nLeft-skewed → mean < median\nSymmetric → mean ≈ median', tag: 'tip' },
    { title: 'Causation vs. Correlation', formula: 'Random-assignment → causation\nObservational → correlation only', tag: 'tip' },
  ],
}

const geometry: ReferenceSection = {
  id: 'geometry',
  title: 'Geometry',
  color: '#ef4444',
  entries: [
    { title: 'Interior Angles (Polygon)', formula: 'Sum = (n − 2) × 180°',    latex: '\\text{sum} = (n-2)\\times180^\\circ', detail: 'n = number of sides', tag: 'memorize' },
    { title: 'Exterior Angle (Regular)', formula: 'Each = 360°/n',             latex: '\\dfrac{360^\\circ}{n}', tag: 'memorize' },
    { title: 'Triangle Angle Rule',      formula: 'Interior sum = 180°; exterior = sum of two remote interior angles', tag: 'memorize' },
    { title: 'Triangle Inequality',      formula: 'For sides a, b, c:  |a−b| < c < a+b', tag: 'memorize' },
    { title: 'Arc Length',               formula: 'L = (θ/360) × 2πr',         latex: 'L = \\dfrac{\\theta}{360}\\times2\\pi r', tag: 'memorize' },
    { title: 'Sector Area',              formula: 'A = (θ/360) × πr²',         latex: 'A = \\dfrac{\\theta}{360}\\times\\pi r^2', tag: 'memorize' },
    { title: 'Inscribed Angle',          formula: 'Inscribed angle = ½ intercepted arc', tag: 'memorize' },
    { title: 'Tangent-Radius',           formula: 'Radius ⊥ tangent at point of tangency', tag: 'memorize' },
    { title: 'Equation of a Circle',     formula: '(x − h)² + (y − k)² = r²', latex: '(x-h)^2+(y-k)^2=r^2', detail: 'Center = (h, k), radius = r', tag: 'memorize' },
    { title: 'Distance Formula',         formula: 'd = √[(x₂−x₁)² + (y₂−y₁)²]', latex: 'd = \\sqrt{(x_2-x_1)^2+(y_2-y_1)^2}', tag: 'memorize' },
    { title: 'Midpoint Formula',         formula: 'M = ((x₁+x₂)/2, (y₁+y₂)/2)', latex: 'M = \\left(\\dfrac{x_1+x_2}{2},\\dfrac{y_1+y_2}{2}\\right)', tag: 'memorize' },
    { title: 'Area Formulas',            formula: 'Triangle: ½bh  |  Trapezoid: ½(b₁+b₂)h  |  Parallelogram: bh', tag: 'memorize' },
    { title: 'Prism Volume/SA',          formula: 'V=lwh, SA=2(lw+lh+wh)', tag: 'memorize' },
    { title: 'Sphere & Cone',            formula: 'Sphere: V=4/3πr³, SA=4πr²  |  Cone: V=1/3πr²h', tag: 'memorize' },
  ],
}

const trigonometry: ReferenceSection = {
  id: 'trigonometry',
  title: 'Trigonometry',
  color: '#ec4899',
  entries: [
    { title: 'SOH-CAH-TOA', formula: 'sin θ = opp/hyp  |  cos θ = adj/hyp  |  tan θ = opp/adj',
      latex: '\\sin\\theta = \\dfrac{\\text{opp}}{\\text{hyp}} \\quad \\cos\\theta = \\dfrac{\\text{adj}}{\\text{hyp}} \\quad \\tan\\theta = \\dfrac{\\text{opp}}{\\text{adj}}', tag: 'memorize' },
    { title: 'Pythagorean Identity', formula: 'sin²θ + cos²θ = 1',  latex: '\\sin^2\\theta + \\cos^2\\theta = 1', tag: 'memorize' },
    { title: 'Co-function',          formula: 'sin θ = cos(90° − θ)', latex: '\\sin\\theta = \\cos(90^\\circ - \\theta)', tag: 'memorize' },
    { title: 'Reference Angles',     formula: '30°: sin=½, cos=√3/2\n45°: sin=cos=√2/2\n60°: sin=√3/2, cos=½', tag: 'memorize' },
    { title: 'tan in terms of sin/cos', formula: 'tan θ = sin θ / cos θ', latex: '\\tan\\theta = \\dfrac{\\sin\\theta}{\\cos\\theta}', tag: 'memorize' },
    { title: 'Radians ↔ Degrees',    formula: '180° = π rad  →  multiply by π/180 or 180/π', tag: 'memorize' },
  ],
}

const desmosPlaybook: ReferenceSection = {
  id: 'desmos-playbook',
  title: 'Desmos SAT Playbook',
  color: '#007aff',
  entries: [
    { title: 'Solve via Intersection', formula: 'Graph y = left side and y = right side; x-values at intersections are solutions.', tag: 'tip' },
    { title: 'System Solve',           formula: 'Enter each equation on its own line and click the intersection point(s).', tag: 'tip' },
    { title: 'Vertex of Parabola',     formula: 'Graph the quadratic; click the minimum/maximum point.', tag: 'tip' },
    { title: 'Find Zeros',             formula: 'Graph f(x); click where the curve crosses the x-axis.', tag: 'tip' },
    { title: 'Circle Equation',        formula: 'Type (x−h)²+(y−k)²=r² directly to see the circle.', tag: 'tip' },
    { title: 'Sliders',                formula: 'Type a, b, or c to create sliders — great for exploring transformations.', tag: 'tip' },
    { title: 'Tables',                 formula: 'Click + → Table to plot points or test specific x/y values.', tag: 'tip' },
  ],
}

// ─────────────────────────────── R&W ──────────────────────────────────────

const sentenceBoundaries: ReferenceSection = {
  id: 'sentence-boundaries',
  title: 'Sentence Boundaries',
  color: '#007aff',
  entries: [
    { title: 'Independent Clause (IC)',    formula: 'Has subject + verb + complete thought', detail: 'Can stand alone as a sentence.', tag: 'rule' },
    { title: 'Dependent Clause (DC)',      formula: 'Has subject + verb but NOT a complete thought', detail: 'Introduced by: although, because, since, when, while, if, unless…', tag: 'rule' },
    { title: 'Comma Splice (NEVER correct)', formula: 'WRONG: [IC], [IC]', detail: 'Two ICs joined only by a comma is always wrong.', tag: 'rule' },
    { title: 'Joining ICs — Period',       formula: '[IC]. [IC].', tag: 'rule' },
    { title: 'Joining ICs — Semicolon',    formula: '[IC]; [IC].', detail: 'Both sides must be independent clauses.', tag: 'rule' },
    { title: 'Joining ICs — FANBOYS',      formula: '[IC], [FANBOYS] [IC].', detail: 'For · And · Nor · But · Or · Yet · So', tag: 'rule' },
    { title: 'Dependent Clause Placement', formula: '[DC], [IC].  or  [IC] [DC].', detail: 'Comma after DC when first; usually none when it follows.', tag: 'rule' },
  ],
}

const commaRules: ReferenceSection = {
  id: 'comma-rules',
  title: 'Commas',
  color: '#f97316',
  entries: [
    { title: 'After Introductory Element', formula: '[Intro phrase/clause], [IC].', detail: "E.g., 'After the game, we went home.'", tag: 'rule' },
    { title: 'Before FANBOYS',             formula: '[IC], [FANBOYS] [IC].', detail: 'Only with comma if BOTH sides are full ICs.', tag: 'rule' },
    { title: 'Nonessential Elements',      formula: 'Set off with commas: [IC, nonessential, rest].', detail: "Remove phrase → sentence still makes sense → commas.\nE.g., 'My sister, who lives in Denver, is a doctor.'", tag: 'rule' },
    { title: 'Essential Elements (no comma)', formula: 'Do NOT add commas around restrictive modifiers.', detail: "'The student who studied most got the highest grade.'", tag: 'rule' },
    { title: 'No Comma Between S + V',     formula: "WRONG: 'The tall student, passed the test.'", tag: 'rule' },
    { title: 'No Comma Before Object',     formula: "WRONG: 'She wrote, a letter.'", tag: 'rule' },
  ],
}

const apostrophes: ReferenceSection = {
  id: 'apostrophes',
  title: 'Apostrophes & Possessives',
  color: '#a855f7',
  entries: [
    { title: 'Plural (no apostrophe)',        formula: 'cats  |  students  |  years  (NEVER cat\'s for plural)', tag: 'rule' },
    { title: 'Singular Possessive',           formula: "Add 's:  dog's bone  |  class's assignment", tag: 'rule' },
    { title: 'Plural Possessive (ends in s)', formula: "Add only ':  students'  |  teachers'", tag: 'rule' },
    { title: 'Irregular Plural Possessive',   formula: "Add 's:  children's  |  men's  |  women's", tag: 'rule' },
    { title: "its vs. it's",                  formula: "its = possessive  |  it's = it is", tag: 'rule' },
    { title: "their / there / they're",       formula: "their = possessive  |  there = place  |  they're = they are", tag: 'rule' },
    { title: "your vs. you're",               formula: "your = possessive  |  you're = you are", tag: 'rule' },
    { title: "whose vs. who's",               formula: "whose = possessive  |  who's = who is", tag: 'rule' },
  ],
}

const subjectVerbAgreement: ReferenceSection = {
  id: 'subject-verb-agreement',
  title: 'Subject-Verb Agreement',
  color: '#16a34a',
  entries: [
    { title: 'Core Rule',                      formula: 'Singular subject → singular verb\nPlural subject → plural verb', tag: 'rule' },
    { title: 'Prepositional Phrase Trap',       formula: "Subject ≠ the noun inside 'of the…'\nE.g., 'The box of chocolates IS open.'", tag: 'rule' },
    { title: 'Collective Nouns',               formula: 'Usually singular: team, group, committee, family, jury, audience', tag: 'rule' },
    { title: 'Singular Indefinite Pronouns',   formula: 'everyone, someone, anyone, nobody, each, either, neither, one → singular verb', tag: 'rule' },
    { title: 'Or / Nor Rule',                  formula: "Verb agrees with closest subject\nE.g., 'Neither the teacher nor the students WERE late.'", tag: 'rule' },
    { title: 'There Is / There Are',           formula: "Verb agrees with real subject after 'there'\nE.g., 'There ARE many reasons.'", tag: 'rule' },
  ],
}

const verbTense: ReferenceSection = {
  id: 'verb-tense',
  title: 'Verb Tense & Form',
  color: '#eab308',
  entries: [
    { title: 'Tense Consistency',  formula: 'Maintain same tense unless a time shift is explicitly stated.', tag: 'rule' },
    { title: 'Simple Tenses',      formula: 'Past: ran, wrote\nPresent: runs, writes\nFuture: will run, will write', tag: 'rule' },
    { title: 'Present Perfect',    formula: 'has / have + past participle', detail: 'Started in past, still relevant now.', tag: 'rule' },
    { title: 'Past Perfect',       formula: 'had + past participle', detail: 'Completed before another past action.', tag: 'rule' },
    { title: 'Progressive',        formula: 'be + -ing  (is writing, was writing)', detail: 'Ongoing / continuing action.', tag: 'rule' },
  ],
}

const pronouns: ReferenceSection = {
  id: 'pronouns',
  title: 'Pronouns',
  color: '#ef4444',
  entries: [
    { title: 'Subject Pronouns',     formula: 'I, you, he, she, it, we, they, who', detail: 'Used as subject of a verb.', tag: 'rule' },
    { title: 'Object Pronouns',      formula: 'me, you, him, her, it, us, them, whom', detail: 'Used as object of verb or preposition.', tag: 'rule' },
    { title: 'Who vs. Whom',         formula: "Who = subject  |  Whom = object", detail: "Test: substitute he/him. 'He' fits → who; 'him' fits → whom.", tag: 'rule' },
    { title: 'Reflexive Pronouns',   formula: "WRONG: 'Contact myself.'  RIGHT: 'Contact me.'", detail: 'Only correct when subject and object are the same.', tag: 'rule' },
    { title: 'Pronoun-Antecedent',   formula: 'Singular antecedent → singular pronoun\nPlural antecedent → plural pronoun', tag: 'rule' },
  ],
}

const modifiers: ReferenceSection = {
  id: 'modifiers',
  title: 'Modifiers',
  color: '#14b8a6',
  entries: [
    { title: 'Core Rule',            formula: 'A modifier must sit immediately next to what it modifies.', tag: 'rule' },
    { title: 'Dangling Modifier',    formula: "WRONG: 'Running to the bus, the rain started.'\nRIGHT: 'Running to the bus, she got caught in the rain.'", detail: 'The subject of the main clause must be the doer of the opening phrase.', tag: 'rule' },
    { title: 'Misplaced Modifier',   formula: "WRONG: 'She almost drove her kids to school every day.'\nRIGHT: 'She drove her kids to school almost every day.'", tag: 'rule' },
  ],
}

const parallelStructure: ReferenceSection = {
  id: 'parallel-structure',
  title: 'Parallel Structure',
  color: '#5856d6',
  entries: [
    { title: 'Core Rule',                   formula: 'Items in a list or comparison must have the same grammatical form.', tag: 'rule' },
    { title: 'Lists',                        formula: "WRONG: 'She likes hiking, swimming, and to run.'\nRIGHT: 'She likes hiking, swimming, and running.'", tag: 'rule' },
    { title: 'Comparisons',                  formula: "WRONG: 'He prefers reading to watch TV.'\nRIGHT: 'He prefers reading to watching TV.'", tag: 'rule' },
    { title: 'Correlative Conjunctions',     formula: 'both…and  |  either…or  |  neither…nor  |  not only…but also', detail: 'Both sides must match in grammatical form.', tag: 'rule' },
    { title: 'Illogical Comparison',         formula: "WRONG: 'He scored higher than any student.'\nRIGHT: 'He scored higher than any OTHER student.'", detail: "Use 'other' or 'else' when comparing one to its own group.", tag: 'rule' },
  ],
}

const transitions: ReferenceSection = {
  id: 'transitions',
  title: 'Transitions',
  color: '#92400e',
  entries: [
    { title: 'Addition',        formula: 'furthermore  ·  moreover  ·  in addition  ·  additionally  ·  also  ·  likewise', tag: 'rule' },
    { title: 'Contrast',        formula: 'however  ·  nevertheless  ·  nonetheless  ·  on the other hand  ·  in contrast  ·  although  ·  whereas  ·  despite', tag: 'rule' },
    { title: 'Cause / Result',  formula: 'therefore  ·  thus  ·  consequently  ·  as a result  ·  hence  ·  for this reason', tag: 'rule' },
    { title: 'Example',         formula: 'for example  ·  for instance  ·  specifically  ·  in particular  ·  to illustrate', tag: 'rule' },
    { title: 'Emphasis',        formula: 'indeed  ·  in fact  ·  that is  ·  in other words  ·  to clarify', tag: 'rule' },
    { title: 'Sequence / Time', formula: 'first  ·  then  ·  next  ·  finally  ·  subsequently  ·  afterward  ·  previously  ·  meanwhile', tag: 'rule' },
    { title: 'Similarity',      formula: 'similarly  ·  likewise  ·  in the same way  ·  just as', tag: 'rule' },
    { title: 'Conclusion',      formula: 'in summary  ·  in conclusion  ·  overall  ·  ultimately  ·  in short', tag: 'rule' },
    { title: 'Key Strategy',    formula: "Read BOTH sides of the blank, then match the logical relationship.", detail: "'However' ≠ 'therefore' ≠ 'furthermore' — not interchangeable.", tag: 'tip' },
  ],
}

const wordsInContext: ReferenceSection = {
  id: 'words-in-context',
  title: 'Words in Context',
  color: '#06b6d4',
  entries: [
    { title: 'Core Approach',        formula: 'Focus on HOW the word functions in context, not its dictionary definition.', tag: 'tip' },
    { title: 'Tone Check',           formula: 'Positive / negative / neutral?  Formal / informal?  Intense / mild?', tag: 'tip' },
    { title: 'Connotation Matters',  formula: "'Curious' vs. 'nosy' — similar meaning, very different tone.", detail: 'Choose the word that fits the specific nuance.', tag: 'tip' },
    { title: 'Best Evidence',        formula: 'Most specific and direct quotation that supports the claim — not just related to the topic.', tag: 'tip' },
    { title: 'Inference Rule',       formula: 'Most reasonable conclusion from the text. No leaps. No outside knowledge.', tag: 'tip' },
    { title: 'Cross-Text',           formula: 'Agree · Disagree · Support · Challenge · Qualify', detail: 'Be specific — identify the exact claim relating the two texts.', tag: 'tip' },
  ],
}

const rhetoricalSynthesis: ReferenceSection = {
  id: 'rhetorical-synthesis',
  title: 'Rhetorical Synthesis',
  color: '#14b8a6',
  entries: [
    { title: 'Follow the Prompt Goal',  formula: 'Choose the option that best accomplishes the stated task.', detail: 'Common goals: introduce, compare, support, qualify, conclude.', tag: 'rule' },
    { title: 'Use Relevant Notes Only', formula: 'Select facts directly tied to the purpose; ignore extras.', tag: 'rule' },
    { title: 'Prioritize Precision',    formula: 'Prefer concise, direct wording over vague or flashy phrasing.', tag: 'tip' },
    { title: 'Maintain Formal Tone',    formula: 'SAT favors objective, neutral academic style.', tag: 'rule' },
  ],
}

const readingStrategies: ReferenceSection = {
  id: 'reading-strategies',
  title: 'Reading Strategies',
  color: '#14b8a6',
  entries: [
    { title: 'Line-Reference Questions', formula: 'Read cited lines plus nearby context before choosing.', tag: 'tip' },
    { title: 'Best Evidence Pair',       formula: 'Answer the claim first, then confirm with exact support lines.', tag: 'tip' },
    { title: 'Main Purpose',             formula: 'Identify what the author is doing: argue, explain, compare, qualify.', tag: 'tip' },
    { title: 'Eliminate Extreme Wording',formula: 'Be cautious with always / never / completely choices.', tag: 'tip' },
    { title: 'Data Questions',           formula: 'Read title, axis labels, and units before evaluating claims.', tag: 'tip' },
  ],
}

export const MATH_SECTIONS: ReferenceSection[] = [
  providedFormulas, linearEquations, quadratics, exponentsRadicals,
  exponentialFunctions, functionsTransformations, systemsInequalities,
  statisticsData, geometry, trigonometry, desmosPlaybook,
]

export const RW_SECTIONS: ReferenceSection[] = [
  sentenceBoundaries, commaRules, apostrophes, subjectVerbAgreement,
  verbTense, pronouns, modifiers, parallelStructure, transitions,
  wordsInContext, rhetoricalSynthesis, readingStrategies,
]

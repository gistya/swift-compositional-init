import Testing
@testable import CompositionalInit

// A type with four required (non-optional) and two optional stored properties — enough surface to
// exercise the definite-initialization rule: succeed iff every required slot is written.
private struct Widget: PropertyInitializable, Equatable {
    var a: Int
    var b: String
    var c: Bool
    var d: Double
    var note: String?
    var tag: Int?

    static var _blank: Widget {
        Widget(a: -1, b: "_blank_", c: false, d: -1, note: "_blank_", tag: -999)
    }
}

private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

// One field of Widget: how to make a property for it, and how it contributes to the expected result.
private struct Field: Sendable {
    let isRequired: Bool
    let makeProperty: @Sendable (Widget) -> PartialProperty<Widget>
    // Writes this field's value (taken from `target`) into `expected`.
    let writeExpected: @Sendable (Widget, inout Widget) -> Void
}

private let fields: [Field] = [
    Field(isRequired: true,  makeProperty: { t in \.a <- t.a },    writeExpected: { t, e in e.a = t.a }),
    Field(isRequired: true,  makeProperty: { t in \.b <- t.b },    writeExpected: { t, e in e.b = t.b }),
    Field(isRequired: true,  makeProperty: { t in \.c <- t.c },    writeExpected: { t, e in e.c = t.c }),
    Field(isRequired: true,  makeProperty: { t in \.d <- t.d },    writeExpected: { t, e in e.d = t.d }),
    Field(isRequired: false, makeProperty: { t in \.note <- t.note }, writeExpected: { t, e in e.note = t.note }),
    Field(isRequired: false, makeProperty: { t in \.tag <- t.tag },   writeExpected: { t, e in e.tag = t.tag }),
]

private func randomTarget(_ rng: inout SeededRNG) -> Widget {
    Widget(
        a: Int.random(in: -1000...1000, using: &rng),
        b: "b\(UInt8.random(in: 0...255, using: &rng))",
        c: Bool.random(using: &rng),
        d: Double(Int.random(in: -1000...1000, using: &rng)),
        note: Bool.random(using: &rng) ? "n\(UInt8.random(in: 0...255, using: &rng))" : nil,
        tag: Bool.random(using: &rng) ? Int.random(in: 0...100, using: &rng) : nil
    )
}

// MARK: randomized DI: success iff all required written, and values are exactly the written ones

@Test func fuzzInitMatchesDefiniteInitializationRule() {
    var rng = SeededRNG(seed: 0xC0FFEE)

    for _ in 0..<5_000 {
        let target = randomTarget(&rng)

        // Decide which fields to supply.
        let included = fields.indices.filter { _ in Bool.random(using: &rng) }

        // Build the property list, occasionally duplicating an included field (same value) and
        // always in a shuffled order — neither should affect the outcome.
        var indices = included
        if let dup = included.randomElement(using: &rng), Bool.random(using: &rng) {
            indices.append(dup)
        }
        indices.shuffle(using: &rng)
        let properties = indices.map { fields[$0].makeProperty(target) }

        let result = Widget(properties)

        let allRequiredIncluded = fields.indices
            .filter { fields[$0].isRequired }
            .allSatisfy { included.contains($0) }

        if allRequiredIncluded {
            // Expected: start from blank, write every included field's target value.
            var expected = Widget._blank
            for i in included { fields[i].writeExpected(target, &expected) }
            #expect(result == expected)
        } else {
            #expect(result == nil)
        }
    }
}

// MARK: targeted soundness regressions

@Test func duplicateRequiredKeyCannotMasqueradeAsTwoSlots() {
    // The old counting logic: writing `a` twice decremented the required counter twice and reported
    // success with `b`/`c`/`d` left at their blank values. It must now fail.
    let props: [PartialProperty<Widget>] = [\.a <- 1, \.a <- 2, \.b <- "x", \.c <- true]
    #expect(Widget(props) == nil) // d (and the duplicate) cannot stand in for the missing slot
}

@Test func duplicateRequiredKeyLastWriteWinsWhenComplete() {
    // With every required slot covered, a duplicate is harmless and the last write wins.
    let props: [PartialProperty<Widget>] = [
        \.a <- 1, \.a <- 9, \.b <- "x", \.c <- true, \.d <- 2.0,
    ]
    #expect(Widget(props) == Widget(a: 9, b: "x", c: true, d: 2.0, note: "_blank_", tag: -999))
}

@Test func optionalsNeverCountTowardRequiredSlots() {
    // Supplying only optionals can never satisfy initialization.
    #expect(Widget([\.note <- "x", \.tag <- 5]) == nil)

    // Supplying all required succeeds even with no optionals; optionals retain blank values.
    let complete: [PartialProperty<Widget>] = [\.a <- 1, \.b <- "x", \.c <- true, \.d <- 3.0]
    #expect(Widget(complete) == Widget(a: 1, b: "x", c: true, d: 3.0, note: "_blank_", tag: -999))
}

@Test func partialRequiredSetAlwaysFails() {
    // Every proper subset of the required fields must fail.
    #expect(Widget([\.a <- 1, \.b <- "x", \.c <- true]) == nil)
    #expect(Widget([\.a <- 1, \.b <- "x", \.d <- 1.0]) == nil)
    #expect(Widget([\.b <- "x", \.c <- true, \.d <- 1.0, \.note <- "n"]) == nil)
}

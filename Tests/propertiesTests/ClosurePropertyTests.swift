import Testing
@testable import properties

// Regression: a `(borrowing T) -> Bool` closure stored via `\.kp <- closure` / `clone(mutating:)`
// silently no-op'd, because the erased applicator round-tripped it through `Any` and `as? V` failed
// for that function type (while `(consuming T) -> U` happened to survive). The applicator now uses
// the captured typed value, so any value type — closures with ownership modifiers included — works.

private struct Holder: Clonable, Sendable {
    var predicate: (@Sendable (borrowing Int) -> Bool)?
    var transform: (@Sendable (consuming Int) -> Int)?
    var plain: Int
}

@Test func borrowingClosurePropertyRoundtrips() {
    let h = Holder(predicate: nil, transform: nil, plain: 0)
    let pred: @Sendable (borrowing Int) -> Bool = { $0 > 0 }

    let h2 = h.clone(mutating: \.predicate <- pred)

    #expect(h2.predicate != nil)            // used to be nil — the bug
    #expect(h2.predicate?(1) == true)
    #expect(h2.predicate?(0) == false)
}

@Test func consumingClosureStillWorks() {
    let h = Holder(predicate: nil, transform: nil, plain: 0)
    let xf: @Sendable (consuming Int) -> Int = { $0 + 10 }

    let h2 = h.clone(mutating: \.transform <- xf)

    #expect(h2.transform != nil)
    #expect(h2.transform?(5) == 15)
}

@Test func mixedAndPlainPropertiesUnaffected() {
    let h = Holder(predicate: nil, transform: nil, plain: 0)
    let h2 = h
        .clone(mutating: \.plain <- 42)
        .clone(mutating: \.predicate <- { @Sendable in $0 == 7 })
    #expect(h2.plain == 42)
    #expect(h2.predicate?(7) == true)
}

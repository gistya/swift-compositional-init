import Testing
@testable import CompositionalInit

private struct State: Cloneable, Equatable {
    var count: Int
    var label: String
}

// MARK: clone() — identity copy

@Test func cloneNoArgsReturnsEqualValue() {
    let s = State(count: 1, label: "a")
    #expect(s.clone() == s)
}

// MARK: clone(mutating:) — key-path variadic / array forms

@Test func cloneMutatingVariadic() {
    let s = State(count: 0, label: "a")
    let s2 = s.clone(mutating: \.count <- 5)
    #expect(s2 == State(count: 5, label: "a"))
}

@Test func cloneMutatingMultipleVariadic() {
    let s = State(count: 0, label: "a")
    let s2 = s.clone(mutating: \.count <- 5, \.label <- "b")
    #expect(s2 == State(count: 5, label: "b"))
}

@Test func cloneMutatingPartialPropertyArray() {
    let props: [PartialProperty<State>] = [\.count <- 9, \.label <- "z"]
    let s = State(count: 0, label: "a").clone(mutating: props)
    #expect(s == State(count: 9, label: "z"))
}

@Test func cloneMutatingEmptyArrayIsIdentity() {
    let props: [PartialProperty<State>] = []
    let s = State(count: 3, label: "k")
    #expect(s.clone(mutating: props) == s)
}

// MARK: clone(mutating:) — case-path array form

private enum Light: Equatable, Cloneable {
    case on(Int)
    case off

    enum Path {
        static let on = CasePath<Light, Int>(
            embed: Light.on,
            extract: { if case let .on(v) = $0 { v } else { nil } }
        )
    }
}

@Test func cloneMutatingCasePropertyArray() {
    let mutations: [CaseProperty<Light>] = [Light.Path.on <- 7]
    let light = Light.on(1).clone(mutating: mutations)
    #expect(light == .on(7))
}

@Test func cloneMutatingCasePropertyArrayReducesInOrder() {
    let mutations: [CaseProperty<Light>] = [Light.Path.on <- 2, Light.Path.on <- 3]
    let light = Light.on(0).clone(mutating: mutations)
    #expect(light == .on(3)) // last write wins
}

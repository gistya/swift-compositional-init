import Testing
@testable import CompositionalInit

// MARK: CasePath get / set / modifying — both in-case and off-case branches

@Test func casePathGetReturnsPayloadOrNil() {
    let c = Traffic.crossing(.init(pedestrian: .walk, signal: .solid))
    #expect(Traffic.Path.crossing.get(c) == Traffic.Crossing(pedestrian: .walk, signal: .solid))
    #expect(Traffic.Path.crossing.get(.working(.red)) == nil)
}

@Test func casePathSetReplacesInCase() {
    let c = Traffic.crossing(.init(pedestrian: .walk, signal: .solid))
    let replaced = Traffic.Path.crossing.set(c, .init(pedestrian: .wait, signal: .flash))
    #expect(replaced == .crossing(.init(pedestrian: .wait, signal: .flash)))
}

@Test func casePathSetIsNoOpOffCase() {
    let w = Traffic.working(.red)
    let result = Traffic.Path.crossing.set(w, .init(pedestrian: .wait, signal: .flash))
    #expect(result == .working(.red))
}

@Test func casePathModifyingInCase() {
    let c = Traffic.crossing(.init(pedestrian: .wait, signal: .solid))
    let result = Traffic.Path.crossing.modifying(c) { $0.signal = .flash }
    #expect(result == .crossing(.init(pedestrian: .wait, signal: .flash)))
}

@Test func casePathModifyingIsNoOpOffCase() {
    let w = Traffic.working(.red)
    let result = Traffic.Path.crossing.modifying(w) { $0.signal = .flash }
    #expect(result == .working(.red))
}

// MARK: WritableCasePath — deep composition, callAsFunction sugar, off-case branches

private enum Outer: Equatable {
    case box(Box)
    case empty

    struct Box: Equatable { var inner: Inner }
    struct Inner: Equatable { var x: Int }

    enum Path {
        static let box = CasePath<Outer, Box>(
            embed: Outer.box,
            extract: { if case let .box(v) = $0 { v } else { nil } }
        )
    }
}

@Test func writableCasePathDeepAppendingInCase() {
    let path = Outer.Path.box(\.inner).appending(\.x) // WritableCasePath<Outer, Int>
    let o = Outer.box(.init(inner: .init(x: 1)))
    #expect(path.get(o) == 1)
    #expect(path.set(o, 9) == .box(.init(inner: .init(x: 9))))
}

@Test func writableCasePathDeepAppendingOffCase() {
    let path = Outer.Path.box(\.inner).appending(\.x)
    #expect(path.get(.empty) == nil)            // get($0)?[keyPath:] short-circuits on nil
    #expect(path.set(.empty, 9) == .empty)      // set guard returns root unchanged
}

@Test func writableCasePathCallAsFunctionSugar() {
    // `box(\.inner)(\.x)` == `box(\.inner).appending(\.x)`
    let path = Outer.Path.box(\.inner)(\.x)
    let o = Outer.box(.init(inner: .init(x: 4)))
    #expect(path.get(o) == 4)
    #expect(path.set(o, 5) == .box(.init(inner: .init(x: 5))))
}

// MARK: CaseProperty applied directly

@Test func casePropertyApplyReplacesPayload() {
    let prop = Traffic.Path.crossing <- .init(pedestrian: .walk, signal: .flash)
    let result = prop.apply(.crossing(.init(pedestrian: .wait, signal: .solid)))
    #expect(result == .crossing(.init(pedestrian: .walk, signal: .flash)))
}

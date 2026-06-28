import Testing
@testable import CompositionalInit

// A statechart-shaped value: compound state (enum / sum) containing a parallel state
// (struct / product) whose two regions are themselves enums.
enum Traffic: Equatable, Clonable {
    case working(Working)
    case crossing(Crossing)

    enum Working: Equatable { case red, green, yellow }
    struct Crossing: Equatable {
        var pedestrian: Pedestrian
        var signal: Signal
        enum Pedestrian: Equatable { case walk, wait }
        enum Signal: Equatable { case flash, solid }
    }

    // Case paths live in a nested namespace so they don't collide with the case names.
    enum Path {
        static let working = CasePath<Traffic, Working>(
            embed: Traffic.working,
            extract: { if case let .working(v) = $0 { v } else { nil } }
        )
        static let crossing = CasePath<Traffic, Crossing>(
            embed: Traffic.crossing,
            extract: { if case let .crossing(v) = $0 { v } else { nil } }
        )
    }
}

@Test func extractAndEmbed() {
    let c = Traffic.crossing(.init(pedestrian: .walk, signal: .flash))
    #expect(Traffic.Path.crossing.extract(c) == Traffic.Crossing(pedestrian: .walk, signal: .flash))
    #expect(Traffic.Path.working.extract(c) == nil)
    #expect(Traffic.Path.working.embed(.green) == .working(.green))
}

@Test func nestedCaseWritablePathSet() {
    // `\.crossing.pedestrian <- .walk` through the enum case — the line that doesn't compile
    // with a bare KeyPath.
    var config = Traffic.crossing(.init(pedestrian: .wait, signal: .solid))
    config = config.clone(mutating: Traffic.Path.crossing(\.pedestrian) <- .walk)
    #expect(config == .crossing(.init(pedestrian: .walk, signal: .solid)))
}

@Test func affineSetIsNoOpOffCase() {
    // Setting the pedestrian region while in `.working` leaves the value untouched.
    let config = Traffic.working(.red)
    let result = config.clone(mutating: Traffic.Path.crossing(\.pedestrian) <- .walk)
    #expect(result == .working(.red))
}

@Test func wholeCasePayloadReplace() {
    var config = Traffic.crossing(.init(pedestrian: .wait, signal: .solid))
    config = config.clone(mutating: Traffic.Path.crossing <- .init(pedestrian: .walk, signal: .flash))
    #expect(config == .crossing(.init(pedestrian: .walk, signal: .flash)))
}

@Test func deepComposition() {
    let path = Traffic.Path.crossing(\.signal)
    let config = Traffic.crossing(.init(pedestrian: .walk, signal: .solid))
    #expect(path.get(config) == .solid)
    #expect(path.set(config, .flash) == .crossing(.init(pedestrian: .walk, signal: .flash)))
}

// MARK: consuming clone

struct BigContext: Clonable, Equatable {
    var data: [Int]
    var tag: Int
}

@Test func consumingClonedClosure() {
    let a = BigContext(data: Array(0..<1000), tag: 0)
    let b = a.cloned { $0.tag = 7 }
    #expect(b.tag == 7)
    #expect(b.data.count == 1000)
}

@Test func consumingClonedKeyPath() {
    let a = BigContext(data: [1, 2, 3], tag: 0)
    let b = a.cloned(\.tag, 42)
    #expect(b == BigContext(data: [1, 2, 3], tag: 42))
}

@Test func consumingClonedMutatesInPlace() {
    // When the consumed value is the unique owner of its CoW buffer, the mutation is in place:
    // the returned array shares the same backing storage as the original's (no deep copy).
    var a = BigContext(data: Array(0..<1000), tag: 0)
    let originalAddress = a.data.withUnsafeBufferPointer { $0.baseAddress }
    a = a.cloned { $0.tag = 1 }   // touches a scalar, not the array
    let newAddress = a.data.withUnsafeBufferPointer { $0.baseAddress }
    #expect(originalAddress == newAddress)
}

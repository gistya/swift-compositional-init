import Testing
@testable import CompositionalInit

private struct Sample: PropertyInitializable, Equatable {
    var value: Int
    static var _blank: Sample { Sample(value: 0) }
}

// A small deterministic generator so randomized tests aren't flaky.
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

// MARK: iterate — cyclic, never out of bounds

@Test func iterateCyclesAndWrapsWithoutOverrun() {
    let mock = MockProperty(\Sample.value, iterate: [10, 20, 30])
    var rng = SeededRNG(seed: 1)
    let observed = (0..<7).map { _ in mock.next(using: &rng) }
    // Walks past the end repeatedly — used to crash with the old `count % index` logic.
    #expect(observed == [10, 20, 30, 10, 20, 30, 10])
}

// MARK: randomize — membership + determinism with injected RNG

@Test func randomizeOnlyProducesMembers() {
    let values = [1, 2, 3, 4, 5]
    let mock = MockProperty(\Sample.value, randomize: values)
    var rng = SeededRNG(seed: 42)
    for _ in 0..<50 { #expect(values.contains(mock.next(using: &rng))) }
}

@Test func randomizeIsDeterministicForAFixedSeed() {
    let values = [1, 2, 3, 4, 5]
    func draws() -> [Int] {
        let mock = MockProperty(\Sample.value, randomize: values)
        var rng = SeededRNG(seed: 99)
        return (0..<10).map { _ in mock.next(using: &rng) }
    }
    #expect(draws() == draws()) // same seed → same sequence
}

@Test func randomizeSingleElementIsConstant() {
    let mock = MockProperty(\Sample.value, randomize: [42])
    var rng = SeededRNG(seed: 7)
    #expect(mock.next(using: &rng) == 42)
}

// MARK: constant

@Test func constantAlwaysProducesSameValue() {
    let mock = MockProperty(\Sample.value, constant: 99)
    var rng = SeededRNG(seed: 0)
    #expect(mock.next(using: &rng) == 99)
    #expect(mock.next() == 99)
}

// MARK: integration — feeding a sampled property into init

@Test func sampledPropertyInitializesValue() {
    let mock = MockProperty(\Sample.value, iterate: [5, 6])
    var rng = SeededRNG(seed: 3)
    let s = Sample([mock.sampleProperty(using: &rng)])
    #expect(s == Sample(value: 5))
    // Generator advanced — the next sample yields the second value.
    let s2 = Sample([mock.sampleProperty(using: &rng)])
    #expect(s2 == Sample(value: 6))
}

import Testing
@testable import CompositionalInit

private struct Box: PropertyInitializable, Equatable {
    var n: Int
    static var _blank: Box { Box(n: 0) }
}

// MARK: Source.single

@Test func singleSourceValueGetter() {
    let p = Property<Box, Int>(key: \.n, value: 7)
    #expect(p.value == 7)
}

@Test func valueSetterIsNoOp() {
    // The setter exists only to satisfy `var value`; it must not change anything.
    var p = Property<Box, Int>(key: \.n, value: 7)
    p.value = 999
    #expect(p.value == 7)
}

// MARK: Source.iterate

@Test func iterateSourceAdvancesThenWrapsCyclically() {
    let values = [10, 20, 30]
    let p = Property<Box, Int>(key: \.n, iteration: 0, valuesToIterate: values)
    // Iterating well past the end cycles back through the values (index % count).
    let observed = (0..<7).map { _ in p.value }
    #expect(observed == [10, 20, 30, 10, 20, 30, 10])
}

@Test func iterateInitWithDefaultArgument() {
    // The `default:` parameter is accepted (currently unused) — exercise that overload.
    let p = Property<Box, Int>(key: \.n, iteration: 1, valuesToIterate: [5, 6, 7], default: 0)
    #expect(p.value == 6) // starts at index 1
}

// MARK: Source.randomize

@Test func randomizeSourceReturnsAMemberOfTheSet() {
    let values = [1, 2, 3, 4]
    let p = Property<Box, Int>(key: \.n, source: .randomize(values))
    for _ in 0..<20 { #expect(values.contains(p.value)) }
}

@Test func randomizeSingleElementIsDeterministic() {
    let p = Property<Box, Int>(key: \.n, source: .randomize([42]))
    #expect(p.value == 42)
}

// MARK: Source.closure

@Test func closureSourceReevaluatesEachAccess() {
    var counter = 0
    func next() -> Int { counter += 1; return counter }
    let p = Property<Box, Int>(key: \.n, closure: next())
    #expect(p.value == 1)
    #expect(p.value == 2)
    #expect(p.value == 3)
}

@Test func closureSourceViaSourceEnum() {
    var counter = 10
    let p = Property<Box, Int>(key: \.n, source: .closure({ counter += 1; return counter }))
    #expect(p.value == 11)
    #expect(p.value == 12)
}

// MARK: type erasure — partial / any

@Test func partialErasurePreservesKeyAndValue() {
    let p = Property<Box, Int>(key: \.n, value: 5)
    let partial = p.partial
    #expect(partial.key == (\Box.n as PartialKeyPath<Box>))
    #expect(partial.value as? Int == 5)
}

@Test func anyErasureFromProperty() {
    let any = Property<Box, Int>(key: \.n, value: 8).any
    #expect(any.value as? Int == 8)
    #expect(any.key == (\Box.n as AnyKeyPath))
}

@Test func anyErasureFromPartialProperty() {
    let partial: PartialProperty<Box> = \.n <- 9
    let any = partial.any
    #expect(any.value as? Int == 9)
}

@Test func anyPropertyApplicatorSetsValue() {
    let any = Property<Box, Int>(key: \.n, value: 3).any
    let (updated, didChange) = any.apply(value: 3, to: Box(n: 0))
    #expect(didChange == true)
    #expect((updated as? Box) == Box(n: 3))
}

@Test func anyPropertyApplicatorReportsNoChangeOnTypeMismatch() {
    let any = Property<Box, Int>(key: \.n, value: 3).any
    // Passing a value of the wrong type fails the internal `as? V` cast → no change.
    let (updated, didChange) = any.apply(value: "not an int", to: Box(n: 7))
    #expect(didChange == false)
    #expect((updated as? Box) == Box(n: 7))
}

// MARK: Property.apply(source:to:) — the Source-typed applicator wrapper

@Test func applySourceReportsNoChangeBecauseSourceIsNotTheValueType() {
    let p = Property<Box, Int>(key: \.n, value: 1)
    let (root, didChange) = p.apply(source: .single(1), to: Box(n: 5))
    #expect(didChange == false) // a Source is not an Int, so the applicator cast fails
    #expect(root == Box(n: 5))
}

// MARK: <- infix overloads

@Test func infixValueToPartialAndAny() {
    let partial: PartialProperty<Box> = \.n <- 1
    let any: AnyProperty = \Box.n <- 2
    #expect(partial.value as? Int == 1)
    #expect(any.value as? Int == 2)
}

@Test func infixSourceToPartialAndAny() {
    let source = Property<Box, Int>.Source.single(11)
    let partial: PartialProperty<Box> = \.n <- source
    let any: AnyProperty = \Box.n <- Property<Box, Int>.Source.single(22)
    #expect(partial.value as? Int == 11)
    #expect(any.value as? Int == 22)
}

@Test func infixClosureToPartialAndAny() {
    let partial: PartialProperty<Box> = \.n <- { 33 }
    let any: AnyProperty = \Box.n <- { 44 }
    #expect(partial.value as? Int == 33)
    #expect(any.value as? Int == 44)
}

// MARK: Array + operator

@Test func arrayPlusBuildsPartialPropertyList() {
    var props: [PartialProperty<Box>] = []
    props = props + (\Box.n, 5)
    #expect(props.count == 1)
    #expect(props[0].value as? Int == 5)
    let box = Box(props)
    #expect(box == Box(n: 5))
}

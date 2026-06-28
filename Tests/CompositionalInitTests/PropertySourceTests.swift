import Testing
@testable import CompositionalInit

private struct Box: PropertyInitializable, Equatable {
    var n: Int
    static var _blank: Box { Box(n: 0) }
}

private struct OptionalHolder: Equatable {
    var required: Int
    var maybe: String?
}

// MARK: Source.single

@Test func singleSourceValueGetter() {
    let p = Property<Box, Int>(key: \.n, value: 7)
    #expect(p.value == 7)
    #expect(p.source.value == 7)
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

// MARK: type-based optional classification

@Test func isOptionalReflectsStaticValueType() {
    #expect(Property(key: \OptionalHolder.required, value: 1).isOptional == false)
    // Optional-typed slot is "optional" even when given a non-nil value.
    #expect(Property(key: \OptionalHolder.maybe, value: "x").isOptional == true)
    #expect(Property(key: \OptionalHolder.maybe, value: nil).isOptional == true)
}

// MARK: typed application — no boxing, no casts

@Test func partialPropertyAppliesTypedWrite() {
    let p: PartialProperty<Box> = \.n <- 5
    #expect(p.key == (\Box.n as PartialKeyPath<Box>))
    #expect(p.isOptional == false)
    var box = Box(n: 0)
    p.apply(to: &box)
    #expect(box == Box(n: 5))
}

@Test func propertyPartialAndAnyErasureApply() {
    let property = Property<Box, Int>(key: \.n, value: 8)

    var b1 = Box(n: 0)
    property.partial.apply(to: &b1)
    #expect(b1 == Box(n: 8))

    let any = property.any
    #expect(any.value as? Int == 8)
    #expect(any.key == (\Box.n as AnyKeyPath))
    var b2: Any = Box(n: 0)
    any.apply(to: &b2)
    #expect((b2 as? Box) == Box(n: 8))
}

@Test func anyPropertyIsNoOpOnRootTypeMismatch() {
    let any: AnyProperty = \Box.n <- 3
    // Applying a Box-rooted property to a non-Box box must do nothing (safe `as?`, no trap).
    var wrong: Any = "untouched"
    any.apply(to: &wrong)
    #expect(wrong as? String == "untouched")
}

// MARK: <- infix overloads (verified through application)

@Test func infixValueOverloads() {
    var b = Box(n: 0)
    let partial: PartialProperty<Box> = \.n <- 1
    partial.apply(to: &b)
    #expect(b == Box(n: 1))

    let any: AnyProperty = \Box.n <- 2
    #expect(any.value as? Int == 2)
}

@Test func infixSourceOverloads() {
    let partial: PartialProperty<Box> = \.n <- Property<Box, Int>.Source.single(11)
    var b = Box(n: 0)
    partial.apply(to: &b)
    #expect(b == Box(n: 11))

    let any: AnyProperty = \Box.n <- Property<Box, Int>.Source.single(22)
    #expect(any.value as? Int == 22)
}

@Test func infixClosureOverloads() {
    let partial: PartialProperty<Box> = \.n <- { 33 }
    var b = Box(n: 0)
    partial.apply(to: &b)
    #expect(b == Box(n: 33))

    let any: AnyProperty = \Box.n <- { 44 }
    #expect(any.value as? Int == 44)
}

// MARK: Array + operator

@Test func arrayPlusBuildsPartialPropertyList() {
    let props: [PartialProperty<Box>] = [] + (\Box.n, 5)
    #expect(props.count == 1)
    #expect(Box(props) == Box(n: 5))
}

@Test func arrayPlusChainsAcrossValueTypes() {
    // The point of the operator: heterogeneous value types in one statically-typed array.
    let props: [PartialProperty<OptionalHolder>] = []
        + (\OptionalHolder.required, 7)
        + (\OptionalHolder.maybe, Optional("hi"))
    #expect(props.count == 2)
    var holder = OptionalHolder(required: 0, maybe: nil)
    for p in props { p.apply(to: &holder) }
    #expect(holder == OptionalHolder(required: 7, maybe: "hi"))
}

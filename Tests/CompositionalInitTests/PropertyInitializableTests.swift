import Testing
@testable import CompositionalInit

// A PropertyInitializable value: two required (non-optional) stored properties and one optional.
// `_blank` supplies the placeholder Swift insists on, and the keypath-value properties fill it in.
private struct Person: PropertyInitializable, Equatable {
    var name: String
    var age: Int
    var nickname: String?

    static var _blank: Person { Person(name: "", age: 0, nickname: nil) }
}

// MARK: numberOfNonOptionalProperties / Mirror+Optional

@Test func nonOptionalChildrenCountsOnlyRequiredProperties() {
    // name + age are required; nickname is optional and excluded.
    #expect(Person._blank.numberOfNonOptionalProperties == 2)
    #expect(Mirror(reflecting: Person._blank).nonOptionalChildren.count == 2)
}

@Test func isOptionalDetectsOptionality() {
    #expect(isOptional(Optional<Int>.none) == true)
    #expect(isOptional(Optional<Int>.some(3)) == true)
    #expect(isOptional(3) == false)
    #expect(isOptional("x") == false)
    // A value whose Mirror has no displayStyle (a function) hits the guard-else and is "not optional".
    let fn: () -> Void = {}
    #expect(isOptional(fn) == false)
}

// MARK: init?([PartialProperty]) — success / failure / optional handling

@Test func initFromPartialPropertyArraySucceedsWhenAllRequiredSet() {
    let props: [PartialProperty<Person>] = [\.name <- "Ada", \.age <- 36]
    let p = Person(props)
    #expect(p == Person(name: "Ada", age: 36, nickname: nil))
}

@Test func initFromPartialPropertyArrayFailsWhenRequiredMissing() {
    // Only `name` supplied — `age` is still uninitialized, so init returns nil.
    let props: [PartialProperty<Person>] = [\.name <- "Ada"]
    #expect(Person(props) == nil)
}

@Test func initAcceptsOptionalPropertyWithoutCountingItAsRequired() {
    // Setting the optional `nickname` must not satisfy a required slot — both required ones still needed.
    let props: [PartialProperty<Person>] = [\.name <- "Ada", \.age <- 36, \.nickname <- "Countess"]
    let p = Person(props)
    #expect(p == Person(name: "Ada", age: 36, nickname: "Countess"))

    // Optional alone is not enough.
    let onlyOptional: [PartialProperty<Person>] = [\.nickname <- "Countess"]
    #expect(Person(onlyOptional) == nil)
}

@Test func initFromPartialPropertyVariadic() {
    let p1: PartialProperty<Person> = \.name <- "Grace"
    let p2: PartialProperty<Person> = \.age <- 45
    let p = Person(p1, p2)
    #expect(p == Person(name: "Grace", age: 45, nickname: nil))
}

// MARK: init?([AnyProperty]) — fully type-erased path

@Test func initFromAnyPropertyArray() {
    let props: [AnyProperty] = [\Person.name |<- "Alan", \Person.age |<- 41]
    let p = Person(props)
    #expect(p == Person(name: "Alan", age: 41, nickname: nil))
}

@Test func initFromAnyPropertyArrayFailsWhenRequiredMissing() {
    let props: [AnyProperty] = [\Person.name |<- "Alan"]
    #expect(Person(props) == nil)
}

@Test func initFromAnyPropertyVariadic() {
    let a1: AnyProperty = \Person.name |<- "Edsger"
    let a2: AnyProperty = \Person.age |<- 60
    let p = Person(a1, a2)
    #expect(p == Person(name: "Edsger", age: 60, nickname: nil))
}

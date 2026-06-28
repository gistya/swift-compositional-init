/// A *stateful value generator* for a single property, for building test fixtures and mocks — the
/// home of the `iterate` and `randomize` behaviors that used to live on ``Property/Source``.
///
/// These are deliberately separated from ``Property`` because they are not value-semantic
/// initialization primitives: a generator has identity and side effects (each sample can change its
/// internal state), so `MockProperty` is a `final class` rather than a struct, and that reference
/// semantics is part of its contract. Randomization draws from a caller-supplied
/// `RandomNumberGenerator` so fixtures can be made deterministic.
///
/// ```swift
/// let ages = MockProperty(\Person.age, iterate: [10, 20, 30])
/// var rng = SystemRandomNumberGenerator()
/// let person = Person(\.name <- "A", ages.sampleProperty(using: &rng))
/// ```
public final class MockProperty<Root, Value> {
    /// How a ``MockProperty`` produces each successive value.
    public enum Strategy {
        /// Cycle through `values` in order, wrapping around at the end. Requires a non-empty array.
        case iterate([Value])
        /// Pick uniformly at random from `values` on each sample. Requires a non-empty array.
        case randomize([Value])
        /// Always produce the same value.
        case constant(Value)
    }

    /// The key path each generated value is destined for.
    public let key: WritableKeyPath<Root, Value>

    /// The strategy driving value generation.
    public let strategy: Strategy

    private var index = 0

    /// Creates a generator that cycles through `values` in order (wrapping at the end).
    /// - Precondition: `values` is non-empty.
    public convenience init(_ key: WritableKeyPath<Root, Value>, iterate values: [Value]) {
        self.init(key, strategy: .iterate(values))
    }

    /// Creates a generator that samples uniformly at random from `values`.
    /// - Precondition: `values` is non-empty.
    public convenience init(_ key: WritableKeyPath<Root, Value>, randomize values: [Value]) {
        self.init(key, strategy: .randomize(values))
    }

    /// Creates a generator that always produces `value`.
    public convenience init(_ key: WritableKeyPath<Root, Value>, constant value: Value) {
        self.init(key, strategy: .constant(value))
    }

    /// Designated initializer taking an explicit ``Strategy``.
    public init(_ key: WritableKeyPath<Root, Value>, strategy: Strategy) {
        self.key = key
        self.strategy = strategy
        switch strategy {
        case .iterate(let values), .randomize(let values):
            precondition(!values.isEmpty, "MockProperty requires a non-empty value set")
        case .constant:
            break
        }
    }

    /// Produces the next value, advancing internal state, drawing randomness from `rng`.
    ///
    /// For `.iterate` the index advances and wraps cyclically (`index % count`) — it never runs off
    /// the end of the array.
    public func next<RNG: RandomNumberGenerator>(using rng: inout RNG) -> Value {
        switch strategy {
        case .iterate(let values):
            defer { index += 1 }
            return values[index % values.count]
        case .randomize(let values):
            return values.randomElement(using: &rng)!
        case .constant(let value):
            return value
        }
    }

    /// Produces the next value using the system random number generator.
    public func next() -> Value {
        var rng = SystemRandomNumberGenerator()
        return next(using: &rng)
    }

    /// Samples the next value and packages it as a ``PartialProperty`` ready for `init`/`clone`,
    /// drawing randomness from `rng`.
    public func sampleProperty<RNG: RandomNumberGenerator>(using rng: inout RNG) -> PartialProperty<Root> {
        Property(key: key, value: next(using: &rng)).partial
    }

    /// Samples the next value and packages it as a ``PartialProperty`` using the system RNG.
    public func sampleProperty() -> PartialProperty<Root> {
        Property(key: key, value: next()).partial
    }
}

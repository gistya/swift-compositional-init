/// The `<-` operator pairs a `WritableKeyPath` with a value (or value source) in a type-safe way,
/// *without* constructing the root object — the surface syntax of compositional initialization.
///
/// Because `\Root.value` is a `WritableKeyPath<Root, Value>`, the pairing `\Root.value <- x` fails
/// to compile if the property is inaccessible, read-only, non-existent, or of a different type than
/// `x` — all the static guarantees of key paths carry through.
infix operator <-

public extension WritableKeyPath {
    /// Pairs `self` with a fixed value, erasing only the value type → ``PartialProperty``.
    static func <- (keyPath: WritableKeyPath<Root, Value>, value: Value) -> PartialProperty<Root> {
        Property(key: keyPath, value: value).partial
    }

    /// Pairs `self` with a fixed value, fully erasing root and value → ``AnyProperty``.
    static func <- (keyPath: WritableKeyPath<Root, Value>, value: Value) -> AnyProperty {
        Property(key: keyPath, value: value).any
    }

    /// Pairs `self` with an explicit ``Property/Source`` → ``PartialProperty``.
    static func <- (keyPath: WritableKeyPath<Root, Value>, source: Property<Root, Value>.Source) -> PartialProperty<Root> {
        Property(key: keyPath, source: source).partial
    }

    /// Pairs `self` with an explicit ``Property/Source`` → ``AnyProperty``.
    static func <- (keyPath: WritableKeyPath<Root, Value>, source: Property<Root, Value>.Source) -> AnyProperty {
        Property(key: keyPath, source: source).any
    }

    /// Pairs `self` with a closure evaluated lazily at application time → ``PartialProperty``.
    static func <- (keyPath: WritableKeyPath<Root, Value>, make: @escaping () -> Value) -> PartialProperty<Root> {
        Property(key: keyPath, source: .closure(make)).partial
    }

    /// Pairs `self` with a closure evaluated lazily at application time → ``AnyProperty``.
    static func <- (keyPath: WritableKeyPath<Root, Value>, make: @escaping () -> Value) -> AnyProperty {
        Property(key: keyPath, source: .closure(make)).any
    }
}

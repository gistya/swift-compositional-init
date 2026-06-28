/// The `<-` operator creates a partially type-erased ``PartialProperty<Root>``  instance from a
/// ``WriteableKeyPath<Root, Value>`` instance on the left, and `Value` instance on the right.
///
/// This is the preferred operator for compositional init and cloning because of its type safety guarantee.
infix operator <-

public extension WritableKeyPath {
    /// Pairs `self` with a fixed value, erasing only the value type → ``PartialProperty``.
    static func <- (keyPath: WritableKeyPath<Root, Value>, value: Value) -> PartialProperty<Root> {
        Property(key: keyPath, value: value).partial
    }

    /// Pairs `self` with an explicit ``Property/Source`` → ``PartialProperty``.
    static func <- (keyPath: WritableKeyPath<Root, Value>, source: Property<Root, Value>.Source) -> PartialProperty<Root> {
        Property(key: keyPath, source: source).partial
    }

    /// Pairs `self` with a closure evaluated lazily at application time → ``PartialProperty``.
    static func <- (keyPath: WritableKeyPath<Root, Value>, make: @escaping () -> Value) -> PartialProperty<Root> {
        Property(key: keyPath, source: .closure(make)).partial
    }
}

/// The `|<-` operator creates a fully type-erased `AnyProperty` instance from a
/// `WritaableKeyPath<Root, Value>` instance on the left, and a `Value` instance on the right.
///
/// Use this operator if you ever need to create a collection of properties with diverse `Root` types, e.g.
/// a dictionary like `[ObjectIdentifier: AnyProperty` as might be useful for dependency injection.
infix operator |<-

public extension WritableKeyPath {
    /// Pairs `self` with a fixed value, fully erasing root and value → ``AnyProperty``.
    static func |<- (keyPath: WritableKeyPath<Root, Value>, value: Value) -> AnyProperty {
        Property(key: keyPath, value: value).any
    }
    
    /// Pairs `self` with an explicit ``Property/Source`` → ``AnyProperty``.
    static func |<- (keyPath: WritableKeyPath<Root, Value>, source: Property<Root, Value>.Source) -> AnyProperty {
        Property(key: keyPath, source: source).any
    }
    
    /// Pairs `self` with a closure evaluated lazily at application time → ``AnyProperty``.
    static func |<- (keyPath: WritableKeyPath<Root, Value>, make: @escaping () -> Value) -> AnyProperty {
        Property(key: keyPath, source: .closure(make)).any
    }
}

/// Appends a key-path/value pair to an array of ``PartialProperty`` without breaking the array's
/// static type, even though each pair may have a different value type.
///
/// ```swift
/// let props: [PartialProperty<Foo>] = [] + (\.bar, "two") + (\.baz, 2.0)
/// ```
///
/// Implemented as a free `+` overload (rather than a constrained `Array` extension) so it composes
/// cleanly for any element root type.
public func + <Root, Value>(
    lhs: [PartialProperty<Root>],
    rhs: (WritableKeyPath<Root, Value>, Value)
) -> [PartialProperty<Root>] {
    lhs + [Property(key: rhs.0, value: rhs.1).partial]
}

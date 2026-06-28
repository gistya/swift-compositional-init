/// A pending case-path mutation — the prism sibling of a key-path ``PartialProperty``.
///
/// It carries a `Root -> Root` transform (case paths can't be `WritableKeyPath`s, so they can't
/// reuse the key-path applicator). Apply a batch with `clone(mutating:)`. The stored transform is
/// `@Sendable`, so `CaseProperty` is checked `Sendable` (no `@unchecked`).
public struct CaseProperty<Root>: Sendable {
    /// The functional transform this property represents.
    public let apply: @Sendable (Root) -> Root

    /// Creates a case property from a `Root -> Root` transform.
    public init(apply: @escaping @Sendable (Root) -> Root) { self.apply = apply }
}

public extension CasePath {
    /// `Traffic.Path.crossing <- newCrossing` — replace the whole case payload (affine).
    ///
    /// Requires `Value: Sendable` because the replacement value is captured by the `@Sendable`
    /// transform stored in the resulting ``CaseProperty``.
    static func <- (path: CasePath<Root, Value>, value: Value) -> CaseProperty<Root> where Value: Sendable {
        CaseProperty { path.set($0, value) }
    }
}

public extension WritableCasePath {
    /// `Traffic.Path.crossing(\.pedestrian) <- .walk` — set a stored property nested in a case.
    ///
    /// Requires `Value: Sendable` (see ``CasePath/<-(_:_:)``).
    static func <- (path: WritableCasePath<Root, Value>, value: Value) -> CaseProperty<Root> where Value: Sendable {
        CaseProperty { path.set($0, value) }
    }
}

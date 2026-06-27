/// A pending case-path mutation — the prism sibling of a key-path `Property`. It carries a
/// `Root -> Root` transform (case paths can't be `WritableKeyPath`s, so they can't reuse the
/// `PartialProperty` applicator). Apply a batch with `clone(mutating:)`.
public struct CaseProperty<Root>: @unchecked Sendable {
    public let apply: (Root) -> Root
    public init(apply: @escaping (Root) -> Root) { self.apply = apply }
}

public extension CasePath {
    /// `Traffic.Path.crossing <- newCrossing` — replace the whole case payload (affine).
    static func <- (path: CasePath<Root, Value>, value: Value) -> CaseProperty<Root> {
        CaseProperty { path.set($0, value) }
    }
}

public extension WritableCasePath {
    /// `Traffic.Path.crossing(\.pedestrian) <- .walk` — set a stored property nested in a case.
    static func <- (path: WritableCasePath<Root, Value>, value: Value) -> CaseProperty<Root> {
        CaseProperty { path.set($0, value) }
    }
}

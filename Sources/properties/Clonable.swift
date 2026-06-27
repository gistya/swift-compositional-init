//


public protocol Clonable {
    func clone<P: PartialPropertyProtocol>(mutating Propertys: P...) -> Self where P.Root == Self
    
    func clone() -> Self
}

public extension Clonable {
    private init<P: PartialPropertyProtocol>(clone: Self, mutations: [P]) where P.Root == Self {
        self = clone
        for mutation in mutations {
            (self, _) = mutation.apply(value: mutation.value, to: self)
        }
    }
    
    private init(clone: Self) {
        self = clone
    }

    func clone<P: PartialPropertyProtocol>(mutating Propertys: P...) -> Self where P.Root == Self {
        Self(clone: self, mutations: Propertys)
    }

    /// Array form of `clone(mutating:)` — apply a pre-built `[Property]` batch.
    func clone<P: PartialPropertyProtocol>(mutating Propertys: [P]) -> Self where P.Root == Self {
        Self(clone: self, mutations: Propertys)
    }

    func clone() -> Self {
        Self(clone: self)
    }
}

public extension Clonable {
    /// Functional update through case paths — the sum-type sibling of
    /// `clone(mutating: \.keyPath <- value)`. Key-path and case-path mutations don't share one
    /// variadic call (different types); chain `.clone(...)` to combine them.
    func clone(mutating mutations: CaseProperty<Self>...) -> Self {
        mutations.reduce(self) { $1.apply($0) }
    }

    /// Array form of the case-path `clone(mutating:)`.
    func clone(mutating mutations: [CaseProperty<Self>]) -> Self {
        mutations.reduce(self) { $1.apply($0) }
    }
}

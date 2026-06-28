/// A type that supports value-semantic *functional update*: producing a copy of an instance with a
/// chosen subset of properties changed, without mutating the original and without per-property
/// boilerplate.
///
/// The protocol itself is `~Copyable`, so even move-only types can use the consuming
/// ``cloned(_:)-closure`` update. The key-path-based `clone`/`cloned` overloads additionally require
/// `Copyable` (Swift key paths do not yet support non-copyable roots) and are provided in a
/// constrained extension.
public protocol Cloneable: ~Copyable {}

// MARK: - Move-only-friendly functional update

public extension Cloneable where Self: ~Copyable {
    /// A `consuming` functional update.
    ///
    /// Because it **takes ownership** of `self`, the value's copy-on-write storage stays uniquely
    /// referenced, so the mutation happens *in place* — no deep copy of large backing buffers (the
    /// "100k-element context" case where a plain copy would clone a CoW array just to touch one
    /// field). The in-place win only materializes if the consumed value was the unique owner; if
    /// anything else still retains it, CoW copies regardless.
    ///
    /// This is the only update form available to non-copyable types, and it needs no key paths:
    ///
    /// ```swift
    /// context = context.cloned { $0.organisms[i].energy -= 1 }
    /// ```
    @inlinable
    consuming func cloned(_ mutate: (inout Self) -> Void) -> Self {
        var this = consume self
        mutate(&this)
        return this
    }
}

// MARK: - Copyable updates (key-path and property based)

public extension Cloneable {
    /// A non-consuming identity copy.
    @inlinable
    func clone() -> Self { self }

    /// Returns a copy of `self` with each property in `properties` applied — the value-semantic
    /// functional update at the heart of compositional initialization. Despite the `mutating:`
    /// label, `self` is not mutated; a new value is returned.
    @inlinable
    func clone(mutating properties: PartialProperty<Self>...) -> Self {
        clone(mutating: properties)
    }

    /// Array form of ``clone(mutating:)-variadic``: apply a pre-built `[PartialProperty]` batch.
    @inlinable
    func clone(mutating properties: [PartialProperty<Self>]) -> Self {
        var copy = self
        for property in properties { property.apply(to: &copy) }
        return copy
    }

    /// A `consuming` single key-path update — `context.cloned(\.count, 5)`. Takes ownership of `self`
    /// so the write can happen in place when `self` is uniquely referenced.
    @inlinable
    consuming func cloned<Value>(_ keyPath: WritableKeyPath<Self, Value>, _ value: Value) -> Self {
        var this = consume self
        this[keyPath: keyPath] = value
        return this
    }
}

// MARK: - Case-path updates

public extension Cloneable {
    /// Functional update through case paths — the sum-type sibling of `clone(mutating: \.kp <- value)`.
    /// Key-path and case-path mutations have different element types and so can't share one variadic
    /// call; chain `.clone(...)` to combine them.
    @inlinable
    func clone(mutating mutations: CaseProperty<Self>...) -> Self {
        clone(mutating: mutations)
    }

    /// Array form of the case-path ``clone(mutating:)-caseVariadic``.
    @inlinable
    func clone(mutating mutations: [CaseProperty<Self>]) -> Self {
        mutations.reduce(self) { $1.apply($0) }
    }
}

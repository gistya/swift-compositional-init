public extension Clonable {
    /// A `consuming` functional update. Because it **takes ownership** of `self`, the value's
    /// copy-on-write storage stays uniquely referenced, so the mutation happens *in place* — no copy
    /// of large backing buffers (the "100k-element context" case where a plain `clone` would deep-copy
    /// a CoW array just to touch one field).
    ///
    /// Trade-off vs. `clone(mutating:)`: this **consumes** the receiver — the old value is gone after
    /// the call (which is exactly what you want when threading a value forward through a reducer/step).
    /// The in-place win only materializes if the consumed value was the *unique* owner; if anything
    /// else still retains it (a kept snapshot, microstep history), CoW copies regardless.
    ///
    /// Use the closure form for arbitrary / multi-field updates; it avoids the type-erased
    /// `Property` applicator (which would box through `Any` and defeat the in-place mutation):
    ///
    /// ```swift
    /// context = context.cloned { $0.organisms[i].energy -= 1 }   // no 100k copy if uniquely held
    /// ```
    consuming func cloned(_ mutate: (inout Self) -> Void) -> Self {
        var this = consume self
        mutate(&this)
        return this
    }

    /// `consuming` single key-path update — `context.cloned(\.count, 5)`.
    consuming func cloned<Value>(_ keyPath: WritableKeyPath<Self, Value>, _ value: Value) -> Self {
        var this = consume self
        this[keyPath: keyPath] = value
        return this
    }
}

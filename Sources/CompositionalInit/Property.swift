/// A marker used to detect, at the type level, whether a property's `Value` is `Optional`.
///
/// This is deliberately type-based rather than value-based: a property's "required vs. optional"
/// status is a fact about its *declared type* (`var nickname: String?`), not about whether the
/// supplied value happens to be `nil`. Checking `Value.self is OptionalProtocol.Type` therefore
/// classifies the slot correctly even when an optional property is given a non-`nil` value.
@usableFromInline
protocol OptionalProtocol {}
extension Optional: OptionalProtocol {}

/// A type-safe pairing of a `WritableKeyPath` with the value (or value-producing source) to write
/// through it — the fundamental building block of compositional initialization.
///
/// A `Property` never erases its `Value`: it is applied by writing `root[keyPath: key] = source.value`
/// directly, so there is no boxing through `Any` and no dynamic cast. Erase it to a
/// ``PartialProperty`` (over `Root`) or an ``AnyProperty`` (over `Root` *and* `Value`) only when an
/// array must hold properties of differing value types.
public struct Property<Root, Value> {
    /// How a ``Property`` produces its value when applied.
    public enum Source {
        /// A value fixed at construction time.
        case single(Value)
        /// A closure evaluated *each time the property is applied* — the "lazily executed at init"
        /// behavior. Re-evaluated on every application, so it can yield a fresh value per use.
        case closure(() -> Value)

        /// The value this source currently represents, evaluating the closure for `.closure`.
        @inlinable
        public var value: Value {
            switch self {
            case .single(let value): return value
            case .closure(let make): return make()
            }
        }
    }

    /// The writable key path this property targets.
    public let key: WritableKeyPath<Root, Value>

    /// The source that produces the value written through ``key``.
    public let source: Source

    /// Creates a property that writes a fixed `value` through `key`.
    @inlinable
    public init(key: WritableKeyPath<Root, Value>, value: Value) {
        self.init(key: key, source: .single(value))
    }

    /// Creates a property whose value is produced by `closure`, evaluated each time the property is
    /// applied (e.g. during init or `clone`).
    @inlinable
    public init(key: WritableKeyPath<Root, Value>, closure: @autoclosure @escaping () -> Value) {
        self.init(key: key, source: .closure(closure))
    }

    /// Creates a property from an explicit ``Source``.
    @inlinable
    public init(key: WritableKeyPath<Root, Value>, source: Source) {
        self.key = key
        self.source = source
    }

    /// The value this property currently represents (evaluates a `.closure` source).
    @inlinable
    public var value: Value { source.value }

    /// Whether this property targets an `Optional`-typed (i.e. not required) stored property.
    @inlinable
    public var isOptional: Bool {
        #if hasFeature(Embedded)
        // Embedded Swift has no runtime protocol-conformance metadata, so this metatype cast can't
        // be performed. The embedded `PropertyInitializable` init doesn't consult required-slot
        // counts anyway, so classify everything as required (`false`).
        false
        #else
        Value.self is OptionalProtocol.Type
        #endif
    }

    /// Erases the `Value` type, yielding a ``PartialProperty`` that can sit in a `[PartialProperty<Root>]`
    /// alongside properties of other value types. Application stays fully typed — no boxing.
    @inlinable
    public var partial: PartialProperty<Root> { PartialProperty(self) }

    /// Erases both `Root` and `Value`, yielding an ``AnyProperty``. Use only when a heterogeneous,
    /// root-agnostic array is required; application costs one safe `as?` per property.
    @inlinable
    public var any: AnyProperty { AnyProperty(self) }
}

/// A ``Property`` with its `Value` type erased, retaining `Root`.
///
/// This is the workhorse of compositional initialization: an `[PartialProperty<Root>]` can describe
/// an arbitrary set of writes to a `Root`, yet each write is performed by a captured, fully typed
/// closure — there is no `Any` boxing and no dynamic cast on the application path. ``key`` is kept
/// only for identity (so duplicate writes to the same property can be detected).
public struct PartialProperty<Root> {
    /// The targeted key path, kept for identity/equality (e.g. duplicate detection during init).
    public let key: PartialKeyPath<Root>

    /// Whether the targeted stored property is `Optional` (and therefore not required at init).
    public let isOptional: Bool

    @usableFromInline
    let _apply: (inout Root) -> Void

    /// Erases the value type of `property` while keeping its application fully typed.
    @inlinable
    public init<Value>(_ property: Property<Root, Value>) {
        self.key = property.key
        self.isOptional = property.isOptional
        let source = property.source
        let key = property.key
        self._apply = { root in root[keyPath: key] = source.value }
    }

    /// Applies this property's write to `root` in place.
    @inlinable
    public func apply(to root: inout Root) { _apply(&root) }
}

/// A ``Property`` with *both* `Root` and `Value` erased.
///
/// This is the maximally erased form, for heterogeneous arrays that don't share a `Root`. Because
/// `Root` is gone, applying it to a concrete value requires recovering that type: application uses a
/// safe conditional cast (`as?`) and is a no-op on mismatch — it never force-casts or traps. Prefer
/// ``PartialProperty`` whenever the `Root` is known.
public struct AnyProperty {
    /// The targeted key path, fully erased.
    public let key: AnyKeyPath

    /// Whether the targeted stored property is `Optional` (and therefore not required at init).
    public let isOptional: Bool

    @usableFromInline
    let _value: () -> Any

    @usableFromInline
    let _applyTo: (inout Any) -> Void

    /// The value this property currently represents, type-erased (evaluates a `.closure` source).
    @inlinable
    public var value: Any { _value() }

    /// Erases both the root and value types of `property`.
    @inlinable
    public init<Root, Value>(_ property: Property<Root, Value>) {
        self.key = property.key
        self.isOptional = property.isOptional
        let source = property.source
        let key = property.key
        self._value = { source.value }
        self._applyTo = { box in
            guard var root = box as? Root else { return }
            root[keyPath: key] = source.value
            box = root
        }
    }

    /// Applies this property's write to the value currently inside `box`, if its type matches the
    /// property's original `Root`; otherwise a no-op.
    @inlinable
    public func apply(to box: inout Any) { _applyTo(&box) }
}

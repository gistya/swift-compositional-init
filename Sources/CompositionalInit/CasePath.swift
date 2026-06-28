/// Wraps an immutable key path so it can be captured by `@Sendable` closures.
///
/// Key paths are deeply immutable and therefore thread-safe, but `WritableKeyPath` does not (yet)
/// carry a `Sendable` conformance in the standard library. This `@unchecked` conformance is the
/// minimal, provably-safe shim that lets ``CasePath``/``WritableCasePath`` stay *checked*-`Sendable`
/// at their public surface rather than marking the whole optic `@unchecked`.
@usableFromInline
struct SendableKeyPath<Root, Value>: @unchecked Sendable {
    @usableFromInline let keyPath: WritableKeyPath<Root, Value>
    @usableFromInline init(_ keyPath: WritableKeyPath<Root, Value>) { self.keyPath = keyPath }
}

/// A `CasePath` is the enum counterpart to a `WritableKeyPath`.
/// `embed` wraps a payload into the case, and `extract` pulls it back out when the value is in that case.
///
/// It is the prism to `WritableKeyPath`'s lens — together they let `<-` / `clone(mutating:)`
/// reach through both enums and other types.
///
/// The stored closures are `@Sendable`, so `CasePath` is unconditionally and *checked* `Sendable`
/// (no `@unchecked` escape hatch). Build a case path from non-capturing closures such as an enum
/// case constructor and a pattern-match extractor:
///
/// ```swift
/// enum Traffic {
///     case working(Working)
///     case crossing(Crossing)
///     enum Path {
///         static let crossing = CasePath<Traffic, Crossing>(
///             embed: Traffic.crossing,
///             extract: { if case let .crossing(v) = $0 { v } else { nil } }
///         )
///     }
/// }
/// ```
public struct CasePath<Root, Value>: Sendable {
    /// Wraps a `Value` payload into the `Root` case this path focuses.
    public let embed: @Sendable (Value) -> Root
    /// Returns the payload if `root` is in this case, else `nil`.
    public let extract: @Sendable (Root) -> Value?

    /// Creates a case path from an `embed`/`extract` pair.
    public init(
        embed: @escaping @Sendable (Value) -> Root,
        extract: @escaping @Sendable (Root) -> Value?
    ) {
        self.embed = embed
        self.extract = extract
    }

    /// The payload if `root` is in this case, else `nil`.
    public func get(_ root: Root) -> Value? { extract(root) }

    /// Replace the payload, leaving `root` unchanged if it isn't in this case (affine set).
    public func set(_ root: Root, _ value: Value) -> Root {
        extract(root) == nil ? root : embed(value)
    }

    /// Modify the payload in place if present; no-op otherwise.
    public func modifying(_ root: Root, _ transform: (inout Value) -> Void) -> Root {
        guard var value = extract(root) else { return root }
        transform(&value)
        return embed(value)
    }

    /// Compose with a `WritableKeyPath` into the payload — the prism∘lens that focuses a stored
    /// property nested inside an enum case (reads `nil` / writes are no-ops off-case).
    public func appending<Sub>(_ keyPath: WritableKeyPath<Value, Sub>) -> WritableCasePath<Root, Sub> {
        let extract = self.extract
        let embed = self.embed
        let kp = SendableKeyPath(keyPath)
        return WritableCasePath(
            get: { extract($0)?[keyPath: kp.keyPath] },
            set: { root, sub in
                guard var value = extract(root) else { return root }
                value[keyPath: kp.keyPath] = sub
                return embed(value)
            }
        )
    }

    /// Sugar for ``appending(_:)``: e.g. `Traffic.Path.crossing(\.pedestrian)`.
    public func callAsFunction<Sub>(_ keyPath: WritableKeyPath<Value, Sub>) -> WritableCasePath<Root, Sub> {
        appending(keyPath)
    }
}

/// The composition of a `CasePath` with a `WritableKeyPath`: an **affine** writable optic that
/// focuses a stored property nested inside an enum case. Reads are `nil` and writes are no-ops when
/// the root isn't in the case.
///
/// Like ``CasePath``, the stored closures are `@Sendable`, so this is checked `Sendable`.
public struct WritableCasePath<Root, Value>: Sendable {
    /// Reads the focused property, or `nil` if `root` isn't in the underlying case.
    public let get: @Sendable (Root) -> Value?
    /// Writes the focused property, returning `root` unchanged if it isn't in the underlying case.
    public let set: @Sendable (Root, Value) -> Root

    /// Creates a writable case path from a `get`/`set` pair.
    public init(
        get: @escaping @Sendable (Root) -> Value?,
        set: @escaping @Sendable (Root, Value) -> Root
    ) {
        self.get = get
        self.set = set
    }

    /// Compose further into a deeper stored property.
    public func appending<Sub>(_ keyPath: WritableKeyPath<Value, Sub>) -> WritableCasePath<Root, Sub> {
        let get = self.get
        let set = self.set
        let kp = SendableKeyPath(keyPath)
        return WritableCasePath<Root, Sub>(
            get: { get($0)?[keyPath: kp.keyPath] },
            set: { root, sub in
                guard var value = get(root) else { return root }
                value[keyPath: kp.keyPath] = sub
                return set(root, value)
            }
        )
    }

    /// Sugar for ``appending(_:)``.
    public func callAsFunction<Sub>(_ keyPath: WritableKeyPath<Value, Sub>) -> WritableCasePath<Root, Sub> {
        appending(keyPath)
    }
}

public extension CasePath where Root: Equatable {
    /// Build a case path from just the case initializer — `CasePath(Event.increment)` — deriving
    /// `extract` by reflection: pull the case's single associated value and confirm the case by
    /// re-embedding and comparing (hence the `Root: Equatable` requirement). Handles unlabeled
    /// (`case foo(Int)`), labeled (`case foo(by: Int)`), and tuple (`case foo(Int, String)`) payloads.
    ///
    /// This is the macro-free, swift-syntax-free way to get an ergonomic case path: no hand-written
    /// `extract` closure, no codegen.
    init(_ embed: @escaping @Sendable (Value) -> Root) {
        self.init(
            embed: embed,
            extract: { root in
                let mirror = Mirror(reflecting: root)
                guard mirror.displayStyle == .enum, let raw = mirror.children.first?.value else { return nil }
                let candidate: Value?
                if let direct = raw as? Value {
                    candidate = direct
                } else {
                    // A labeled single payload (`foo(by: Int)`) reflects as a 1-element tuple; unwrap it.
                    let inner = Mirror(reflecting: raw)
                    candidate = (inner.displayStyle == .tuple && inner.children.count == 1)
                        ? inner.children.first?.value as? Value
                        : nil
                }
                guard let value = candidate, embed(value) == root else { return nil }
                return value
            }
        )
    }
}

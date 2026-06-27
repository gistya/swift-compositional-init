/// A `CasePath` is the enum counterpart to a `WritableKeyPath`.
/// `embed` wraps a payload into the case, and `extract` pulls it back out when the value is in that case.
///
/// It is the prism to `WritableKeyPath`'s lens — together they let `<-` / `clone(mutating:)`
/// reach through both enums and other types.
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
public struct CasePath<Root, Value>: @unchecked Sendable {
    public let embed: (Value) -> Root
    public let extract: (Root) -> Value?

    public init(
        embed: @escaping (Value) -> Root,
        extract: @escaping (Root) -> Value?
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
        WritableCasePath(
            get: { extract($0)?[keyPath: keyPath] },
            set: { root, sub in
                guard var value = extract(root) else { return root }
                value[keyPath: keyPath] = sub
                return embed(value)
            }
        )
    }

    /// Sugar for `appending(_:)`: e.g. `Traffic.Path.crossing(\.pedestrian)`.
    public func callAsFunction<Sub>(_ keyPath: WritableKeyPath<Value, Sub>) -> WritableCasePath<Root, Sub> {
        appending(keyPath)
    }
}

/// The composition of a `CasePath` with a `WritableKeyPath`: an **affine** writable optic that
/// focuses a stored property nested inside an enum case. Reads are `nil` and writes are no-ops when
/// the root isn't in the case.
public struct WritableCasePath<Root, Value>: @unchecked Sendable {
    public let get: (Root) -> Value?
    public let set: (Root, Value) -> Root

    public init(
        get: @escaping (Root) -> Value?,
        set: @escaping (Root, Value) -> Root
    ) {
        self.get = get
        self.set = set
    }

    /// Compose further into a deeper stored property.
    public func appending<Sub>(_ keyPath: WritableKeyPath<Value, Sub>) -> WritableCasePath<Root, Sub> {
        WritableCasePath<Root, Sub>(
            get: { get($0)?[keyPath: keyPath] },
            set: { root, sub in
                guard var value = get(root) else { return root }
                value[keyPath: keyPath] = sub
                return set(root, value)
            }
        )
    }

    public func callAsFunction<Sub>(_ keyPath: WritableKeyPath<Value, Sub>) -> WritableCasePath<Root, Sub> {
        appending(keyPath)
    }
}


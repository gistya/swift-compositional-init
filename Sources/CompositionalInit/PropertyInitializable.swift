/// A type that can be initialized *compositionally* — from a collection of type-safe key-path/value
/// ``Property`` pairs — and cloned with a subset of its properties overridden.
///
/// Conforming requires only ``_blank``: a fully-formed placeholder instance. (This requirement
/// exists because Swift key paths cannot yet be used to assign stored properties at definite-init
/// time; a compiler feature would remove it. It is spelled with a leading underscore to signal that
/// it is conformance plumbing, not part of the type's public vocabulary.)
public protocol PropertyInitializable: Cloneable {
    /// Failable initialization from a set of properties. Succeeds iff every *required* (non-optional)
    /// stored property is written exactly once across `properties`; otherwise returns `nil`.
    init?(_ properties: [PartialProperty<Self>])

    /// A placeholder instance with every stored property already populated.
    ///
    /// Necessary because Swift key paths may not be used to set stored properties during definite
    /// initialization; the supplied values are overwritten by any property that targets them. The
    /// soundness of the failable initializer does not depend on which placeholder values are used —
    /// only required properties that are *actually written* count toward success.
    static var _blank: Self { get }
}

public extension PropertyInitializable {
    /// The number of stored properties that are *required* — i.e. not `Optional`-typed — and so must
    /// be written for the failable initializer to succeed.
    var numberOfNonOptionalProperties: Int {
        Mirror(reflecting: self).nonOptionalChildren.count
    }

    /// Failably initializes `Self` from `properties`.
    ///
    /// Each property is applied (a fully typed write — no boxing, no dynamic cast). Initialization
    /// succeeds iff the set of *distinct* required key paths written equals the number of required
    /// stored properties. Tracking distinct key paths (rather than counting applications) makes the
    /// check robust to duplicate writes: writing the same property twice cannot masquerade as having
    /// satisfied two required slots.
    init?(_ properties: [PartialProperty<Self>]) {
        var new = Self._blank
        let requiredCount = new.numberOfNonOptionalProperties
        var requiredKeysWritten = Set<PartialKeyPath<Self>>()

        for property in properties {
            property.apply(to: &new)
            if !property.isOptional {
                requiredKeysWritten.insert(property.key)
            }
        }

        guard requiredKeysWritten.count == requiredCount else { return nil }
        self = new
    }

    /// Variadic sugar for the array-based failable initializer.
    init?(_ properties: PartialProperty<Self>...) {
        self.init(properties)
    }

    /// Failably initializes `Self` from fully type-erased ``AnyProperty`` values.
    ///
    /// Each property is applied through a single boxed copy of `Self` using a safe conditional cast,
    /// so a property whose original root was a *different* type is a no-op (and the init then fails
    /// because a required slot is left unwritten) rather than trapping. Prefer the
    /// ``PartialProperty`` overload when the root type is known.
    init?(_ properties: [AnyProperty]) {
        var box: Any = Self._blank
        let requiredCount = Self._blank.numberOfNonOptionalProperties
        var requiredKeysWritten = Set<AnyKeyPath>()

        for property in properties {
            property.apply(to: &box)
            if !property.isOptional {
                requiredKeysWritten.insert(property.key)
            }
        }

        guard requiredKeysWritten.count == requiredCount, let new = box as? Self else { return nil }
        self = new
    }

    /// Variadic sugar for the array-based ``AnyProperty`` failable initializer.
    init?(_ properties: AnyProperty...) {
        self.init(properties)
    }
}

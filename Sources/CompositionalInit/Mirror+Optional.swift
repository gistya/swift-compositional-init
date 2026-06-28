public extension Mirror {
    /// The reflected children whose declared type is *not* `Optional` — i.e. the stored properties
    /// that must be set during compositional initialization. Used to count required slots.
    var nonOptionalChildren: Mirror.Children {
        let filtered = self.children.filter { child in
            guard let varName = child.label, let descendant = self.descendant(varName) else { return false }
            return !isOptional(descendant)
        }
        return Mirror.Children(filtered)
    }
}

/// Returns `true` if `instance` is an `Optional` value (its mirror's display style is `.optional`).
///
/// Used to classify reflected stored properties as required vs. optional during initialization.
/// For classifying a ``Property`` by its *static* `Value` type instead, see ``Property/isOptional``.
public func isOptional<T>(_ instance: T) -> Bool {
    guard let displayStyle = Mirror(reflecting: instance).displayStyle
        else { return false }
    return displayStyle == .optional
}

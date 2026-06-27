/// Extension to mirror that ensures all children that need to be set at init time, are accounted for.
public extension Mirror {
    var nonOptionalChildren: Mirror.Children {
        let filtered = self.children.filter { child in
            guard let varName = child.label, let descendant = self.descendant(varName) else { return false }
            return !isOptional(descendant)
        }
        return Mirror.Children(filtered)
    }
}

/// A function to check if a property is optional.
public func isOptional<T>(_ instance: T) -> Bool {
    guard let displayStyle = Mirror(reflecting: instance).displayStyle 
        else { return false }
    return displayStyle == .optional
}

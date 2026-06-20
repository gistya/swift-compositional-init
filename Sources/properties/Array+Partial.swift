infix operator +: AdditionPrecedence

/// Convenience extension on Array to support arrays of PartialProperty items.
public extension Array where Element == PartialProperty<Any?> {
    /// Infix operator function for partially type-erasing a Property tuple
    /// and adding it to an array of PartialProperties. This allows the variable type
    /// of each property to be different without violating the static typing of the array.
    static func + <Root, Value>(left: Array<PartialProperty<Root>>, right: (WritableKeyPath<Root, Value>, Value)) -> Array<PartialProperty<Root>> { 
        var new = left
        let partial = (Property<Root, Value>(key: right.0, value: right.1)).partial
        new.append(partial)
        return new
    }
}

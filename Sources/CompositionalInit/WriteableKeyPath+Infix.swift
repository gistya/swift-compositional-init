/// Operator <- allows association of a keypath with a value in a typesafe manner
/// without initializing the root object.
infix operator <-

public extension WritableKeyPath {
    static func <- (left: WritableKeyPath<Root, Value>, right: Value) -> AnyProperty {
        Property<Root, Value>(key: left, value: right).any
    }

    static func <- (left: WritableKeyPath<Root, Value>, right: Value) -> PartialProperty<Root> {
        Property<Root, Value>(key: left, value: right).partial
    }
    
    static func <- (left: WritableKeyPath<Root, Value>, right: Property<Root, Value>.Source) -> AnyProperty {
        Property<Root, Value>(key: left, source: right).any
    }

    static func <- (left: WritableKeyPath<Root, Value>, right: Property<Root, Value>.Source) -> PartialProperty<Root> {
        Property<Root, Value>(key: left, source: right).partial
    }
    
    static func <- (left: WritableKeyPath<Root, Value>, right: @escaping () -> Value) -> AnyProperty {
        Property<Root, Value>(key: left, source: .closure(right)).any
    }
    
    static func <- (left: WritableKeyPath<Root, Value>, right: @escaping () -> Value) -> PartialProperty<Root> {
        Property<Root, Value>(key: left, source: .closure(right)).partial
    }
}

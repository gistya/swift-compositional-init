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
}

/// `<-` for a `Mockable` root, pairing a key path with a `Mock` value (now non-throwing, matching
/// the plain `<-`). Restored after the non-throwing refactor dropped it.
public extension WritableKeyPath where Root: Mockable {
    static func <- (left: WritableKeyPath<Root, Value>, right: Mock<Value>) -> PartialProperty<Root> {
        MockProperty<Root, Value>(key: left, mock: right).partial
    }
}

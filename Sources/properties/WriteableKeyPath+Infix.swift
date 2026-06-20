/// Operator <- allows association of a keypath with a value in a typesafe manner
/// without initializing the root object.
infix operator <-

public extension WritableKeyPath {
    static func <- (left: WritableKeyPath<Root, Value>, right: @autoclosure @escaping () throws -> Value) throws -> PartialProperty<Root> {
        return Property<Root, Value>(key: left, value: try right()).partial
    }
}

/// Extension to support <- operator with Mockable root.
public extension WritableKeyPath where Root: Mockable {
    static func <- (left: WritableKeyPath<Root, Value>, right: Mock<Value>) throws -> PartialProperty<Root> {
        return MockProperty<Root, Value>(key: left, mock: right).partial
    }
}

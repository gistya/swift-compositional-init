/// An object available as a fully type-erased keypath-value pair.
/// (The keypath-value pairing is fully typesafe internally.)
public protocol AnyPropertyProtocol {
    associatedtype Root = Any
    associatedtype Value = Any
    associatedtype KP = AnyKeyPath
    var key: KP { get }
    var value: Value { get }
    var applicator: (Any, Any?, Any?) -> (Any, didChange: Bool) { get set }
}

/// An object available as a partially type-erased keypath-value pair.
/// (The keypath-value pairing is fully typesafe internally.) 
public protocol PartialPropertyProtocol: AnyPropertyProtocol
where KP: PartialKeyPath<Root> {
}

/// An object available as a keypath-value pair.
public protocol PropertyProtocol: PartialPropertyProtocol
where KP: WritableKeyPath<Root, Value> {
}

extension AnyPropertyProtocol {
    /// Applies a mutation to a root object.
    public func apply(value: Value?, to root: Root) -> (Root, didChange: Bool) {
        return applicator(root, value, nil) as! (Self.Root, didChange: Bool)
    }
}

/// An AnyProperty is a fully type-erased, yet internally typesafe, keypath-value pair.
public struct AnyProperty: AnyPropertyProtocol {
    public typealias KP = AnyKeyPath
    public typealias Root = Any
    public typealias Value = Any
    
    private(set) public var key: KP
    private var _value: Closure<Value>
    
    public var applicator: (Any, Any?, Any?) -> (Any, didChange: Bool)
    
    public init<P>(_ base: P) where P: PropertyProtocol {
        self._value = .value(base.value)
        self.key = base.key as AnyKeyPath
        self.applicator = base.applicator
    }
    
    public init<P>(_ base: P) where P: PartialPropertyProtocol {
        self._value = .value(base.value)
        self.key = base.key as AnyKeyPath
        self.applicator = base.applicator
    }
    
    public var value: Value {
        switch _value {
        case let .value(value): value
        case let .lambda(value): value()
        }
    }
    
    private enum Closure<Value> {
        case value(Value)
        case lambda(() -> Value)
    }
}

/// A PartialProperty is a partially type-erased, yet internally typesafe, keypath-value pair.
public struct PartialProperty<R>: PartialPropertyProtocol {
    public typealias Value = Any
    public typealias KP = PartialKeyPath<R>
    public typealias Root = R
    
    private(set) public var key: PartialKeyPath<R>
    private(set) public var value: Value
    public var applicator: (Any, Any?, Any?) -> (Any, didChange: Bool)
    
    public init<P>(_ base: P) where P: PartialPropertyProtocol, P.Root == R {
        self.value = base.value
        self.key = base.key as PartialKeyPath<Root>
        self.applicator = base.applicator
    }
    
    public var any: AnyProperty { AnyProperty(self) }
}

/// A Property is a typesafe keypath-value pair.
public struct Property<R, V>: PropertyProtocol {
    public typealias Root = R
    public typealias Value = V
    public typealias KP = WritableKeyPath<R, V>
    
    private(set) public var key: KP
    private(set) public var value: Value
    public var applicator: (Any, Any?, Any?) -> (Any, didChange: Bool)
    
    public init(key: KP, value: Value) {
        self.key = key
        self.value = value
        self.applicator = { root, passed, _ in
            var instance: R = root as! R
            instance[keyPath: key] = (passed as? V) ?? value
            return (instance, true)
        }
    }
    
    public var partial: PartialProperty<Root> {
        PartialProperty(self)
    }
    
    public var any: AnyProperty {
        AnyProperty(self)
    }
}

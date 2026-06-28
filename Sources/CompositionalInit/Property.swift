/// An AnyProperty is a fully type-erased, yet internally typesafe, keypath-value pair.
public struct AnyProperty: AnyPropertyProtocol {
    public typealias KP = AnyKeyPath
    public typealias Root = Any
    public typealias Value = Any
    
    private(set) public var key: KP
    public var value: Value
    
    public var applicator: (Any, Any?, Any?) -> (Any, didChange: Bool)
    
    public init<P>(_ base: P) where P: PropertyProtocol {
        self.value = base.value
        self.key = base.key as AnyKeyPath
        self.applicator = base.applicator
    }
    
    public init<P>(_ base: P) where P: PartialPropertyProtocol {
        self.value = base.value
        self.key = base.key as AnyKeyPath
        self.applicator = base.applicator
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

public class Iteration {
    var i: Int
    init(_ i: Int) { self.i = i }
}

/// A Property is a typesafe keypath-value pair.
public struct Property<R, V>: PropertyProtocol {
    public indirect enum Source {
        case single(Value)
        case iterate(Iteration, [Value])
        case randomize([Value])
        case closure(() -> Value)
    }

    public typealias Root = R
    public typealias Value = V
    public typealias KP = WritableKeyPath<R, V>
    
    private(set) public var key: KP
    private(set) public var source: Source
    
    public var applicator: (Any, Any?, Any?) -> (Any, didChange: Bool)
    
    /// Initializing a Property with a single value defaults the origin to .single.
    public init(key: KP, value: Value) {
        self.init(key: key, source: .single(value))
    }
    
    /// Initializing a Property with a range of possibleValues enables the property to be in
    /// .iterate mode, where the getter will iterate to the next value each time, or
    /// .randomize mode, where it will pick randomly from a set of values each time the getter is used.
    public init(key: KP, iteration i: Int, valuesToIterate values: [Value], default: Value? = nil) {
        self.init(key: key, source: .iterate(Iteration(i), values))
    }
    
    /// Initializing a Property with a closure function sets the origin to
    /// .generate, where the function `closure` will be called whenever the getter is invoked,
    /// and it may use the passed-in `origin` to inform its behavior.
    public init(key: KP, closure: @autoclosure @escaping () -> Value) {
        self.init(key: key, source: .closure(closure))
    }
    
    /// Initializing a Property with a predefined Source behavior object created before-hand.
    /// This function is called by the other initializers.
    public init(key: KP, source: Source) {
        self.source = source
        self.key = key
        self.applicator = {root, value, _ in
            var instance: R = root as! R
            if let value = value as? V {
                instance[keyPath: key] = value
                return (instance, true)
            }
            return (instance, false)
        }
    }
    
    /// Partial type-erasure.
    public var partial: PartialProperty<Root> {
        return PartialProperty(self)
    }
    
    /// Full type-erasure.
    public var any: AnyProperty {
        return AnyProperty(self)
    }
    
    public var value: Value {
        get {
            switch source {
            case .single(let value):
                return value
                
            case .iterate(let iteration, let values):
                var index = iteration.i
                if index >= values.count {
                    index = index % values.count
                }
                iteration.i += 1
                return values[values.index(values.startIndex, offsetBy: index)]
                
            case .randomize(let values):
                let max = values.count - 1
                let rand = Int((0...UInt32(max)).randomElement() ?? 0)
                return values[values.index(values.startIndex, offsetBy: rand)]
                
            case .closure(let closure):
                return closure()
            }
        }
        
        set {
            /// Do nothing. This is just to let us use the default init.
        }
    }
    
    /// Applies the `source` value to the `root` object of this Property.
    func apply(source: Source, to root: Root) -> (Root, didChange: Bool) {
        return applicator(root, source, nil) as! (Self.Root, didChange: Bool)
    }
}

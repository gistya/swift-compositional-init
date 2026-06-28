/// Example implementation using the above types for service sourceing.
///
/// DynamicProperty implements SourceableProperty, which allows a Property to 
/// generate its own value at runtime depending upon the value of the origin variable.
public struct DynamicProperty<R: PropertyInitializable, V>: SourceableProperty {
    public typealias Root = R
    public typealias Value = V
    public typealias KP = WritableKeyPath<R, V>
    
    private(set) public var key: KP
    private(set) public var source: Source<Value>
    
    public var applicator: (Any, Any?, Any?) -> (Any, didChange: Bool)
    
    /// Initializing a DynamicProperty with a single value defaults the origin to .single.
    public init(key: KP, value: Value) {
        let source: Source<Value> = Source<Value>(
            \.origin <- .single(value)
        )!
        self.init(key: key, source: source)
    }
    
    /// Initializing a DynamicProperty with a range of possibleValues enables the property to be in
    /// .iterate mode, where the getter will iterate to the next value each time, or
    /// .randomize mode, where it will pick randomly from a set of values each time the getter is used.
    public init(key: KP, possibleValues: [Value], shouldRandomize: Bool = false, iteration: Int) {
        let source: Source<Value> = Source<Value>(
            \.iteration <- iteration,
            \.origin <- (shouldRandomize 
                ? .randomize(possibleValues) 
                : .iterate(possibleValues))
            )!
        self.init(key: key, source: source)
    }
    
    /// Initializing a DynamicProperty with a closure function sets the origin to
    /// .generate, where the function `closure` will be called whenever the getter is invoked,
    /// and it may use the passed-in `origin` to inform its behavior.
    public init(key: KP, closure: @escaping Source<Value>.Closure, origin: Source<Value>.Origin) {
        let source: Source<Value> = Source<Value>(
            \.origin <- .closure(closure)
        )!
        self.init(key: key, source: source)
    }
    
    /// Initializing a SourcePropety with a predefined Source behavior object created before-hand.
    /// This function is called by the other initializers.
    public init(key: KP, source: Source<Value>) {
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
            switch source.origin {
            case .none:
                fatalError()
                
            case .single(let value):
                return value
                
            case .iterate(let values):
                var index = source.iteration
                if index >= values.count {
                    index = values.count % index
                }
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
    
    /// Applies the `source` value to the `root` object of this DynamicProperty.
    func apply(source: Source<Value>, to root: Root) -> (Root, didChange: Bool) {
        return applicator(root, source, nil) as! (Self.Root, didChange: Bool)
    }

}

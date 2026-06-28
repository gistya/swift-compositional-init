/// Example implementation using the above types for service sourceing.
/// 
/// DynamicProperty implements SourceableProperty, which allows a Property to 
/// generate its own value at runtime depending upon the value of the creationMethod variable.
public struct DynamicProperty<R: PropertyInitializable, V>: SourceableProperty {
    public typealias Root = R
    public typealias Value = V
    public typealias KP = WritableKeyPath<R, V>
    
    private(set) public var key: KP
    private(set) public var source: Source<Value>
    
    public var applicator: (Any, Any?, Any?) -> (Any, didChange: Bool)
    
    /// Initializing a DynamicProperty with a single value defaults the creationMethod to .single.
    public init(key: KP, value: Value) {
        let source: Source<Value> = Source<Value>(
            \.creationMethod <- .single(value)
        )!
        self.init(key: key, source: source)
    }
    
    /// Initializing a DynamicProperty with a range of possibleValues enables the property to be in
    /// .iterate mode, where the getter will iterate to the next value each time, or
    /// .randomize mode, where it will pick randomly from a set of values each time the getter is used.
    public init(key: KP, possibleValues: [Value], shouldRandomize: Bool = false, iteration: Int) {
        let source: Source<Value> = Source<Value>(
            \.iteration <- iteration,
            \.creationMethod <- (shouldRandomize 
                ? .randomize(possibleValues) 
                : .iterate(possibleValues))
            )!
        self.init(key: key, source: source)
    }
    
    /// Initializing a DynamicProperty with a generator function sets the creationMethod to
    /// .generate, where the function `generator` will be called whenever the getter is invoked,
    /// and it may use the passed-in `creationMethod` to inform its behavior.
    public init(key: KP, generator: @escaping Source<Value>.Generator, creationMethod: Source<Value>.CreationMethod) {
        let source: Source<Value> = try! Source<Value>(
            \.creationMethod <- .generate(generator, creationMethod)
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
}

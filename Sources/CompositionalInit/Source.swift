//public protocol Sourceable {}
//
///// Struct defining the configurable and default behavior for SourceableProperties.
//public struct Source<Value>: PropertyInitializable, Sourceable {
//    
//    public typealias Closure = () -> Value
//    
//    public var iteration: Int = 0
//    public var `default`: Value?
//    public var origin: Origin
//    
//    public init() {
//        origin = .none
//    }
//    
//    public init(value: Value) {
//        origin = .single(value)
//    }
//    
//    public init(iteration: Int, valuesToIterate values: [Value], default: Value? = nil) {
//        origin = .iterate(values)
//        self.iteration = iteration
//        self.default = `default`
//    }
//    
//    public init(randomize values: [Value]) {
//        origin = .randomize(values)
//    }
//    
//    public init(_ closure: @autoclosure @escaping () -> Value) {
//        self.origin = .closure(closure)
//    }
//    
//    public static var _blank: Self { .init() }
//}

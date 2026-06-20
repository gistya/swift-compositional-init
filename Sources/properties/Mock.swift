/// Struct defining the configurable and default behavior for MockableProperties.
public struct Mock<Value>: PropertyInitializable {
    public indirect enum CreationMethod {
        case none
        case single(Value)
        case iterate([Value])
        case randomize([Value])
        case generate(Generator, CreationMethod)
    }
    
    public typealias Generator = (CreationMethod) -> Value
    public var iteration: Int
    public var `default`: Value?
    public var creationMethod: CreationMethod
    
    public static var _blank: Mock<Value> { 
        Mock<Value>(iteration: 0, default: nil, creationMethod: .none) 
    }
}

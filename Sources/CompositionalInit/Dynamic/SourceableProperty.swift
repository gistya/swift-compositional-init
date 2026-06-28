import Foundation

/// A property that can generate its own values according to configurable behavior,
/// for the purpose of mocking a service (testing).
public protocol SourceableProperty: PropertyProtocol {
    var source: Source<Value> { get }
}

/// Extension that provides the configurable behavior for the `value` of the property.
public extension DynamicProperty {
    var value: Value {
        get {
            switch source.creationMethod {
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
                let rand = Int(arc4random_uniform(UInt32(max)))
                return values[values.index(values.startIndex, offsetBy: rand)]
                
            case .generate(let generator, let creationMethod):
                return generator(creationMethod)
            }
        }
        
        set {
            /// Do nothing. This is just to let us use the default init.
        }
    }
    
    /// Applies the `mock` value to the `root` object of this MockProperty.
    func apply(mock: Source<Value>, to root: Root) -> (Root, didChange: Bool) {
        return applicator(root, mock, nil) as! (Self.Root, didChange: Bool)
    }
}

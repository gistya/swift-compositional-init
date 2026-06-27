/// Allows an object to be defined as PropertyInitializable.
/// This allows it to be initialized from a collection of keypath-value pairs (Properties).
public protocol PropertyInitializable: Clonable {
    /// Init from an array of properties.
    init?(_ properties: [PartialProperty<Self>])
    
    /// A default getter for a "blank" object with its variables all initialized, 
    /// necessary since Swift 5 keypaths may not be used at actual init time to set values.
    /// Note: hopefully some "under the hood" improvements to Swift could
    ///       make this step unneccessary.
    static var _blank: Self { get }
}

/// Implementation of initialization from an array of properties or variadic properties.
public extension PropertyInitializable {
    var numberOfNonOptionalProperties: Int {
        return Mirror(reflecting: self).nonOptionalChildren.count
    }
    
    init?(_ properties: [PartialProperty<Self>]) {
        var new = Self._blank
        var propertiesLeftToInit = new.numberOfNonOptionalProperties
        
        for property in properties {
            let value = property.value
            let (updated, didChange) = property.apply(value: value, to: new)
            if didChange {
                new = updated
                if !isOptional(value) { propertiesLeftToInit -= 1 }
            }
        }
        
        if propertiesLeftToInit == 0 { self = new; return } else { return nil }
    }
    
    init?(_ properties: PartialProperty<Self>...) {
        self.init(properties)
    }
    
    init?(_ properties: [AnyProperty]) {
        var new = Self._blank
        var propertiesLeftToInit = new.numberOfNonOptionalProperties
        
        for property in properties {
            let value = property.value
            let (updated, didChange) = property.apply(value: value, to: new)
            if didChange {
                guard let updated = updated as? Self else {
                    return nil
                }
                
                new = updated
                if !isOptional(value) { propertiesLeftToInit -= 1 }
            }
        }
        
        if propertiesLeftToInit == 0 { self = new; return } else { return nil }
    }
    
    init?(_ properties: AnyProperty...) {
        self.init(properties)
    }
}


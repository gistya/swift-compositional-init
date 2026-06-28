# Swift Compositional Initialization

This library provides the ability to initialize instances of types conforming to `PropertyInitializable` from a collection of `Property` objects. 

You can now compose initialization itself:

```swift
import CompositionalInit

struct IceCream {
    var flavor: String
    var softness: Double
}

extension IceCream: PropertyInitializable {
    static var _blank: Self {
        .init(flavor: "", softness: 0.0)
    }
}

let flavorProperty: AnyProperty = \IceCream.flavor <- "Chocolate"
let softnessProperty: AnyProperty = \IceCream.softness <- 0.8

guard let chocolateIceCream = IceCream(flavorProperty, softnessProperty) 
else {
    fatalError("Death by lack of ice cream.")
}
```

You can also clone any instance of a conforming type, mutating only certain properties: 

```swift
let vanillaIceCream = chocolatIceCream.clone(
    mutating: \.flavor <- "vanilla"
)
```

Further you can use a closure to provide the value at call time:

```swift
struct HotDay {
    let time = Date.now.timeIntervalSince1970

    var meltingIceCream: IceCream { 
        vanillaIceCream.clone(mutating: 
            \.softness <- heat(over: time)
        )
    }
    
    func heat(over time: Double) -> Double {
        (Date.now.timeIntervalSince1970 - time) * 1000.0
    }
}

let hotDay = HotDay()

print(hotDay.meltingIceCream.softness) // 0.219291
 
print(hotDay.meltingIceCream.softness) // 0.848912
```

This library grew out of my 2019 Swift Evolution proposal, [Compositional Initialization](https://forums.swift.org/t/pitch-init-wrappers/87095d), which proposed:

- failable init from a collections of extensible, typesafe keypath-value Property objects
- non-failable init to clone from another instance, mutating select properties

Since then this little library has undergone some of its own. Hope you find it useful.
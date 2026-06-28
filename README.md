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
let vanillaIceCream = chocolateIceCream.clone(
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

Enums work too. Pair a `CasePath` with a key path and you can reach a property buried inside a case:

```swift
enum Cone: Cloneable {
    case waffle(Scoops)
    case cup(Scoops)
    struct Scoops { var count: Int; var flavor: String }

    enum Path {
        static let waffle = CasePath<Cone, Scoops>(
            embed: Cone.waffle,
            extract: { if case let .waffle(s) = $0 { s } else { nil } }
        )
    }
}

var order = Cone.waffle(.init(count: 1, flavor: "Chocolate"))
order = order.clone(mutating: Cone.Path.waffle(\.count) <- 3)
```

If the value happens to be in some other case, the write just no-ops, so you never have to check first:

```swift
let cup = Cone.cup(.init(count: 2, flavor: "Vanilla"))
cup.clone(mutating: Cone.Path.waffle(\.count) <- 99) // still a cup, untouched
```

Need to mock up a pile of instances? `MockProperty` hands you a fresh value each time — cycle through a list, or pick at random:

```swift
let flavors = MockProperty(\IceCream.flavor, randomize: ["Chocolate", "Vanilla", "Mint"])
let softness = MockProperty(\IceCream.softness, iterate: [0.1, 0.5, 0.9])

let cone = IceCream(flavors.sampleProperty(), softness.sampleProperty())!
```

The randomness comes from a generator you hand it, so seed your own when you want the same fixtures every run:

```swift
var rng = MySeededGenerator(seed: 42)
let same = IceCream(flavors.sampleProperty(using: &rng),
                    softness.sampleProperty(using: &rng))!
```

And when you're threading one big value forward and don't want to copy its storage, `cloned` takes ownership and mutates in place:

```swift
var batch = chocolateIceCream
batch = batch.cloned { $0.softness += 0.1 } // no copy when batch is uniquely held
```

That one even works on `~Copyable` types.

This library grew out of my 2019 Swift Evolution proposal, [Compositional Initialization](https://forums.swift.org/t/pitch-init-wrappers/87095d), which proposed:

- failable init from a collections of extensible, typesafe keypath-value Property objects
- non-failable init to clone from another instance, mutating select properties

Since then this little library has undergone some of its own. Hope you find it useful.
import Testing
import Foundation
@testable import properties

struct Test2 {
    var str1: String
    var int4: Int?
    var int5: Int?
}

extension Test2: PropertyInitializable {
    static let _blank = Test2(str1: "ERROR-NOT-SET", int4: nil, int5: nil)
}

@Test func propertiesTest() async throws {
    /// Succeeds to init.
    let properties1: [PartialProperty<Test2>] = [
        Property(key: \Test2.str1, value: "asdf").partial,
        //Property(key: \Test2.int4, value: 1337).partial
    ]
    
    /// Succeeds to init.
    let properties2: [PartialProperty<Test2>] = [
        Property(key: \Test2.str1, value: "asdf").partial,
        Property(key: \Test2.int4, value: 1337).partial
    ]
    
    /// will fail to if commented line is uncommented, because str1 is not optional.
    let properties3: [PartialProperty<Test2>] = [
        //Property(key: \Test2.str1, value: "asdf").partial,
        Property(key: \Test2.int4, value: 1337).partial
    ]
    
    /// Succeeds to init:
    let properties4: [PartialProperty<Test2>] = [
        Property(key: \Test2.str1, value: "asdf").partial,
        Property(key: \Test2.int4, value: nil).partial
    ]
    
    /// Further Tests:
    
    let test1 = Test2(properties1)
    assert(test1 != nil, "test1 should not be nil")
    assert(test1!.str1 == "asdf", "test1.str1 should be 'asdf'")
    
    let test2 = Test2(properties2)
    assert(test2 != nil, "test2 should not be nil")
    assert(test2!.str1 == "asdf", "test2.str1 should be 'asdf'")
    assert(test2!.int4 == 1337, "test2.int4 should be 1337")
    
    let test3 = Test2(properties3)
    assert(test3 == nil, "test3 should be nil")
    
    let test4 = Test2(clone: test2!, with: properties4)
    assert(test4.str1 == "asdf", "test4.str1 should be 'asdf'")
    assert(test4.int4 == nil, "test4.int4 should be nil")
    
    let test5 = Test2(clone: test2!, with: properties3)
    assert(test5.str1 == "asdf", "test5.str1 should be 'asdf'")
    assert(test5.int4 == 1337, "test5.int5 should be 1337")
    
    /// Compiler won't accept this unless the we wrap the cast in parentheses.
    let fooProps: [PartialProperty<Foo>] = try! [
        (\Foo.bar as! WritableKeyPath) <- 5
    ]
    
    let foo = Foo(fooProps)
    assert(foo != nil)

    /// Here there is a problem where for some reason, the infix operator is not treated correctly by the compiler:

    let p: [PartialProperty<Test2>] = [] + (\Test2.str1, "asdf") + (\Test2.int4, 1337) + (\Test2.int5, 999)

    let testy = Test2.init(p)
    
    assert(testy != nil)

    let z: [PartialProperty<Zag>] = [] + (\.a, 2) + (\.b, "2") + (\.c, 2.0)

    let testz = Zag(z)
    assert(testz != nil)
    assert(testz!.a == 2)
    assert(testz!.b == "2")
    assert(testz!.c == 2.0)

    // MARK: - Mockables test

    typealias GeneratorInput<V> = (initialValue: V?, index: Int?)

    /// A generator function for a mock value.
    func gen<V: StringProtocol> (_ input: GeneratorInput<V>) throws -> V {
        let val = "\(input.initialValue ?? "2")"
        let index = input.index ?? 0
        return val + "\(index)" as! V
    }

    /// Validate that compositional-style PropertyInitializable init works (using an array of properties).
    let m: [PartialProperty<Mag>] = try! [
        \.a <- 2,
        \.b <- gen((nil, nil)),
        \.c <- nil
    ]
    
    assert(m.count == 3)

    /// Validate that PropertyInitializable init works as expected.
    let magtest1 = try! Mag(
        \.a <- 2,
        \.b <- gen((nil, nil)),
        \.c <- nil
    )

    assert(magtest1 != nil)
    assert(magtest1?.a == 2)
    assert(magtest1?.b == "20")
    assert(magtest1?.c == nil)
    
    var magtest2 = [Mag]()

    /// Example 1 of using PropertyInitializable init with iterable value.
    for i in 0...5 {
        magtest2.append((try! Mag(
            \.a <- 2,
            \.b <- Mock(iteration: i, default: nil, creationMethod: .iterate(["a", "b", "c", "d", "e"])),
            \.c <- nil
            ))!
        )
    }

    let letters = ["a", "b", "c", "d", "e"]

    /// Validate that the proper values got set correctly.
    for i in 0...4 {
        assert(magtest2[i].b == letters[i])
    }

    do {
        let testHat = try Hat(
            /// Breaks if uncommented, as expected since a is let.
            //\.a <- 2,
            
            /// Breaks if uncommented, as expected since b is private.
            //\.b <- 2,
            
            /// Breaks if uncommented, as expected since d is let.
            //\.d = 2,
            
            /// Breaks if uncommented, as expected since e is private.
            //\.e = 2,
            
            /// Breaks if uncommented, as expected since f has a default value,
            /// and private(set) is externally immutable once set.
            //\.f = 2,
            
            \.c <- 2,
            \.g <- 2,
            \.h <- 2
        )
        
        assert(testHat != nil)
    } catch {
        print(error)
    }

    struct Customer: PropertyInitializable {
        var name: String = ""
        var zipcode: Int = 0
        var addressLine1: String = ""
        var addressLine2: String = ""
        var addressLine3: String = ""
        
        internal static var _blank: Customer {
            get { return Customer() }
        }
    }

    let dataFromTestWebResponse = [PartialProperty<Customer>]()
        + (\.name, "Steve Jobs")
        + (\.zipcode, 97202)
        + (\.addressLine1, "Reed College")
        + (\.addressLine2, "3203 SE Woodstock Blvd Box #121")

    if let customer: Customer = Customer(dataFromTestWebResponse) {
        print(customer)
    } else {
        print("Data is missing.")
    }

    let reedieData = [PartialProperty<Customer>]()
        + (\.zipcode, 97202)
        + (\.addressLine1, "Reed College")
        + (\.addressLine2, "3203 SE Woodstock Blvd")

    let studentBoxAssignments: [(String, Int)] = [("Steve Jobs", 121), ("The Woz", 314)]

    var customers = [Customer]()

    for (name, box) in studentBoxAssignments {
        let data = reedieData + (\.name, name) + (\.addressLine3, "Box #\(box)")
        if let customer: Customer = Customer(data) {
            customers += [customer]
        } else {
            print("Data is missing.")
        }
    }

    print(customers)
}

/// Test for initializing a private(set) value
/// with force-cast WritableKeyPath
final class Foo {
    private(set) var bar: NSNumber?
    private(set) var baz: URLSession?
}

extension Foo: PropertyInitializable {
    /// Required due to present inability to WritableKeyPath to initialize a value.
    nonisolated(unsafe) internal static let _blank: Foo = Foo()
}

/// A test struct of a mockable object, e.g. from a webservice.
struct Zag: PropertyInitializable {
    var a: Int
    var b: String
    var c: Double?
    
    internal static var _blank: Zag {
        return Zag(a: 1, b: "1", c: 1.0)
    }
}

/// A test struct of a mockable object, e.g. from a webservice.
struct Mag: Mockable {
    var a: Int
    var b: String
    var c: Double?
    
    internal static var _blank: Mag {
        return Mag(a: 1, b: "10", c: 1.0)
    }
}

extension Mag {
    // todo
    // Custom property initter
}

/// Further illustrates the current limitations.
struct Hat {
    /// breaks PropertyInitializable if uncommented,
    /// since let cannot be set via keypaths
    //let a: Int
    
    /// Breaks PropertyInitializable if uncommented,
    /// since private var cannot be set via keypaths
    //private var b: Int
    
    /// Breaks PropertyInitializable if uncommented,
    /// since let cannot be set via keypaths,
    /// and there is no way to check if it has a default value
    //let d = 1
    
    /// Breaks PropertyInitializable if uncommented,
    /// since private var cannot be set via keypaths,
    /// and there is no way to check if it has a default value
    //private var e = 1
    
    /// Breaks PropertyInitializable if uncommented, since f has a default value,
    /// and private(set) is externally immutable once set.
    /// Also, now in Swift 5 all keypaths to private(set) are non-writable.
    //private(set) var f = 1
    
    var c: Int
    
    /// Must be set again for PropertyInitializable init to succeed,
    /// because reflection does not let us see whether a default value gets assigned.
    var g = 1
    
    var h: Int
}

extension Hat: PropertyInitializable {
    internal static var _blank: Hat {
        return Hat(c: 1, g: 1, h: 1)
    }
}

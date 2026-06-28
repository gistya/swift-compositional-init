/// A property that can generate its own values according to configurable behavior,
/// for the purpose of mocking a service (testing).
public protocol SourceableProperty: PropertyProtocol {
    var source: Source<Value> { get }
}

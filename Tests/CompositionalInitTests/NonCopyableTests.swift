import Testing
@testable import CompositionalInit

// A move-only type — it cannot be copied, so the only functional-update form available is the
// consuming closure `cloned`, which threads ownership through without ever copying.
private struct Resource: Cloneable, ~Copyable {
    var handle: Int
    var label: String
}

@Test func nonCopyableTypeSupportsConsumingClonedClosure() {
    let r = Resource(handle: 3, label: "a")
    let updated = r.cloned { $0.handle = 7 }   // consumes `r`
    #expect(updated.handle == 7)
    #expect(updated.label == "a")
}

@Test func nonCopyableConsumingClonedThreadsForward() {
    var r = Resource(handle: 0, label: "start")
    r = r.cloned { $0.handle += 1 }
    r = r.cloned { $0.label = "end" }
    #expect(r.handle == 1)
    #expect(r.label == "end")
}

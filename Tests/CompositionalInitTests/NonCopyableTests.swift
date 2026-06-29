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

// MARK: NonCopyableProperty — storable, composable edits for move-only values

@Test func nonCopyablePropertyBatchAppliesAllEdits() {
    let edits: [NonCopyableProperty<Resource>] = [
        .init { $0.handle = 5 },
        .init { $0.label = "open" },
    ]
    let r = Resource(handle: 0, label: "").cloned(applying: edits)
    #expect(r.handle == 5)
    #expect(r.label == "open")
}

@Test func nonCopyablePropertyVariadicAppliesInOrder() {
    let r = Resource(handle: 0, label: "x").cloned(
        applying: .init { $0.handle = 1 }, .init { $0.handle = 2 }
    )
    #expect(r.handle == 2) // edits apply left to right; last write wins
}

@Test func nonCopyablePropertyEmptyBatchIsIdentity() {
    let edits: [NonCopyableProperty<Resource>] = []
    let r = Resource(handle: 9, label: "id").cloned(applying: edits)
    #expect(r.handle == 9)
    #expect(r.label == "id")
}

@Test func nonCopyablePropertyAccumulatesAtRuntime() {
    // The reason the type exists: build the edit list dynamically, then apply in one consuming pass.
    var edits: [NonCopyableProperty<Resource>] = []
    for i in 1...3 { edits.append(.init { $0.handle += i }) }
    let r = Resource(handle: 0, label: "sum").cloned(applying: edits)
    #expect(r.handle == 6) // 0 + 1 + 2 + 3
}

/// A pending in-place edit of a (possibly non-copyable) `Root`, expressed as a mutation closure
/// rather than a key-path/value pair.
///
/// Key paths cannot refer to non-copyable types, so move-only values can't be described by
/// ``Property``/``PartialProperty`` or the `<-` operators. `NonCopyableProperty` fills the one gap
/// that inline ``Cloneable/cloned(_:)`` doesn't: accumulating a *storable, composable* batch of edits
/// at runtime and applying them to a move-only value in a single consuming pass — the reducer
/// pattern. It trades away key-path identity (no duplicate detection) and the `<-` sugar for the
/// ability to work on non-copyable roots.
///
/// For edits known at the call site, prefer inline `cloned { … }`.
///
/// ```swift
/// let edits: [NonCopyableProperty<Resource>] = [
///     .init { $0.handle = fd },
///     .init { $0.label = "open" },
/// ]
/// resource = resource.cloned(applying: edits)
/// ```
public struct NonCopyableProperty<Root: ~Copyable> {
    @usableFromInline
    let _apply: (inout Root) -> Void

    /// Wraps an in-place edit of `Root`.
    @inlinable
    public init(_ apply: @escaping (inout Root) -> Void) { self._apply = apply }

    /// Applies the edit to `root` in place.
    @inlinable
    public func apply(to root: inout Root) { _apply(&root) }
}

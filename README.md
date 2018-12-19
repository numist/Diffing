# Ordered Collection Diffing

This prototype implements ordered collection diffing as [proposed to swift-evolution](https://github.com/apple/swift-evolution/pull/968) and [pitched in swift-evolution](https://forums.swift.org/t/ordered-collection-diffing/18933).

## API Summary

### `OrderedCollection`

``` swift
/// An ordered collection treats the structural positions of its elements as
/// part of its interface. Differences in order always affect whether two
/// instances are equal.
///
/// For example, a tree is an ordered collection; a dictionary is not.
@available(swift, introduced: 5.1)
public protocol OrderedCollection : Collection
    where SubSequence : OrderedCollection
{
    /// Returns a Boolean value indicating whether this ordered collection and
    /// another ordered collection contain equivalent elements in the same
    /// order, using the given predicate as the equivalence test.
    ///
    /// The predicate must be a *equivalence relation* over the elements. That
    /// is, for any elements `a`, `b`, and `c`, the following conditions must
    /// hold:
    ///
    /// - `areEquivalent(a, a)` is always `true`. (Reflexivity)
    /// - `areEquivalent(a, b)` implies `areEquivalent(b, a)`. (Symmetry)
    /// - If `areEquivalent(a, b)` and `areEquivalent(b, c)` are both `true`,
    ///   then `areEquivalent(a, c)` is also `true`. (Transitivity)
    ///
    /// - Parameters:
    ///   - other: An ordered collection to compare to this ordered collection.
    ///   - areEquivalent: A predicate that returns `true` if its two arguments
    ///     are equivalent; otherwise, `false`.
    /// - Returns: `true` if this ordered collection and `other` contain
    ///   equivalent items, using `areEquivalent` as the equivalence test;
    ///   otherwise, `false.`
    ///
    /// - Complexity: O(*m*), where *m* is the lesser of the length of the
    ///   ordered collection and the length of `other`.
    func elementsEqual<C>(
       _ other: C, by areEquivalent: (Element, C.Element) throws -> Bool
    ) rethrows -> Bool where C : OrderedCollection
}

extension OrderedCollection {
    /// Returns the difference needed to produce the receiver's state from the
    /// parameter's state, using the provided closure to establish equivalence
    /// between elements.
    ///
    /// This function does not infer element moves, but they can be computed
    /// using `OrderedCollectionDifference.inferringMoves()` if
    /// desired.
    ///
    /// Implementation is an optimized variation of the algorithm described by
    /// E. Myers (1986).
    ///
    /// - Parameters:
    ///   - other: The base state.
    ///   - areEquivalent: A closure that returns whether the two
    ///     parameters are equivalent.
    ///
    /// - Returns: The difference needed to produce the reciever's state from
    ///   the parameter's state.
    ///
    /// - Complexity: O(*n* * *d*), where *n* is `other.count + self.count` and
    ///   *d* is the number of differences between the two ordered collections.
    public func difference<C: OrderedCollection>(
        from other: C, by areEquivalent: (Element, C.Element) -> Bool
    ) -> OrderedCollectionDifference<Element> where C.Element == Self.Element
}

extension OrderedCollection where Element: Equatable {
    /// Returns the difference needed to produce the receiver's state from the
    /// parameter's state, using equality to establish equivalence between
    /// elements.
    ///
    /// This function does not infer element moves, but they can be computed
    /// using `OrderedCollectionDifference.inferringMoves()` if
    /// desired.
    ///
    /// Implementation is an optimized variation of the algorithm described by
    /// E. Myers (1986).
    ///
    /// - Parameters:
    ///   - other: The base state.
    ///
    /// - Returns: The difference needed to produce the reciever's state from
    ///   the parameter's state.
    ///
    /// - Complexity: O(*n* * *d*), where *n* is `other.count + self.count` and
    ///   *d* is the number of differences between the two ordered collections.
    public func difference<C>(from other: C) -> OrderedCollectionDifference<Element>
        where C: OrderedCollection, C.Element == Self.Element
    
    /// Returns a Boolean value indicating whether this ordered collection and
    /// another ordered collection contain the same elements in the same order.
    ///
    /// This example tests whether one countable range shares the same elements
    /// as another countable range and an array.
    ///
    ///     let a = 1...3
    ///     let b = 1...10
    ///
    ///     print(a.elementsEqual(b))
    ///     // Prints "false"
    ///     print(a.elementsEqual([1, 2, 3]))
    ///     // Prints "true"
    ///
    /// - Parameter other: An ordered collection to compare to this ordered
    ///   collection.
    /// - Returns: `true` if this ordered collection and `other` contain the
    ///   same elements in the same order.
    ///
    /// - Complexity: O(*m*), where *m* is the lesser of the `count` of the
    ///   ordered collection and the `count` of `other`.
    public func elementsEqual<C>(_ other: C) -> Bool
        where C : OrderedCollection, C.Element == Element
}

// stdlib conformance:
extension Array : OrderedCollection {}
extension ArraySlice : OrderedCollection {}
extension ClosedRange : OrderedCollection where Bound : Strideable, Bound.Stride : SignedInteger {}
extension CollectionOfOne : OrderedCollection {}
extension ContiguousArray : OrderedCollection {}
extension CountingIndexCollection : OrderedCollection where Base : OrderedCollection {}
extension EmptyCollection : OrderedCollection {}
extension Range : OrderedCollection where Bound : Strideable, Bound.Stride : SignedInteger {}
extension Slice : OrderedCollection where Base : OrderedCollection {}
extension String : OrderedCollection {}
extension Substring : OrderedCollection {}
extension UnsafeBufferPointer : OrderedCollection {}
extension UnsafeMutableBufferPointer : OrderedCollection {}
extension UnsafeMutableRawBufferPointer : OrderedCollection {}
extension UnsafeRawBufferPointer : OrderedCollection {}

// In Foundation:
extension IndexPath : OrderedCollection {}
extension DataProtocol : OrderedCollection {}
```

### `OrderedCollectionDifference`

``` swift
/// A type that represents the difference between two ordered collection states.
@available(swift, introduced: 5.1)
public struct OrderedCollectionDifference<ChangeElement> {
    /// A type that represents a single change to an ordered collection.
    ///
    /// The `offset` of each `insert` refers to the offset of its `element` in
    /// the final state after the difference is fully applied. The `offset` of
    /// each `remove` refers to the offset of its `element` in the original
    /// state. Non-`nil` values of `associatedWith` refer to the offset of the
    /// complementary change.
    public enum Change {
        case insert(offset: Int, element: ChangeElement, associatedWith: Int?)
        case remove(offset: Int, element: ChangeElement, associatedWith: Int?)
    }

    /// Creates an instance from a collection of changes.
    ///
    /// For clients interested in the difference between two ordered
    /// collections, see `OrderedCollection.difference(from:)`.
    ///
    /// To guarantee that instances are unambiguous and safe for compatible base
    /// states, this initializer will fail unless its parameter meets to the
    /// following requirements:
    ///
    /// 1) All insertion offsets are unique
    /// 2) All removal offsets are unique
    /// 3) All offset associations between insertions and removals are symmetric
    ///
    /// - Parameter changes: A collection of changes that represent a transition
    ///   between two states.
    ///
    /// - Complexity: O(*n* * log(*n*)), where *n* is the length of the
    ///   parameter.
    public init?<C: Collection>(_ c: C) where C.Element == Change

    /// The `.insert` changes contained by this difference, from lowest offset to highest
    public var insertions: [Change] { get }
    
    /// The `.remove` changes contained by this difference, from lowest offset to highest
    public var removals: [Change] { get }
}

/// An OrderedCollectionDifference is itself a RandomAccessCollection.
///
/// The `Change` elements are ordered as:
///
/// 1. `.remove`s, from highest `offset` to lowest
/// 2. `.insert`s, from lowest `offset` to highest
///
/// This guarantees that applicators on compatible base states are safe when
/// written in the form:
///
/// ```
/// for c in diff {
///     switch c {
///     case .remove(offset: let o, element: _, associatedWith: _):
///         arr.remove(at: o)
///     case .insert(offset: let o, element: let e, associatedWith: _):
///         arr.insert(e, at: o)
///     }
/// }
/// ```
extension OrderedCollectionDifference : Collection {
    public typealias Element = OrderedCollectionDifference<ChangeElement>.Change
    public struct Index: Comparable, Hashable {}
}

extension OrderedCollectionDifference.Change: Equatable where ChangeElement: Equatable {}
extension OrderedCollectionDifference: Equatable where ChangeElement: Equatable {}

extension OrderedCollectionDifference.Change: Hashable where ChangeElement: Hashable {}
extension OrderedCollectionDifference: Hashable where ChangeElement: Hashable {
    /// Infers which `ChangeElement`s have been both inserted and removed only
    /// once and returns a new difference with those associations.
    ///
    /// - Returns: an instance with all possible moves inferred.
    ///
    /// - Complexity: O(*n*) where *n* is `self.count`
	public func inferringMoves() -> OrderedCollectionDifference<ChangeElement>
}

extension OrderedCollectionDifference: Codable where ChangeElement: Codable {}
```

### `RangeReplaceableCollection`

``` swift
extension RangeReplaceableCollection {
    /// Applies a difference to a collection.
    ///
    /// - Parameter difference: The difference to be applied.
    ///
    /// - Returns: An instance representing the state of the receiver with the
    ///   difference applied, or `nil` if the difference is incompatible with
    ///   the receiver's state.
    ///
    /// - Complexity: O(*n* + *c*), where *n* is `self.count` and *c* is the
    ///   number of changes contained by the parameter.
    @available(swift, introduced: 5.1)
    public func applying(_ difference: OrderedCollectionDifference<Element>) -> Self?
}
```

## Examples

### 3-way merge

``` swift
// Split the contents of the sources into lines
let baseLines = base.components(separatedBy: "\n")
let theirLines = theirs.components(separatedBy: "\n")
let myLines = mine.components(separatedBy: "\n")
    
// Create a difference from base to theirs
let diff = theirLines.difference(from:baseLines)
    
// Apply it to mine, if possible
guard let patchedLines = myLines.applying(diff) else {
    print("Merge conflict applying patch, manual merge required")
    return
}
    
// Reassemble the result
let patched = patchedLines.joined(separator: "\n")
print(patched)
```

### Reversing a diff

``` swift
let diff: OrderedCollectionDifference<Int> = /* ... */
let reversed = OrderedCollectionDifference<Int>(
    diff.map({(change) -> OrderedCollectionDifference<Int>.Change in
        switch change {
        case .insert(offset: let o, element: let e, associatedWith: let a):
            return .remove(offset: o, element: e, associatedWith: a)
        case .remove(offset: let o, element: let e, associatedWith: let a):
            return .insert(offset: o, element: e, associatedWith: a)
        }
    })
)!
```

### Inferring moves

``` swift
let diff = [0, 1, 2].difference(from:[2, 0, 1])

print(diff)
// OrderedCollectionDifference<Int>(
//     insertions: [Diffing.OrderedCollectionDifference<Swift.Int>.Change.insert(offset: 2, element: 2, associatedWith: nil)],
//     removals: [Diffing.OrderedCollectionDifference<Swift.Int>.Change.remove(offset: 0, element: 2, associatedWith: nil)]
// )

print(diff.inferringMoves())
// OrderedCollectionDifference<Int>(
//     insertions: [Diffing.OrderedCollectionDifference<Swift.Int>.Change.insert(offset: 2, element: 2, associatedWith: Optional(0))],
//     removals: [Diffing.OrderedCollectionDifference<Swift.Int>.Change.remove(offset: 0, element: 2, associatedWith: Optional(2))]
// )
```
